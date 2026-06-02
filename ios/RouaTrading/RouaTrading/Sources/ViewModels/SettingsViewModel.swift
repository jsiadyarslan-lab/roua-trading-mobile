// ============================================================================
// SettingsViewModel.swift
// RouaTrading — Settings and account management ViewModel.
//
// Manages user profile, active sessions, session deletion, and
// notification preferences.
// ============================================================================

import Foundation
import SwiftUI

// MARK: - Settings ViewModel

/// Manages settings and account management for the Roua Trading app.
///
/// Manages:
/// - **User profile** — Current user information
/// - **Active sessions** — Device/browser sessions for security management
/// - **Session deletion** — Revoke individual or all sessions
/// - **Notification preferences** — Configure push, sound, and alert settings
///
/// Usage:
/// ```swift
/// @StateObject private var settingsVM = SettingsViewModel()
///
/// .task { await settingsVM.loadAll() }
/// ```
@MainActor
final class SettingsViewModel: ObservableObject {

    // MARK: - Published State

    /// The currently authenticated user.
    @Published var user: User?

    /// Active sessions across all devices/browsers.
    @Published var sessions: [AuthSession] = []

    /// The user's notification preferences.
    @Published var notificationPrefs: NotificationPreferences?

    /// Whether a loading operation is in progress.
    @Published var isLoading: Bool = false

    /// The most recent error message, if any.
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let apiClient = APIClient.shared
    private let authService = AuthService.shared
    private let cache = CacheManager.shared
    private let logger = AppLogger.general

    // MARK: - Initialization

    init() {
        // Seed user from AuthService
        self.user = authService.currentUser
    }

    // MARK: - Load All

    /// Loads all settings data: sessions and notification preferences.
    func loadAll() {
        Task {
            isLoading = true
            errorMessage = nil

            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.loadSessions() }
                group.addTask { await self.loadNotificationPrefs() }
            }

            isLoading = false
        }
    }

    // MARK: - User Profile

    /// Refreshes the current user profile from the AuthService.
    func refreshUserProfile() {
        self.user = authService.currentUser
    }

    // MARK: - Sessions

    /// Loads all active sessions for the current user.
    func loadSessions() async {
        do {
            let sessions: [AuthSession] = try await apiClient.request(.authSessions)
            self.sessions = sessions
        } catch {
            logger.error("Failed to load sessions: \(error.localizedDescription)")
            errorMessage = "Failed to load sessions."
        }
    }

    /// Deletes a specific session by its ID.
    ///
    /// This revokes access for the associated device/browser. After deletion,
    /// the sessions list is refreshed.
    ///
    /// - Parameter id: The session identifier to delete.
    func deleteSession(id: String) async {
        errorMessage = nil

        do {
            let _: Data = try await apiClient.requestRaw(.authDeleteSessionById(id: id))
            logger.info("Session deleted: \(id)")

            // Optimistically remove from local list
            sessions.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
            logger.error("Failed to delete session \(id): \(error.localizedDescription)")
        }
    }

    /// Deletes all active sessions except the current one.
    ///
    /// After deletion, the sessions list is refreshed.
    func deleteAllSessions() async {
        isLoading = true
        errorMessage = nil

        do {
            let _: Data = try await apiClient.requestRaw(.authDeleteAllSessions)
            logger.info("All sessions deleted")

            // Refresh sessions list
            await loadSessions()
        } catch {
            errorMessage = error.localizedDescription
            logger.error("Failed to delete all sessions: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Notification Preferences

    /// Loads the user's notification preferences.
    func loadNotificationPrefs() async {
        do {
            let prefs: NotificationPreferences = try await cache.valueOrFetch(
                forKey: CacheKeys.notificationsPreferences(),
                ttl: AppConfig.defaultCacheTimeout
            ) {
                try await self.apiClient.request(.notificationsPreferences)
            }
            self.notificationPrefs = prefs
        } catch {
            logger.error("Failed to load notification preferences: \(error.localizedDescription)")
            errorMessage = "Failed to load notification preferences."
        }
    }

    /// Updates the user's notification preferences.
    ///
    /// - Parameter prefs: The updated notification preferences.
    func updateNotificationPrefs(_ prefs: NotificationPreferences) async {
        isLoading = true
        errorMessage = nil

        do {
            let updated: NotificationPreferences = try await apiClient.request(
                .notificationsUpdatePreferences,
                body: prefs
            )
            self.notificationPrefs = updated

            // Update cache
            cache.set(value: updated, forKey: CacheKeys.notificationsPreferences())

            logger.info("Notification preferences updated")
        } catch {
            errorMessage = error.localizedDescription
            logger.error("Failed to update notification preferences: \(error.localizedDescription)")
        }

        isLoading = false
    }
}
