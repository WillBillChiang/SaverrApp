//
//  PlaidLinkButton.swift
//  Saverr
//
//  Button component to initiate Plaid Link using native SDK
//

import SwiftUI
import LinkKit

/// Button that initiates the Plaid Link flow using the native SDK
struct PlaidLinkButton: View {
    let onSuccess: (String) -> Void  // Returns public token
    let onExit: () -> Void
    
    @SwiftUI.Environment(\.plaidManager) private var plaidManager
    @SwiftUI.Environment(\.colorScheme) private var colorScheme
    
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var linkHandler: Handler?  // Keep handler alive while Plaid Link is open
    
    var body: some View {
        Button {
            initiateLink()
        } label: {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "link.badge.plus")
                        .font(.title3)
                }
                
                Text(isLoading ? "Preparing..." : "Link Bank Account")
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.accentPrimary)
            .cornerRadius(12)
        }
        .disabled(isLoading)
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func initiateLink() {
        isLoading = true
        print("🔗 PlaidLinkButton: Starting link process...")
        
        Task {
            await plaidManager.initializePlaidLink()
            
            guard let linkToken = plaidManager.linkToken else {
                print("❌ PlaidLinkButton: No link token received")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to get link token. Please check your connection and try again."
                    showError = true
                }
                return
            }
            
            print("✅ PlaidLinkButton: Got link token, presenting native Plaid Link...")
            print("🔗 Link token preview: \(linkToken.prefix(30))...")
            
            await MainActor.run {
                presentPlaidLink(with: linkToken)
            }
        }
    }
    
    private func presentPlaidLink(with linkToken: String) {
        // Create Link token configuration
        var linkConfiguration = LinkTokenConfiguration(
            token: linkToken,
            onSuccess: { linkSuccess in
                print("✅ Plaid Link Success!")
                print("   Public Token: \(linkSuccess.publicToken.prefix(30))...")
                print("   Accounts: \(linkSuccess.metadata.accounts.count)")
                
                isLoading = false
                self.linkHandler = nil  // Release handler
                onSuccess(linkSuccess.publicToken)
            }
        )
        
        linkConfiguration.onExit = { linkExit in
            isLoading = false
            self.linkHandler = nil  // Release handler
            
            if let error = linkExit.error {
                print("❌ Plaid Link Error: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                showError = true
            } else {
                print("ℹ️ Plaid Link Exited by user")
                onExit()
            }
        }
        
        linkConfiguration.onEvent = { linkEvent in
            print("📊 Plaid Link Event: \(linkEvent.eventName)")
        }
        
        // Create the Plaid Link handler
        let result = Plaid.create(linkConfiguration)
        
        switch result {
        case .success(let handler):
            print("✅ Plaid handler created successfully")
            
            // Store handler to keep it alive while Plaid Link is open
            self.linkHandler = handler
            
            // Get the top view controller to present from
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                print("❌ Could not find root view controller")
                isLoading = false
                self.linkHandler = nil
                errorMessage = "Could not present Plaid Link"
                showError = true
                return
            }
            
            // Find the topmost presented view controller
            var topController = rootViewController
            while let presented = topController.presentedViewController {
                topController = presented
            }
            
            // Present Plaid Link
            handler.open(presentUsing: .viewController(topController))
            print("✅ Plaid Link presented")
            
            // Reset loading state after presenting (Plaid is now handling the UI)
            isLoading = false
            
        case .failure(let error):
            print("❌ Failed to create Plaid handler: \(error)")
            isLoading = false
            errorMessage = "Failed to initialize Plaid Link: \(error.localizedDescription)"
            showError = true
        }
    }
}

#Preview {
    PlaidLinkButton(
        onSuccess: { token in print("Token: \(token)") },
        onExit: { print("Exited") }
    )
    .padding()
    .environment(\.plaidManager, PlaidManager())
}
