//
//  PlaidAPIService.swift
//  Saverr
//
//  Service for communicating with Plaid backend API
//

import Foundation

// MARK: - Plaid API Service Protocol

protocol PlaidAPIServiceProtocol {
    /// Get a link token to initialize Plaid Link
    func getLinkToken() async throws -> String
    
    /// Exchange public token and link the account
    func linkAccount(publicToken: String) async throws -> AccountLinkResponse
    
    /// Sync transactions for an account
    func syncTransactions(accountId: String) async throws -> SyncResponse
    
    /// Get transactions for an account
    func getTransactions(accountId: String, startDate: Date?, endDate: Date?) async throws -> [PlaidTransaction]
    
    /// Get all linked accounts
    func getLinkedAccounts() async throws -> [PlaidLinkedAccount]
    
    /// Refresh account balance from Plaid
    func refreshAccountBalance(accountId: String) async throws -> PlaidLinkedAccount
    
    /// Unlink an account
    func unlinkAccount(accountId: String) async throws
}

// MARK: - Plaid API Service

final class PlaidAPIService: PlaidAPIServiceProtocol {
    
    // MARK: - Configuration
    
    /// Base URL for your backend API
    /// TODO: Replace with your actual API Gateway URL
    private let baseURL: String
    //     API Endpoint:          
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    init(
        baseURL: String = ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "https://93bhx1f8z1.execute-api.us-east-1.amazonaws.com/dev",
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
        
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }
    
    // MARK: - Public Methods
    
    func getLinkToken() async throws -> String {
        let response: LinkTokenResponse = try await post(
            endpoint: "/accounts/link-token",
            body: EmptyBody()
        )
        return response.linkToken
    }
    
    func linkAccount(publicToken: String) async throws -> AccountLinkResponse {
        struct LinkRequest: Codable {
            let publicToken: String
            enum CodingKeys: String, CodingKey {
                case publicToken = "public_token"
            }
        }
        
        return try await post(
            endpoint: "/accounts/link",
            body: LinkRequest(publicToken: publicToken)
        )
    }
    
    func syncTransactions(accountId: String) async throws -> SyncResponse {
        return try await post(
            endpoint: "/accounts/\(accountId)/sync",
            body: EmptyBody()
        )
    }
    
    func getTransactions(accountId: String, startDate: Date?, endDate: Date?) async throws -> [PlaidTransaction] {
        var queryItems: [URLQueryItem] = []
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        if let start = startDate {
            queryItems.append(URLQueryItem(name: "start_date", value: dateFormatter.string(from: start)))
        }
        
        if let end = endDate {
            queryItems.append(URLQueryItem(name: "end_date", value: dateFormatter.string(from: end)))
        }
        
        let response: TransactionsResponse = try await get(
            endpoint: "/accounts/\(accountId)/transactions",
            queryItems: queryItems
        )
        
        return response.transactions
    }
    
    func getLinkedAccounts() async throws -> [PlaidLinkedAccount] {
        struct AccountsResponse: Codable {
            let accounts: [PlaidLinkedAccount]
        }
        
        let response: AccountsResponse = try await get(
            endpoint: "/accounts",
            queryItems: []
        )
        
        return response.accounts
    }
    
    func unlinkAccount(accountId: String) async throws {
        struct UnlinkResponse: Codable {
            let success: Bool
        }
        
        let _: UnlinkResponse = try await delete(endpoint: "/accounts/\(accountId)")
    }
    
    func refreshAccountBalance(accountId: String) async throws -> PlaidLinkedAccount {
        struct RefreshResponse: Codable {
            let account: PlaidLinkedAccount
        }
        
        let response: RefreshResponse = try await post(
            endpoint: "/accounts/\(accountId)/refresh",
            body: EmptyBody()
        )
        
        return response.account
    }
    
    // MARK: - Private Methods
    
    private struct EmptyBody: Codable {}
    
    private func get<R: Decodable>(
        endpoint: String,
        queryItems: [URLQueryItem]
    ) async throws -> R {
        guard var urlComponents = URLComponents(string: "\(baseURL)\(endpoint)") else {
            throw PlaidServiceError.invalidURL
        }
        
        if !queryItems.isEmpty {
            urlComponents.queryItems = queryItems
        }
        
        guard let url = urlComponents.url else {
            throw PlaidServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        addAuthHeader(to: &request)
        
        return try await performRequest(request)
    }
    
    private func post<T: Encodable, R: Decodable>(
        endpoint: String,
        body: T
    ) async throws -> R {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw PlaidServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        addAuthHeader(to: &request)
        
        request.httpBody = try encoder.encode(body)
        
        return try await performRequest(request)
    }
    
    private func delete<R: Decodable>(endpoint: String) async throws -> R {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw PlaidServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        addAuthHeader(to: &request)
        
        return try await performRequest(request)
    }
    
    private func performRequest<R: Decodable>(_ request: URLRequest) async throws -> R {
        print("🌐 PlaidAPI Request: \(request.httpMethod ?? "?") \(request.url?.absoluteString ?? "?")")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PlaidServiceError.invalidResponse
        }
        
        print("📥 PlaidAPI Response: Status \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            print("❌ PlaidAPI: Unauthorized (401)")
            throw PlaidServiceError.unauthorized
        }
        
        if httpResponse.statusCode == 403 {
            print("❌ PlaidAPI: Forbidden (403)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("   Response: \(responseString)")
            }
        }
        
        if httpResponse.statusCode >= 400 {
            if let apiError = try? decoder.decode(PlaidAPIError.self, from: data) {
                print("❌ PlaidAPI Error: \(apiError.errorDescription ?? "Unknown error")")
                throw PlaidServiceError.apiError(apiError.errorDescription ?? "Unknown error")
            }
            print("❌ PlaidAPI: Server error \(httpResponse.statusCode)")
            throw PlaidServiceError.serverError(httpResponse.statusCode)
        }
        
        do {
            // Debug: print raw response for link-token endpoint
            if let urlString = request.url?.absoluteString, urlString.contains("link-token") {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📦 PlaidAPI Raw Response: \(responseString)")
                }
            }
            return try decoder.decode(R.self, from: data)
        } catch {
            print("❌ PlaidAPI: Decoding error - \(error)")
            throw PlaidServiceError.decodingError(error)
        }
    }
    
    private func addAuthHeader(to request: inout URLRequest) {
        // Get access token from keychain
        if let accessToken = KeychainService.shared.getAccessToken() {
            // Print first and last few characters for debugging (don't print full token for security)
            let tokenPreview = accessToken.count > 20 ? "\(accessToken.prefix(10))...\(accessToken.suffix(10))" : accessToken
            print("🔐 PlaidAPI: Adding Bearer token (preview: \(tokenPreview))")
            print("🔐 PlaidAPI: Token length: \(accessToken.count) characters")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            print("❌ PlaidAPI: No access token found in keychain!")
        }
    }
}

// MARK: - Service Errors

enum PlaidServiceError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case apiError(String)
    case unauthorized
    case serverError(Int)
    case noLinkedAccounts
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API configuration"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to parse server response"
        case .apiError(let message):
            return message
        case .unauthorized:
            return "Please sign in to continue"
        case .serverError(let code):
            return "Server error (code: \(code))"
        case .noLinkedAccounts:
            return "No linked accounts found"
        }
    }
}
