//
//  AuthenticationManager.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import Foundation
import SwiftUI

// MARK: - Authentication State

enum AuthenticationState: Equatable {
    case unauthenticated
    case authenticating
    case authenticated
    case needsVerification(email: String)
    case needsPasswordReset(email: String)
}

@Observable
@MainActor
final class AuthenticationManager {
    
    // MARK: - Published State
    
    var authState: AuthenticationState = .unauthenticated
    var isLoading = false
    var currentUser: User?
    var errorMessage: String?
    
    var isAuthenticated: Bool {
        authState == .authenticated
    }
    
    // MARK: - User Model
    
    struct User {
        let id: String
        let email: String
        let name: String
        let avatarInitials: String
        
        init(from authUser: AuthUser) {
            self.id = authUser.id
            self.email = authUser.email
            self.name = authUser.name ?? authUser.email.components(separatedBy: "@").first?.capitalized ?? "User"
            self.avatarInitials = String(name.prefix(2)).uppercased()
        }
        
        init(id: String, email: String, name: String) {
            self.id = id
            self.email = email
            self.name = name
            self.avatarInitials = String(name.prefix(2)).uppercased()
        }
    }
    
    // MARK: - Private Properties
    
    private let apiService: AuthAPIServiceProtocol
    private let keychain: KeychainService
    
    // MARK: - Initialization
    
    init(apiService: AuthAPIServiceProtocol? = nil, keychain: KeychainService = .shared) {
        // Always use real API service
        self.apiService = apiService ?? AuthAPIService()
        self.keychain = keychain
        
        // Check for existing session
        checkExistingSession()
    }
    
    // MARK: - Session Management
    
    private func checkExistingSession() {
        Task {
            await restoreSession()
        }
    }
    
    /// Restore session from stored tokens
    func restoreSession() async {
        guard let tokens = try? keychain.getTokens() else {
            authState = .unauthenticated
            return
        }
        
        // If token needs refresh, try to refresh it
        if tokens.needsRefresh || tokens.isExpired {
            await refreshSession()
        } else {
            // Token is still valid
            currentUser = User(from: tokens.user)
            authState = .authenticated
        }
    }
    
    /// Refresh the access token using refresh token
    func refreshSession() async {
        guard let refreshToken = keychain.getRefreshToken() else {
            authState = .unauthenticated
            return
        }
        
        do {
            let response = try await apiService.refreshToken(refreshToken)
            try saveTokens(from: response)
            currentUser = User(from: response.user)
            authState = .authenticated
        } catch {
            // Refresh failed, user needs to login again
            try? keychain.deleteTokens()
            authState = .unauthenticated
        }
    }
    
    // MARK: - Authentication Methods
    
    /// Login with email and password
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        // Validation
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter your email and password"
            isLoading = false
            return
        }
        
        guard email.contains("@") else {
            errorMessage = "Please enter a valid email address"
            isLoading = false
            return
        }
        
        do {
            let response = try await apiService.login(email: email, password: password)
            try saveTokens(from: response)
            currentUser = User(from: response.user)
            authState = .authenticated
        } catch let error as AuthServiceError {
            handleAuthError(error, email: email)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Sign up a new user
    func signUp(name: String, email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        // Validation
        guard !name.isEmpty else {
            errorMessage = "Please enter your name"
            isLoading = false
            return
        }
        
        guard !email.isEmpty, email.contains("@") else {
            errorMessage = "Please enter a valid email address"
            isLoading = false
            return
        }
        
        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters"
            isLoading = false
            return
        }
        
        do {
            let response = try await apiService.signUp(email: email, password: password, name: name)
            
            if response.needsConfirmation == true {
                authState = .needsVerification(email: email)
            } else {
                // Auto-confirmed (shouldn't happen with Cognito email verification)
                await login(email: email, password: password)
            }
        } catch let error as AuthServiceError {
            handleAuthError(error, email: email)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Confirm email with verification code
    func confirmEmail(email: String, code: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        guard !code.isEmpty else {
            errorMessage = "Please enter the verification code"
            isLoading = false
            return false
        }
        
        do {
            _ = try await apiService.confirmSignUp(email: email, code: code)
            isLoading = false
            return true
        } catch let error as AuthServiceError {
            handleAuthError(error, email: email)
            isLoading = false
            return false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    /// Resend verification code
    func resendVerificationCode(email: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await apiService.resendCode(email: email)
            // Show success feedback
        } catch let error as AuthServiceError {
            handleAuthError(error, email: email)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Request password reset
    func forgotPassword(email: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        guard !email.isEmpty, email.contains("@") else {
            errorMessage = "Please enter a valid email address"
            isLoading = false
            return false
        }
        
        do {
            _ = try await apiService.forgotPassword(email: email)
            authState = .needsPasswordReset(email: email)
            isLoading = false
            return true
        } catch let error as AuthServiceError {
            handleAuthError(error, email: email)
            isLoading = false
            return false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    /// Reset password with code
    func resetPassword(email: String, code: String, newPassword: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        guard !code.isEmpty else {
            errorMessage = "Please enter the reset code"
            isLoading = false
            return false
        }
        
        guard newPassword.count >= 8 else {
            errorMessage = "Password must be at least 8 characters"
            isLoading = false
            return false
        }
        
        do {
            _ = try await apiService.resetPassword(email: email, code: code, newPassword: newPassword)
            authState = .unauthenticated
            isLoading = false
            return true
        } catch let error as AuthServiceError {
            handleAuthError(error, email: email)
            isLoading = false
            return false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    /// Logout and clear session
    func logout() {
        try? keychain.deleteTokens()
        currentUser = nil
        authState = .unauthenticated
        errorMessage = nil
    }
    
    /// Get current access token (refreshing if needed)
    func getAccessToken() async -> String? {
        guard let tokens = try? keychain.getTokens() else {
            return nil
        }
        
        if tokens.needsRefresh || tokens.isExpired {
            await refreshSession()
            return try? keychain.getTokens()?.accessToken
        }
        
        return tokens.accessToken
    }
    
    // MARK: - Private Helpers
    
    private func saveTokens(from response: AuthResponse) throws {
        let expiresAt = Date().addingTimeInterval(TimeInterval(response.expiresIn))
        
        print("💾 AuthManager: Saving tokens, expires in \(response.expiresIn) seconds")
        print("💾 AuthManager: Token will expire at \(expiresAt)")
        print("💾 AuthManager: Access token length: \(response.accessToken.count)")
        
        let tokens = StoredTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresAt: expiresAt,
            user: response.user
        )
        
        try keychain.saveTokens(tokens)
        print("✅ AuthManager: Tokens saved to keychain")
    }
    
    private func handleAuthError(_ error: AuthServiceError, email: String) {
        print("🔍 AuthManager: Handling error: \(error)")
        switch error {
        case .userNotConfirmed:
            print("✅ AuthManager: Setting state to needsVerification for email: '\(email)'")
            authState = .needsVerification(email: email)
            errorMessage = error.errorDescription
        case .passwordResetRequired:
            authState = .needsPasswordReset(email: email)
            errorMessage = error.errorDescription
        default:
            errorMessage = error.errorDescription
        }
    }
}

// MARK: - Environment Key

struct AuthenticationManagerKey: EnvironmentKey {
    static let defaultValue = AuthenticationManager()
}

extension EnvironmentValues {
    var authManager: AuthenticationManager {
        get { self[AuthenticationManagerKey.self] }
        set { self[AuthenticationManagerKey.self] = newValue }
    }
}
