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
            if authManager.isAuthenticated {
                ContentView()
                    .transition(.opacity)
            } else {
                LoginView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
    }
}

#Preview {
    RootView()
}
