//
//  FinancialGoal.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class FinancialGoal {
    var id: UUID
    var title: String
    var goalDescription: String
    var targetAmount: Double
    var currentAmount: Double
    var targetDate: Date
    var createdAt: Date
    var categoryRaw: String
    var isAIGenerated: Bool
    var priority: Int

    var category: GoalCategory {
        get { GoalCategory(rawValue: categoryRaw) ?? .savings }
        set { categoryRaw = newValue.rawValue }
    }

    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }

    var remainingAmount: Double {
        max(0, targetAmount - currentAmount)
    }

    var isCompleted: Bool {
        currentAmount >= targetAmount
    }

    var daysRemaining: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: targetDate)
        return max(0, components.day ?? 0)
    }

    enum GoalCategory: String, Codable, CaseIterable, Identifiable {
        case savings = "Savings"
        case debtPayoff = "Debt Payoff"
        case emergency = "Emergency Fund"
        case investment = "Investment"
        case purchase = "Major Purchase"
        case retirement = "Retirement"
        case vacation = "Vacation"
        case custom = "Custom"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .savings: return "banknote"
            case .debtPayoff: return "creditcard"
            case .emergency: return "umbrella"
            case .investment: return "chart.line.uptrend.xyaxis"
            case .purchase: return "cart"
            case .retirement: return "beach.umbrella"
            case .vacation: return "airplane"
            case .custom: return "star"
            }
        }

        var color: Color {
            switch self {
            case .savings: return .accentPrimary
            case .debtPayoff: return .accentSecondary
            case .emergency: return .warningColor
            case .investment: return Color(hex: "#45B7D1")
            case .purchase: return Color(hex: "#96CEB4")
            case .retirement: return Color(hex: "#DDA0DD")
            case .vacation: return Color(hex: "#87CEEB")
            case .custom: return Color(hex: "#A0AEC0")
            }
        }
    }

    init(
        title: String,
        description: String,
        targetAmount: Double,
        targetDate: Date,
        category: GoalCategory,
        isAIGenerated: Bool = false,
        currentAmount: Double = 0
    ) {
        self.id = UUID()
        self.title = title
        self.goalDescription = description
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.targetDate = targetDate
        self.createdAt = Date()
        self.categoryRaw = category.rawValue
        self.isAIGenerated = isAIGenerated
        self.priority = 0
    }
}
