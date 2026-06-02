// ============================================================================
// NotificationModels.swift
// RouaTrading — Push / in-app notification models and preferences.
// ============================================================================

import Foundation

// MARK: - Notification Type

/// Category of a notification.
enum NotificationType: String, Codable {
    case trade  = "TRADE"
    case signal = "SIGNAL"
    case ai     = "AI"
    case risk   = "RISK"
    case system = "SYSTEM"
    case news   = "NEWS"

    var displayName: String {
        switch self {
        case .trade:  return "Trade"
        case .signal: return "Signal"
        case .ai:     return "AI"
        case .risk:   return "Risk"
        case .system: return "System"
        case .news:   return "News"
        }
    }

    /// SF Symbol name for icon rendering.
    var iconName: String {
        switch self {
        case .trade:  return "arrow.left.arrow.right"
        case .signal: return "antenna.radiowaves.left.and.right"
        case .ai:     return "brain"
        case .risk:   return "exclamationmark.triangle"
        case .system: return "gearshape"
        case .news:   return "newspaper"
        }
    }
}

// MARK: - Roua Notification

/// A single in-app or push notification.
struct RouaNotification: Codable, Identifiable, Hashable {
    let id: String
    let type: NotificationType
    let title: String
    let message: String
    /// Optional structured payload (key-value).
    let data: [String: String]?
    let isRead: Bool
    let createdAt: String
    let actionUrl: String?

    // ---- Computed helpers ----

    /// Whether tapping this notification should navigate somewhere.
    var isActionable: Bool { actionUrl != nil }

    /// Time-ago label (placeholder – use a DateFormatter for real values).
    var timeAgo: String {
        // In production, parse `createdAt` with ISO8601DateFormatter
        // and compute a relative string.  This is a placeholder.
        return createdAt
    }
}

// MARK: - Notification Preferences

/// User-configurable notification settings.
struct NotificationPreferences: Codable {
    let enabled: Bool
    let pushEnabled: Bool
    let soundEnabled: Bool
    let browserEnabled: Bool
    let telegramEnabled: Bool
    let signalAlerts: Bool
    let tradeAlerts: Bool
    let aiAlerts: Bool
    let scannerAlerts: Bool
    let riskAlerts: Bool
    let systemAlerts: Bool
    let autoExecuteEnabled: Bool
    let autoExecuteMinConfidence: Int?
    let autoExecuteMaxPositionSize: Double?

    /// Number of alert categories enabled.
    var enabledAlertCount: Int {
        [signalAlerts, tradeAlerts, aiAlerts, scannerAlerts, riskAlerts, systemAlerts]
            .filter { $0 }
            .count
    }

    /// Whether auto-execute has a minimum confidence threshold set.
    var hasAutoExecuteThreshold: Bool { autoExecuteMinConfidence != nil }
}

// MARK: - Unread Count

/// Simple wrapper for the number of unread notifications.
struct UnreadCount: Codable {
    let count: Int

    /// Whether there are any unread notifications.
    var hasUnread: Bool { count > 0 }
}
