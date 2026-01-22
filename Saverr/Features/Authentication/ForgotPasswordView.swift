//
//  ForgotPasswordView.swift
//  Saverr
//
//  View for requesting password reset
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.authManager) private var authManager
    
    @State private var email = ""
    @State private var showResetPassword = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                (colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerSection
                        
                        // Email Input
                        emailInputSection
                        
                        // Send Button
                        sendButton
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
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
            .sheet(isPresented: $showResetPassword) {
                ResetPasswordView(email: email) {
                    showResetPassword = false
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Lock Icon
            ZStack {
                Circle()
                    .fill(Color.accentPrimary.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "lock.rotation")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.accentPrimary)
            }
            
            VStack(spacing: 8) {
                Text("Forgot Password?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                
                Text("Enter your email and we'll send you a code to reset your password")
                    .font(.subheadline)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Email Input Section
    
    private var emailInputSection: some View {
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
    
    // MARK: - Send Button
    
    private var sendButton: some View {
        Button {
            Task {
                let success = await authManager.forgotPassword(email: email)
                if success {
                    showResetPassword = true
                }
            }
        } label: {
            HStack(spacing: 8) {
                if authManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Send Reset Code")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(email.contains("@") ? Color.accentPrimary : Color.gray)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!email.contains("@") || authManager.isLoading)
    }
}

// MARK: - Reset Password View

struct ResetPasswordView: View {
    let email: String
    let onReset: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.authManager) private var authManager
    
    @State private var code = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showSuccess = false
    
    var passwordsMatch: Bool {
        !newPassword.isEmpty && newPassword == confirmPassword
    }
    
    var isFormValid: Bool {
        code.count == 6 && newPassword.count >= 8 && passwordsMatch
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                (colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Form
                        formSection
                        
                        // Reset Button
                        resetButton
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
                
                // Success Overlay
                if showSuccess {
                    successOverlay
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
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Reset Password")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
            
            Text("Enter the code sent to \(email) and your new password")
                .font(.subheadline)
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(spacing: 16) {
            // Code Input
            formField(title: "Reset Code", icon: "number") {
                TextField("6-digit code", text: $code)
                    .textFieldStyle(.plain)
                    .keyboardType(.numberPad)
                    .onChange(of: code) { _, newValue in
                        if newValue.count > 6 {
                            code = String(newValue.prefix(6))
                        }
                        code = newValue.filter { $0.isNumber }
                    }
            }
            
            // New Password
            formField(title: "New Password", icon: "lock") {
                HStack {
                    if showPassword {
                        TextField("At least 8 characters", text: $newPassword)
                            .textFieldStyle(.plain)
                    } else {
                        SecureField("At least 8 characters", text: $newPassword)
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
            
            // Confirm Password
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
    
    // MARK: - Reset Button
    
    private var resetButton: some View {
        Button {
            Task {
                let success = await authManager.resetPassword(email: email, code: code, newPassword: newPassword)
                if success {
                    withAnimation {
                        showSuccess = true
                    }
                    
                    // Dismiss after showing success
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        onReset()
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                if authManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Reset Password")
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
    
    // MARK: - Success Overlay
    
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.successColor)
                
                Text("Password Reset!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Text("You can now log in with your new password")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(40)
        }
    }
}

#Preview("Forgot Password") {
    ForgotPasswordView()
}

#Preview("Reset Password") {
    ResetPasswordView(email: "user@example.com") {
        print("Reset!")
    }
}
