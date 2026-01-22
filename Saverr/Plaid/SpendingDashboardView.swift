//
//  SpendingDashboardView.swift
//  Saverr
//
//  Dashboard view showing spending from linked accounts
//

import SwiftUI

struct SpendingDashboardView: View {
    @Environment(\.plaidManager) private var plaidManager
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showLinkAccount = false
    @State private var selectedTimeRange: TimeRange = .month
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "3 Months"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                (colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        if plaidManager.hasLinkedAccounts {
                            // Time Range Picker
                            timeRangePicker
                            
                            // Summary Cards
                            summarySection
                            
                            // Spending by Category
                            if !plaidManager.spendingSummary.isEmpty {
                                spendingByCategorySection
                            }
                            
                            // Recent Transactions
                            if !plaidManager.recentTransactions.isEmpty {
                                recentTransactionsSection
                            }
                            
                            // Linked Accounts
                            linkedAccountsSection
                        } else {
                            emptyStateView
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await plaidManager.refresh()
                }
                
                // Loading Overlay
                if plaidManager.isLoading || plaidManager.isSyncing {
                    loadingOverlay
                }
            }
            .navigationTitle("Spending")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showLinkAccount = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.accentPrimary)
                    }
                }
                
                if plaidManager.hasLinkedAccounts {
                    ToolbarItem(placement: .secondaryAction) {
                        Button {
                            Task {
                                await plaidManager.syncAllAccounts()
                            }
                        } label: {
                            Label("Sync", systemImage: "arrow.triangle.2.circlepath")
                        }
                    }
                }
            }
            .sheet(isPresented: $showLinkAccount) {
                linkAccountSheet
            }
            .task {
                if plaidManager.linkedAccounts.isEmpty {
                    await plaidManager.loadLinkedAccounts()
                }
                if plaidManager.hasLinkedAccounts && plaidManager.transactions.isEmpty {
                    await plaidManager.loadAllTransactions(days: selectedTimeRange.days)
                }
            }
            .onChange(of: selectedTimeRange) { _, newRange in
                Task {
                    await plaidManager.loadAllTransactions(days: newRange.days)
                }
            }
            .alert("Error", isPresented: .constant(plaidManager.error != nil)) {
                Button("OK") {
                    plaidManager.error = nil
                }
            } message: {
                if let error = plaidManager.error {
                    Text(error.localizedDescription)
                }
            }
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
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        HStack(spacing: 12) {
            // Total Spending
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(Color.dangerColor)
                    Text("Spent")
                        .font(.caption)
                        .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                }
                
                Text(plaidManager.totalSpending.asCurrency)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackgroundLight)
            .cornerRadius(12)
            
            // Total Income
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(Color.successColor)
                    Text("Income")
                        .font(.caption)
                        .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                }
                
                Text(plaidManager.totalIncome.asCurrency)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackgroundLight)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Spending by Category
    
    private var spendingByCategorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending by Category")
                .font(.headline)
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
            
            ForEach(plaidManager.spendingSummary.prefix(5)) { summary in
                SpendingCard(summary: summary, totalSpending: plaidManager.totalSpending)
            }
            
            if plaidManager.spendingSummary.count > 5 {
                NavigationLink {
                    AllCategoriesView()
                } label: {
                    Text("See all categories")
                        .font(.subheadline)
                        .foregroundStyle(Color.accentPrimary)
                }
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Recent Transactions
    
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                
                Spacer()
                
                NavigationLink {
                    AllTransactionsView()
                } label: {
                    Text("See all")
                        .font(.subheadline)
                        .foregroundStyle(Color.accentPrimary)
                }
            }
            
            ForEach(plaidManager.recentTransactions) { transaction in
                NavigationLink {
                    TransactionDetailView(transaction: transaction)
                } label: {
                    TransactionCard(transaction: transaction)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Linked Accounts
    
    private var linkedAccountsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Linked Accounts")
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                
                Spacer()
                
                NavigationLink {
                    LinkedAccountsView()
                } label: {
                    Text("Manage")
                        .font(.subheadline)
                        .foregroundStyle(Color.accentPrimary)
                }
            }
            
            ForEach(plaidManager.linkedAccounts) { account in
                NavigationLink {
                    PlaidAccountDetailView(account: account)
                } label: {
                    AccountSummaryCard(account: account)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "building.columns.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.accentPrimary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Accounts Linked")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                
                Text("Link your bank account to automatically track your spending and gain insights into your finances.")
                    .font(.body)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            PlaidLinkButton(
                onSuccess: { publicToken in
                    Task {
                        await plaidManager.completeLinking(publicToken: publicToken)
                    }
                    showLinkAccount = false
                },
                onExit: {
                    showLinkAccount = false
                }
            )
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.white)
                
                Text(plaidManager.isSyncing ? "Syncing transactions..." : "Loading...")
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Link Account Sheet
    
    private var linkAccountSheet: some View {
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
                    
                    Text("Securely connect your bank to track spending automatically")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                // Security badges
                VStack(spacing: 12) {
                    securityBadge(icon: "lock.shield.fill", text: "Bank-level encryption")
                    securityBadge(icon: "eye.slash.fill", text: "We never see your credentials")
                    securityBadge(icon: "checkmark.shield.fill", text: "Read-only access")
                }
                .padding(.vertical)
                
                Spacer()
                
                PlaidLinkButton(
                    onSuccess: { publicToken in
                        Task {
                            await plaidManager.completeLinking(publicToken: publicToken)
                        }
                        showLinkAccount = false
                    },
                    onExit: {
                        showLinkAccount = false
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
                        showLinkAccount = false
                    }
                }
            }
        }
    }
    
    private func securityBadge(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.successColor)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
            
            Spacer()
        }
        .padding(.horizontal, 48)
    }
}

// MARK: - All Categories View

struct AllCategoriesView: View {
    @Environment(\.plaidManager) private var plaidManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(plaidManager.spendingSummary) { summary in
                    SpendingCard(summary: summary, totalSpending: plaidManager.totalSpending)
                }
            }
            .padding()
        }
        .background(colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
        .navigationTitle("All Categories")
    }
}

// MARK: - All Transactions View

struct AllTransactionsView: View {
    @Environment(\.plaidManager) private var plaidManager
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var searchText = ""
    @State private var selectedFilter: TransactionFilter = .all
    
    enum TransactionFilter: String, CaseIterable {
        case all = "All"
        case spending = "Spending"
        case income = "Income"
        case pending = "Pending"
    }
    
    var filteredTransactions: [PlaidTransaction] {
        var result = plaidManager.transactions
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { transaction in
                transaction.displayName.localizedCaseInsensitiveContains(searchText) ||
                (transaction.primaryCategory?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply category filter
        switch selectedFilter {
        case .all:
            break
        case .spending:
            result = result.filter { !$0.isIncome }
        case .income:
            result = result.filter { $0.isIncome }
        case .pending:
            result = result.filter { $0.pending }
        }
        
        return result
    }
    
    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search Bar
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
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(TransactionFilter.allCases, id: \.self) { filter in
                            Button {
                                selectedFilter = filter
                            } label: {
                                Text(filter.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(selectedFilter == filter ? .semibold : .regular)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedFilter == filter ? Color.accentPrimary : (colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackgroundLight))
                                    .foregroundStyle(selectedFilter == filter ? .white : (colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                
                // Transactions List
                ScrollView {
                    if filteredTransactions.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundStyle(Color.accentPrimary.opacity(0.5))
                            
                            Text(searchText.isEmpty ? "No transactions" : "No matching transactions")
                                .font(.subheadline)
                                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredTransactions) { transaction in
                                NavigationLink {
                                    TransactionDetailView(transaction: transaction)
                                } label: {
                                    TransactionCard(transaction: transaction)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("All Transactions")
    }
}

#Preview {
    SpendingDashboardView()
        .environment(\.plaidManager, PlaidManager())
}
