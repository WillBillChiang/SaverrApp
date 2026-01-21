//
//  Transaction.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID
    var amount: Double
    var transactionDescription: String
    var date: Date
    var categoryName: String?
    var isIncome: Bool
    var merchant: String?

    var account: BankAccount?

    var displayAmount: String {
        let prefix = isIncome ? "+" : "-"
        return "\(prefix)\(abs(amount).asCurrency)"
    }

    init(
        amount: Double,
        description: String,
        date: Date,
        isIncome: Bool,
        merchant: String? = nil,
        categoryName: String? = nil
    ) {
        self.id = UUID()
        self.amount = amount
        self.transactionDescription = description
        self.date = date
        self.isIncome = isIncome
        self.merchant = merchant
        self.categoryName = categoryName
    }
}
