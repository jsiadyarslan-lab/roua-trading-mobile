// =============================================================================
// RootView.swift — Roua Trading · Root View
// =============================================================================
// Top-level view that switches between the authentication flow and the
// main tabbed app based on AuthViewModel.isAuthenticated. Shows a loading
// state while the session is being validated on launch.
// =============================================================================

import SwiftUI

struct RootView: View {

    @EnvironmentObject private var authViewModel: AuthViewModel

    // MARK: - Animation State

    @State private var showMainApp = false
    @State private var hasValidated = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // Always render the background
            Color.rouaBackground
                .ignoresSafeArea()

            if !hasValidated {
                // ── Session Validation ──
                LoadingView(message: "جاري التحقق من الجلسة…")
                    .transition(.opacity)

            } else if authViewModel.isAuthenticated {
                // ── Authenticated → Main App ──
                TabBarView()
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
        .onAppear {
            authViewModel.validateSession()
        }
        .onChange(of: authViewModel.isLoading) { _, isLoading in
            // When loading completes for the first time, mark as validated
            if !isLoading && !hasValidated {
                withAnimation(.easeOut(duration: RouaSpacing.animationDuration)) {
                    hasValidated = true
                }
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                Task {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showMainApp = true
                    }
                }
            } else {
                showMainApp = false
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
