//
//  KeychainService.swift
//  Saverr
//
//  Secure storage for authentication tokens using Keychain
//

import Foundation
import Security

final class KeychainService {
    
    static let shared = KeychainService()
    
    private let service = "com.saverr.app"
    private let tokenKey = "auth_tokens"
    
    private init() {}
    
    // MARK: - Token Storage
    
    /// Save authentication tokens securely
    func saveTokens(_ tokens: StoredTokens) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(tokens)
        
        // Delete existing item first
        try? deleteTokens()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unableToSave(status)
        }
    }
    
    /// Retrieve stored authentication tokens
    func getTokens() throws -> StoredTokens? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unableToRetrieve(status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.invalidData
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(StoredTokens.self, from: data)
    }
    
    /// Delete stored tokens
    func deleteTokens() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenKey
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete(status)
        }
    }
    
    /// Update existing tokens
    func updateTokens(_ tokens: StoredTokens) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(tokens)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenKey
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        if status == errSecItemNotFound {
            // Item doesn't exist, save new
            try saveTokens(tokens)
        } else if status != errSecSuccess {
            throw KeychainError.unableToUpdate(status)
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Get the current access token if valid
    func getAccessToken() -> String? {
        do {
            guard let tokens = try getTokens() else {
                print("🔑 Keychain: No tokens found")
                return nil
            }
            
            print("🔑 Keychain: Token expires at \(tokens.expiresAt), isExpired: \(tokens.isExpired)")
            print("🔑 Keychain: Current time: \(Date())")
            
            if tokens.isExpired {
                print("⚠️ Keychain: Token is expired, returning nil")
                return nil
            }
            
            return tokens.accessToken
        } catch {
            print("❌ Keychain: Error getting tokens - \(error)")
            return nil
        }
    }
    
    /// Get the refresh token
    func getRefreshToken() -> String? {
        return try? getTokens()?.refreshToken
    }
    
    /// Check if user has valid stored session
    func hasValidSession() -> Bool {
        guard let tokens = try? getTokens() else {
            return false
        }
        // Session is valid if we have a refresh token (even if access token expired)
        return !tokens.refreshToken.isEmpty
    }
}

// MARK: - Keychain Errors

enum KeychainError: LocalizedError {
    case unableToSave(OSStatus)
    case unableToRetrieve(OSStatus)
    case unableToDelete(OSStatus)
    case unableToUpdate(OSStatus)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .unableToSave(let status):
            return "Unable to save to keychain (status: \(status))"
        case .unableToRetrieve(let status):
            return "Unable to retrieve from keychain (status: \(status))"
        case .unableToDelete(let status):
            return "Unable to delete from keychain (status: \(status))"
        case .unableToUpdate(let status):
            return "Unable to update keychain (status: \(status))"
        case .invalidData:
            return "Invalid data in keychain"
        }
    }
}
