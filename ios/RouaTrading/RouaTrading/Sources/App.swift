// =============================================================================
// App.swift — Roua Trading · Application Entry Point
// =============================================================================
// Root application definition. Injects AuthViewModel into the environment,
// enforces dark color scheme, and presents RootView as the initial scene.
// =============================================================================

import SwiftUI

@main
struct RouaTradingApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .preferredColorScheme(.dark)
        }
    }
}
