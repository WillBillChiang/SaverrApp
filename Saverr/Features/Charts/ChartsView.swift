//
//  ChartsView.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import SwiftUI
import Charts

struct ChartsView: View {
    @State private var cashFlowData: CashFlowData?
    @State private var categorySpending: [CategorySpending] = []
    @State private var budgetComparison: BudgetComparison?
    @State private var savingsProgress: [GoalProgress] = []
    @State private var isLoading = true
    @State private var selectedTimeRange: TimeRange = .month

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.services) var services

    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                (colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
                    .ignoresSafeArea()

                if isLoading {
                    ProgressView("Loading insights...")
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Time Range Picker
                            timeRangePicker

                            // Cash Flow Summary
                            cashFlowSummary

                            // Cash Flow Chart
                            if let data = cashFlowData {
                                CashFlowChartView(data: data)
                            }

                            // Budget Progress
                            if let budget = budgetComparison {
                                BudgetProgressView(comparison: budget)
                            }

                            // Spending by Category
                            if !categorySpending.isEmpty {
                                CategoryBreakdownView(categories: categorySpending)
                            }

                            // Savings Goals Progress
                            if !savingsProgress.isEmpty {
                                SavingsGoalsView(goals: savingsProgress)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Insights")
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
        }
    }

    // MARK: - Subviews

    private var timeRangePicker: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    private var cashFlowSummary: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Money In",
                value: (cashFlowData?.totalInflow ?? 0).asCurrency,
                icon: "arrow.down.circle",
                iconColor: .successColor
            )

            StatCard(
                title: "Money Out",
                value: (cashFlowData?.totalOutflow ?? 0).asCurrency,
                icon: "arrow.up.circle",
                iconColor: .accentSecondary
            )
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true

        let dateRange = DateInterval(start: Date().addingTimeInterval(-30 * 86400), end: Date())

        do {
            async let cashFlow = services.analyticsService.getCashFlow(for: dateRange)
            async let spending = services.analyticsService.getSpendingByCategory(for: dateRange)
            async let budget = services.analyticsService.getBudgetComparison(for: Date().apiMonthYear)
            async let savings = services.analyticsService.getSavingsProgress()

            cashFlowData = try await cashFlow
            categorySpending = try await spending
            budgetComparison = try await budget
            savingsProgress = try await savings
        } catch {
            print("Failed to load analytics: \(error)")
        }

        isLoading = false
    }
}

// MARK: - Cash Flow Chart

struct CashFlowChartView: View {
    let data: CashFlowData

    @Environment(\.colorScheme) var colorScheme

    var chartData: [CashFlowEntry] {
        var entries: [CashFlowEntry] = []

        for (date, amount) in data.inflows {
            entries.append(CashFlowEntry(date: date, amount: amount, type: "Income"))
        }

        for (date, amount) in data.outflows {
            entries.append(CashFlowEntry(date: date, amount: -amount, type: "Expenses"))
        }

        return entries.sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cash Flow")
                .font(.headline)
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

            Chart(chartData) { entry in
                BarMark(
                    x: .value("Date", entry.date, unit: .day),
                    y: .value("Amount", entry.amount)
                )
                .foregroundStyle(entry.type == "Income" ? Color.successColor : Color.accentSecondary)
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month(), centered: true)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(amount.asCompactCurrency)
                        }
                    }
                }
            }

            // Legend
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Circle().fill(Color.successColor).frame(width: 10, height: 10)
                    Text("Income")
                        .font(.caption)
                        .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                }
                HStack(spacing: 6) {
                    Circle().fill(Color.accentSecondary).frame(width: 10, height: 10)
                    Text("Expenses")
                        .font(.caption)
                        .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                }
            }
        }
        .padding()
        .cardStyle()
    }
}

struct CashFlowEntry: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
    let type: String
}

// MARK: - Budget Progress

struct BudgetProgressView: View {
    let comparison: BudgetComparison

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Budget")
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

                Spacer()

                Text(comparison.isOverBudget ? "Over Budget" : "On Track")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(comparison.isOverBudget ? Color.dangerColor.opacity(0.15) : Color.successColor.opacity(0.15))
                    .foregroundStyle(comparison.isOverBudget ? Color.dangerColor : Color.successColor)
                    .clipShape(Capsule())
            }

            // Overall progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Total Spent")
                        .font(.subheadline)
                        .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)

                    Spacer()

                    Text("\(comparison.actual.asCurrency) / \(comparison.budgeted.asCurrency)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                }

                LinearProgress(
                    progress: comparison.percentUsed,
                    height: 10,
                    color: comparison.isOverBudget ? .dangerColor : .accentPrimary
                )
            }

            // Donut Chart
            Chart(comparison.byCategory, id: \.categoryName) { item in
                SectorMark(
                    angle: .value("Amount", item.actual),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(by: .value("Category", item.categoryName))
                .cornerRadius(4)
            }
            .frame(height: 180)
            .chartLegend(position: .bottom, alignment: .center, spacing: 10)
        }
        .padding()
        .cardStyle()
    }
}

// MARK: - Category Breakdown

struct CategoryBreakdownView: View {
    let categories: [CategorySpending]

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending by Category")
                .font(.headline)
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

            ForEach(categories.sorted { $0.amount > $1.amount }) { category in
                HStack(spacing: 12) {
                    Image(systemName: category.iconName)
                        .font(.body)
                        .foregroundStyle(Color(hex: category.colorHex))
                        .frame(width: 32, height: 32)
                        .background(Color(hex: category.colorHex).opacity(0.15))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(category.categoryName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

                            Spacer()

                            Text(category.amount.asCurrency)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(hex: category.colorHex))
                                    .frame(width: geometry.size.width * category.percentage, height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
        }
        .padding()
        .cardStyle()
    }
}

// MARK: - Savings Goals

struct SavingsGoalsView: View {
    let goals: [GoalProgress]

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Savings Goals")
                .font(.headline)
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

            ForEach(goals) { progress in
                HStack(spacing: 14) {
                    CircularProgress(
                        progress: progress.goal.progress,
                        lineWidth: 6,
                        color: progress.goal.category.color,
                        showPercentage: false
                    )
                    .frame(width: 50, height: 50)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(progress.goal.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

                            if progress.onTrack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.successColor)
                            }
                        }

                        Text("\(progress.goal.currentAmount.asCurrency) of \(progress.goal.targetAmount.asCurrency)")
                            .font(.caption)
                            .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                    }

                    Spacer()

                    Text(progress.goal.progress.asPercentage)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(progress.goal.category.color)
                }
            }
        }
        .padding()
        .cardStyle()
    }
}

#Preview {
    ChartsView()
}
