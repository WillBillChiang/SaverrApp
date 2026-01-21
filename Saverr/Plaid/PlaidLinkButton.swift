//
//  PlaidLinkButton.swift
//  Saverr
//
//  Button component to initiate Plaid Link
//

import SwiftUI

/// Button that initiates the Plaid Link flow
struct PlaidLinkButton: View {
    let onSuccess: (String) -> Void  // Returns public token
    let onExit: () -> Void
    
    @Environment(\.plaidManager) private var plaidManager
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showPlaidLink = false
    @State private var isLoading = false
    
    var body: some View {
        Button {
            initiateLink()
        } label: {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "link.badge.plus")
                        .font(.title3)
                }
                
                Text(isLoading ? "Preparing..." : "Link Bank Account")
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.accentPrimary)
            .cornerRadius(12)
        }
        .disabled(isLoading)
        .sheet(isPresented: $showPlaidLink) {
            PlaidLinkSheet(
                linkToken: plaidManager.linkToken ?? "",
                onSuccess: { publicToken in
                    showPlaidLink = false
                    onSuccess(publicToken)
                },
                onExit: {
                    showPlaidLink = false
                    onExit()
                }
            )
        }
    }
    
    private func initiateLink() {
        isLoading = true
        
        Task {
            await plaidManager.initializePlaidLink()
            
            if plaidManager.linkToken != nil {
                showPlaidLink = true
            }
            
            isLoading = false
        }
    }
}

// MARK: - Plaid Link Sheet

/// Sheet that presents the Plaid Link flow
/// Note: In production, use the actual Plaid Link SDK
struct PlaidLinkSheet: View {
    let linkToken: String
    let onSuccess: (String) -> Void
    let onExit: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedBank: MockBank?
    @State private var isConnecting = false
    @State private var connectionStep: ConnectionStep = .selectBank
    
    enum ConnectionStep {
        case selectBank
        case authenticating
        case success
    }
    
    struct MockBank: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let color: Color
    }
    
    let banks: [MockBank] = [
        MockBank(name: "Chase", icon: "building.columns.fill", color: .blue),
        MockBank(name: "Bank of America", icon: "building.columns.fill", color: .red),
        MockBank(name: "Wells Fargo", icon: "building.columns.fill", color: .yellow),
        MockBank(name: "Citi", icon: "building.columns.fill", color: .blue),
        MockBank(name: "Capital One", icon: "creditcard.fill", color: .red),
        MockBank(name: "US Bank", icon: "building.columns.fill", color: .purple),
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                (colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
                    .ignoresSafeArea()
                
                switch connectionStep {
                case .selectBank:
                    bankSelectionView
                case .authenticating:
                    authenticatingView
                case .success:
                    successView
                }
            }
            .navigationTitle("Link Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onExit()
                    }
                }
            }
        }
    }
    
    private var bankSelectionView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Security message
                HStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(Color.accentPrimary)
                    
                    Text("Your credentials are encrypted and never stored on our servers")
                        .font(.caption)
                        .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                }
                .padding()
                .background(Color.accentPrimary.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Banks list
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(banks) { bank in
                        Button {
                            selectBank(bank)
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: bank.icon)
                                    .font(.title)
                                    .foregroundStyle(bank.color)
                                    .frame(width: 50, height: 50)
                                    .background(bank.color.opacity(0.1))
                                    .clipShape(Circle())
                                
                                Text(bank.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackgroundLight)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
    
    private var authenticatingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Connecting to \(selectedBank?.name ?? "your bank")...")
                .font(.headline)
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
            
            Text("This may take a moment")
                .font(.subheadline)
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
        }
    }
    
    private var successView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.successColor)
            
            Text("Account Linked!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
            
            Text("Your \(selectedBank?.name ?? "") account has been successfully connected")
                .font(.body)
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
    
    private func selectBank(_ bank: MockBank) {
        selectedBank = bank
        connectionStep = .authenticating
        
        // Simulate authentication delay
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            connectionStep = .success
            
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            // In production, this would be the actual public token from Plaid Link SDK
            // For demo, we generate a mock token
            let mockPublicToken = "public-sandbox-\(UUID().uuidString.lowercased())"
            onSuccess(mockPublicToken)
        }
    }
}

#Preview {
    PlaidLinkButton(
        onSuccess: { token in print("Token: \(token)") },
        onExit: { print("Exited") }
    )
    .padding()
    .environment(\.plaidManager, PlaidManager())
}
