//
//  AccountCard.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import SwiftUI

struct AccountCard: View {
    let account: BankAccount
    let onTap: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Institution Icon
                Image(systemName: account.institutionLogo ?? "building.columns")
                    .font(.title2)
                    .foregroundStyle(Color.accentPrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.accentPrimary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                // Account Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.accountName)
                        .font(.headline)
                        .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

                    HStack(spacing: 6) {
                        Text(account.institutionName)
                        Text("••••\(account.accountNumberLast4)")
                    }
                    .font(.caption)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                }

                Spacer()

                // Balance
                VStack(alignment: .trailing, spacing: 4) {
                    Text(account.balance.asCurrency)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(account.balance >= 0 ? (colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight) : Color.dangerColor)

                    Text(account.accountType.rawValue)
                        .font(.caption)
                        .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
            }
            .padding()
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

struct AccountRow: View {
    let account: BankAccount

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: account.accountType.icon)
                .font(.body)
                .foregroundStyle(Color.accentPrimary)
                .frame(width: 32, height: 32)
                .background(Color.accentPrimary.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(account.accountName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

                Text(account.institutionName)
                    .font(.caption)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
            }

            Spacer()

            Text(account.balance.asCurrency)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(account.balance >= 0 ? (colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight) : Color.dangerColor)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    let account = BankAccount(
        institutionName: "Chase",
        accountName: "Total Checking",
        accountType: .checking,
        balance: 4523.67,
        accountNumberLast4: "4521",
        institutionLogo: "building.columns"
    )

    VStack(spacing: 16) {
        AccountCard(account: account) {}
        AccountRow(account: account)
    }
    .padding()
}
