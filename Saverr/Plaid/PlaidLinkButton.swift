//
//  PlaidLinkButton.swift
//  Saverr
//
//  Button component to initiate Plaid Link
//

import SwiftUI
import WebKit

/// Button that initiates the Plaid Link flow
struct PlaidLinkButton: View {
    let onSuccess: (String) -> Void  // Returns public token
    let onExit: () -> Void
    
    @SwiftUI.Environment(\.plaidManager) private var plaidManager
    @SwiftUI.Environment(\.colorScheme) private var colorScheme
    
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showPlaidWebView = false
    
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
        .sheet(isPresented: $showPlaidWebView) {
            PlaidLinkWebView(
                linkToken: plaidManager.linkToken ?? "",
                onSuccess: { publicToken in
                    showPlaidWebView = false
                    onSuccess(publicToken)
                },
                onExit: {
                    showPlaidWebView = false
                    onExit()
                }
            )
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
            
            print("✅ PlaidLinkButton: Got link token, showing Plaid Link...")
            print("🔗 Link token preview: \(linkToken.prefix(30))...")
            
            await MainActor.run {
                isLoading = false
                // Use WebView to present Plaid Link
                showPlaidWebView = true
            }
        }
    }
}

// MARK: - Plaid Link WebView

/// WebView-based Plaid Link for when the native SDK is not available
struct PlaidLinkWebView: UIViewControllerRepresentable {
    let linkToken: String
    let onSuccess: (String) -> Void
    let onExit: () -> Void
    
    func makeUIViewController(context: Context) -> UINavigationController {
        print("🌐 PlaidLinkWebView: Creating with token: \(linkToken.prefix(30))...")
        let controller = PlaidLinkWebViewController()
        controller.linkToken = linkToken
        controller.onSuccess = onSuccess
        controller.onExit = onExit
        
        let navController = UINavigationController(rootViewController: controller)
        return navController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}


class PlaidLinkWebViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {
    var linkToken: String = ""
    var onSuccess: ((String) -> Void)?
    var onExit: (() -> Void)?
    
    private var webView: WKWebView!
    private var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Link Bank Account"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        view.backgroundColor = .systemBackground
        
        // Add activity indicator
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        
        // Configure WKWebView with message handler for Plaid callbacks
        let contentController = WKUserContentController()
        contentController.add(self, name: "plaidLink")
        
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        
        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.navigationDelegate = self
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.isHidden = true  // Hide until loaded
        view.addSubview(webView)
        
        print("🌐 PlaidLinkWebView: Loading Plaid Link...")
        
        // Load Plaid Link in WebView
        loadPlaidLink()
    }
    
    @objc private func cancelTapped() {
        print("🌐 PlaidLinkWebView: User cancelled")
        onExit?()
    }
    
    private func loadPlaidLink() {
        // Plaid Link URL with token
        let plaidHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <script src="https://cdn.plaid.com/link/v2/stable/link-initialize.js"></script>
            <style>
                body { 
                    margin: 0; 
                    padding: 20px; 
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    background: #f5f5f5;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    min-height: 100vh;
                }
                .loading { text-align: center; color: #666; }
            </style>
        </head>
        <body>
            <div class="loading">
                <p>Loading Plaid Link...</p>
            </div>
            <script>
                const handler = Plaid.create({
                    token: '\(linkToken)',
                    onSuccess: (public_token, metadata) => {
                        window.webkit.messageHandlers.plaidLink.postMessage({
                            type: 'success',
                            publicToken: public_token
                        });
                    },
                    onExit: (err, metadata) => {
                        window.webkit.messageHandlers.plaidLink.postMessage({
                            type: 'exit',
                            error: err ? err.display_message : null
                        });
                    },
                    onEvent: (eventName, metadata) => {
                        console.log('Plaid event:', eventName);
                    }
                });
                
                // Automatically open Plaid Link
                handler.open();
            </script>
        </body>
        </html>
        """
        
        webView.loadHTMLString(plaidHTML, baseURL: URL(string: "https://cdn.plaid.com"))
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("🌐 PlaidLinkWebView: Page loaded successfully")
        activityIndicator.stopAnimating()
        webView.isHidden = false
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ PlaidLinkWebView: Navigation failed - \(error.localizedDescription)")
        activityIndicator.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("❌ PlaidLinkWebView: Provisional navigation failed - \(error.localizedDescription)")
        activityIndicator.stopAnimating()
    }
    
    // MARK: - WKScriptMessageHandler
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let type = body["type"] as? String else { return }
        
        DispatchQueue.main.async { [weak self] in
            if type == "success", let publicToken = body["publicToken"] as? String {
                print("✅ Plaid WebView Success - Public Token: \(publicToken)")
                self?.onSuccess?(publicToken)
            } else if type == "exit" {
                print("ℹ️ Plaid WebView Exit")
                self?.onExit?()
            }
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
