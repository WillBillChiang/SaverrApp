//
//  AIChatView.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import SwiftUI

struct AIChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isTyping = false
    @State private var showGeneratePlanButton = false
    @State private var isGeneratingPlan = false
    @State private var generatedPlan: FinancialPlan?
    @State private var showPlanAlert = false

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.services) var services

    var body: some View {
        NavigationStack {
            ZStack {
                (colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                // Welcome message
                                if messages.isEmpty {
                                    welcomeView
                                }

                                ForEach(messages, id: \.id) { message in
                                    ChatBubble(message: message)
                                        .id(message.id)
                                }

                                if isTyping {
                                    TypingIndicator()
                                }

                                // Generate Plan Button
                                if showGeneratePlanButton && !isGeneratingPlan {
                                    generatePlanButton
                                }
                            }
                            .padding()
                        }
                        .onChange(of: messages.count) { _, _ in
                            withAnimation {
                                proxy.scrollTo(messages.last?.id, anchor: .bottom)
                            }
                        }
                    }

                    // Quick Actions
                    quickActionsView

                    // Input
                    chatInputView
                }
            }
            .navigationTitle("AI Advisor")
            .alert("Plan Created!", isPresented: $showPlanAlert) {
                Button("View Plan") {
                    // Navigate to plan tab
                }
                Button("Later", role: .cancel) {}
            } message: {
                Text("Your personalized financial plan is ready! Check the 'My Plan' tab to see your goals and recommendations.")
            }
            .onAppear {
                if messages.isEmpty {
                    loadInitialMessage()
                }
            }
        }
    }

    // MARK: - Subviews

    private var welcomeView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentPrimary)

            Text("Your Financial Buddy")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

            Text("I'm here to help you with budgeting, saving, and reaching your financial goals. Let's chat!")
                .font(.subheadline)
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }

    private var quickActionsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                QuickActionChip(title: "Save Money", icon: "banknote") {
                    sendQuickMessage("How can I save more money?")
                }
                QuickActionChip(title: "Budget Help", icon: "chart.pie") {
                    sendQuickMessage("Help me create a budget")
                }
                QuickActionChip(title: "Set Goals", icon: "target") {
                    sendQuickMessage("I want to set some financial goals")
                }
                QuickActionChip(title: "Spending Tips", icon: "lightbulb") {
                    sendQuickMessage("Give me tips to reduce spending")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(colorScheme == .dark ? Color.cardBackgroundDark.opacity(0.5) : Color.cardBackgroundLight.opacity(0.8))
    }

    private var chatInputView: some View {
        HStack(spacing: 12) {
            TextField("Ask me anything about finances...", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackgroundLight)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(inputText.isEmpty ? Color.gray : Color.accentPrimary)
            }
            .disabled(inputText.isEmpty || isTyping)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
    }

    private var generatePlanButton: some View {
        Button {
            generatePlan()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                Text("Generate My Financial Plan")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [Color.accentPrimary, Color(hex: "#45B7D1")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 8)
    }

    // MARK: - Actions

    private func loadInitialMessage() {
        let greeting = ChatMessage(
            content: "Hey there! I'm Saverr, your friendly financial buddy. What's on your mind today? I can help with budgeting, saving goals, or just chat about your finances!",
            isFromUser: false
        )
        messages.append(greeting)
    }

    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let userMessage = ChatMessage(content: inputText, isFromUser: true)
        messages.append(userMessage)

        let messageToSend = inputText
        inputText = ""
        isTyping = true

        Task {
            do {
                let response = try await services.aiService.sendMessage(messageToSend, context: messages)
                isTyping = false
                messages.append(response)

                // Show generate plan button after a few exchanges
                if messages.filter({ $0.isFromUser }).count >= 3 {
                    withAnimation {
                        showGeneratePlanButton = true
                    }
                }
            } catch {
                isTyping = false
                let errorMessage = ChatMessage(
                    content: "Oops! Something went wrong. Let's try that again!",
                    isFromUser: false
                )
                messages.append(errorMessage)
            }
        }
    }

    private func sendQuickMessage(_ message: String) {
        inputText = message
        sendMessage()
    }

    private func generatePlan() {
        isGeneratingPlan = true

        let generatingMessage = ChatMessage(
            content: "Let me put together a personalized financial plan based on everything we've talked about...",
            isFromUser: false
        )
        messages.append(generatingMessage)

        Task {
            do {
                let plan = try await services.aiService.generateFinancialPlan(from: messages)
                isGeneratingPlan = false
                generatedPlan = plan

                let successMessage = ChatMessage(
                    content: "Your financial plan is ready! I've created \(plan.recommendations.count) personalized recommendations and set up some goals for you. Check out the 'My Plan' tab to see everything!",
                    isFromUser: false,
                    messageType: .planGenerated
                )
                messages.append(successMessage)
                showGeneratePlanButton = false
                showPlanAlert = true
            } catch {
                isGeneratingPlan = false
                let errorMessage = ChatMessage(
                    content: "I had trouble creating your plan. Let's keep chatting and try again!",
                    isFromUser: false
                )
                messages.append(errorMessage)
            }
        }
    }
}

// MARK: - Quick Action Chip

struct QuickActionChip: View {
    let title: String
    let icon: String
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.accentPrimary.opacity(0.12))
            .foregroundStyle(Color.accentPrimary)
            .clipShape(Capsule())
        }
    }
}

#Preview {
    AIChatView()
}
