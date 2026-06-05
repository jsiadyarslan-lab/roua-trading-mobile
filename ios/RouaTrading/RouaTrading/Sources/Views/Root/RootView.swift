// =============================================================================
// RootView.swift — Roua Trading · Root View
// =============================================================================
// Top-level view that switches between the authentication flow and the
// main tabbed app based on AuthViewModel.isAuthenticated. Shows a loading
// state while the session is being validated on launch.
//
// FIX: Added timeout fallback and error handling to prevent the app from
// getting stuck on the loading screen when:
//   1. SwiftUI batches the isLoading false→true→false transition (race condition)
//   2. Network requests hang due to unreachable server or stale tokens
//   3. Any unexpected error prevents validation from completing
// =============================================================================

import SwiftUI

struct RootView: View {

    @EnvironmentObject private var authViewModel: AuthViewModel

    // MARK: - Socket Manager

    /// Manages real-time connections to the backend (WebSocket + polling).
    @StateObject private var socketManager = SocketManager()

    // MARK: - Animation State

    @State private var showMainApp = false
    @State private var hasValidated = false

    // MARK: - Error State

    /// Set to true when validation fails or times out, allowing the user to retry.
    @State private var validationFailed = false

    /// Maximum seconds to wait for session validation before showing the login screen.
    private let validationTimeoutSeconds: TimeInterval = 10

    // MARK: - Body

    var body: some View {
        ZStack {
            // Always render the background
            Color.rouaBackground
                .ignoresSafeArea()

            if !hasValidated && !validationFailed {
                // ── Session Validation ──
                LoadingView(message: "جاري التحقق من الجلسة…")
                    .transition(.opacity)

            } else if validationFailed && !hasValidated {
                // ── Validation Failed / Timed Out → Show Auth with retry hint ──
                AuthView()
                    .transition(.opacity)

            } else if authViewModel.isAuthenticated {
                // ── Authenticated → Main App ──
                TabBarView(socketManager: socketManager)
                    .opacity(showMainApp ? 1 : 0)
                    .offset(y: showMainApp ? 0 : 20)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))

            } else {
                // ── Not Authenticated → Auth Screen ──
                AuthView()
                    .transition(.opacity)
            }
        }
        .animation(
            .spring(response: RouaSpacing.animationSlow, dampingFraction: 0.85),
            value: authViewModel.isAuthenticated
        )
        .animation(
            .easeOut(duration: RouaSpacing.animationDuration),
            value: hasValidated
        )
        .animation(
            .easeOut(duration: RouaSpacing.animationDuration),
            value: validationFailed
        )
        .onAppear {
            authViewModel.validateSession()
            startValidationTimeout()
        }
        .onChange(of: authViewModel.isLoading) { _, isLoading in
            // When loading completes for the first time, mark as validated
            if !isLoading && !hasValidated {
                withAnimation(.easeOut(duration: RouaSpacing.animationDuration)) {
                    hasValidated = true
                    validationFailed = false
                }
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                // Connect real-time channels when authenticated
                socketManager.connect()
                Task {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showMainApp = true
                    }
                }
            } else {
                // Disconnect real-time channels when signed out
                socketManager.disconnect()
                showMainApp = false
            }
        }
    }

    // MARK: - Timeout Safety Net

    /// Starts a fallback timer. If validation hasn't completed within
    /// `validationTimeoutSeconds`, force the app to show the auth screen
    /// so the user isn't stuck on the loading spinner forever.
    private func startValidationTimeout() {
        Task {
            try? await Task.sleep(nanoseconds: UInt64(validationTimeoutSeconds * 1_000_000_000))
            guard !hasValidated else { return }

            AppLogger.auth.warning("Session validation timed out after \(Int(validationTimeoutSeconds))s — showing auth screen")

            withAnimation(.easeOut(duration: RouaSpacing.animationDuration)) {
                validationFailed = true
            }
        }
    }
}

// MARK: - Preview

#Preview("RootView") {
    RootView()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.dark)
}
