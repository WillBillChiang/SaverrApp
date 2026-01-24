//
//  MockPlaidAPIService.swift
//  Saverr
//
//  Mock implementation of Plaid API for development/testing
//

import Foundation

final class MockPlaidAPIService: PlaidAPIServiceProtocol {
    
    // Simulated delay for network requests
    private let simulatedDelay: UInt64 = 1_000_000_000 // 1 second
    
    // Mock data storage
    private var mockAccounts: [PlaidLinkedAccount] = []
    private var mockTransactions: [PlaidTransaction] = []
    
    init() {
        // Initialize with some mock data
        generateMockData()
    }
    
    func getLinkToken() async throws -> String {
        try await Task.sleep(nanoseconds: simulatedDelay)
        return "link-sandbox-\(UUID().uuidString)"
    }
    
    func linkAccount(publicToken: String) async throws -> AccountLinkResponse {
        try await Task.sleep(nanoseconds: simulatedDelay * 2)

        let newAccount = PlaidLinkedAccount(
            id: UUID().uuidString,
            accountName: "Checking Account",
            accountType: "checking",
            balance: 5432.10,
            institutionName: "Chase",
            institutionLogo: "building.columns",
            accountNumberLast4: "1234",
            lastUpdated: ISO8601DateFormatter().string(from: Date()),
            isLinked: true
        )

        mockAccounts.append(newAccount)

        return AccountLinkResponse(
            account: newAccount,
            linkStatus: "connected"
        )
    }
    
    func syncTransactions(accountId: String) async throws -> SyncResponse {
        try await Task.sleep(nanoseconds: simulatedDelay)
        
        return SyncResponse(
            synced: mockTransactions.count,
            added: 15,
            modified: 2,
            removed: 0,
            hasMore: false,
            cursor: "cursor_\(UUID().uuidString.prefix(8))"
        )
    }
    
    func getTransactions(accountId: String, startDate: Date?, endDate: Date?) async throws -> [PlaidTransaction] {
        try await Task.sleep(nanoseconds: simulatedDelay)
        
        // Filter by date if provided
        var filtered = mockTransactions
        
        if let start = startDate {
            filtered = filtered.filter { transaction in
                guard let date = transaction.transactionDate else { return true }
                return date >= start
            }
        }
        
        if let end = endDate {
            filtered = filtered.filter { transaction in
                guard let date = transaction.transactionDate else { return true }
                return date <= end
            }
        }
        
        return filtered
    }
    
    func getLinkedAccounts() async throws -> [PlaidLinkedAccount] {
        try await Task.sleep(nanoseconds: simulatedDelay / 2)
        return mockAccounts
    }
    
    func unlinkAccount(accountId: String) async throws {
        try await Task.sleep(nanoseconds: simulatedDelay)
        mockAccounts.removeAll { $0.id == accountId }
    }
    
    func refreshAccountBalance(accountId: String) async throws -> PlaidLinkedAccount {
        try await Task.sleep(nanoseconds: simulatedDelay)

        guard let index = mockAccounts.firstIndex(where: { $0.id == accountId }) else {
            throw PlaidServiceError.noLinkedAccounts
        }

        // Simulate balance update with slight random change
        let account = mockAccounts[index]
        let balanceChange = Double.random(in: -100...100)

        let updatedAccount = PlaidLinkedAccount(
            id: account.id,
            accountName: account.accountName,
            accountType: account.accountType,
            balance: (account.balance ?? 0) + balanceChange,
            institutionName: account.institutionName,
            institutionLogo: account.institutionLogo,
            accountNumberLast4: account.accountNumberLast4,
            lastUpdated: ISO8601DateFormatter().string(from: Date()),
            isLinked: account.isLinked
        )

        mockAccounts[index] = updatedAccount
        return updatedAccount
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockData() {
        // Create mock accounts
        mockAccounts = [
            PlaidLinkedAccount(
                id: "acc_1",
                accountName: "Checking",
                accountType: "checking",
                balance: 5432.10,
                institutionName: "Chase",
                institutionLogo: "building.columns",
                accountNumberLast4: "1234",
                lastUpdated: "2024-01-21T12:00:00Z",
                isLinked: true
            ),
            PlaidLinkedAccount(
                id: "acc_2",
                accountName: "Savings",
                accountType: "savings",
                balance: 12500.00,
                institutionName: "Chase",
                institutionLogo: "building.columns",
                accountNumberLast4: "5678",
                lastUpdated: "2024-01-21T12:00:00Z",
                isLinked: true
            ),
            PlaidLinkedAccount(
                id: "acc_3",
                accountName: "Sapphire Preferred",
                accountType: "credit",
                balance: -1250.50,
                institutionName: "Chase",
                institutionLogo: "building.columns",
                accountNumberLast4: "9012",
                lastUpdated: "2024-01-21T12:00:00Z",
                isLinked: true
            )
        ]

        // Generate mock transactions
        mockTransactions = generateMockTransactions()
    }
    
    private func generateMockTransactions() -> [PlaidTransaction] {
        let merchants: [(name: String, category: String, amount: ClosedRange<Double>)] = [
            ("Uber Eats", "Food and Drink", 15...45),
            ("Starbucks", "Food and Drink", 5...12),
            ("Whole Foods", "Food and Drink", 50...150),
            ("Amazon", "Shops", 20...200),
            ("Target", "Shops", 30...100),
            ("Netflix", "Service", 15...20),
            ("Spotify", "Service", 10...15),
            ("Shell Gas Station", "Travel", 40...80),
            ("Uber", "Travel", 15...35),
            ("CVS Pharmacy", "Healthcare", 10...50),
            ("Planet Fitness", "Recreation", 25...30),
            ("Apple Store", "Shops", 100...500),
            ("Chipotle", "Food and Drink", 12...18),
            ("Walgreens", "Healthcare", 8...25),
            ("Home Depot", "Shops", 50...200),
        ]
        
        var transactions: [PlaidTransaction] = []
        let calendar = Calendar.current
        
        // Generate transactions for the last 90 days
        for dayOffset in 0..<90 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            
            // Generate 0-4 transactions per day
            let transactionCount = Int.random(in: 0...4)
            
            for _ in 0..<transactionCount {
                let merchant = merchants.randomElement()!
                let amount = Double.random(in: merchant.amount)
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                let transaction = PlaidTransaction(
                    id: UUID().uuidString,
                    transactionId: "tx_\(UUID().uuidString.prefix(8))",
                    accountId: mockAccounts.randomElement()?.id ?? "acc_1",
                    amount: amount,
                    date: dateFormatter.string(from: date),
                    name: merchant.name.uppercased(),
                    merchantName: merchant.name,
                    category: [merchant.category],
                    pending: dayOffset == 0 && Bool.random(),
                    paymentChannel: "in store",
                    isoCurrencyCode: "USD",
                    logoUrl: nil,
                    website: nil
                )
                
                transactions.append(transaction)
            }
        }
        
        // Add some income transactions
        for monthOffset in 0..<3 {
            guard let date = calendar.date(byAdding: .month, value: -monthOffset, to: Date()),
                  let payday = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else { continue }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            // Paycheck 1 (1st of month)
            if let firstPayday = calendar.date(byAdding: .day, value: 1, to: payday) {
                transactions.append(PlaidTransaction(
                    id: UUID().uuidString,
                    transactionId: "tx_pay_\(UUID().uuidString.prefix(8))",
                    accountId: "account_checking_1",
                    amount: -3500.00, // Negative = income in Plaid
                    date: dateFormatter.string(from: firstPayday),
                    name: "DIRECT DEPOSIT - EMPLOYER",
                    merchantName: nil,
                    category: ["Transfer", "Payroll"],
                    pending: false,
                    paymentChannel: "other",
                    isoCurrencyCode: "USD",
                    logoUrl: nil,
                    website: nil
                ))
            }
            
            // Paycheck 2 (15th of month)
            if let secondPayday = calendar.date(byAdding: .day, value: 15, to: payday) {
                transactions.append(PlaidTransaction(
                    id: UUID().uuidString,
                    transactionId: "tx_pay_\(UUID().uuidString.prefix(8))",
                    accountId: "account_checking_1",
                    amount: -3500.00,
                    date: dateFormatter.string(from: secondPayday),
                    name: "DIRECT DEPOSIT - EMPLOYER",
                    merchantName: nil,
                    category: ["Transfer", "Payroll"],
                    pending: false,
                    paymentChannel: "other",
                    isoCurrencyCode: "USD",
                    logoUrl: nil,
                    website: nil
                ))
            }
        }
        
        // Sort by date, most recent first
        return transactions.sorted { 
            ($0.transactionDate ?? Date()) > ($1.transactionDate ?? Date()) 
        }
    }
}
