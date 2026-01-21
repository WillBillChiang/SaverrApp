//
//  BankAccount.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import Foundation
import SwiftData

@Model
final class BankAccount {
    var id: UUID
    var institutionName: String
    var accountName: String
    var accountTypeRaw: String
    var balance: Double
    var lastUpdated: Date
    var isLinked: Bool
    var institutionLogo: String?
    var accountNumberLast4: String

    @Relationship(deleteRule: .cascade, inverse: \Transaction.account)
    var transactions: [Transaction]?

    var accountType: AccountType {
        get { AccountType(rawValue: accountTypeRaw) ?? .checking }
        set { accountTypeRaw = newValue.rawValue }
    }

    enum AccountType: String, Codable, CaseIterable, Identifiable {
        case checking = "Checking"
        case savings = "Savings"
        case credit = "Credit Card"
        case investment = "Investment"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .checking: return "dollarsign.circle"
            case .savings: return "banknote"
            case .credit: return "creditcard"
            case .investment: return "chart.line.uptrend.xyaxis"
            }
        }
    }

    init(
        institutionName: String,
        accountName: String,
        accountType: AccountType,
        balance: Double,
        accountNumberLast4: String,
        institutionLogo: String? = nil
    ) {
        self.id = UUID()
        self.institutionName = institutionName
        self.accountName = accountName
        self.accountTypeRaw = accountType.rawValue
        self.balance = balance
        self.lastUpdated = Date()
        self.isLinked = true
        self.accountNumberLast4 = accountNumberLast4
        self.institutionLogo = institutionLogo
    }
}
