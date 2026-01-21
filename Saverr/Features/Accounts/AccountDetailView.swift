//
//  AccountDetailView.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import SwiftUI

struct AccountDetailView: View {
    let account: BankAccount

    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.services) var services

    @State private var transactions: [Transaction] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                (colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Account Header
                        accountHeader

                        // Quick Stats
                        quickStats

                        // Transactions
                        transactionsSection
                    }
                    .padding()
                }
            }
            .navigationTitle(account.accountName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadTransactions()
            }
        }
    }

    // MARK: - Subviews

    private var accountHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: account.institutionLogo ?? "building.columns")
                .font(.largeTitle)
                .foregroundStyle(Color.accentPrimary)
                .frame(width: 70, height: 70)
                .background(Color.accentPrimary.opacity(0.12))
                .clipShape(Circle())

            VStack(spacing: 4) {
                Text(account.institutionName)
                    .font(.subheadline)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)

                Text(account.balance.asCurrency)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(account.balance >= 0 ?
                        (colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight) :
                        Color.dangerColor)

                HStack(spacing: 8) {
                    Text(account.accountType.rawValue)
                    Text("•")
                    Text("••••\(account.accountNumberLast4)")
                }
                .font(.caption)
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
            }

            Text("Last updated \(account.lastUpdated.relativeFormatted)")
                .font(.caption2)
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .cardStyle()
    }

    private var quickStats: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Money In",
                value: incomeTotal.asCurrency,
                icon: "arrow.down.circle",
                iconColor: .successColor
            )

            StatCard(
                title: "Money Out",
                value: expenseTotal.asCurrency,
                icon: "arrow.up.circle",
                iconColor: .accentSecondary
            )
        }
    }

    private var incomeTotal: Double {
        transactions.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
    }

    private var expenseTotal: Double {
        transactions.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }
    }

    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Transactions")
                .font(.headline)
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 40)
            } else if transactions.isEmpty {
                Text("No transactions yet")
                    .font(.subheadline)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                VStack(spacing: 0) {
                    ForEach(transactions, id: \.id) { transaction in
                        TransactionRow(transaction: transaction)

                        if transaction.id != transactions.last?.id {
                            Divider()
                                .padding(.leading, 50)
                        }
                    }
                }
                .padding()
                .cardStyle()
            }
        }
    }

    // MARK: - Actions

    private func loadTransactions() async {
        isLoading = true
        do {
            transactions = try await services.bankingService.fetchTransactions(
                for: account.id,
                dateRange: nil
            )
        } catch {
            print("Failed to load transactions: \(error)")
        }
        isLoading = false
    }
}

struct TransactionRow: View {
    let transaction: Transaction

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: categoryIcon)
                .font(.body)
                .foregroundStyle(transaction.isIncome ? Color.successColor : Color.accentSecondary)
                .frame(width: 36, height: 36)
                .background((transaction.isIncome ? Color.successColor : Color.accentSecondary).opacity(0.12))
                .clipShape(Circle())

            // Description
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.merchant ?? transaction.transactionDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

                Text(transaction.date.shortFormatted)
                    .font(.caption)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
            }

            Spacer()

            // Amount
            Text(transaction.displayAmount)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(transaction.isIncome ? Color.successColor : (colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight))
        }
        .padding(.vertical, 8)
    }

    private var categoryIcon: String {
        switch transaction.categoryName {
        case "Food & Dining": return "fork.knife"
        case "Transportation": return "car.fill"
        case "Shopping": return "bag.fill"
        case "Entertainment": return "tv.fill"
        case "Bills & Utilities": return "bolt.fill"
        case "Health": return "heart.fill"
        case "Income": return "dollarsign.circle.fill"
        case "Transfer": return "arrow.left.arrow.right"
        default: return "ellipsis.circle.fill"
        }
    }
}

#Preview {
    let account = BankAccount(
        institutionName: "Chase",
        accountName: "Total Checking",
        accountType: .checking,
        balance: 4523.67,
        accountNumberLast4: "4521",
        institutionLogo: "building.columns"
    )

    AccountDetailView(account: account)
}
