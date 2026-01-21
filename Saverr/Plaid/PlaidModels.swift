//
//  PlaidModels.swift
//  Saverr
//
//  Models for Plaid API responses from backend
//

import Foundation

// MARK: - Link Token Response

struct LinkTokenResponse: Codable {
    let linkToken: String
    
    enum CodingKeys: String, CodingKey {
        case linkToken = "link_token"
    }
}

// MARK: - Account Link Response

struct AccountLinkResponse: Codable {
    let account: PlaidLinkedAccount
    let linkStatus: String
    
    enum CodingKeys: String, CodingKey {
        case account
        case linkStatus = "link_status"
    }
}

struct PlaidLinkedAccount: Codable, Identifiable {
    let id: String
    let accountId: String
    let name: String
    let officialName: String?
    let type: String
    let subtype: String?
    let mask: String?
    let institutionId: String?
    let institutionName: String?
    let currentBalance: Double?
    let availableBalance: Double?
    let isoCurrencyCode: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case accountId = "account_id"
        case name
        case officialName = "official_name"
        case type
        case subtype
        case mask
        case institutionId = "institution_id"
        case institutionName = "institution_name"
        case currentBalance = "current_balance"
        case availableBalance = "available_balance"
        case isoCurrencyCode = "iso_currency_code"
    }
    
    /// Convert Plaid account type to app's AccountType
    var appAccountType: BankAccount.AccountType {
        switch type.lowercased() {
        case "depository":
            if subtype?.lowercased() == "savings" {
                return .savings
            }
            return .checking
        case "credit":
            return .credit
        case "investment", "brokerage":
            return .investment
        default:
            return .checking
        }
    }
    
    /// Best available balance
    var displayBalance: Double {
        availableBalance ?? currentBalance ?? 0
    }
}

// MARK: - Sync Response

struct SyncResponse: Codable {
    let synced: Int
    let added: Int
    let modified: Int
    let removed: Int
    let hasMore: Bool
    let cursor: String?
    
    enum CodingKeys: String, CodingKey {
        case synced
        case added
        case modified
        case removed
        case hasMore = "has_more"
        case cursor
    }
}

// MARK: - Transactions Response

struct TransactionsResponse: Codable {
    let transactions: [PlaidTransaction]
    let totalCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case transactions
        case totalCount = "total_count"
    }
}

struct PlaidTransaction: Codable, Identifiable {
    let id: String
    let transactionId: String
    let accountId: String
    let amount: Double
    let date: String
    let name: String
    let merchantName: String?
    let category: [String]?
    let pending: Bool
    let paymentChannel: String?
    let isoCurrencyCode: String?
    let logoUrl: String?
    let website: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case transactionId = "transaction_id"
        case accountId = "account_id"
        case amount
        case date
        case name
        case merchantName = "merchant_name"
        case category
        case pending
        case paymentChannel = "payment_channel"
        case isoCurrencyCode = "iso_currency_code"
        case logoUrl = "logo_url"
        case website
    }
    
    /// Plaid uses positive amounts for outflows (spending), negative for inflows (income)
    var isIncome: Bool {
        amount < 0
    }
    
    /// Get the absolute transaction amount
    var absoluteAmount: Double {
        abs(amount)
    }
    
    /// Get the primary category name
    var primaryCategory: String? {
        category?.first
    }
    
    /// Parse date string to Date
    var transactionDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }
    
    /// Display name (prefer merchant name)
    var displayName: String {
        merchantName ?? name
    }
}

// MARK: - Spending Summary

struct SpendingSummary: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
    let transactionCount: Int
    let icon: String
    let color: String
    
    static func fromTransactions(_ transactions: [PlaidTransaction]) -> [SpendingSummary] {
        // Group transactions by category
        var categorySpending: [String: (amount: Double, count: Int)] = [:]
        
        for transaction in transactions where !transaction.isIncome && !transaction.pending {
            let category = transaction.primaryCategory ?? "Other"
            let current = categorySpending[category] ?? (amount: 0, count: 0)
            categorySpending[category] = (
                amount: current.amount + transaction.absoluteAmount,
                count: current.count + 1
            )
        }
        
        // Convert to SpendingSummary array
        let categoryInfo = SpendingCategoryInfo.all
        
        return categorySpending.map { category, data in
            let info = categoryInfo[category] ?? SpendingCategoryInfo(icon: "questionmark.circle", color: "#718096")
            return SpendingSummary(
                category: category,
                amount: data.amount,
                transactionCount: data.count,
                icon: info.icon,
                color: info.color
            )
        }
        .sorted { $0.amount > $1.amount }
    }
}

struct SpendingCategoryInfo {
    let icon: String
    let color: String
    
    static let all: [String: SpendingCategoryInfo] = [
        "Food and Drink": SpendingCategoryInfo(icon: "fork.knife", color: "#FF6B6B"),
        "Shops": SpendingCategoryInfo(icon: "bag", color: "#4ECDC4"),
        "Travel": SpendingCategoryInfo(icon: "airplane", color: "#45B7D1"),
        "Transfer": SpendingCategoryInfo(icon: "arrow.left.arrow.right", color: "#96CEB4"),
        "Payment": SpendingCategoryInfo(icon: "creditcard", color: "#FFEAA7"),
        "Recreation": SpendingCategoryInfo(icon: "gamecontroller", color: "#DDA0DD"),
        "Service": SpendingCategoryInfo(icon: "wrench.and.screwdriver", color: "#87CEEB"),
        "Healthcare": SpendingCategoryInfo(icon: "cross.case", color: "#98D8C8"),
        "Bank Fees": SpendingCategoryInfo(icon: "building.columns", color: "#A0AEC0"),
        "Community": SpendingCategoryInfo(icon: "person.3", color: "#E8DAEF"),
        "Other": SpendingCategoryInfo(icon: "ellipsis.circle", color: "#718096"),
    ]
}

// MARK: - API Error

struct PlaidAPIError: Codable, LocalizedError {
    let error: String?
    let message: String?
    let errorCode: String?
    
    enum CodingKeys: String, CodingKey {
        case error
        case message
        case errorCode = "error_code"
    }
    
    var errorDescription: String? {
        message ?? error ?? "An unknown error occurred"
    }
}
