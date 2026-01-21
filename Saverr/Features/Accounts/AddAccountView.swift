//
//  AddAccountView.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import SwiftUI

struct AddAccountView: View {
    let onAccountLinked: (BankAccount) -> Void

    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.services) var services

    @State private var searchText = ""
    @State private var selectedInstitution: Institution?
    @State private var isLinking = false
    @State private var linkingStep: LinkingStep = .selectInstitution

    enum LinkingStep {
        case selectInstitution
        case enterCredentials
        case linking
        case success
    }

    struct Institution: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let color: Color
    }

    let institutions: [Institution] = [
        Institution(name: "Chase", icon: "building.columns", color: .blue),
        Institution(name: "Bank of America", icon: "building.columns.fill", color: .red),
        Institution(name: "Wells Fargo", icon: "building.2", color: .yellow),
        Institution(name: "Citi", icon: "building.columns", color: .blue),
        Institution(name: "Capital One", icon: "creditcard", color: .red),
        Institution(name: "American Express", icon: "creditcard.fill", color: .blue),
        Institution(name: "Discover", icon: "creditcard", color: .orange),
        Institution(name: "US Bank", icon: "building.columns", color: .blue),
        Institution(name: "PNC", icon: "building", color: .orange),
        Institution(name: "Fidelity", icon: "chart.line.uptrend.xyaxis", color: .green),
        Institution(name: "Charles Schwab", icon: "chart.bar", color: .blue),
        Institution(name: "Vanguard", icon: "chart.pie", color: .red)
    ]

    var filteredInstitutions: [Institution] {
        if searchText.isEmpty {
            return institutions
        }
        return institutions.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                (colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
                    .ignoresSafeArea()

                switch linkingStep {
                case .selectInstitution:
                    institutionSelectionView
                case .enterCredentials:
                    credentialsView
                case .linking:
                    linkingProgressView
                case .success:
                    successView
                }
            }
            .navigationTitle("Link Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Step Views

    private var institutionSelectionView: some View {
        VStack(spacing: 16) {
            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)

                TextField("Search banks and institutions", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding()
            .background(colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackgroundLight)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            // Institutions grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(filteredInstitutions) { institution in
                        institutionCard(institution)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.top)
    }

    private func institutionCard(_ institution: Institution) -> some View {
        Button {
            selectedInstitution = institution
            withAnimation {
                linkingStep = .enterCredentials
            }
        } label: {
            VStack(spacing: 12) {
                Image(systemName: institution.icon)
                    .font(.title)
                    .foregroundStyle(institution.color)
                    .frame(width: 50, height: 50)
                    .background(institution.color.opacity(0.12))
                    .clipShape(Circle())

                Text(institution.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    private var credentialsView: some View {
        VStack(spacing: 24) {
            // Institution header
            if let institution = selectedInstitution {
                VStack(spacing: 12) {
                    Image(systemName: institution.icon)
                        .font(.largeTitle)
                        .foregroundStyle(institution.color)
                        .frame(width: 70, height: 70)
                        .background(institution.color.opacity(0.12))
                        .clipShape(Circle())

                    Text(institution.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)
                }
                .padding(.top, 20)
            }

            // Mock credentials form
            VStack(spacing: 16) {
                Text("This is a demo. In production, this would connect to Plaid or a similar service for secure bank authentication.")
                    .font(.caption)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.warningColor.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 12) {
                PrimaryButton("Link Account", icon: "link") {
                    withAnimation {
                        linkingStep = .linking
                    }
                    linkAccount()
                }

                SecondaryButton("Back") {
                    withAnimation {
                        linkingStep = .selectInstitution
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }

    private var linkingProgressView: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView()
                .scaleEffect(1.5)

            Text("Connecting to \(selectedInstitution?.name ?? "your bank")...")
                .font(.headline)
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

            Text("This may take a moment")
                .font(.subheadline)
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)

            Spacer()
        }
    }

    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.successColor)

            Text("Account Linked!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimaryLight)

            Text("Your \(selectedInstitution?.name ?? "") account has been successfully linked.")
                .font(.subheadline)
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondaryLight)
                .multilineTextAlignment(.center)

            Spacer()

            PrimaryButton("Done", icon: "checkmark") {
                dismiss()
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Actions

    private func linkAccount() {
        Task {
            do {
                let account = try await services.bankingService.linkAccount(
                    institutionId: selectedInstitution?.name ?? "Unknown",
                    credentials: [:]
                )
                onAccountLinked(account)
                withAnimation {
                    linkingStep = .success
                }
            } catch {
                print("Failed to link account: \(error)")
            }
        }
    }
}

#Preview {
    AddAccountView { _ in }
}
