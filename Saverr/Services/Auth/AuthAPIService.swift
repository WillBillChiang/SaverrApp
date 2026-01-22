//
//  AuthAPIService.swift
//  Saverr
//
//  API service for authentication endpoints
//

import Foundation

// MARK: - Auth API Service Protocol

protocol AuthAPIServiceProtocol {
    /// Register a new user
    func signUp(email: String, password: String, name: String) async throws -> SignUpResponse
    
    /// Confirm email with verification code
    func confirmSignUp(email: String, code: String) async throws -> ConfirmResponse
    
    /// Login and get tokens
    func login(email: String, password: String) async throws -> AuthResponse
    
    /// Refresh the access token
    func refreshToken(_ refreshToken: String) async throws -> AuthResponse
    
    /// Request password reset
    func forgotPassword(email: String) async throws -> ForgotPasswordResponse
    
    /// Complete password reset with code
    func resetPassword(email: String, code: String, newPassword: String) async throws -> ResetPasswordResponse
    
    /// Resend verification code
    func resendCode(email: String) async throws -> ResendCodeResponse
}

// MARK: - Auth API Service

final class AuthAPIService: AuthAPIServiceProtocol {
    
    // MARK: - Configuration
    
    private let baseURL: String
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
    
    func signUp(email: String, password: String, name: String) async throws -> SignUpResponse {
        let request = SignUpRequest(email: email, password: password, name: name)
        return try await post(endpoint: "/auth/signup", body: request)
    }
    
    func confirmSignUp(email: String, code: String) async throws -> ConfirmResponse {
        let request = ConfirmSignUpRequest(email: email, code: code)
        return try await post(endpoint: "/auth/confirm", body: request)
    }
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let request = LoginRequest(email: email, password: password)
        return try await post(endpoint: "/auth/login", body: request)
    }
    
    func refreshToken(_ refreshToken: String) async throws -> AuthResponse {
        let request = RefreshTokenRequest(refreshToken: refreshToken)
        return try await post(endpoint: "/auth/refresh", body: request)
    }
    
    func forgotPassword(email: String) async throws -> ForgotPasswordResponse {
        let request = ForgotPasswordRequest(email: email)
        return try await post(endpoint: "/auth/forgot-password", body: request)
    }
    
    func resetPassword(email: String, code: String, newPassword: String) async throws -> ResetPasswordResponse {
        let request = ResetPasswordRequest(email: email, code: code, newPassword: newPassword)
        return try await post(endpoint: "/auth/reset-password", body: request)
    }
    
    func resendCode(email: String) async throws -> ResendCodeResponse {
        let request = ResendCodeRequest(email: email)
        return try await post(endpoint: "/auth/resend-code", body: request)
    }
    
    // MARK: - Private Methods
    
    private func post<T: Encodable, R: Decodable>(
        endpoint: String,
        body: T
    ) async throws -> R {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw AuthServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try encoder.encode(body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthServiceError.invalidResponse
        }
        
        // Handle error responses
        if httpResponse.statusCode >= 400 {
            print("❌ Auth API Error - Status: \(httpResponse.statusCode)")
            if let errorResponse = try? decoder.decode(AuthErrorResponse.self, from: data) {
                print("  Parsed Error: \(errorResponse.message ?? errorResponse.error ?? "unknown")")
                throw AuthServiceError.apiError(
                    code: errorResponse.code ?? "unknown",
                    message: errorResponse.message ?? errorResponse.error ?? "An error occurred"
                )
            }
            // Try to decode nested error structure
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorDict = json["error"] as? [String: String],
               let message = errorDict["message"],
               let code = errorDict["code"] {
                print("  Nested Error: \(message)")
                
                // Check if this is an email verification error
                if message.lowercased().contains("verify your email") || 
                   message.lowercased().contains("email address before logging in") {
                    throw AuthServiceError.userNotConfirmed
                }
                
                // Check for other known error patterns
                if message.lowercased().contains("already exists") {
                    throw AuthServiceError.userAlreadyExists
                }
                
                throw AuthServiceError.apiError(code: code, message: message)
            }
            print("  Raw Error Data: \(String(data: data, encoding: .utf8) ?? "unable to decode")")
            throw AuthServiceError.serverError(httpResponse.statusCode)
        }
        
        do {
            return try decoder.decode(R.self, from: data)
        } catch {
            throw AuthServiceError.decodingError(error)
        }
    }
}

// MARK: - Auth Service Errors

enum AuthServiceError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case apiError(code: String, message: String)
    case serverError(Int)
    case invalidCredentials
    case userNotConfirmed
    case userAlreadyExists
    case expiredCode
    case invalidCode
    case passwordResetRequired
    case tooManyAttempts
    
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
        case .apiError(_, let message):
            return message
        case .serverError(let code):
            return "Server error (code: \(code))"
        case .invalidCredentials:
            return "Invalid email or password"
        case .userNotConfirmed:
            return "Please verify your email address"
        case .userAlreadyExists:
            return "An account with this email already exists"
        case .expiredCode:
            return "Verification code has expired"
        case .invalidCode:
            return "Invalid verification code"
        case .passwordResetRequired:
            return "Password reset is required"
        case .tooManyAttempts:
            return "Too many attempts. Please try again later"
        }
    }
    
    /// Map Cognito error codes to our error types
    static func fromCognitoCode(_ code: String, message: String) -> AuthServiceError {
        switch code {
        case "NotAuthorizedException":
            return .invalidCredentials
        case "UserNotConfirmedException":
            return .userNotConfirmed
        case "UsernameExistsException":
            return .userAlreadyExists
        case "ExpiredCodeException":
            return .expiredCode
        case "CodeMismatchException":
            return .invalidCode
        case "PasswordResetRequiredException":
            return .passwordResetRequired
        case "TooManyRequestsException", "LimitExceededException":
            return .tooManyAttempts
        default:
            return .apiError(code: code, message: message)
        }
    }
}

// MARK: - Mock Auth API Service

final class MockAuthAPIService: AuthAPIServiceProtocol {
    
    private let simulatedDelay: UInt64 = 1_000_000_000 // 1 second
    
    // Simulated user database
    private var users: [String: (password: String, name: String, confirmed: Bool)] = [:]
    private var pendingCodes: [String: String] = [:]
    
    func signUp(email: String, password: String, name: String) async throws -> SignUpResponse {
        try await Task.sleep(nanoseconds: simulatedDelay)
        
        if users[email] != nil {
            throw AuthServiceError.userAlreadyExists
        }
        
        // Store user as unconfirmed
        users[email] = (password: password, name: name, confirmed: false)
        
        // Generate mock verification code
        let code = String(format: "%06d", Int.random(in: 0..<1000000))
        pendingCodes[email] = code
        print("📧 Mock verification code for \(email): \(code)")
        
        return SignUpResponse(
            message: "Verification code sent to \(email)",
            userId: UUID().uuidString,
            needsConfirmation: true
        )
    }
    
    func confirmSignUp(email: String, code: String) async throws -> ConfirmResponse {
        try await Task.sleep(nanoseconds: simulatedDelay)
        
        guard let expectedCode = pendingCodes[email] else {
            throw AuthServiceError.expiredCode
        }
        
        // For testing, accept "123456" as a universal code
        guard code == expectedCode || code == "123456" else {
            throw AuthServiceError.invalidCode
        }
        
        // Mark user as confirmed
        if var user = users[email] {
            user.confirmed = true
            users[email] = user
        }
        
        pendingCodes.removeValue(forKey: email)
        
        return ConfirmResponse(message: "Email confirmed successfully", confirmed: true)
    }
    
    func login(email: String, password: String) async throws -> AuthResponse {
        try await Task.sleep(nanoseconds: simulatedDelay)
        
        guard let user = users[email] else {
            throw AuthServiceError.invalidCredentials
        }
        
        guard user.password == password else {
            throw AuthServiceError.invalidCredentials
        }
        
        guard user.confirmed else {
            throw AuthServiceError.userNotConfirmed
        }
        
        return AuthResponse(
            accessToken: "mock-access-token-\(UUID().uuidString)",
            refreshToken: "mock-refresh-token-\(UUID().uuidString)",
            expiresIn: 3600,
            user: AuthUser(
                id: UUID().uuidString,
                email: email,
                name: user.name
            )
        )
    }
    
    func refreshToken(_ refreshToken: String) async throws -> AuthResponse {
        try await Task.sleep(nanoseconds: simulatedDelay)
        
        return AuthResponse(
            accessToken: "mock-access-token-\(UUID().uuidString)",
            refreshToken: "mock-refresh-token-\(UUID().uuidString)",
            expiresIn: 3600,
            user: AuthUser(
                id: UUID().uuidString,
                email: "user@example.com",
                name: "User"
            )
        )
    }
    
    func forgotPassword(email: String) async throws -> ForgotPasswordResponse {
        try await Task.sleep(nanoseconds: simulatedDelay)
        
        let code = String(format: "%06d", Int.random(in: 0..<1000000))
        pendingCodes[email] = code
        print("📧 Mock password reset code for \(email): \(code)")
        
        return ForgotPasswordResponse(
            message: "Password reset code sent to \(email)",
            deliveryMedium: "EMAIL"
        )
    }
    
    func resetPassword(email: String, code: String, newPassword: String) async throws -> ResetPasswordResponse {
        try await Task.sleep(nanoseconds: simulatedDelay)
        
        guard let expectedCode = pendingCodes[email], code == expectedCode || code == "123456" else {
            throw AuthServiceError.invalidCode
        }
        
        if var user = users[email] {
            user.password = newPassword
            users[email] = user
        }
        
        pendingCodes.removeValue(forKey: email)
        
        return ResetPasswordResponse(message: "Password reset successfully", success: true)
    }
    
    func resendCode(email: String) async throws -> ResendCodeResponse {
        try await Task.sleep(nanoseconds: simulatedDelay)
        
        let code = String(format: "%06d", Int.random(in: 0..<1000000))
        pendingCodes[email] = code
        print("📧 Mock verification code for \(email): \(code)")
        
        return ResendCodeResponse(
            message: "Verification code resent to \(email)",
            deliveryMedium: "EMAIL"
        )
    }
}
