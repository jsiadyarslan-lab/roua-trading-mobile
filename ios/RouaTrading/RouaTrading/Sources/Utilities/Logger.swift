import Foundation
import os

// MARK: - App Logger

/// A centralized logging utility backed by `os.Logger`.
///
/// Provides structured, categorized logging with different severity levels.
/// Debug and info logs are compiled out in release builds for performance.
/// Warning and error logs are always captured.
///
/// Usage:
/// ```swift
/// AppLogger.network.debug("Request started: \(url)")
/// AppLogger.auth.info("User signed in: \(email)")
/// AppLogger.trading.warning("Order partially filled")
/// AppLogger.auth.error("Token refresh failed: \(error)")
/// ```
///
/// - Note: Each category maps to a separate subsystem in Console.app,
///   making it easy to filter logs during development.
enum AppLogger {

    // MARK: - Category Loggers

    /// Logging for network requests and responses.
    static let network = RouaLogger(category: "Network")

    /// Logging for authentication flows.
    static let auth = RouaLogger(category: "Auth")

    /// Logging for trading operations.
    static let trading = RouaLogger(category: "Trading")

    /// Logging for WebSocket connections.
    static let webSocket = RouaLogger(category: "WebSocket")

    /// Logging for security-related operations (Keychain, biometrics).
    static let security = RouaLogger(category: "Security")

    /// Logging for caching operations.
    static let cache = RouaLogger(category: "Cache")

    /// Logging for real-time socket events.
    static let socket = RouaLogger(category: "Socket")

    /// General-purpose logging.
    static let general = RouaLogger(category: "General")

    /// Logging for UI/view-related events.
    static let ui = RouaLogger(category: "UI")
}

// MARK: - Roua Logger

/// A typed logger wrapping `os.Logger` with convenience methods.
///
/// Provides `debug`, `info`, `warning`, and `error` methods that automatically
/// include file, function, and line information for `debug` and `error` levels.
struct RouaLogger {

    /// The underlying `os.Logger` instance.
    private let logger: os.Logger

    /// The category name for this logger.
    let category: String

    /// Creates a logger for the given category.
    ///
    /// - Parameter category: A descriptive category name used for filtering in Console.app.
    init(category: String) {
        let subsystem = Bundle.main.bundleIdentifier ?? "com.roua.trading"
        self.logger = os.Logger(subsystem: subsystem, category: category)
        self.category = category
    }

    // MARK: - Debug

    /// Logs a debug-level message.
    ///
    /// Debug messages are only emitted in DEBUG builds.
    /// They include file, function, and line context.
    ///
    /// - Parameters:
    ///   - message: The message to log.
    ///   - file: Source file (auto-populated).
    ///   - function: Function name (auto-populated).
    ///   - line: Line number (auto-populated).
    @_transparent
    func debug(
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        logger.debug("[\(fileName):\(line)] \(function) — \(message())")
        #endif
    }

    // MARK: - Info

    /// Logs an info-level message.
    ///
    /// Info messages are captured in both debug and release builds,
    /// but may be throttled by the system in release.
    ///
    /// - Parameter message: The message to log.
    @_transparent
    func info(_ message: @autoclosure () -> String) {
        logger.info("ℹ️ \(message())")
    }

    // MARK: - Warning

    /// Logs a warning-level message.
    ///
    /// Warnings are always captured and persisted by the system.
    ///
    /// - Parameter message: The message to log.
    @_transparent
    func warning(_ message: @autoclosure () -> String) {
        logger.warning("⚠️ \(message())")
    }

    // MARK: - Error

    /// Logs an error-level message.
    ///
    /// Errors are always captured, persisted, and may trigger system alerts.
    /// Includes file, function, and line context.
    ///
    /// - Parameters:
    ///   - message: The message to log.
    ///   - file: Source file (auto-populated).
    ///   - function: Function name (auto-populated).
    ///   - line: Line number (auto-populated).
    @_transparent
    func error(
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent
        logger.error("❌ [\(fileName):\(line)] \(function) — \(message())")
    }

    // MARK: - Fault

    /// Logs a fault-level message for critical errors.
    ///
    /// Faults indicate bugs or serious issues that should never occur.
    ///
    /// - Parameter message: The message to log.
    @_transparent
    func fault(_ message: @autoclosure () -> String) {
        logger.fault("🚨 \(message())")
    }
}
