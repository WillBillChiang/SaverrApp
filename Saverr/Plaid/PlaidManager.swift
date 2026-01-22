//
//  PlaidManager.swift
//  Saverr
//
//  Main manager for Plaid account linking and transaction syncing
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class PlaidManager {
    
    // MARK: - Published State
    
    var linkedAccounts: [PlaidLinkedAccount] = []
    var transactions: [PlaidTransaction] = []
    var spendingSummary: [SpendingSummary] = []
    var isLoading = false
    var isLinking = false
    var isSyncing = false
    var error: Error?
    var linkToken: String?
    
    // MARK: - Computed Properties
    
    var totalSpending: Double {
        transactions
            .filter { !$0.isIncome && !$0.pending }
            .reduce(0) { $0 + $1.absoluteAmount }
    }
    
    var totalIncome: Double {
        transactions
            .filter { $0.isIncome }
            .reduce(0) { $0 + $1.absoluteAmount }
    }
    
    var recentTransactions: [PlaidTransaction] {
        Array(transactions.prefix(10))
    }
    
    var hasLinkedAccounts: Bool {
        !linkedAccounts.isEmpty
    }
    
    // MARK: - Private
    
    private let apiService: PlaidAPIServiceProtocol
    
    init(apiService: PlaidAPIServiceProtocol? = nil) {
        // Always use real API service
        self.apiService = apiService ?? PlaidAPIService()
    }
    
    // MARK: - Public Methods
    
    /// Initialize Plaid Link by getting a link token
    func initializePlaidLink() async {
        isLoading = true
        error = nil
        
        do {
            let token = try await apiService.getLinkToken()
            print("✅ PlaidManager: Received link token: \(token.prefix(20))...")
            linkToken = token
        } catch {
            print("❌ PlaidManager: Failed to get link token - \(error)")
            self.error = error
        }
        
        isLoading = false
    }
    
    /// Complete the linking process with the public token from Plaid Link
    func completeLinking(publicToken: String) async -> Bool {
        isLinking = true
        error = nil
        
        do {
            let response = try await apiService.linkAccount(publicToken: publicToken)
            linkedAccounts.append(response.account)
            
            // Sync transactions for the new account
            await syncAccount(response.account.id)
            
            isLinking = false
            return true
        } catch {
            self.error = error
            isLinking = false
            return false
        }
    }
    
    /// Load all linked accounts
    func loadLinkedAccounts() async {
        isLoading = true
        error = nil
        
        do {
            linkedAccounts = try await apiService.getLinkedAccounts()
            print("✅ PlaidManager: Loaded \(linkedAccounts.count) linked accounts")
        } catch let plaidError as PlaidServiceError {
            // Don't show error for new users with no accounts or backend auth issues
            switch plaidError {
            case .serverError(let code) where code == 404:
                print("ℹ️ PlaidManager: No linked accounts found (new user)")
                linkedAccounts = []
            case .serverError(let code) where code == 403:
                print("⚠️ PlaidManager: Forbidden error - backend auth may not be configured")
                linkedAccounts = []
                // Don't set error - this is a backend issue, not user error
            case .apiError(let message) where message.lowercased().contains("forbidden"):
                print("⚠️ PlaidManager: Forbidden - backend auth configuration issue")
                linkedAccounts = []
                // Don't show error popup for auth config issues
            case .unauthorized:
                print("⚠️ PlaidManager: Unauthorized - token may be invalid")
                linkedAccounts = []
                // Could trigger re-login here
            default:
                print("❌ PlaidManager: Error loading accounts - \(plaidError)")
                self.error = plaidError
            }
        } catch {
            print("❌ PlaidManager: Unexpected error - \(error)")
            self.error = error
        }
        
        isLoading = false
    }
    
    /// Sync transactions for a specific account
    func syncAccount(_ accountId: String) async {
        isSyncing = true
        error = nil
        
        do {
            // First sync with Plaid
            _ = try await apiService.syncTransactions(accountId: accountId)
            
            // Then fetch the transactions
            await loadTransactions(for: accountId)
        } catch {
            self.error = error
        }
        
        isSyncing = false
    }
    
    /// Sync all linked accounts
    func syncAllAccounts() async {
        isSyncing = true
        error = nil
        
        do {
            var allTransactions: [PlaidTransaction] = []
            
            for account in linkedAccounts {
                _ = try await apiService.syncTransactions(accountId: account.id)
                let transactions = try await apiService.getTransactions(
                    accountId: account.id,
                    startDate: Calendar.current.date(byAdding: .day, value: -90, to: Date()),
                    endDate: Date()
                )
                allTransactions.append(contentsOf: transactions)
            }
            
            // Sort by date, most recent first
            self.transactions = allTransactions.sorted { 
                ($0.transactionDate ?? Date()) > ($1.transactionDate ?? Date()) 
            }
            
            // Update spending summary
            updateSpendingSummary()
            
        } catch {
            self.error = error
        }
        
        isSyncing = false
    }
    
    /// Load transactions for an account
    func loadTransactions(for accountId: String, days: Int = 90) async {
        isLoading = true
        error = nil
        
        do {
            let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())
            let fetchedTransactions = try await apiService.getTransactions(
                accountId: accountId,
                startDate: startDate,
                endDate: Date()
            )
            
            // Merge with existing transactions
            let existingIds = Set(transactions.map { $0.id })
            let newTransactions = fetchedTransactions.filter { !existingIds.contains($0.id) }
            transactions.append(contentsOf: newTransactions)
            
            // Sort by date
            transactions.sort { ($0.transactionDate ?? Date()) > ($1.transactionDate ?? Date()) }
            
            // Update spending summary
            updateSpendingSummary()
            
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    /// Load all transactions from all linked accounts
    func loadAllTransactions(days: Int = 90) async {
        isLoading = true
        error = nil
        
        do {
            var allTransactions: [PlaidTransaction] = []
            let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())
            
            for account in linkedAccounts {
                let accountTransactions = try await apiService.getTransactions(
                    accountId: account.id,
                    startDate: startDate,
                    endDate: Date()
                )
                allTransactions.append(contentsOf: accountTransactions)
            }
            
            // Sort by date, most recent first
            self.transactions = allTransactions.sorted { 
                ($0.transactionDate ?? Date()) > ($1.transactionDate ?? Date()) 
            }
            
            // Update spending summary
            updateSpendingSummary()
            
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    /// Unlink an account
    func unlinkAccount(_ accountId: String) async -> Bool {
        do {
            try await apiService.unlinkAccount(accountId: accountId)
            linkedAccounts.removeAll { $0.id == accountId }
            transactions.removeAll { $0.accountId == accountId }
            updateSpendingSummary()
            return true
        } catch {
            self.error = error
            return false
        }
    }
    
    /// Refresh balance for a specific account
    func refreshAccountBalance(_ accountId: String) async {
        isLoading = true
        error = nil
        
        do {
            let updatedAccount = try await apiService.refreshAccountBalance(accountId: accountId)
            if let index = linkedAccounts.firstIndex(where: { $0.id == accountId }) {
                linkedAccounts[index] = updatedAccount
            }
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    /// Get transactions for a specific account
    func getTransactionsForAccount(_ accountId: String) -> [PlaidTransaction] {
        return transactions.filter { $0.accountId == accountId }
    }
    
    /// Get account by ID
    func getAccount(_ accountId: String) -> PlaidLinkedAccount? {
        return linkedAccounts.first { $0.id == accountId }
    }
    
    /// Refresh data
    func refresh() async {
        await loadLinkedAccounts()
        if hasLinkedAccounts {
            await loadAllTransactions()
        }
    }
    
    // MARK: - Private Methods
    
    private func updateSpendingSummary() {
        spendingSummary = SpendingSummary.fromTransactions(transactions)
    }
}

// MARK: - Environment Key

struct PlaidManagerKey: EnvironmentKey {
    static let defaultValue = PlaidManager()
}

extension EnvironmentValues {
    var plaidManager: PlaidManager {
        get { self[PlaidManagerKey.self] }
        set { self[PlaidManagerKey.self] = newValue }
    }
}
