//
//  FinancialPlan.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import Foundation
import SwiftData

@Model
final class FinancialPlan {
    var id: UUID
    var summary: String
    var recommendations: [String]
    var monthlyTargetSavings: Double
    var generatedAt: Date
    var isActive: Bool

    init(
        summary: String,
        recommendations: [String],
        monthlyTargetSavings: Double
    ) {
        self.id = UUID()
        self.summary = summary
        self.recommendations = recommendations
        self.monthlyTargetSavings = monthlyTargetSavings
        self.generatedAt = Date()
        self.isActive = true
    }
}
