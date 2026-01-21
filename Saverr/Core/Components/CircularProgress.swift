//
//  CircularProgress.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import SwiftUI

struct CircularProgress: View {
    let progress: Double
    let lineWidth: CGFloat
    let color: Color
    let showPercentage: Bool

    @Environment(\.colorScheme) var colorScheme

    init(
        progress: Double,
        lineWidth: CGFloat = 10,
        color: Color = .accentPrimary,
        showPercentage: Bool = true
    ) {
        self.progress = min(max(progress, 0), 1)
        self.lineWidth = lineWidth
        self.color = color
        self.showPercentage = showPercentage
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(
                    colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05),
                    lineWidth: lineWidth
                )

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)

            // Percentage text
            if showPercentage {
                Text(progress.asPercentage)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
            }
        }
    }
}

struct LinearProgress: View {
    let progress: Double
    let height: CGFloat
    let color: Color
    let showPercentage: Bool

    @Environment(\.colorScheme) var colorScheme

    init(
        progress: Double,
        height: CGFloat = 8,
        color: Color = .accentPrimary,
        showPercentage: Bool = false
    ) {
        self.progress = min(max(progress, 0), 1)
        self.height = height
        self.color = color
        self.showPercentage = showPercentage
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                        .frame(height: height)

                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: height)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: height)

            if showPercentage {
                Text(progress.asPercentage)
                    .font(.caption2)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
            }
        }
    }
}

#Preview {
    VStack(spacing: 32) {
        CircularProgress(progress: 0.65, color: .accentPrimary)
            .frame(width: 100, height: 100)

        CircularProgress(progress: 0.35, color: .accentSecondary, showPercentage: false)
            .frame(width: 60, height: 60)

        LinearProgress(progress: 0.75, color: .successColor, showPercentage: true)
            .padding(.horizontal)

        LinearProgress(progress: 0.45, height: 12, color: .warningColor)
            .padding(.horizontal)
    }
    .padding()
}
