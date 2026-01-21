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

    var passwordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }

    var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && email.contains("@") &&
        password.count >= 6 && passwordsMatch && agreeToTerms
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
                        TextField("At least 6 characters", text: $password)
                            .textFieldStyle(.plain)
                    } else {
                        SecureField("At least 6 characters", text: $password)
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

            // Password strength indicator
            if !password.isEmpty {
                passwordStrengthIndicator
            }

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

    private var passwordStrengthIndicator: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                ForEach(0..<4) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index < passwordStrength ? strengthColor : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1)))
                        .frame(height: 4)
                }
            }

            Text(strengthText)
                .font(.caption)
                .foregroundStyle(strengthColor)
        }
    }

    private var passwordStrength: Int {
        var strength = 0
        if password.count >= 6 { strength += 1 }
        if password.count >= 8 { strength += 1 }
        if password.contains(where: { $0.isNumber }) { strength += 1 }
        if password.contains(where: { $0.isUppercase }) { strength += 1 }
        return strength
    }

    private var strengthText: String {
        switch passwordStrength {
        case 0: return "Very Weak"
        case 1: return "Weak"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Strong"
        default: return ""
        }
    }

    private var strengthColor: Color {
        switch passwordStrength {
        case 0, 1: return .dangerColor
        case 2: return .warningColor
        case 3, 4: return .successColor
        default: return .gray
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
                if authManager.isAuthenticated {
                    dismiss()
                }
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
