//
//  LinkedAccountsView.swift
//  Saverr
//
//  View for managing Plaid-linked bank accounts
//

import SwiftUI

struct LinkedAccountsView: View {
    @Environment(\.plaidManager) private var plaidManager
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showLinkAccount = false
    @State private var selectedAccount: PlaidLinkedAccount?
    @State private var accountToUnlink: PlaidLinkedAccount?
    
    var totalBalance: Double {
        plaidManager.linkedAccounts.reduce(0) { $0 + $1.displayBalance }
    }
    
    var accountsByType: [String: [PlaidLinkedAccount]] {
        Dictionary(grouping: plaidManager.linkedAccounts) { $0.type }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                (colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        if plaidManager.hasLinkedAccounts {
                            // Total Balance Card
                            totalBalanceCard
                            
                            // Accounts by Type
                            accountsListSection
                        } else {
                            emptyStateView
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await plaidManager.loadLinkedAccounts()
                }
                
                // Loading Overlay
                if plaidManager.isLoading && !plaidManager.hasLinkedAccounts {
                    loadingOverlay
                }
            }
            .navigationTitle("Linked Accounts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showLinkAccount = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.accentPrimary)
                    }
                }
            }
            .sheet(isPresented: $showLinkAccount) {
                linkAccountSheet
            }
            .sheet(item: $selectedAccount) { account in
                PlaidAccountDetailView(account: account)
            }
            .confirmationDialog(
                "Unlink Account",
                isPresented: .constant(accountToUnlink != nil),
                titleVisibility: .visible
            ) {
                Button("Unlink", role: .destructive) {
                    if let account = accountToUnlink {
                        Task {
                            _ = await plaidManager.unlinkAccount(account.id)
                            accountToUnlink = nil
                        }
                    }
                }
                Button("Cancel", role: .cancel) {
                    accountToUnlink = nil
                }
            } message: {
                if let account = accountToUnlink {
                    Text("Remove \(account.name) from \(account.institutionName ?? "your linked accounts")? You can always link it again later.")
                }
            }
            .task {
                if plaidManager.linkedAccounts.isEmpty {
                    await plaidManager.loadLinkedAccounts()
                }
            }
            .alert("Error", isPresented: .constant(plaidManager.error != nil)) {
                Button("OK") {
                    plaidManager.error = nil
                }
            } message: {
                if let error = plaidManager.error {
                    Text(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Total Balance Card
    
    private var totalBalanceCard: some View {
        VStack(spacing: 12) {
            Text("Total Balance")
                .font(.subheadline)
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
            
            Text(totalBalance.asCurrency)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
            
            HStack(spacing: 4) {
                Image(systemName: "link.circle.fill")
                    .foregroundStyle(Color.successColor)
                Text("\(plaidManager.linkedAccounts.count) account\(plaidManager.linkedAccounts.count == 1 ? "" : "s") linked")
            }
            .font(.caption)
            .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackgroundLight)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Accounts List Section
    
    private var accountsListSection: some View {
        VStack(spacing: 16) {
            ForEach(Array(accountsByType.keys.sorted()), id: \.self) { type in
                if let accounts = accountsByType[type] {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(formatAccountType(type))
                            .font(.headline)
                            .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                            .padding(.horizontal, 4)
                        
                        ForEach(accounts) { account in
                            LinkedAccountCard(
                                account: account,
                                onTap: { selectedAccount = account },
                                onUnlink: { accountToUnlink = account }
                            )
                        }
                    }
                }
            }
        }
    }
    
    private func formatAccountType(_ type: String) -> String {
        switch type.lowercased() {
        case "depository": return "Bank Accounts"
        case "credit": return "Credit Cards"
        case "investment", "brokerage": return "Investments"
        case "loan": return "Loans"
        default: return type.capitalized
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "building.columns.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.accentPrimary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Accounts Linked")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                
                Text("Connect your bank accounts to automatically track balances and transactions in one place.")
                    .font(.body)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            PlaidLinkButton(
                onSuccess: { publicToken in
                    Task {
                        await plaidManager.completeLinking(publicToken: publicToken)
                    }
                },
                onExit: {}
            )
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading accounts...")
                .font(.subheadline)
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
        }
    }
    
    // MARK: - Link Account Sheet
    
    private var linkAccountSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "link.badge.plus")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.accentPrimary)
                
                VStack(spacing: 8) {
                    Text("Link a Bank Account")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Securely connect your bank to track balances and transactions automatically")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                // Security badges
                VStack(spacing: 12) {
                    securityBadge(icon: "lock.shield.fill", text: "Bank-level encryption")
                    securityBadge(icon: "eye.slash.fill", text: "We never see your credentials")
                    securityBadge(icon: "checkmark.shield.fill", text: "Read-only access")
                }
                .padding(.vertical)
                
                Spacer()
                
                PlaidLinkButton(
                    onSuccess: { publicToken in
                        Task {
                            await plaidManager.completeLinking(publicToken: publicToken)
                        }
                        showLinkAccount = false
                    },
                    onExit: {
                        showLinkAccount = false
                    }
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle("Link Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showLinkAccount = false
                    }
                }
            }
        }
    }
    
    private func securityBadge(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.successColor)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
            
            Spacer()
        }
        .padding(.horizontal, 48)
    }
}

// MARK: - Linked Account Card

struct LinkedAccountCard: View {
    let account: PlaidLinkedAccount
    let onTap: () -> Void
    let onUnlink: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Bank Icon
                Image(systemName: account.appAccountType.icon)
                    .font(.title2)
                    .foregroundStyle(Color.accentPrimary)
                    .frame(width: 48, height: 48)
                    .background(Color.accentPrimary.opacity(0.12))
                    .clipShape(Circle())
                
                // Account Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.institutionName ?? "Bank Account")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                    
                    HStack(spacing: 4) {
                        Text(account.name)
                        if let mask = account.mask {
                            Text("•••• \(mask)")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                }
                
                Spacer()
                
                // Balance & Chevron
                VStack(alignment: .trailing, spacing: 4) {
                    Text(account.displayBalance.asCurrency)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                }
            }
            .padding()
            .background(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackgroundLight)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onTap()
            } label: {
                Label("View Details", systemImage: "info.circle")
            }
            
            Button(role: .destructive) {
                onUnlink()
            } label: {
                Label("Unlink Account", systemImage: "link.badge.minus")
            }
        }
    }
}

#Preview {
    LinkedAccountsView()
        .environment(\.plaidManager, PlaidManager())
}
