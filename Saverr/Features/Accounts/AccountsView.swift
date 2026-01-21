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

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.services) var services

    var totalBalance: Double {
        accounts.reduce(0) { $0 + $1.balance }
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

                        // Accounts List
                        if isLoading {
                            loadingView
                        } else if accounts.isEmpty {
                            emptyStateView
                        } else {
                            accountsList
                        }
                    }
                    .padding()
                    .padding(.bottom, 100) // Space for FAB
                }

                // Floating Add Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        addAccountButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
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
            .task {
                await loadAccounts()
            }
            .refreshable {
                await loadAccounts()
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

            Text("Across \(accounts.count) account\(accounts.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .cardStyle()
    }

    private var accountsList: some View {
        VStack(spacing: 12) {
            ForEach(BankAccount.AccountType.allCases, id: \.self) { type in
                if let typeAccounts = accountsByType[type], !typeAccounts.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(type.rawValue)
                            .font(.headline)
                            .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
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
        VStack(spacing: 16) {
            Image(systemName: "building.columns")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentPrimary.opacity(0.5))

            Text("No accounts linked yet")
                .font(.headline)
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

            Text("Link your bank accounts to start tracking your finances")
                .font(.subheadline)
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                .multilineTextAlignment(.center)

            PrimaryButton("Link Account", icon: "plus") {
                showAddAccount = true
            }
            .frame(width: 200)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var addAccountButton: some View {
        Button {
            showAddAccount = true
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
}

#Preview {
    AccountsView()
}
