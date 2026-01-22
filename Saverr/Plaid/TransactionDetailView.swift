//
//  TransactionDetailView.swift
//  Saverr
//
//  Detailed view for a single Plaid transaction
//

import SwiftUI

struct TransactionDetailView: View {
    let transaction: PlaidTransaction
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    var categoryInfo: SpendingCategoryInfo {
        let category = transaction.primaryCategory ?? "Other"
        return SpendingCategoryInfo.all[category] ?? SpendingCategoryInfo(icon: "dollarsign.circle", color: "#718096")
    }
    
    var formattedDate: String {
        guard let date = transaction.transactionDate else { return transaction.date }
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
    
    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header with amount
                    headerSection
                    
                    // Transaction Details Card
                    detailsCard
                    
                    // Category Card
                    categoryCard
                    
                    // Metadata Card
                    if transaction.paymentChannel != nil || transaction.website != nil {
                        metadataCard
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Transaction")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Merchant Logo or Icon
            ZStack {
                if let logoUrl = transaction.logoUrl, let url = URL(string: logoUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Image(systemName: categoryInfo.icon)
                            .font(.title)
                            .foregroundStyle(Color(hex: categoryInfo.color))
                    }
                    .frame(width: 48, height: 48)
                } else {
                    Image(systemName: categoryInfo.icon)
                        .font(.title)
                        .foregroundStyle(Color(hex: categoryInfo.color))
                }
            }
            .frame(width: 72, height: 72)
            .background(Color(hex: categoryInfo.color).opacity(0.15))
            .clipShape(Circle())
            
            // Merchant Name
            Text(transaction.displayName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                .multilineTextAlignment(.center)
            
            // Amount
            HStack(spacing: 4) {
                Text(transaction.isIncome ? "+" : "-")
                Text(transaction.absoluteAmount.asCurrency)
            }
            .font(.system(size: 36, weight: .bold))
            .foregroundStyle(transaction.isIncome ? Color.successColor : (colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight))
            
            // Status Badge
            if transaction.pending {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                    Text("Pending")
                }
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.warningColor.opacity(0.2))
                .foregroundStyle(Color.warningColor)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackgroundLight)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Details Card
    
    private var detailsCard: some View {
        VStack(spacing: 0) {
            detailRow(label: "Date", value: formattedDate, icon: "calendar")
            
            Divider()
                .padding(.leading, 52)
            
            detailRow(label: "Original Name", value: transaction.name, icon: "doc.text")
            
            if let merchantName = transaction.merchantName, merchantName != transaction.name {
                Divider()
                    .padding(.leading, 52)
                
                detailRow(label: "Merchant", value: merchantName, icon: "storefront")
            }
            
            Divider()
                .padding(.leading, 52)
            
            detailRow(label: "Transaction ID", value: String(transaction.transactionId.prefix(16)) + "...", icon: "number")
        }
        .background(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackgroundLight)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Category Card
    
    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
            
            HStack(spacing: 12) {
                Image(systemName: categoryInfo.icon)
                    .font(.title3)
                    .foregroundStyle(Color(hex: categoryInfo.color))
                    .frame(width: 40, height: 40)
                    .background(Color(hex: categoryInfo.color).opacity(0.15))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.primaryCategory ?? "Uncategorized")
                        .font(.headline)
                        .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                    
                    if let categories = transaction.category, categories.count > 1 {
                        Text(categories.dropFirst().joined(separator: " • "))
                            .font(.caption)
                            .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackgroundLight)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Metadata Card
    
    private var metadataCard: some View {
        VStack(spacing: 0) {
            if let channel = transaction.paymentChannel {
                detailRow(label: "Payment Method", value: channel.capitalized, icon: "creditcard")
                
                if transaction.website != nil {
                    Divider()
                        .padding(.leading, 52)
                }
            }
            
            if let website = transaction.website {
                detailRow(label: "Website", value: website, icon: "globe")
            }
            
            if let currency = transaction.isoCurrencyCode {
                Divider()
                    .padding(.leading, 52)
                
                detailRow(label: "Currency", value: currency, icon: "dollarsign.circle")
            }
        }
        .background(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackgroundLight)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Helper Views
    
    private func detailRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.accentPrimary)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                
                Text(value)
                    .font(.body)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        TransactionDetailView(
            transaction: PlaidTransaction(
                id: "1",
                transactionId: "tx_abc123def456",
                accountId: "acc_1",
                amount: 45.99,
                date: "2026-01-20",
                name: "UBER EATS",
                merchantName: "Uber Eats",
                category: ["Food and Drink", "Restaurants", "Fast Food"],
                pending: false,
                paymentChannel: "online",
                isoCurrencyCode: "USD",
                logoUrl: nil,
                website: "ubereats.com"
            )
        )
    }
}
