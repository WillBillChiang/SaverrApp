//
//  AddGoalView.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import SwiftUI

struct AddGoalView: View {
    let onGoalCreated: (FinancialGoal) -> Void

    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var title = ""
    @State private var description = ""
    @State private var targetAmount = ""
    @State private var targetDate = Date().addingTimeInterval(180 * 86400) // 6 months from now
    @State private var selectedCategory: FinancialGoal.GoalCategory = .savings
    @State private var currentAmount = ""

    var isValid: Bool {
        !title.isEmpty && Double(targetAmount) ?? 0 > 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                (colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Category Selection
                        categorySelection

                        // Goal Details
                        VStack(spacing: 16) {
                            formField(title: "Goal Name", placeholder: "e.g., Emergency Fund") {
                                TextField("", text: $title)
                            }

                            formField(title: "Description (optional)", placeholder: "What's this goal for?") {
                                TextField("", text: $description, axis: .vertical)
                                    .lineLimit(2...4)
                            }

                            formField(title: "Target Amount", placeholder: "$0.00") {
                                HStack {
                                    Text("$")
                                        .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                                    TextField("", text: $targetAmount)
                                        .keyboardType(.decimalPad)
                                }
                            }

                            formField(title: "Already Saved (optional)", placeholder: "$0.00") {
                                HStack {
                                    Text("$")
                                        .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                                    TextField("", text: $currentAmount)
                                        .keyboardType(.decimalPad)
                                }
                            }

                            formField(title: "Target Date", placeholder: "") {
                                DatePicker("", selection: $targetDate, in: Date()..., displayedComponents: .date)
                                    .labelsHidden()
                            }
                        }

                        // Preview
                        if isValid {
                            goalPreview
                        }

                        Spacer(minLength: 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createGoal()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Subviews

    private var categorySelection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.headline)
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(FinancialGoal.GoalCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    }
                }
            }
        }
    }

    private func formField<Content: View>(title: String, placeholder: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

            content()
                .padding()
                .background(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackgroundLight)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var goalPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

            let previewGoal = FinancialGoal(
                title: title,
                description: description,
                targetAmount: Double(targetAmount) ?? 0,
                targetDate: targetDate,
                category: selectedCategory,
                currentAmount: Double(currentAmount) ?? 0
            )

            GoalProgressCard(goal: previewGoal)
        }
    }

    // MARK: - Actions

    private func createGoal() {
        let goal = FinancialGoal(
            title: title,
            description: description,
            targetAmount: Double(targetAmount) ?? 0,
            targetDate: targetDate,
            category: selectedCategory,
            currentAmount: Double(currentAmount) ?? 0
        )
        onGoalCreated(goal)
        dismiss()
    }
}

struct CategoryButton: View {
    let category: FinancialGoal.GoalCategory
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : category.color)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? category.color : category.color.opacity(0.15))
                    .clipShape(Circle())

                Text(category.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? category.color.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? category.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddGoalView { _ in }
}
