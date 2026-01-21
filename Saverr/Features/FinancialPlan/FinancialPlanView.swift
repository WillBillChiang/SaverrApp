//
//  FinancialPlanView.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import SwiftUI

struct FinancialPlanView: View {
    @State private var goals: [FinancialGoal] = []
    @State private var plan: FinancialPlan?
    @State private var isLoading = true
    @State private var showAddGoal = false
    @State private var selectedGoal: FinancialGoal?

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.services) var services

    var totalProgress: Double {
        guard !goals.isEmpty else { return 0 }
        let total = goals.reduce(0.0) { $0 + $1.progress }
        return total / Double(goals.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                (colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
                    .ignoresSafeArea()

                if isLoading {
                    ProgressView("Loading your plan...")
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Plan Summary
                            if let plan = plan {
                                planSummaryCard(plan)
                            } else {
                                noPlanCard
                            }

                            // Overall Progress
                            if !goals.isEmpty {
                                overallProgressCard
                            }

                            // Goals Section
                            goalsSection

                            // Recommendations
                            if let plan = plan, !plan.recommendations.isEmpty {
                                recommendationsSection(plan.recommendations)
                            }
                        }
                        .padding()
                        .padding(.bottom, 100)
                    }

                    // Floating Add Button
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            addGoalButton
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("My Plan")
            .sheet(isPresented: $showAddGoal) {
                AddGoalView { newGoal in
                    goals.append(newGoal)
                }
            }
            .sheet(item: $selectedGoal) { goal in
                GoalDetailView(goal: goal) { updatedGoal in
                    if let index = goals.firstIndex(where: { $0.id == updatedGoal.id }) {
                        goals[index] = updatedGoal
                    }
                }
            }
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
        }
    }

    // MARK: - Subviews

    private func planSummaryCard(_ plan: FinancialPlan) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.accentPrimary)
                Text("Your Financial Plan")
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
            }

            Text(plan.summary)
                .font(.subheadline)
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                .lineSpacing(4)

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Savings Target")
                        .font(.caption)
                        .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                    Text(plan.monthlyTargetSavings.asCurrency)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.accentPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Created")
                        .font(.caption)
                        .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                    Text(plan.generatedAt.formatted)
                        .font(.caption)
                        .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                }
            }
        }
        .padding()
        .cardStyle()
    }

    private var noPlanCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 40))
                .foregroundStyle(Color.accentPrimary.opacity(0.5))

            Text("No Plan Yet")
                .font(.headline)
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

            Text("Chat with your AI advisor to create a personalized financial plan!")
                .font(.subheadline)
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .cardStyle()
    }

    private var overallProgressCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Overall Progress")
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

                Spacer()

                Text("\(goals.count) goal\(goals.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
            }

            HStack(spacing: 20) {
                CircularProgress(
                    progress: totalProgress,
                    lineWidth: 12,
                    color: .accentPrimary
                )
                .frame(width: 80, height: 80)

                VStack(alignment: .leading, spacing: 8) {
                    progressStat(
                        title: "Total Saved",
                        value: goals.reduce(0) { $0 + $1.currentAmount }.asCurrency,
                        color: .successColor
                    )
                    progressStat(
                        title: "Total Goal",
                        value: goals.reduce(0) { $0 + $1.targetAmount }.asCurrency,
                        color: .accentPrimary
                    )
                    progressStat(
                        title: "Remaining",
                        value: goals.reduce(0) { $0 + $1.remainingAmount }.asCurrency,
                        color: .accentSecondary
                    )
                }
            }
        }
        .padding()
        .cardStyle()
    }

    private func progressStat(title: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(title)
                .font(.caption)
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)

            Spacer()

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
        }
    }

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Goals")
                .font(.headline)
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

            if goals.isEmpty {
                emptyGoalsView
            } else {
                ForEach(goals, id: \.id) { goal in
                    GoalProgressCard(goal: goal)
                        .onTapGesture {
                            selectedGoal = goal
                        }
                }
            }
        }
    }

    private var emptyGoalsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "target")
                .font(.title)
                .foregroundStyle(Color.accentPrimary.opacity(0.5))

            Text("No goals set yet")
                .font(.subheadline)
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)

            PrimaryButton("Create Your First Goal", icon: "plus") {
                showAddGoal = true
            }
            .frame(width: 220)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .cardStyle()
    }

    private func recommendationsSection(_ recommendations: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(Color.warningColor)
                Text("AI Recommendations")
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
            }

            VStack(spacing: 10) {
                ForEach(recommendations.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(Color.accentPrimary)
                            .clipShape(Circle())

                        Text(recommendations[index])
                            .font(.subheadline)
                            .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                            .lineSpacing(2)

                        Spacer()
                    }
                }
            }
        }
        .padding()
        .cardStyle()
    }

    private var addGoalButton: some View {
        Button {
            showAddGoal = true
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(Color.accentPrimary)
                .clipShape(Circle())
                .shadow(color: Color.accentPrimary.opacity(0.4), radius: 8, x: 0, y: 4)
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true

        // Load mock goals and plan
        do {
            let progress = try await services.analyticsService.getSavingsProgress()
            goals = progress.map { $0.goal }

            // Create a mock plan
            plan = FinancialPlan(
                summary: "Based on your financial profile, you're in a good position! Focus on building your emergency fund first, then work towards your other goals. Consistency is key!",
                recommendations: [
                    "Build a 3-month emergency fund of $6,000 as your safety net",
                    "Reduce dining out expenses by 20% - that's about $150/month savings",
                    "Set up automatic transfers of $400/month to your savings",
                    "Review subscriptions - you might find $30-50 in unused services",
                    "Consider increasing your 401(k) contribution by 1%"
                ],
                monthlyTargetSavings: 500
            )
        } catch {
            print("Failed to load data: \(error)")
        }

        isLoading = false
    }
}

#Preview {
    FinancialPlanView()
}
