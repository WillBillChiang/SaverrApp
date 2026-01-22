//
//  AuthModels.swift
//  Saverr
//
//  Models for authentication API requests and responses
//

import Foundation

// MARK: - Request Models

struct SignUpRequest: Codable {
    let email: String
    let password: String
    let name: String
}

struct ConfirmSignUpRequest: Codable {
    let email: String
    let code: String
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

struct ForgotPasswordRequest: Codable {
    let email: String
}

struct ResetPasswordRequest: Codable {
    let email: String
    let code: String
    let newPassword: String
    
    enum CodingKeys: String, CodingKey {
        case email
        case code
        case newPassword = "new_password"
    }
}

struct ResendCodeRequest: Codable {
    let email: String
}

// MARK: - Response Models

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let user: AuthUser
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case user
    }
}

struct AuthUser: Codable {
    let id: String
    let email: String
    let name: String?
}

struct SignUpResponse: Decodable {
    let message: String
    let userId: String?
    let needsConfirmation: Bool?
    let userConfirmed: Bool?
    let user: SignUpUser?
    
    enum CodingKeys: String, CodingKey {
        case message
        case userId = "user_id"
        case needsConfirmation = "needs_confirmation"
        case userConfirmed = "user_confirmed"
        case user
        // Also support the backend's alternative naming
        case confirmationRequired = "confirmation_required"
    }
    
    // Custom initializer for creating instances programmatically
    init(message: String, userId: String? = nil, needsConfirmation: Bool? = nil, userConfirmed: Bool? = nil, user: SignUpUser? = nil) {
        self.message = message
        self.userId = userId
        self.needsConfirmation = needsConfirmation
        self.userConfirmed = userConfirmed
        self.user = user
    }
    
    // Custom decoder to handle multiple backend response formats
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        message = try container.decode(String.self, forKey: .message)
        userId = try? container.decode(String.self, forKey: .userId)
        user = try? container.decode(SignUpUser.self, forKey: .user)
        userConfirmed = try? container.decode(Bool.self, forKey: .userConfirmed)
        
        // Try both possible keys for confirmation requirement
        if let needs = try? container.decode(Bool.self, forKey: .needsConfirmation) {
            needsConfirmation = needs
        } else if let required = try? container.decode(Bool.self, forKey: .confirmationRequired) {
            needsConfirmation = required
        } else {
            needsConfirmation = nil
        }
    }
}

struct SignUpUser: Decodable {
    let email: String
    let name: String?
}

struct ConfirmResponse: Codable {
    let message: String
    let confirmed: Bool?
}

struct ForgotPasswordResponse: Codable {
    let message: String
    let deliveryMedium: String?
    
    enum CodingKeys: String, CodingKey {
        case message
        case deliveryMedium = "delivery_medium"
    }
}

struct ResetPasswordResponse: Codable {
    let message: String
    let success: Bool?
}

struct ResendCodeResponse: Codable {
    let message: String
    let deliveryMedium: String?
    
    enum CodingKeys: String, CodingKey {
        case message
        case deliveryMedium = "delivery_medium"
    }
}

// MARK: - Auth Error Response

struct AuthErrorResponse: Codable, LocalizedError {
    let error: String?
    let message: String?
    let code: String?
    
    var errorDescription: String? {
        message ?? error ?? "An authentication error occurred"
    }
}

// MARK: - Stored Token Info

struct StoredTokens: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let user: AuthUser
    
    var isExpired: Bool {
        Date() >= expiresAt
    }
    
    var needsRefresh: Bool {
        // Refresh if less than 5 minutes until expiry
        Date().addingTimeInterval(300) >= expiresAt
    }
}
