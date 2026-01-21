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
            accountId: "acc_\(UUID().uuidString.prefix(8))",
            name: "Checking Account",
            officialName: "TOTAL CHECKING",
            type: "depository",
            subtype: "checking",
            mask: "1234",
            institutionId: "ins_3",
            institutionName: "Chase",
            currentBalance: 5432.10,
            availableBalance: 5230.00,
            isoCurrencyCode: "USD"
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
    
    // MARK: - Mock Data Generation
    
    private func generateMockData() {
        // Create mock accounts
        mockAccounts = [
            PlaidLinkedAccount(
                id: "acc_1",
                accountId: "account_checking_1",
                name: "Checking",
                officialName: "TOTAL CHECKING",
                type: "depository",
                subtype: "checking",
                mask: "1234",
                institutionId: "ins_3",
                institutionName: "Chase",
                currentBalance: 5432.10,
                availableBalance: 5230.00,
                isoCurrencyCode: "USD"
            ),
            PlaidLinkedAccount(
                id: "acc_2",
                accountId: "account_savings_1",
                name: "Savings",
                officialName: "CHASE SAVINGS",
                type: "depository",
                subtype: "savings",
                mask: "5678",
                institutionId: "ins_3",
                institutionName: "Chase",
                currentBalance: 12500.00,
                availableBalance: 12500.00,
                isoCurrencyCode: "USD"
            ),
            PlaidLinkedAccount(
                id: "acc_3",
                accountId: "account_credit_1",
                name: "Sapphire Preferred",
                officialName: "CHASE SAPPHIRE PREFERRED",
                type: "credit",
                subtype: "credit card",
                mask: "9012",
                institutionId: "ins_3",
                institutionName: "Chase",
                currentBalance: -1250.50,
                availableBalance: 8749.50,
                isoCurrencyCode: "USD"
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
                    accountId: mockAccounts.randomElement()?.accountId ?? "acc_1",
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
