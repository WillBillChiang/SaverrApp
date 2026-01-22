//
//  RootView.swift
//  Saverr
//
//  Created by William Chiang on 1/21/26.
//

import SwiftUI

struct RootView: View {
    @Environment(\.authManager) var authManager

    var body: some View {
        Group {
            switch authManager.authState {
            case .authenticated:
                ContentView()
                    .transition(.opacity)
            case .authenticating:
                // Show loading while checking session
                loadingView
                    .transition(.opacity)
            case .unauthenticated, .needsVerification, .needsPasswordReset:
                LoginView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.authState)
    }
    
    private var loadingView: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // App Icon
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
                    
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                }
                
                ProgressView()
                    .tint(.white)
                
                Text("Loading...")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }
}

#Preview {
    RootView()
}
