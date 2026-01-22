//
//  EmailVerificationView.swift
//  Saverr
//
//  View for email verification with OTP code input
//

import SwiftUI

struct EmailVerificationView: View {
    let email: String
    let onVerified: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.authManager) private var authManager
    
    @State private var code = ""
    @State private var showResendSuccess = false
    @State private var resendCooldown = 0
    @State private var timer: Timer?
    
    @FocusState private var isCodeFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                (colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerSection
                        
                        // Code Input
                        codeInputSection
                        
                        // Verify Button
                        verifyButton
                        
                        // Resend Section
                        resendSection
                        
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
            .onAppear {
                isCodeFocused = true
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Email Icon
            ZStack {
                Circle()
                    .fill(Color.accentPrimary.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.accentPrimary)
            }
            
            VStack(spacing: 8) {
                Text("Verify Your Email")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                
                Text("We've sent a 6-digit code to")
                    .font(.subheadline)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                
                Text(email)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentPrimary)
            }
        }
    }
    
    // MARK: - Code Input Section
    
    private var codeInputSection: some View {
        VStack(spacing: 16) {
            // OTP Style Input
            HStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { index in
                    OTPDigitBox(
                        digit: getDigit(at: index),
                        isFocused: code.count == index && isCodeFocused
                    )
                }
            }
            
            // Hidden TextField for input
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isCodeFocused)
                .onChange(of: code) { _, newValue in
                    // Limit to 6 digits
                    if newValue.count > 6 {
                        code = String(newValue.prefix(6))
                    }
                    // Remove non-digits
                    code = newValue.filter { $0.isNumber }
                }
                .frame(width: 1, height: 1)
                .opacity(0.01)
            
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
            
            // Success Message for Resend
            if showResendSuccess {
                HStack {
                    Image(systemName: "checkmark.circle")
                    Text("Verification code resent!")
                }
                .font(.caption)
                .foregroundStyle(Color.successColor)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.successColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .transition(.opacity)
            }
        }
    }
    
    private func getDigit(at index: Int) -> String {
        guard index < code.count else { return "" }
        return String(code[code.index(code.startIndex, offsetBy: index)])
    }
    
    // MARK: - Verify Button
    
    private var verifyButton: some View {
        Button {
            Task {
                let success = await authManager.confirmEmail(email: email, code: code)
                if success {
                    onVerified()
                }
            }
        } label: {
            HStack(spacing: 8) {
                if authManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Verify Email")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(code.count == 6 ? Color.accentPrimary : Color.gray)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(code.count != 6 || authManager.isLoading)
    }
    
    // MARK: - Resend Section
    
    private var resendSection: some View {
        VStack(spacing: 12) {
            Text("Didn't receive the code?")
                .font(.subheadline)
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
            
            if resendCooldown > 0 {
                Text("Resend in \(resendCooldown)s")
                    .font(.subheadline)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
            } else {
                Button("Resend Code") {
                    Task {
                        await resendCode()
                    }
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.accentPrimary)
                .disabled(authManager.isLoading)
            }
        }
    }
    
    private func resendCode() async {
        await authManager.resendVerificationCode(email: email)
        
        if authManager.errorMessage == nil {
            showResendSuccess = true
            resendCooldown = 60
            
            // Start cooldown timer
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if resendCooldown > 0 {
                    resendCooldown -= 1
                } else {
                    timer?.invalidate()
                }
            }
            
            // Hide success message after 3 seconds
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                await MainActor.run {
                    withAnimation {
                        showResendSuccess = false
                    }
                }
            }
        }
    }
}

// MARK: - OTP Digit Box

struct OTPDigitBox: View {
    let digit: String
    let isFocused: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackgroundLight)
                .frame(width: 48, height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isFocused ? Color.accentPrimary : Color.clear,
                            lineWidth: 2
                        )
                )
            
            if digit.isEmpty && isFocused {
                // Blinking cursor
                Rectangle()
                    .fill(Color.accentPrimary)
                    .frame(width: 2, height: 24)
                    .opacity(isFocused ? 1 : 0)
            } else {
                Text(digit)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
            }
        }
    }
}

#Preview {
    EmailVerificationView(email: "user@example.com") {
        print("Verified!")
    }
}
