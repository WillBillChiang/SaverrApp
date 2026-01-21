//
//  GoalDetailView.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import SwiftUI

struct GoalDetailView: View {
    let goal: FinancialGoal
    let onUpdate: (FinancialGoal) -> Void

    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var currentAmount: Double
    @State private var showAddContribution = false
    @State private var contributionAmount = ""

    init(goal: FinancialGoal, onUpdate: @escaping (FinancialGoal) -> Void) {
        self.goal = goal
        self.onUpdate = onUpdate
        _currentAmount = State(initialValue: goal.currentAmount)
    }

    var updatedGoal: FinancialGoal {
        let updated = goal
        updated.currentAmount = currentAmount
        return updated
    }

    var body: some View {
        NavigationStack {
            ZStack {
                (colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        goalHeader

                        // Progress Circle
                        progressSection

                        // Stats
                        statsSection

                        // Timeline
                        timelineSection

                        // Add Contribution Button
                        addContributionSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Goal Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onUpdate(updatedGoal)
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showAddContribution) {
                addContributionSheet
            }
        }
    }

    // MARK: - Subviews

    private var goalHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: goal.category.icon)
                .font(.largeTitle)
                .foregroundStyle(goal.category.color)
                .frame(width: 70, height: 70)
                .background(goal.category.color.opacity(0.15))
                .clipShape(Circle())

            VStack(spacing: 4) {
                Text(goal.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

                if !goal.goalDescription.isEmpty {
                    Text(goal.goalDescription)
                        .font(.subheadline)
                        .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 6) {
                    Text(goal.category.rawValue)
                    if goal.isAIGenerated {
                        Image(systemName: "sparkles")
                            .font(.caption)
                        Text("AI Suggested")
                    }
                }
                .font(.caption)
                .foregroundStyle(goal.category.color)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .cardStyle()
    }

    private var progressSection: some View {
        VStack(spacing: 16) {
            CircularProgress(
                progress: updatedGoal.progress,
                lineWidth: 16,
                color: goal.category.color
            )
            .frame(width: 140, height: 140)

            HStack(spacing: 30) {
                VStack(spacing: 4) {
                    Text("Saved")
                        .font(.caption)
                        .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                    Text(currentAmount.asCurrency)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.successColor)
                }

                Rectangle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                    .frame(width: 1, height: 40)

                VStack(spacing: 4) {
                    Text("Target")
                        .font(.caption)
                        .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                    Text(goal.targetAmount.asCurrency)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .cardStyle()
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Remaining",
                value: max(0, goal.targetAmount - currentAmount).asCurrency,
                icon: "dollarsign.circle",
                iconColor: .accentSecondary
            )

            StatCard(
                title: "Days Left",
                value: "\(goal.daysRemaining)",
                icon: "calendar",
                iconColor: goal.daysRemaining < 30 ? .warningColor : .accentPrimary
            )
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timeline")
                .font(.headline)
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Started")
                        .font(.caption)
                        .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                    Text(goal.createdAt.formatted)
                        .font(.subheadline)
                        .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                }

                Spacer()

                // Progress line
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                            .frame(height: 4)

                        Rectangle()
                            .fill(goal.category.color)
                            .frame(width: geometry.size.width * updatedGoal.progress, height: 4)

                        Circle()
                            .fill(goal.category.color)
                            .frame(width: 12, height: 12)
                            .offset(x: geometry.size.width * updatedGoal.progress - 6)
                    }
                }
                .frame(width: 100, height: 12)

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Target")
                        .font(.caption)
                        .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                    Text(goal.targetDate.formatted)
                        .font(.subheadline)
                        .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                }
            }

            // Monthly savings needed
            let monthsRemaining = max(1, Double(goal.daysRemaining) / 30)
            let monthlySavingsNeeded = (goal.targetAmount - currentAmount) / monthsRemaining

            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(Color.accentPrimary)
                Text("Save \(monthlySavingsNeeded.asCurrency)/month to reach your goal on time")
                    .font(.caption)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
            }
            .padding()
            .background(Color.accentPrimary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding()
        .cardStyle()
    }

    private var addContributionSection: some View {
        PrimaryButton("Add Contribution", icon: "plus.circle") {
            showAddContribution = true
        }
    }

    private var addContributionSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Add to \(goal.title)")
                        .font(.headline)
                        .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

                    Text("How much would you like to add?")
                        .font(.subheadline)
                        .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                }

                HStack {
                    Text("$")
                        .font(.largeTitle)
                        .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)

                    TextField("0", text: $contributionAmount)
                        .font(.system(size: 48, weight: .bold))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                }
                .frame(maxWidth: .infinity)

                // Quick amounts
                HStack(spacing: 12) {
                    ForEach([25, 50, 100, 250], id: \.self) { amount in
                        Button {
                            contributionAmount = "\(amount)"
                        } label: {
                            Text("$\(amount)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.accentPrimary.opacity(0.12))
                                .foregroundStyle(Color.accentPrimary)
                                .clipShape(Capsule())
                        }
                    }
                }

                Spacer()

                PrimaryButton("Add Contribution", icon: "plus") {
                    if let amount = Double(contributionAmount), amount > 0 {
                        currentAmount += amount
                        contributionAmount = ""
                        showAddContribution = false
                    }
                }
                .disabled(Double(contributionAmount) ?? 0 <= 0)
            }
            .padding()
            .background(colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showAddContribution = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
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

    GoalDetailView(goal: goal) { _ in }
}
