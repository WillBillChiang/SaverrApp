//
//  PlaidAccountDetailView.swift
//  Saverr
//
//  Detailed view for a Plaid-linked account
//

import SwiftUI

struct PlaidAccountDetailView: View {
    let account: PlaidLinkedAccount
    
    @Environment(\.plaidManager) private var plaidManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @State private var isRefreshing = false
    @State private var showUnlinkConfirmation = false
    @State private var selectedTimeRange: TimeRange = .month
    @State private var searchText = ""
    
    enum TimeRange: String, CaseIterable {
        case week = "7 Days"
        case month = "30 Days"
        case quarter = "90 Days"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            }
        }
    }
    
    var accountTransactions: [PlaidTransaction] {
        let allTransactions = plaidManager.getTransactionsForAccount(account.id)
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: Date()) ?? Date()
        
        var filtered = allTransactions.filter { transaction in
            guard let date = transaction.transactionDate else { return true }
            return date >= cutoffDate
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { transaction in
                transaction.displayName.localizedCaseInsensitiveContains(searchText) ||
                (transaction.primaryCategory?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return filtered
    }
    
    var totalSpent: Double {
        accountTransactions
            .filter { !$0.isIncome && !$0.pending }
            .reduce(0) { $0 + $1.absoluteAmount }
    }
    
    var totalIncome: Double {
        accountTransactions
            .filter { $0.isIncome }
            .reduce(0) { $0 + $1.absoluteAmount }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                (colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Account Header Card
                        accountHeaderCard
                        
                        // Quick Stats
                        quickStatsSection
                        
                        // Time Range Picker
                        timeRangePicker
                        
                        // Search Bar
                        searchBar
                        
                        // Transactions List
                        transactionsSection
                    }
                    .padding()
                }
                .refreshable {
                    await refreshAccount()
                }
            }
            .navigationTitle(account.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            Task { await refreshAccount() }
                        } label: {
                            Label("Refresh Balance", systemImage: "arrow.clockwise")
                        }
                        
                        Button {
                            Task { await syncTransactions() }
                        } label: {
                            Label("Sync Transactions", systemImage: "arrow.triangle.2.circlepath")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            showUnlinkConfirmation = true
                        } label: {
                            Label("Unlink Account", systemImage: "link.badge.minus")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(Color.accentPrimary)
                    }
                }
            }
            .confirmationDialog(
                "Unlink Account",
                isPresented: $showUnlinkConfirmation,
                titleVisibility: .visible
            ) {
                Button("Unlink", role: .destructive) {
                    Task {
                        let success = await plaidManager.unlinkAccount(account.id)
                        if success {
                            dismiss()
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove the connection to \(account.institutionName ?? "this account"). You can always link it again later.")
            }
        }
    }
    
    // MARK: - Account Header Card
    
    private var accountHeaderCard: some View {
        VStack(spacing: 16) {
            // Institution & Account Info
            HStack(spacing: 16) {
                // Bank Icon
                Image(systemName: account.appAccountType.icon)
                    .font(.title)
                    .foregroundStyle(Color.accentPrimary)
                    .frame(width: 56, height: 56)
                    .background(Color.accentPrimary.opacity(0.12))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.institutionName ?? "Bank Account")
                        .font(.headline)
                        .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                    
                    HStack(spacing: 6) {
                        Text(account.name)
                        if let mask = account.mask {
                            Text("•••• \(mask)")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                    
                    Text(account.type.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentPrimary.opacity(0.15))
                        .foregroundStyle(Color.accentPrimary)
                        .clipShape(Capsule())
                }
                
                Spacer()
            }
            
            Divider()
            
            // Balance Section
            VStack(spacing: 8) {
                if isRefreshing {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(Color.accentPrimary)
                        Text("Updating balance...")
                            .font(.caption)
                            .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                    }
                } else {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Balance")
                                .font(.caption)
                                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                            
                            Text(account.displayBalance.asCurrency)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                        }
                        
                        Spacer()
                        
                        // Note: Backend API returns single balance field
                        // Available balance section removed as API doesn't provide separate available/current balances
                    }
                }
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackgroundLight)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Quick Stats Section
    
    private var quickStatsSection: some View {
        HStack(spacing: 12) {
            // Spending
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(Color.dangerColor)
                    Text("Spent")
                        .font(.caption)
                        .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                }
                
                Text(totalSpent.asCurrency)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                
                Text("\(selectedTimeRange.rawValue)")
                    .font(.caption2)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackgroundLight)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Income
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(Color.successColor)
                    Text("Income")
                        .font(.caption)
                        .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                }
                
                Text(totalIncome.asCurrency)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                
                Text("\(selectedTimeRange.rawValue)")
                    .font(.caption2)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackgroundLight)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Time Range Picker
    
    private var timeRangePicker: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
            
            TextField("Search transactions", text: $searchText)
                .textFieldStyle(.plain)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                }
            }
        }
        .padding(12)
        .background(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackgroundLight)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Transactions Section
    
    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Transactions")
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                
                Spacer()
                
                Text("\(accountTransactions.count) transactions")
                    .font(.caption)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
            }
            
            if accountTransactions.isEmpty {
                emptyTransactionsView
            } else {
                // Group transactions by date
                let grouped = Dictionary(grouping: accountTransactions) { transaction -> String in
                    transaction.transactionDate?.formatted(date: .abbreviated, time: .omitted) ?? transaction.date
                }
                
                let sortedKeys = grouped.keys.sorted { key1, key2 in
                    let date1 = grouped[key1]?.first?.transactionDate ?? Date.distantPast
                    let date2 = grouped[key2]?.first?.transactionDate ?? Date.distantPast
                    return date1 > date2
                }
                
                ForEach(sortedKeys, id: \.self) { dateKey in
                    if let transactions = grouped[dateKey] {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(dateKey)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                                .padding(.top, 8)
                            
                            ForEach(transactions) { transaction in
                                NavigationLink {
                                    TransactionDetailView(transaction: transaction)
                                } label: {
                                    TransactionCard(transaction: transaction)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var emptyTransactionsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(Color.accentPrimary.opacity(0.5))
            
            Text(searchText.isEmpty ? "No transactions found" : "No matching transactions")
                .font(.subheadline)
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
            
            if searchText.isEmpty {
                Button("Sync Transactions") {
                    Task { await syncTransactions() }
                }
                .font(.subheadline)
                .foregroundStyle(Color.accentPrimary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Actions
    
    private func refreshAccount() async {
        isRefreshing = true
        await plaidManager.refreshAccountBalance(account.id)
        isRefreshing = false
    }
    
    private func syncTransactions() async {
        await plaidManager.syncAccount(account.id)
    }
}

#Preview {
    PlaidAccountDetailView(
        account: PlaidLinkedAccount(
            id: "acc_1",
            accountName: "Checking",
            accountType: "checking",
            balance: 5432.10,
            institutionName: "Chase",
            institutionLogo: "building.columns",
            accountNumberLast4: "1234",
            lastUpdated: "2024-01-21T12:00:00Z",
            isLinked: true
        )
    )
    .environment(\.plaidManager, PlaidManager())
}
