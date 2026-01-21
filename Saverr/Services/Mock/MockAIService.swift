//
//  MockAIService.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import Foundation

final class MockAIService: AIServiceProtocol {
    private let delay: Duration = .seconds(1)

    private let greetings = [
        "Hey there! I'm Saverr, your friendly financial buddy. What's on your mind today?",
        "Hi! Ready to chat about your money goals? I'm all ears!",
        "Welcome back! Let's make some magic happen with your finances today."
    ]

    private let savingsResponses = [
        "Great question about savings! Based on typical spending patterns, I'd recommend the 50/30/20 rule: 50% for needs, 30% for wants, and 20% for savings. Want me to help you set up a savings goal?",
        "Saving money is all about building good habits! Start small - even $50 a week adds up to over $2,600 a year. What amount feels comfortable for you to set aside regularly?",
        "Love that you're thinking about saving! The secret is to 'pay yourself first' - set up automatic transfers right when you get paid. Should we create a savings goal together?"
    ]

    private let budgetResponses = [
        "Budgeting doesn't have to be boring! Let's start by looking at your biggest spending categories. Usually, food and entertainment are great places to find some wiggle room.",
        "I've got your back on budgeting! The key is being realistic - a budget that's too strict won't stick. What areas of spending would you like to focus on?",
        "Smart thinking! A good budget is like a roadmap for your money. Want me to analyze your spending and suggest some budget categories?"
    ]

    private let goalResponses = [
        "I love setting goals! They give your money a purpose. What are you dreaming about - an emergency fund, a vacation, paying off debt?",
        "Goals are the best! When you have a clear target, saving becomes so much easier. What would feel like a big win for you financially?",
        "Setting financial goals is my favorite! Whether it's a rainy day fund or that dream vacation, I can help you get there. What's on your wishlist?"
    ]

    private let encouragingResponses = [
        "You're doing great by even thinking about this stuff! Most people don't take the time. I'm here to help however I can.",
        "That's a really thoughtful question. Financial wellness is a journey, and you're taking the right steps!",
        "I appreciate you sharing that with me! Let's figure this out together."
    ]

    func sendMessage(_ message: String, context: [ChatMessage]) async throws -> ChatMessage {
        try await Task.sleep(for: delay)

        let response = generateResponse(for: message, contextCount: context.count)
        return ChatMessage(content: response, isFromUser: false)
    }

    func generateFinancialPlan(from context: [ChatMessage]) async throws -> FinancialPlan {
        try await Task.sleep(for: .seconds(2))

        return FinancialPlan(
            summary: "Based on our conversation, I've put together a personalized plan to help you reach your financial goals! You're in a good position - let's make it even better.",
            recommendations: [
                "Build a 3-month emergency fund of $6,000 as your safety net",
                "Reduce dining out expenses by 20% - that's about $150/month savings",
                "Set up automatic transfers of $400/month to your savings",
                "Review subscriptions - you might find $30-50 in unused services",
                "Consider increasing your 401(k) contribution by 1%"
            ],
            monthlyTargetSavings: 500
        )
    }

    func suggestGoals(basedOn transactions: [Transaction]) async throws -> [FinancialGoal] {
        try await Task.sleep(for: delay)

        let sixMonthsFromNow = Calendar.current.date(byAdding: .month, value: 6, to: Date())!
        let yearFromNow = Calendar.current.date(byAdding: .year, value: 1, to: Date())!

        return [
            FinancialGoal(
                title: "Emergency Fund",
                description: "Build a 3-month safety net for peace of mind",
                targetAmount: 6000,
                targetDate: sixMonthsFromNow,
                category: .emergency,
                isAIGenerated: true,
                currentAmount: 1500
            ),
            FinancialGoal(
                title: "Vacation Fund",
                description: "That dream trip you've been thinking about!",
                targetAmount: 3000,
                targetDate: yearFromNow,
                category: .vacation,
                isAIGenerated: true,
                currentAmount: 500
            )
        ]
    }

    // MARK: - Response Generation

    private func generateResponse(for message: String, contextCount: Int) -> String {
        let lowercased = message.lowercased()

        // First message - greeting
        if contextCount <= 1 {
            return greetings.randomElement()!
        }

        // Keyword-based responses
        if lowercased.contains("save") || lowercased.contains("saving") {
            return savingsResponses.randomElement()!
        }

        if lowercased.contains("budget") || lowercased.contains("spend") {
            return budgetResponses.randomElement()!
        }

        if lowercased.contains("goal") || lowercased.contains("want") || lowercased.contains("plan") {
            return goalResponses.randomElement()!
        }

        if lowercased.contains("help") || lowercased.contains("advice") {
            return "I'd love to help! Here are some things I can assist with:\n\n• Setting up savings goals\n• Creating a budget that works for you\n• Analyzing your spending patterns\n• Building a financial plan\n\nWhat sounds most useful right now?"
        }

        if lowercased.contains("thank") {
            return "You're so welcome! That's what I'm here for. Anything else you'd like to chat about?"
        }

        // Default encouraging response
        return encouragingResponses.randomElement()!
    }
}
