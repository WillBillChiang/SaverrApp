//
//  SettingsView.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.authManager) var authManager

    @State private var showLogoutConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                (colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Card
                        profileCard

                        // Settings Sections
                        settingsSection(title: "Account") {
                            settingsRow(icon: "person.circle", title: "Edit Profile", color: Color.accentPrimary)
                            settingsRow(icon: "bell", title: "Notifications", color: Color.warningColor)
                            settingsRow(icon: "lock.shield", title: "Security", color: Color.successColor)
                        }

                        settingsSection(title: "Preferences") {
                            settingsRow(icon: "moon", title: "Appearance", color: Color(hex: "#DDA0DD"))
                            settingsRow(icon: "dollarsign.circle", title: "Currency", color: Color.accentPrimary)
                            settingsRow(icon: "calendar", title: "Budget Period", color: Color.accentSecondary)
                        }

                        settingsSection(title: "Connected Accounts") {
                            settingsRow(icon: "building.columns", title: "Manage Banks", color: Color(hex: "#45B7D1"))
                            settingsRow(icon: "link", title: "Link New Account", color: Color.successColor)
                        }

                        settingsSection(title: "Support") {
                            settingsRow(icon: "questionmark.circle", title: "Help Center", color: Color(hex: "#87CEEB"))
                            settingsRow(icon: "envelope", title: "Contact Us", color: Color.accentPrimary)
                            settingsRow(icon: "star", title: "Rate the App", color: Color.warningColor)
                        }

                        settingsSection(title: "Legal") {
                            settingsRow(icon: "doc.text", title: "Terms of Service", color: Color.textSecondaryLight)
                            settingsRow(icon: "hand.raised", title: "Privacy Policy", color: Color.textSecondaryLight)
                        }

                        // Logout Button
                        logoutButton

                        // App Version
                        appVersion
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .alert("Log Out", isPresented: $showLogoutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Log Out", role: .destructive) {
                    authManager.logout()
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }

    // MARK: - Subviews

    private var profileCard: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentPrimary, Color(hex: "#45B7D1")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Text(authManager.currentUser?.avatarInitials ?? "U")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }

            VStack(spacing: 4) {
                Text(authManager.currentUser?.name ?? "User")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

                Text(authManager.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
            }

            // Member badge
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.caption)
                Text("Free Member")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.accentPrimary.opacity(0.15))
            .foregroundStyle(Color.accentPrimary)
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .cardStyle()
    }

    private func settingsSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content()
            }
            .cardStyle()
        }
    }

    private func settingsRow(icon: String, title: String, color: Color) -> some View {
        Button {
            // Handle tap
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(title)
                    .font(.body)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }

    private var logoutButton: some View {
        Button {
            showLogoutConfirmation = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Log Out")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(Color.dangerColor)
            .background(Color.dangerColor.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var appVersion: some View {
        VStack(spacing: 4) {
            Text("Saverr")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)

            Text("Version 1.0.0")
                .font(.caption2)
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark.opacity(0.7) : Color.textSecondaryLight.opacity(0.7))
        }
        .padding(.vertical, 20)
    }
}

#Preview {
    SettingsView()
}
