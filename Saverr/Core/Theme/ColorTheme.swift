//
//  ColorTheme.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import SwiftUI

extension Color {
    // MARK: - Primary Backgrounds

    /// Dark mode background - neutral dark slate blue
    static let backgroundDark = Color(hex: "#1A1F2E")

    /// Light mode background - neutral light blue
    static let backgroundLight = Color(hex: "#F0F4F8")

    /// Card backgrounds
    static let cardBackgroundDark = Color(hex: "#252B3B")
    static let cardBackgroundLight = Color(hex: "#FFFFFF")

    // MARK: - Accent Colors

    /// Primary accent - calming teal
    static let accentPrimary = Color(hex: "#4ECDC4")

    /// Secondary accent - soft coral
    static let accentSecondary = Color(hex: "#FF6B6B")

    /// Success - soft mint green
    static let successColor = Color(hex: "#98D8C8")

    /// Warning - soft amber
    static let warningColor = Color(hex: "#FFEAA7")

    /// Danger - soft red
    static let dangerColor = Color(hex: "#FF8A80")

    // MARK: - Text Colors

    static let textPrimaryDark = Color(hex: "#FFFFFF")
    static let textPrimaryLight = Color(hex: "#1A1F2E")

    static let textSecondaryDark = Color(hex: "#A0AEC0")
    static let textSecondaryLight = Color(hex: "#718096")

    // MARK: - Chart Colors

    static let chartColors: [Color] = [
        Color(hex: "#4ECDC4"), // Teal
        Color(hex: "#45B7D1"), // Sky blue
        Color(hex: "#96CEB4"), // Sage
        Color(hex: "#FFEAA7"), // Soft yellow
        Color(hex: "#DDA0DD"), // Plum
        Color(hex: "#FF6B6B"), // Coral
        Color(hex: "#87CEEB"), // Light blue
        Color(hex: "#98D8C8"), // Mint
    ]

    // MARK: - Hex Initializer

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Theme Environment

struct SaverrTheme {
    let background: Color
    let cardBackground: Color
    let textPrimary: Color
    let textSecondary: Color
    let accent: Color

    static func current(for colorScheme: ColorScheme) -> SaverrTheme {
        switch colorScheme {
        case .dark:
            return SaverrTheme(
                background: .backgroundDark,
                cardBackground: .cardBackgroundDark,
                textPrimary: .textPrimaryDark,
                textSecondary: .textSecondaryDark,
                accent: .accentPrimary
            )
        case .light:
            return SaverrTheme(
                background: .backgroundLight,
                cardBackground: .cardBackgroundLight,
                textPrimary: .textPrimaryLight,
                textSecondary: .textSecondaryLight,
                accent: .accentPrimary
            )
        @unknown default:
            return SaverrTheme(
                background: .backgroundLight,
                cardBackground: .cardBackgroundLight,
                textPrimary: .textPrimaryLight,
                textSecondary: .textSecondaryLight,
                accent: .accentPrimary
            )
        }
    }
}

// MARK: - View Modifiers

struct ThemedBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
    }
}

struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackgroundLight)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func themedBackground() -> some View {
        modifier(ThemedBackground())
    }

    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
