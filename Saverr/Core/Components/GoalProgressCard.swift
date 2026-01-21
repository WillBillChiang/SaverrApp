//
//  GoalProgressCard.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import SwiftUI

struct GoalProgressCard: View {
    let goal: FinancialGoal

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: goal.category.icon)
                    .font(.title3)
                    .foregroundStyle(goal.category.color)
                    .frame(width: 36, height: 36)
                    .background(goal.category.color.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title)
                        .font(.headline)
                        .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

                    Text(goal.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                }

                Spacer()

                if goal.isAIGenerated {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundStyle(Color.accentPrimary)
                }
            }

            // Progress Bar
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(goal.category.color)
                            .frame(width: geometry.size.width * goal.progress, height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text(goal.currentAmount.asCurrency)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

                    Spacer()

                    Text(goal.targetAmount.asCurrency)
                        .font(.subheadline)
                        .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                }
            }

            // Footer
            HStack {
                Label("\(goal.daysRemaining) days left", systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)

                Spacer()

                Text(goal.progress.asPercentage)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(goal.category.color)
            }
        }
        .padding()
        .cardStyle()
    }
}

#Preview {
    let goal = FinancialGoal(
        title: "Emergency Fund",
        description: "Build a 3-month safety net",
        targetAmount: 6000,
        targetDate: Calendar.current.date(byAdding: .month, value: 6, to: Date())!,
        category: .emergency,
        isAIGenerated: true,
        currentAmount: 2400
    )

    GoalProgressCard(goal: goal)
        .padding()
}
