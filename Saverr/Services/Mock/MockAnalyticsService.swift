//
//  MockAnalyticsService.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import Foundation

final class MockAnalyticsService: AnalyticsServiceProtocol {
    private let delay: Duration = .milliseconds(300)

    func getCashFlow(for dateRange: DateInterval) async throws -> CashFlowData {
        try await Task.sleep(for: delay)

        let calendar = Calendar.current
        var inflows: [(date: Date, amount: Double)] = []
        var outflows: [(date: Date, amount: Double)] = []

        // Generate 30 days of data
        for dayOffset in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }

            // Income on 1st and 15th
            let dayOfMonth = calendar.component(.day, from: date)
            if dayOfMonth == 1 || dayOfMonth == 15 {
                inflows.append((date: date, amount: Double.random(in: 2800...3500)))
            }

            // Random outflows
            let dailySpending = Double.random(in: 20...150)
            outflows.append((date: date, amount: dailySpending))
        }

        let totalIn = inflows.reduce(0) { $0 + $1.amount }
        let totalOut = outflows.reduce(0) { $0 + $1.amount }

        return CashFlowData(
            inflows: inflows.reversed(),
            outflows: outflows.reversed(),
            netFlow: totalIn - totalOut
        )
    }

    func getSpendingByCategory(for dateRange: DateInterval) async throws -> [CategorySpending] {
        try await Task.sleep(for: delay)

        let categories: [(String, String, String, Double, Int)] = [
            ("Food & Dining", "fork.knife", "#FF6B6B", 485.50, 23),
            ("Transportation", "car.fill", "#4ECDC4", 320.00, 12),
            ("Shopping", "bag.fill", "#45B7D1", 267.80, 8),
            ("Entertainment", "tv.fill", "#96CEB4", 145.99, 5),
            ("Bills & Utilities", "bolt.fill", "#FFEAA7", 412.00, 6),
            ("Health", "heart.fill", "#DDA0DD", 89.00, 2),
            ("Other", "ellipsis.circle.fill", "#C9C9C9", 156.34, 7)
        ]

        let total = categories.reduce(0) { $0 + $1.3 }

        return categories.map { name, icon, color, amount, count in
            CategorySpending(
                categoryName: name,
                iconName: icon,
                colorHex: color,
                amount: amount,
                percentage: amount / total,
                transactionCount: count
            )
        }
    }

    func getBudgetComparison(for month: String) async throws -> BudgetComparison {
        try await Task.sleep(for: delay)

        let byCategory: [(String, Double, Double)] = [
            ("Food & Dining", 500, 485.50),
            ("Transportation", 300, 320.00),
            ("Shopping", 200, 267.80),
            ("Entertainment", 150, 145.99),
            ("Bills & Utilities", 450, 412.00),
            ("Health", 100, 89.00)
        ]

        let totalBudgeted = byCategory.reduce(0) { $0 + $1.1 }
        let totalActual = byCategory.reduce(0) { $0 + $1.2 }

        return BudgetComparison(
            budgeted: totalBudgeted,
            actual: totalActual,
            byCategory: byCategory
        )
    }

    func getSavingsProgress() async throws -> [GoalProgress] {
        try await Task.sleep(for: delay)

        let sixMonths = Calendar.current.date(byAdding: .month, value: 6, to: Date())!
        let oneYear = Calendar.current.date(byAdding: .year, value: 1, to: Date())!

        let goals = [
            FinancialGoal(
                title: "Emergency Fund",
                description: "3-month safety net",
                targetAmount: 6000,
                targetDate: sixMonths,
                category: .emergency,
                isAIGenerated: true,
                currentAmount: 2400
            ),
            FinancialGoal(
                title: "Vacation to Japan",
                description: "Dream trip savings",
                targetAmount: 5000,
                targetDate: oneYear,
                category: .vacation,
                isAIGenerated: false,
                currentAmount: 1200
            ),
            FinancialGoal(
                title: "New Laptop",
                description: "MacBook Pro upgrade",
                targetAmount: 2500,
                targetDate: Calendar.current.date(byAdding: .month, value: 4, to: Date())!,
                category: .purchase,
                isAIGenerated: false,
                currentAmount: 800
            )
        ]

        return goals.map { goal in
            GoalProgress(
                goal: goal,
                monthlyContribution: 400,
                projectedCompletionDate: goal.targetDate,
                onTrack: goal.progress >= 0.3
            )
        }
    }
}
