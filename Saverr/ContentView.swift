//
//  ContentView.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .accounts
    @Environment(\.colorScheme) var colorScheme

    enum Tab: String, CaseIterable {
        case accounts = "Accounts"
        case insights = "Insights"
        case chat = "AI Chat"
        case plan = "My Plan"
        case settings = "Settings"

        var iconName: String {
            switch self {
            case .accounts: return "building.columns"
            case .insights: return "chart.pie"
            case .chat: return "bubble.left.and.bubble.right"
            case .plan: return "target"
            case .settings: return "gearshape"
            }
        }

        var selectedIconName: String {
            switch self {
            case .accounts: return "building.columns.fill"
            case .insights: return "chart.pie.fill"
            case .chat: return "bubble.left.and.bubble.right.fill"
            case .plan: return "target"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            AccountsView()
                .tabItem {
                    Label(Tab.accounts.rawValue, systemImage: selectedTab == .accounts ? Tab.accounts.selectedIconName : Tab.accounts.iconName)
                }
                .tag(Tab.accounts)

            ChartsView()
                .tabItem {
                    Label(Tab.insights.rawValue, systemImage: selectedTab == .insights ? Tab.insights.selectedIconName : Tab.insights.iconName)
                }
                .tag(Tab.insights)

            AIChatView()
                .tabItem {
                    Label(Tab.chat.rawValue, systemImage: selectedTab == .chat ? Tab.chat.selectedIconName : Tab.chat.iconName)
                }
                .tag(Tab.chat)

            FinancialPlanView()
                .tabItem {
                    Label(Tab.plan.rawValue, systemImage: selectedTab == .plan ? Tab.plan.selectedIconName : Tab.plan.iconName)
                }
                .tag(Tab.plan)

            SettingsView()
                .tabItem {
                    Label(Tab.settings.rawValue, systemImage: selectedTab == .settings ? Tab.settings.selectedIconName : Tab.settings.iconName)
                }
                .tag(Tab.settings)
        }
        .tint(Color.accentPrimary)
    }
}

#Preview {
    ContentView()
        .environment(\.services, ServiceContainer.shared)
        .environment(\.authManager, AuthenticationManager())
}
