// =============================================================================
// RootView.swift — Roua Trading · Root View
// =============================================================================
// Top-level view that shows the main tabbed app immediately, allowing
// unauthenticated users to browse public market data (scanner, exchange,
// news). Authenticated features (portfolio, trading, signals) show a
// sign-in prompt when the user is not logged in.
//
// FIX: Previously, the entire app was blocked behind authentication.
// Market data endpoints are PUBLIC and don't require login. The app now
// shows the main TabBarView immediately, with a sign-in banner for
// unauthenticated users.
// =============================================================================

import SwiftUI

struct RootView: View {

    @EnvironmentObject private var authViewModel: AuthViewModel

    // MARK: - Socket Manager

    /// Manages real-time connections to the backend (WebSocket + polling).
    @StateObject private var socketManager = SocketManager()

    // MARK: - Auth Sheet State

    /// Whether the authentication sheet is presented.
    @State private var showAuthSheet = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // Always render the background
            Color.rouaBackground
                .ignoresSafeArea()

            // ── Main App (always visible) ──
            TabBarView(socketManager: socketManager)
                .overlay(alignment: .top) {
                    // Show sign-in banner when not authenticated
                    if !authViewModel.isAuthenticated {
                        signInBanner
                            .padding(.horizontal, RouaSpacing.screenPadding)
                            .padding(.top, 4)
                    }
                }
        }
        .sheet(isPresented: $showAuthSheet) {
            AuthView()
        }
        .onAppear {
            // Validate session in the background — don't block the UI
            authViewModel.validateSession()
        }
        .onChange(of: authViewModel.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                // Connect real-time channels when authenticated
                socketManager.connect()
                showAuthSheet = false
            } else {
                // Disconnect real-time channels when signed out
                socketManager.disconnect()
            }
        }
    }

    // MARK: - Sign-In Banner

    /// A subtle banner that encourages the user to sign in for full access.
    private var signInBanner: some View {
        Button {
            showAuthSheet = true
        } label: {
            HStack(spacing: RouaSpacing.sm) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.rouaPrimary)

                Text("سجّل الدخول للوصول الكامل")
                    .rouaFont(.captionBold, color: .rouaTextPrimary)

                Spacer()

                Text("دخول")
                    .rouaFont(.captionBold, color: .rouaPrimary)

                Image(systemName: "chevron.left")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.rouaPrimary)
            }
            .padding(.horizontal, RouaSpacing.md)
            .padding(.vertical, RouaSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                    .fill(Color.rouaPrimary.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                    .stroke(Color.rouaPrimary.opacity(0.2), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("تسجيل الدخول")
        .accessibilityHint("اضغط لتسجيل الدخول والوصول إلى محفظتك وصفقاتك")
    }
}

// MARK: - Preview

#Preview("RootView") {
    RootView()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.dark)
}
