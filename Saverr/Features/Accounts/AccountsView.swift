//
//  AccountsView.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import SwiftUI

struct AccountsView: View {
    @State private var accounts: [BankAccount] = []
    @State private var isLoading = false
    @State private var showAddAccount = false
    @State private var selectedAccount: BankAccount?
    @State private var showPlaidLink = false
    @State private var selectedPlaidAccount: PlaidLinkedAccount?

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.services) var services
    @Environment(\.plaidManager) var plaidManager

    var totalBalance: Double {
        let manualBalance = accounts.reduce(0) { $0 + $1.balance }
        let plaidBalance = plaidManager.linkedAccounts.reduce(0) { $0 + $1.displayBalance }
        return manualBalance + plaidBalance
    }
    
    var totalAccountCount: Int {
        accounts.count + plaidManager.linkedAccounts.count
    }

    var accountsByType: [BankAccount.AccountType: [BankAccount]] {
        Dictionary(grouping: accounts, by: { $0.accountType })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                (colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Total Balance Card
                        totalBalanceCard

                        // Linked Accounts Section (Plaid)
                        if !plaidManager.linkedAccounts.isEmpty {
                            linkedAccountsSection
                        }
                        
                        // Manual Accounts List
                        if isLoading {
                            loadingView
                        } else if accounts.isEmpty && plaidManager.linkedAccounts.isEmpty {
                            emptyStateView
                        } else if !accounts.isEmpty {
                            manualAccountsList
                        }
                    }
                    .padding()
                    .padding(.bottom, 100) // Space for FAB
                }
                .refreshable {
                    await refreshAllAccounts()
                }

                // Floating Add Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        addAccountMenu
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                
                // Loading Overlay
                if plaidManager.isLinking {
                    linkingOverlay
                }
            }
            .navigationTitle("Accounts")
            .sheet(isPresented: $showAddAccount) {
                AddAccountView { newAccount in
                    accounts.append(newAccount)
                }
            }
            .sheet(item: $selectedAccount) { account in
                AccountDetailView(account: account)
            }
            .sheet(item: $selectedPlaidAccount) { account in
                PlaidAccountDetailView(account: account)
            }
            .sheet(isPresented: $showPlaidLink) {
                plaidLinkSheet
            }
            .task {
                await loadAccounts()
                if plaidManager.linkedAccounts.isEmpty {
                    await plaidManager.loadLinkedAccounts()
                }
            }
        }
    }

    // MARK: - Subviews

    private var totalBalanceCard: some View {
        VStack(spacing: 8) {
            Text("Total Balance")
                .font(.subheadline)
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)

            Text(totalBalance.asCurrency)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

            HStack(spacing: 16) {
                if !plaidManager.linkedAccounts.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "link.circle.fill")
                            .foregroundStyle(Color.successColor)
                        Text("\(plaidManager.linkedAccounts.count) linked")
                    }
                }
                
                if !accounts.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(Color.accentPrimary)
                        Text("\(accounts.count) manual")
                    }
                }
            }
            .font(.caption)
            .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .cardStyle()
    }
    
    // MARK: - Linked Accounts Section
    
    private var linkedAccountsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "link.circle.fill")
                        .foregroundStyle(Color.successColor)
                    Text("Linked Accounts")
                        .font(.headline)
                }
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                
                Spacer()
                
                Button {
                    Task {
                        await plaidManager.syncAllAccounts()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Sync")
                    }
                    .font(.caption)
                    .foregroundStyle(Color.accentPrimary)
                }
                .disabled(plaidManager.isSyncing)
            }
            .padding(.horizontal, 4)
            
            ForEach(plaidManager.linkedAccounts) { account in
                Button {
                    selectedPlaidAccount = account
                } label: {
                    PlaidAccountRow(account: account)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var manualAccountsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Manual Accounts")
                .font(.headline)
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                .padding(.horizontal, 4)
            
            ForEach(BankAccount.AccountType.allCases, id: \.self) { type in
                if let typeAccounts = accountsByType[type], !typeAccounts.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(type.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                            .padding(.horizontal, 4)

                        ForEach(typeAccounts, id: \.id) { account in
                            AccountCard(account: account) {
                                selectedAccount = account
                            }
                        }
                    }
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading accounts...")
                .font(.subheadline)
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "building.columns")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentPrimary.opacity(0.5))

            VStack(spacing: 8) {
                Text("No accounts yet")
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

                Text("Link your bank accounts to automatically track your finances, or add accounts manually.")
                    .font(.subheadline)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                PlaidLinkButton(
                    onSuccess: { publicToken in
                        Task {
                            await plaidManager.completeLinking(publicToken: publicToken)
                        }
                    },
                    onExit: {}
                )
                
                Button {
                    showAddAccount = true
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Manual Account")
                    }
                    .foregroundStyle(Color.accentPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentPrimary.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var addAccountMenu: some View {
        Menu {
            Button {
                showPlaidLink = true
            } label: {
                Label("Link Bank Account", systemImage: "link.badge.plus")
            }
            
            Button {
                showAddAccount = true
            } label: {
                Label("Add Manual Account", systemImage: "square.and.pencil")
            }
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(Color.accentPrimary)
                .clipShape(Circle())
                .shadow(color: Color.accentPrimary.opacity(0.4), radius: 8, x: 0, y: 4)
        }
    }
    
    private var plaidLinkSheet: some View {
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
                
                Spacer()
                
                PlaidLinkButton(
                    onSuccess: { publicToken in
                        Task {
                            await plaidManager.completeLinking(publicToken: publicToken)
                        }
                        showPlaidLink = false
                    },
                    onExit: {
                        showPlaidLink = false
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
                        showPlaidLink = false
                    }
                }
            }
        }
    }
    
    private var linkingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.white)
                
                Text("Linking account...")
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
    }

    // MARK: - Actions

    private func loadAccounts() async {
        isLoading = true
        do {
            accounts = try await services.bankingService.fetchAccounts()
        } catch {
            print("Failed to load accounts: \(error)")
        }
        isLoading = false
    }
    
    private func refreshAllAccounts() async {
        await loadAccounts()
        await plaidManager.loadLinkedAccounts()
    }
}

// MARK: - Plaid Account Row

struct PlaidAccountRow: View {
    let account: PlaidLinkedAccount
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
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
                HStack(spacing: 6) {
                    Text(account.institutionName ?? "Bank Account")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                    
                    Image(systemName: "link")
                        .font(.caption2)
                        .foregroundStyle(Color.successColor)
                }
                
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
}

#Preview {
    AccountsView()
        .environment(\.plaidManager, PlaidManager())
}
