//
//  SpendingCard.swift
//  Saverr
//
//  Card component to display spending by category
//

import SwiftUI

struct SpendingCard: View {
    let summary: SpendingSummary
    let totalSpending: Double
    
    @Environment(\.colorScheme) private var colorScheme
    
    var percentage: Double {
        guard totalSpending > 0 else { return 0 }
        return summary.amount / totalSpending
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Category Icon
            Image(systemName: summary.icon)
                .font(.title2)
                .foregroundStyle(Color(hex: summary.color))
                .frame(width: 48, height: 48)
                .background(Color(hex: summary.color).opacity(0.15))
                .clipShape(Circle())
            
            // Category Info
            VStack(alignment: .leading, spacing: 4) {
                Text(summary.category)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                
                Text("\(summary.transactionCount) transaction\(summary.transactionCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
            }
            
            Spacer()
            
            // Amount & Percentage
            VStack(alignment: .trailing, spacing: 4) {
                Text(summary.amount.asCurrency)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                
                Text(percentage.asPercentage)
                    .font(.caption)
                    .foregroundStyle(Color(hex: summary.color))
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackgroundLight)
        .cornerRadius(12)
    }
}

// MARK: - Transaction Card

struct TransactionCard: View {
    let transaction: PlaidTransaction
    
    @Environment(\.colorScheme) private var colorScheme
    
    var formattedDate: String {
        guard let date = transaction.transactionDate else { return transaction.date }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var categoryInfo: SpendingCategoryInfo {
        let category = transaction.primaryCategory ?? "Other"
        return SpendingCategoryInfo.all[category] ?? SpendingCategoryInfo(icon: "dollarsign.circle", color: "#718096")
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                if let logoUrl = transaction.logoUrl, let url = URL(string: logoUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Image(systemName: categoryInfo.icon)
                            .foregroundStyle(Color(hex: categoryInfo.color))
                    }
                    .frame(width: 32, height: 32)
                } else {
                    Image(systemName: categoryInfo.icon)
                        .font(.title3)
                        .foregroundStyle(Color(hex: categoryInfo.color))
                }
            }
            .frame(width: 44, height: 44)
            .background(Color(hex: categoryInfo.color).opacity(0.12))
            .clipShape(Circle())
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(formattedDate)
                    
                    if transaction.pending {
                        Text("• Pending")
                            .foregroundStyle(Color.warningColor)
                    }
                }
                .font(.caption)
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
            }
            
            Spacer()
            
            // Amount
            Text(transaction.isIncome ? "+\(transaction.absoluteAmount.asCurrency)" : "-\(transaction.absoluteAmount.asCurrency)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(transaction.isIncome ? Color.successColor : (colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackgroundLight)
        .cornerRadius(12)
    }
}

// MARK: - Account Summary Card

struct AccountSummaryCard: View {
    let account: PlaidLinkedAccount
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 14) {
            // Bank Icon
            Image(systemName: account.appAccountType.icon)
                .font(.title2)
                .foregroundStyle(Color.accentPrimary)
                .frame(width: 48, height: 48)
                .background(Color.accentPrimary.opacity(0.12))
                .clipShape(Circle())
            
            // Account Info
            VStack(alignment: .leading, spacing: 4) {
                Text(account.institutionName ?? "Bank Account")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                
                HStack(spacing: 4) {
                    Text(account.name)
                    if let mask = account.mask {
                        Text("••••\(mask)")
                    }
                }
                .font(.caption)
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
            }
            
            Spacer()
            
            // Balance
            Text(account.displayBalance.asCurrency)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
        }
        .padding()
        .background(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackgroundLight)
        .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 16) {
        SpendingCard(
            summary: SpendingSummary(
                category: "Food and Drink",
                amount: 485.32,
                transactionCount: 23,
                icon: "fork.knife",
                color: "#FF6B6B"
            ),
            totalSpending: 2500
        )
        
        TransactionCard(
            transaction: PlaidTransaction(
                id: "1",
                transactionId: "tx1",
                accountId: "acc1",
                amount: 45.99,
                date: "2026-01-20",
                name: "UBER EATS",
                merchantName: "Uber Eats",
                category: ["Food and Drink", "Restaurants"],
                pending: false,
                paymentChannel: "online",
                isoCurrencyCode: "USD",
                logoUrl: nil,
                website: nil
            )
        )
    }
    .padding()
    .background(Color.backgroundDark)
}
