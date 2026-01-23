//
//  SaverrApp.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import SwiftUI
import SwiftData
import LinkKit

@main
struct SaverrApp: App {
    @State private var authManager = AuthenticationManager()
    @State private var plaidManager = PlaidManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            BankAccount.self,
            Transaction.self,
            FinancialGoal.self,
            ChatMessage.self,
            Category.self,
            FinancialPlan.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.services, ServiceContainer.shared)
                .environment(\.authManager, authManager)
                .environment(\.plaidManager, plaidManager)
                .onOpenURL { url in
                    // Handle Plaid OAuth redirect
                    print("🔗 App received OAuth redirect URL: \(url)")
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
