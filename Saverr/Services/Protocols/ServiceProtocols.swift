//
//  ServiceProtocols.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import Foundation

// MARK: - Banking Service Protocol

protocol BankingServiceProtocol {
    func fetchAccounts() async throws -> [BankAccount]
    func fetchTransactions(for accountId: UUID, dateRange: DateInterval?) async throws -> [Transaction]
    func linkAccount(institutionId: String, credentials: [String: String]) async throws -> BankAccount
    func unlinkAccount(accountId: UUID) async throws
    func refreshAccountBalance(accountId: UUID) async throws -> Double
}

// MARK: - AI Service Protocol

protocol AIServiceProtocol {
    func sendMessage(_ message: String, context: [ChatMessage]) async throws -> ChatMessage
    func generateFinancialPlan(from context: [ChatMessage]) async throws -> FinancialPlan
    func suggestGoals(basedOn transactions: [Transaction]) async throws -> [FinancialGoal]
}

// MARK: - Analytics Service Protocol

protocol AnalyticsServiceProtocol {
    func getCashFlow(for dateRange: DateInterval) async throws -> CashFlowData
    func getSpendingByCategory(for dateRange: DateInterval) async throws -> [CategorySpending]
    func getBudgetComparison(for month: String) async throws -> BudgetComparison
    func getSavingsProgress() async throws -> [GoalProgress]
}

// MARK: - Data Transfer Objects

struct CashFlowData {
    let inflows: [(date: Date, amount: Double)]
    let outflows: [(date: Date, amount: Double)]
    let netFlow: Double

    var totalInflow: Double {
        inflows.reduce(0) { $0 + $1.amount }
    }

    var totalOutflow: Double {
        outflows.reduce(0) { $0 + $1.amount }
    }
}

struct CategorySpending: Identifiable {
    let id = UUID()
    let categoryName: String
    let iconName: String
    let colorHex: String
    let amount: Double
    let percentage: Double
    let transactionCount: Int
}

struct BudgetComparison {
    let budgeted: Double
    let actual: Double
    let byCategory: [(categoryName: String, budgeted: Double, actual: Double)]

    var isOverBudget: Bool {
        actual > budgeted
    }

    var percentUsed: Double {
        guard budgeted > 0 else { return 0 }
        return actual / budgeted
    }
}

struct GoalProgress: Identifiable {
    let id = UUID()
    let goal: FinancialGoal
    let monthlyContribution: Double
    let projectedCompletionDate: Date?
    let onTrack: Bool
}

// MARK: - Service Errors

enum ServiceError: LocalizedError {
    case networkError
    case authenticationFailed
    case accountNotFound
    case invalidResponse
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Unable to connect. Please check your internet connection."
        case .authenticationFailed:
            return "Authentication failed. Please try again."
        case .accountNotFound:
            return "Account not found."
        case .invalidResponse:
            return "Received an invalid response."
        case .rateLimited:
            return "Too many requests. Please try again later."
        }
    }
}
