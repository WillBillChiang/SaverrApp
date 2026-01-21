//
//  AuthenticationManager.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class AuthenticationManager {
    var isAuthenticated = false
    var isLoading = false
    var currentUser: User?
    var errorMessage: String?

    struct User {
        let id: UUID
        let email: String
        let name: String
        let avatarInitials: String
    }

    init() {
        // Check if user was previously logged in
        checkExistingSession()
    }

    private func checkExistingSession() {
        // In production, check Keychain for stored tokens
        // For now, always start logged out
        isAuthenticated = false
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        // Simulate network delay
        try? await Task.sleep(for: .seconds(1.5))

        // Mock validation
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

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            isLoading = false
            return
        }

        // Mock successful login
        let name = email.components(separatedBy: "@").first?.capitalized ?? "User"
        let initials = String(name.prefix(2)).uppercased()

        currentUser = User(
            id: UUID(),
            email: email,
            name: name,
            avatarInitials: initials
        )

        isAuthenticated = true
        isLoading = false
    }

    func signUp(name: String, email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        try? await Task.sleep(for: .seconds(1.5))

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

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            isLoading = false
            return
        }

        let initials = String(name.prefix(2)).uppercased()

        currentUser = User(
            id: UUID(),
            email: email,
            name: name,
            avatarInitials: initials
        )

        isAuthenticated = true
        isLoading = false
    }

    func logout() {
        currentUser = nil
        isAuthenticated = false
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
