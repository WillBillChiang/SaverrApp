//
//  SignUpView.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.authManager) var authManager

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var agreeToTerms = false
    @State private var showEmailVerification = false
    @State private var verificationEmail = ""

    var passwordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }

    var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && email.contains("@") &&
        password.count >= 8 && passwordsMatch && agreeToTerms
    }

    var body: some View {
        NavigationStack {
            ZStack {
                (colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Header
                        headerSection

                        // Form
                        formSection

                        // Terms
                        termsSection

                        // Sign Up Button
                        signUpButton

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showEmailVerification) {
                EmailVerificationView(email: verificationEmail) {
                    showEmailVerification = false
                    // After verification, try to login
                    Task {
                        await authManager.login(email: verificationEmail, password: password)
                        if authManager.isAuthenticated {
                            dismiss()
                        }
                    }
                }
                .id(verificationEmail) // Force recreate when email changes
            }
            .onChange(of: authManager.authState) { _, newState in
                // Handle verification required state
                if case .needsVerification(let email) = newState {
                    verificationEmail = email
                    showEmailVerification = true
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Create Account")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

            Text("Start your journey to financial freedom")
                .font(.subheadline)
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
        }
    }

    private var formSection: some View {
        VStack(spacing: 16) {
            // Name Field
            formField(title: "Full Name", icon: "person") {
                TextField("John Doe", text: $name)
                    .textFieldStyle(.plain)
                    .textContentType(.name)
            }

            // Email Field
            formField(title: "Email", icon: "envelope") {
                TextField("your@email.com", text: $email)
                    .textFieldStyle(.plain)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }

            // Password Field
            formField(title: "Password", icon: "lock") {
                HStack {
                    if showPassword {
                        TextField("At least 8 characters", text: $password)
                            .textFieldStyle(.plain)
                    } else {
                        SecureField("At least 8 characters", text: $password)
                            .textFieldStyle(.plain)
                    }

                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                    }
                }
            }
            
            // Password requirements
            VStack(alignment: .leading, spacing: 4) {
                passwordRequirement("At least 8 characters", met: password.count >= 8)
                passwordRequirement("Contains uppercase letter", met: password.contains(where: { $0.isUppercase }))
                passwordRequirement("Contains lowercase letter", met: password.contains(where: { $0.isLowercase }))
                passwordRequirement("Contains number", met: password.contains(where: { $0.isNumber }))
            }
            .padding(.top, -8)

            // Confirm Password Field
            formField(title: "Confirm Password", icon: "lock.fill") {
                HStack {
                    SecureField("Re-enter password", text: $confirmPassword)
                        .textFieldStyle(.plain)

                    if !confirmPassword.isEmpty {
                        Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(passwordsMatch ? Color.successColor : Color.dangerColor)
                    }
                }
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

    private func formField<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                    .frame(width: 20)

                content()
            }
            .padding()
            .background(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackgroundLight)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func passwordRequirement(_ text: String, met: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.caption2)
                .foregroundStyle(met ? Color.successColor : (colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight))
            
            Text(text)
                .font(.caption2)
                .foregroundStyle(met ? Color.successColor : (colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight))
        }
    }

    private var termsSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                agreeToTerms.toggle()
            } label: {
                Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(agreeToTerms ? Color.accentPrimary : (colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight))
            }

            Text("I agree to the ")
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
            + Text("Terms of Service")
                .foregroundStyle(Color.accentPrimary)
            + Text(" and ")
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
            + Text("Privacy Policy")
                .foregroundStyle(Color.accentPrimary)
        }
        .font(.subheadline)
    }

    private var signUpButton: some View {
        Button {
            Task {
                await authManager.signUp(name: name, email: email, password: password)
                // The onChange handler will show verification sheet if needed
            }
        } label: {
            HStack(spacing: 8) {
                if authManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Create Account")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isFormValid ? Color.accentPrimary : Color.gray)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!isFormValid || authManager.isLoading)
    }
}

#Preview {
    SignUpView()
}
