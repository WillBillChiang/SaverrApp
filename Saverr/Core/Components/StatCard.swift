//
//  StatCard.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String?
    let iconColor: Color
    let trend: Trend?

    @Environment(\.colorScheme) var colorScheme

    enum Trend {
        case up(String)
        case down(String)
        case neutral(String)

        var color: Color {
            switch self {
            case .up: return .successColor
            case .down: return .dangerColor
            case .neutral: return .textSecondaryLight
            }
        }

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }

        var text: String {
            switch self {
            case .up(let text), .down(let text), .neutral(let text):
                return text
            }
        }
    }

    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String? = nil,
        iconColor: Color = .accentPrimary,
        trend: Trend? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.trend = trend
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(iconColor)
                }

                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)

                Spacer()

                if let trend = trend {
                    HStack(spacing: 4) {
                        Image(systemName: trend.icon)
                            .font(.caption)
                        Text(trend.text)
                            .font(.caption)
                    }
                    .foregroundStyle(trend.color)
                }
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
            }
        }
        .padding()
        .cardStyle()
    }
}

#Preview {
    VStack(spacing: 16) {
        StatCard(
            title: "Total Balance",
            value: "$12,450.67",
            subtitle: "Across 4 accounts",
            icon: "dollarsign.circle",
            trend: .up("+2.4%")
        )

        StatCard(
            title: "Monthly Spending",
            value: "$2,145.80",
            icon: "arrow.down.circle",
            iconColor: .accentSecondary,
            trend: .down("-5.2%")
        )
    }
    .padding()
}
