import Foundation

/// Centralized application configuration.
///
/// Contains all static configuration values used throughout the app including
/// API endpoints, WebSocket URLs, authentication keys, cache timeouts, and feature flags.
///
/// - Note: Environment-specific overrides can be added by reading from `Info.plist` or
///   environment variables in a future iteration.
enum AppConfig {
    // MARK: - API

    /// Base URL for all REST API requests.
    static let apiBaseURL = URL(string: "https://roua-trading.com/api")!

    /// Base URL for web-based flows (OAuth, legal pages, etc.).
    static let webBaseURL = "https://roua-trading.com"

    /// Base URL for the backend Socket.IO / WebSocket server.
    static let socketURL = URL(string: "https://roua-trading.com")!

    // MARK: - WebSocket

    /// Binance combined stream WebSocket URL.
    static let binanceWSURL = "wss://stream.binance.com:9443/stream"

    // MARK: - Auth

    /// Keychain key for the session token (`roua_session` cookie value).
    static let sessionTokenKey = "roua_session_token"

    /// Keychain key for the refresh token (`roua_refresh` cookie value).
    static let refreshTokenKey = "roua_refresh_token"

    /// URL scheme used for OAuth redirect callbacks.
    static let authCallbackScheme = "roua"

    /// Path appended to `webBaseURL` to initiate Google OAuth sign-in.
    static let googleOAuthPath = "/auth/signin/google?app_redirect_uri=roua://auth/callback"

    // MARK: - Cache

    /// Default cache time-to-live in seconds (5 minutes).
    static let defaultCacheTimeout: TimeInterval = 300

    /// Cache TTL for fast-changing market data in seconds (1 minute).
    static let marketDataCacheTimeout: TimeInterval = 60

    // MARK: - Timeouts

    /// Standard request timeout in seconds.
    static let requestTimeout: TimeInterval = 30

    /// Resource timeout (entire request lifecycle) in seconds.
    static let resourceTimeout: TimeInterval = 60

    // MARK: - App Info

    /// Short version string read from the bundle, defaults to "2.1.0".
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.1.0"

    /// Build number read from the bundle, defaults to "1".
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    // MARK: - Feature Flags

    /// Whether biometric authentication is enabled.
    static let enableBiometrics = true

    /// Whether push notifications are enabled.
    static let enablePushNotifications = true

    /// Whether the Neural Lab feature is visible.
    static let enableNeuralLab = true

    /// Whether the Prediction Market feature is visible.
    static let enablePredictionMarket = true
}
