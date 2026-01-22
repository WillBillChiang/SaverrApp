//
//  LoginView.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import SwiftUI

// Helper to make String work with sheet(item:)
extension String: Identifiable {
    public var id: String { self }
}

struct LoginView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.authManager) var authManager

    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    @State private var showPassword = false
    @State private var showForgotPassword = false
    @State private var pendingVerificationEmail: String?

    var body: some View {
        ZStack {
            // Background
            (colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 60)

                    // Logo and Welcome
                    headerSection

                    // Login Form
                    formSection

                    // Login Button
                    loginButton

                    // Sign Up Link
                    signUpSection

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView()
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
        .sheet(item: $pendingVerificationEmail) { emailToVerify in
            EmailVerificationView(email: emailToVerify) {
                pendingVerificationEmail = nil
                // After verification, try to login
                Task {
                    await authManager.login(email: emailToVerify, password: password)
                }
            }
        }
        .onChange(of: authManager.authState) { _, newState in
            
            // Handle verification required state
            if case .needsVerification(let email) = newState {
                pendingVerificationEmail = email
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 16) {
            // App Icon
            Image("Saverr_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)


            VStack(spacing: 8) {
                Text("Welcome to Saverr")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

                Text("Your friendly financial buddy")
                    .font(.subheadline)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
            }
        }
    }

    private var formSection: some View {
        VStack(spacing: 16) {
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

                HStack(spacing: 12) {
                    Image(systemName: "envelope")
                        .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)

                    TextField("your@email.com", text: $email)
                        .textFieldStyle(.plain)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                .padding()
                .background(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackgroundLight)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

                HStack(spacing: 12) {
                    Image(systemName: "lock")
                        .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)

                    if showPassword {
                        TextField("Enter password", text: $password)
                            .textFieldStyle(.plain)
                            .textContentType(.password)
                    } else {
                        SecureField("Enter password", text: $password)
                            .textFieldStyle(.plain)
                            .textContentType(.password)
                    }

                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                    }
                }
                .padding()
                .background(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackgroundLight)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Forgot Password
            HStack {
                Spacer()
                Button("Forgot password?") {
                    showForgotPassword = true
                }
                .font(.subheadline)
                .foregroundStyle(Color.accentPrimary)
            }

            // Error Message
            if let error = authManager.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.circle")
                    Text(error)
                }
                .font(.caption)
                .foregroundStyle(Color.dangerColor)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.dangerColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var loginButton: some View {
        Button {
            Task {
                await authManager.login(email: email, password: password)
            }
        } label: {
            HStack(spacing: 8) {
                if authManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Log In")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.accentPrimary)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(authManager.isLoading)
    }

    private var signUpSection: some View {
        HStack(spacing: 4) {
            Text("Don't have an account?")
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)

            Button("Sign up") {
                showSignUp = true
            }
            .fontWeight(.semibold)
            .foregroundStyle(Color.accentPrimary)
        }
        .font(.subheadline)
    }
}

#Preview {
    LoginView()
}
