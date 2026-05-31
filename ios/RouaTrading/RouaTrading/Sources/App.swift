import SwiftUI

// MARK: - App Entry Point
@main
struct RouaTradingApp: App {
    @ObservedObject private var authService = AuthService.shared
    @AppStorage("appLanguage") private var appLanguage = "ar"

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    TabBarView()
                } else {
                    AuthView()
                }
            }
            .tint(RouaTheme.Colors.accent)
            .preferredColorScheme(.dark)
            .environment(\.layoutDirection, appLanguage == "ar" ? .rightToLeft : .leftToRight)
            .environment(\.locale, Locale(identifier: appLanguage))
            .onAppear { authService.checkExistingSession() }
        }
    }
}
