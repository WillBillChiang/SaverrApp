//
//  ChatBubble.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import SwiftUI

struct ChatBubble: View {
    let message: ChatMessage

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isFromUser {
                Spacer(minLength: 60)
            } else {
                // AI Avatar
                Circle()
                    .fill(Color.accentPrimary)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundStyle(.white)
                    )
            }

            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundStyle(message.isFromUser ? .white : (colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.isFromUser ?
                            Color.accentPrimary :
                            (colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackgroundLight)
                    )
                    .clipShape(ChatBubbleShape(isFromUser: message.isFromUser))
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)

                Text(message.timestamp.relativeFormatted)
                    .font(.caption2)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
            }

            if !message.isFromUser {
                Spacer(minLength: 60)
            }
        }
    }
}

struct ChatBubbleShape: Shape {
    let isFromUser: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 16
        let tailSize: CGFloat = 6

        var path = Path()

        if isFromUser {
            // User bubble - tail on right
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                       radius: radius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius - tailSize))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius - tailSize),
                       radius: radius, startAngle: .degrees(0), endAngle: .degrees(45), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX + tailSize, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.maxY - tailSize))
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY - tailSize))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius - tailSize),
                       radius: radius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                       radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        } else {
            // AI bubble - tail on left
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                       radius: radius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius - tailSize))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius - tailSize),
                       radius: radius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY - tailSize))
            path.addLine(to: CGPoint(x: rect.minX - tailSize, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY - tailSize - radius))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius - tailSize),
                       radius: radius, startAngle: .degrees(135), endAngle: .degrees(180), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                       radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        }

        path.closeSubpath()
        return path
    }
}

struct TypingIndicator: View {
    @State private var dotOffset: CGFloat = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Circle()
                .fill(Color.accentPrimary)
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundStyle(.white)
                )

            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.accentPrimary.opacity(0.6))
                        .frame(width: 8, height: 8)
                        .offset(y: dotOffset)
                        .animation(
                            Animation.easeInOut(duration: 0.4)
                                .repeatForever()
                                .delay(Double(index) * 0.15),
                            value: dotOffset
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.cardBackgroundLight)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .onAppear {
                dotOffset = -5
            }

            Spacer()
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ChatBubble(message: ChatMessage(
            content: "Hey! How can I help you with your finances today?",
            isFromUser: false
        ))

        ChatBubble(message: ChatMessage(
            content: "I want to save more money each month",
            isFromUser: true
        ))

        TypingIndicator()
    }
    .padding()
}
