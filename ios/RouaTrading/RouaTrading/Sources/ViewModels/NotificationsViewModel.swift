// ============================================================================
// NotificationsViewModel.swift
// RouaTrading — Notifications ViewModel.
//
// Manages in-app and push notifications: loading, unread counts,
// marking as read, and deletion.
// ============================================================================

import Foundation
import SwiftUI

// MARK: - Mark Read Request

/// Payload for marking notifications as read.
private struct MarkReadRequest: Codable {
    let ids: [String]
}

// MARK: - Notifications ViewModel

/// Manages notification state for the Roua Trading app.
///
/// Manages:
/// - **Notification list** — Paginated in-app notifications
/// - **Unread count** — Badge count for the tab bar
/// - **Mark as read** — Individual or bulk read operations
/// - **Delete** — Remove individual notifications
///
/// Usage:
/// ```swift
/// @StateObject private var notifsVM = NotificationsViewModel()
///
/// .task { await notifsVM.loadNotifications() }
/// ```
@MainActor
final class NotificationsViewModel: ObservableObject {

    // MARK: - Published State

    /// The list of notifications.
    @Published var notifications: [RouaNotification] = []

    /// Number of unread notifications (for badge display).
    @Published var unreadCount: Int = 0

    /// Whether a loading operation is in progress.
    @Published var isLoading: Bool = false

    /// The most recent error message, if any.
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let apiClient = APIClient.shared
    private let logger = AppLogger.general

    // MARK: - Load Notifications

    /// Loads notifications from the backend.
    ///
    /// By default, loads the 50 most recent notifications. After loading,
    /// the unread count is also refreshed.
    func loadNotifications() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                let items: [RouaNotification] = try await apiClient.request(
                    .notifications(limit: 50, offset: nil, unread: nil, type: nil)
                )
                self.notifications = items

                // Refresh unread count after loading
                await loadUnreadCount()
            } catch {
                logger.error("Failed to load notifications: \(error.localizedDescription)")
                errorMessage = "Failed to load notifications."
            }

            isLoading = false
        }
    }

    // MARK: - Unread Count

    /// Loads the number of unread notifications.
    func loadUnreadCount() async {
        do {
            let count: UnreadCount = try await apiClient.request(.notificationsUnreadCount)
            self.unreadCount = count.count
        } catch {
            logger.error("Failed to load unread count: \(error.localizedDescription)")
        }
    }

    // MARK: - Mark as Read

    /// Marks specific notifications as read by their IDs.
    ///
    /// After marking, the local notification list and unread count are
    /// updated optimistically.
    ///
    /// - Parameter ids: The notification IDs to mark as read.
    func markAsRead(ids: [String]) async {
        errorMessage = nil

        do {
            let _: Data = try await apiClient.requestRaw(
                .notificationsRead,
                body: MarkReadRequest(ids: ids)
            )
            logger.info("Marked \(ids.count) notifications as read")

            // Optimistically update local state
            let idSet = Set(ids)
            for index in notifications.indices {
                if idSet.contains(notifications[index].id) {
                    notifications[index] = RouaNotification(
                        id: notifications[index].id,
                        type: notifications[index].type,
                        title: notifications[index].title,
                        message: notifications[index].message,
                        data: notifications[index].data,
                        isRead: true,
                        createdAt: notifications[index].createdAt,
                        actionUrl: notifications[index].actionUrl
                    )
                }
            }

            // Refresh unread count
            await loadUnreadCount()
        } catch {
            errorMessage = error.localizedDescription
            logger.error("Failed to mark notifications as read: \(error.localizedDescription)")
        }
    }

    /// Marks all notifications as read.
    func markAllAsRead() async {
        errorMessage = nil

        do {
            let _: Data = try await apiClient.requestRaw(.notificationsReadAll)
            logger.info("All notifications marked as read")

            // Optimistically update all local notifications
            for index in notifications.indices {
                if !notifications[index].isRead {
                    notifications[index] = RouaNotification(
                        id: notifications[index].id,
                        type: notifications[index].type,
                        title: notifications[index].title,
                        message: notifications[index].message,
                        data: notifications[index].data,
                        isRead: true,
                        createdAt: notifications[index].createdAt,
                        actionUrl: notifications[index].actionUrl
                    )
                }
            }

            // Reset unread count
            self.unreadCount = 0
        } catch {
            errorMessage = error.localizedDescription
            logger.error("Failed to mark all notifications as read: \(error.localizedDescription)")
        }
    }

    // MARK: - Delete

    /// Deletes a specific notification by its ID.
    ///
    /// - Parameter id: The notification identifier to delete.
    func deleteNotification(id: String) async {
        errorMessage = nil

        do {
            let _: Data = try await apiClient.requestRaw(.notificationDelete(id: id))
            logger.info("Notification deleted: \(id)")

            // Optimistically remove from local list
            let wasUnread = notifications.first(where: { $0.id == id })?.isRead == false
            notifications.removeAll { $0.id == id }

            // Update unread count if the deleted notification was unread
            if wasUnread {
                unreadCount = max(0, unreadCount - 1)
            }
        } catch {
            errorMessage = error.localizedDescription
            logger.error("Failed to delete notification \(id): \(error.localizedDescription)")
        }
    }
}
