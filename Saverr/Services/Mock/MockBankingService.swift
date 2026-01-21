//
//  MockBankingService.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import Foundation

final class MockBankingService: BankingServiceProtocol {
    private let delay: Duration = .milliseconds(500)

    private var mockAccounts: [BankAccount] = []

    init() {
        mockAccounts = createMockAccounts()
    }

    func fetchAccounts() async throws -> [BankAccount] {
        try await Task.sleep(for: delay)
        return mockAccounts
    }

    func fetchTransactions(for accountId: UUID, dateRange: DateInterval?) async throws -> [Transaction] {
        try await Task.sleep(for: delay)
        return generateMockTransactions(count: 30)
    }

    func linkAccount(institutionId: String, credentials: [String: String]) async throws -> BankAccount {
        try await Task.sleep(for: .seconds(2))

        let newAccount = BankAccount(
            institutionName: institutionId,
            accountName: "New Account",
            accountType: .checking,
            balance: Double.random(in: 1000...15000),
            accountNumberLast4: String(format: "%04d", Int.random(in: 0...9999)),
            institutionLogo: "building.columns"
        )
        mockAccounts.append(newAccount)
        return newAccount
    }

    func unlinkAccount(accountId: UUID) async throws {
        try await Task.sleep(for: delay)
        mockAccounts.removeAll { $0.id == accountId }
    }

    func refreshAccountBalance(accountId: UUID) async throws -> Double {
        try await Task.sleep(for: delay)
        if let index = mockAccounts.firstIndex(where: { $0.id == accountId }) {
            let variation = Double.random(in: -100...500)
            mockAccounts[index].balance += variation
            mockAccounts[index].lastUpdated = Date()
            return mockAccounts[index].balance
        }
        throw ServiceError.accountNotFound
    }

    // MARK: - Mock Data Generation

    private func createMockAccounts() -> [BankAccount] {
        [
            BankAccount(
                institutionName: "Chase",
                accountName: "Total Checking",
                accountType: .checking,
                balance: 4523.67,
                accountNumberLast4: "4521",
                institutionLogo: "building.columns"
            ),
            BankAccount(
                institutionName: "Chase",
                accountName: "Savings",
                accountType: .savings,
                balance: 12850.00,
                accountNumberLast4: "7832",
                institutionLogo: "building.columns"
            ),
            BankAccount(
                institutionName: "American Express",
                accountName: "Blue Cash Preferred",
                accountType: .credit,
                balance: -1234.56,
                accountNumberLast4: "1005",
                institutionLogo: "creditcard"
            ),
            BankAccount(
                institutionName: "Fidelity",
                accountName: "Investment Account",
                accountType: .investment,
                balance: 45678.90,
                accountNumberLast4: "9012",
                institutionLogo: "chart.line.uptrend.xyaxis"
            )
        ]
    }

    private func generateMockTransactions(count: Int) -> [Transaction] {
        let merchants = [
            ("Amazon", "Shopping", false),
            ("Starbucks", "Food & Dining", false),
            ("Uber", "Transportation", false),
            ("Netflix", "Entertainment", false),
            ("Whole Foods", "Food & Dining", false),
            ("Shell Gas", "Transportation", false),
            ("Target", "Shopping", false),
            ("Spotify", "Entertainment", false),
            ("Electric Company", "Bills & Utilities", false),
            ("Employer Direct Deposit", "Income", true),
            ("Venmo Transfer", "Transfer", true),
            ("Apple Store", "Shopping", false),
            ("Gym Membership", "Health", false)
        ]

        return (0..<count).map { index in
            let merchant = merchants.randomElement()!
            let amount = merchant.2 ?
                Double.random(in: 500...3500) :
                Double.random(in: 5...200)
            let daysAgo = Double(index)

            return Transaction(
                amount: amount,
                description: merchant.0,
                date: Date().addingTimeInterval(-daysAgo * 86400),
                isIncome: merchant.2,
                merchant: merchant.0,
                categoryName: merchant.1
            )
        }
    }
}
