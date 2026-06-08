// ============================================================================
// AuthViewModel.swift
// RouaTrading — ViewModel for authentication flows: passkey registration,
// passkey login, Google OAuth, session validation, logout, and biometric
// unlock.
//
// Delegates all heavy lifting to AuthService.shared and exposes
// @Published properties for SwiftUI views to observe.
// ============================================================================

import Foundation
import SwiftUI
import Combine

// MARK: - Auth ViewModel

/// Manages authentication state and flows for the Roua Trading app.
///
/// This ViewModel acts as a bridge between the `AuthService` singleton and
/// SwiftUI views. It mirrors key auth state as `@Published` properties so
/// that views can reactively update when the authentication state changes.
///
/// Supported authentication methods:
/// - **WebAuthn (Passkeys)** — FIDO2 registration and authentication
/// - **Google OAuth** — via `ASWebAuthenticationSession`
/// - **Biometric unlock** — quick re-authentication using Face ID / Touch ID
///
/// Usage:
/// ```swift
/// @StateObject private var authVM = AuthViewModel()
///
/// // On app launch
/// Task { await authVM.validateSession() }
///
/// // Sign in
/// Task { try await authVM.loginWithPasskey(email: "user@example.com") }
/// ```
@MainActor
final class AuthViewModel: ObservableObject {

    // MARK: - Published State

    /// Whether the user is currently authenticated.
    @Published var isAuthenticated: Bool = false

    /// The currently authenticated user, if any.
    @Published var currentUser: User?

    /// Whether an authentication operation is in progress.
    @Published var isLoading: Bool = false

    /// The most recent error message, if any. Reset at the start of each operation.
    @Published var errorMessage: String?

    /// The email address used for OTP authentication.
    @Published var otpEmail: String = ""

    /// The 6-digit OTP code entered by the user.
    @Published var otpCode: String = ""

    /// Whether the OTP has been sent and we're waiting for verification.
    @Published var isOtpSent: Bool = false

    // MARK: - Dependencies

    private let authService = AuthService.shared
    private let logger = AppLogger.auth

    // MARK: - Cancellation Support

    /// Task handle for the current in-flight operation, allowing cancellation.
    private var currentTask: Task<Void, Never>?

    // MARK: - Initialization

    init() {
        // Seed state from the AuthService singleton
        self.isAuthenticated = authService.isAuthenticated
        self.currentUser = nil // Will be populated by validateSession()

        // Start as loading so the RootView state machine works correctly.
        // If isLoading starts as false, a fast validateSession() that completes
        // in the same run-loop iteration causes SwiftUI to batch the
        // false → true → false transition, so .onChange never fires and
        // the loading screen gets stuck forever.
        self.isLoading = true

        // Observe AuthService published properties to stay in sync
        observeAuthService()
    }

    deinit {
        currentTask?.cancel()
    }

    // MARK: - Session Validation (App Launch)

    /// Validates the current session on app launch.
    ///
    /// Checks if a valid session token exists and, if so, fetches the current
    /// user profile. If the session is expired, attempts an automatic refresh.
    ///
    /// Call this from `App.onAppear` or the root view's `onAppear`.
    func validateSession() {
        currentTask?.cancel()
        currentTask = Task {
            isLoading = true
            errorMessage = nil

            await authService.validateSession()

            // Sync state after validation
            isAuthenticated = authService.isAuthenticated
            if authService.isAuthenticated {
                currentUser = authService.currentUser
            }

            isLoading = false
        }
    }



    // MARK: - Google Sign-In

    /// Opens a browser-based Google OAuth flow via `ASWebAuthenticationSession`.
    ///
    /// The browser redirects back to the app via the `roua://` custom URL
    /// scheme with a session token, which is then stored in the Keychain.
    ///
    /// - Important: This method must be called from the main actor since it
    ///   presents UI (`ASWebAuthenticationSession`).
    func googleSignIn() {
        currentTask?.cancel()
        currentTask = Task {
            isLoading = true
            errorMessage = nil

            do {
                try await authService.signInWithGoogle()
                isAuthenticated = authService.isAuthenticated
                currentUser = authService.currentUser
                logger.info("Google sign-in successful")
            } catch {
                errorMessage = error.localizedDescription
                logger.error("Google sign-in failed: \(error.localizedDescription)")
            }

            isLoading = false
        }
    }

    // MARK: - Passkey Registration

    /// Registers a new user with a WebAuthn passkey.
    ///
    /// Flow:
    /// 1. POST email to `/auth/register` → receive challenge
    /// 2. Create a credential with the platform authenticator
    /// 3. POST verification to `/auth/verify`
    ///
    /// - Parameter email: The user's email address.
    func registerWithPasskey(email: String) {
        currentTask?.cancel()
        currentTask = Task {
            isLoading = true
            errorMessage = nil

            do {
                try await authService.registerWithPasskey(email: email)
                isAuthenticated = authService.isAuthenticated
                currentUser = authService.currentUser
                logger.info("Passkey registration successful for \(email)")
            } catch {
                errorMessage = error.localizedDescription
                logger.error("Passkey registration failed: \(error.localizedDescription)")
            }

            isLoading = false
        }
    }

    // MARK: - Passkey Login

    /// Authenticates an existing user with a WebAuthn passkey.
    ///
    /// Flow:
    /// 1. POST email to `/auth/challenge` → receive challenge
    /// 2. Get an assertion from the platform authenticator
    /// 3. POST verification to `/auth/verify`
    ///
    /// - Parameter email: The user's email address.
    func loginWithPasskey(email: String) {
        currentTask?.cancel()
        currentTask = Task {
            isLoading = true
            errorMessage = nil

            do {
                try await authService.authenticateWithPasskey(email: email)
                isAuthenticated = authService.isAuthenticated
                currentUser = authService.currentUser
                logger.info("Passkey login successful for \(email)")
            } catch {
                errorMessage = error.localizedDescription
                logger.error("Passkey login failed: \(error.localizedDescription)")
            }

            isLoading = false
        }
    }

    // MARK: - OTP Authentication

    /// Sends a verification code (OTP) to the user's email.
    ///
    /// This is the primary authentication method for the mobile app since
    /// WebAuthn endpoints are not exposed through the Next.js proxy.
    ///
    /// - Parameter email: The user's email address.
    func sendOtp(email: String) {
        currentTask?.cancel()
        currentTask = Task {
            isLoading = true
            errorMessage = nil

            do {
                try await authService.sendOtp(email: email)
                otpEmail = email
                isOtpSent = true
                logger.info("OTP sent to \(email)")
            } catch {
                errorMessage = error.localizedDescription
                logger.error("OTP send failed: \(error.localizedDescription)")
            }

            isLoading = false
        }
    }

    /// Verifies the OTP code and completes authentication.
    ///
    /// - Parameter otp: The 6-digit verification code.
    func verifyOtp(otp: String) {
        currentTask?.cancel()
        currentTask = Task {
            isLoading = true
            errorMessage = nil

            do {
                try await authService.verifyOtp(email: otpEmail, otp: otp)
                isAuthenticated = authService.isAuthenticated
                currentUser = authService.currentUser
                isOtpSent = false
                otpCode = ""
                logger.info("OTP login successful")
            } catch {
                errorMessage = error.localizedDescription
                logger.error("OTP verify failed: \(error.localizedDescription)")
            }

            isLoading = false
        }
    }

    // MARK: - Logout

    /// Logs the user out by deleting the session server-side and clearing
    /// all local Keychain data, then navigating to the login screen.
    func logout() {
        currentTask?.cancel()
        currentTask = Task {
            isLoading = true
            errorMessage = nil

            await authService.logout()

            isAuthenticated = false
            currentUser = nil
            isLoading = false

            logger.info("User logged out")
        }
    }



    // MARK: - Biometric Unlock

    /// Attempts to unlock the app using Face ID or Touch ID.
    ///
    /// This checks that a session exists in the Keychain and then prompts
    /// the user for biometric verification. If biometrics are not available
    /// or not enrolled, the unlock silently succeeds (the session token
    /// presence is sufficient).
    ///
    /// - Returns: `true` if biometric authentication succeeded and a session exists.
    func biometricUnlock() async -> Bool {
        errorMessage = nil

        do {
            let success = try await authService.biometricUnlock()
            if success {
                isAuthenticated = authService.isAuthenticated
                currentUser = authService.currentUser
            }
            return success
        } catch {
            errorMessage = error.localizedDescription
            logger.error("Biometric unlock failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Private Helpers

    /// Observes `AuthService.shared` published properties and keeps this
    /// ViewModel's state in sync.
    private func observeAuthService() {
        // Use Combine to observe the AuthService's published state
        authService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthed in
                self?.isAuthenticated = isAuthed
            }
            .store(in: &cancellables)

        authService.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
            }
            .store(in: &cancellables)
    }

    /// Combine cancellables for observing AuthService.
    private var cancellables = Set<AnyCancellable>()
}
