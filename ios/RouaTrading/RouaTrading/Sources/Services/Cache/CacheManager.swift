import Foundation

// MARK: - Cache Entry

/// A single cache entry with an expiration timestamp.
private struct CacheEntry<T> {
    let value: T
    let expiresAt: Date

    /// Whether this entry has expired.
    var isExpired: Bool {
        Date() > expiresAt
    }
}

// MARK: - Cache Manager

/// Thread-safe in-memory cache with time-to-live (TTL) support.
///
/// Stores `Codable` values keyed by a string identifier, each with an
/// expiration date. Expired entries are lazily cleaned up on access or
/// proactively via `cleanupExpired()`.
///
/// Usage:
/// ```swift
/// let cache = CacheManager.shared
///
/// // Store with 5-minute TTL
/// cache.set(value: scannerResult, forKey: "scanner:overview", ttl: 300)
///
/// // Retrieve
/// if let result: ScannerOverview = cache.value(forKey: "scanner:overview") {
///     // Use cached result
/// }
/// ```
///
/// - Note: This is an in-memory cache; all data is lost when the app terminates.
///   For persistent caching, use `UserDefaults` or a database.
@MainActor
final class CacheManager {

    // MARK: - Singleton

    static let shared = CacheManager()

    // MARK: - Properties

    /// The underlying storage. Keyed by a domain prefix to avoid collisions.
    private var storage: [String: Any] = [:]

    /// Default TTL in seconds (5 minutes).
    private let defaultTTL: TimeInterval = AppConfig.defaultCacheTimeout

    /// Interval for automatic cleanup.
    private let cleanupInterval: TimeInterval = 60.0

    /// Timer for periodic cleanup.
    private var cleanupTimer: Timer?

    private let logger = AppLogger.cache

    // MARK: - Initialization

    private init() {
        startCleanupTimer()
    }

    deinit {
        cleanupTimer?.invalidate()
    }

    // MARK: - Set

    /// Stores a value in the cache with a specified TTL.
    ///
    /// - Parameters:
    ///   - value: The value to cache.
    ///   - key: A unique key for the entry.
    ///   - ttl: Time-to-live in seconds. Defaults to `AppConfig.defaultCacheTimeout`.
    func set<T: Codable>(value: T, forKey key: String, ttl: TimeInterval? = nil) {
        let effectiveTTL = ttl ?? defaultTTL
        let entry = CacheEntry(value: value, expiresAt: Date().addingTimeInterval(effectiveTTL))
        storage[key] = entry
    }

    /// Stores a value in the cache with market-data-appropriate TTL.
    ///
    /// Uses `AppConfig.marketDataCacheTimeout` (1 minute).
    func setMarketData<T: Codable>(value: T, forKey key: String) {
        set(value: value, forKey: key, ttl: AppConfig.marketDataCacheTimeout)
    }

    // MARK: - Get

    /// Retrieves a cached value if it exists and hasn't expired.
    ///
    /// - Parameter key: The cache key.
    /// - Returns: The cached value, or `nil` if not found or expired.
    func value<T: Codable>(forKey key: String) -> T? {
        guard let entry = storage[key] as? CacheEntry<T> else {
            return nil
        }

        if entry.isExpired {
            storage.removeValue(forKey: key)
            return nil
        }

        return entry.value
    }

    /// Retrieves a cached value, executing the fetch closure if the value
    /// is missing or expired, and storing the result.
    ///
    /// - Parameters:
    ///   - key: The cache key.
    ///   - ttl: Time-to-live in seconds.
    ///   - fetch: An async closure that produces the value if not cached.
    /// - Returns: The cached or freshly fetched value.
    func valueOrFetch<T: Codable>(
        forKey key: String,
        ttl: TimeInterval? = nil,
        fetch: @Sendable () async throws -> T
    ) async throws -> T {
        if let cached: T = value(forKey: key) {
            return cached
        }

        let fresh = try await fetch()
        set(value: fresh, forKey: key, ttl: ttl)
        return fresh
    }

    // MARK: - Remove

    /// Removes a specific entry from the cache.
    func remove(forKey key: String) {
        storage.removeValue(forKey: key)
    }

    /// Removes all entries matching the given key prefix.
    func removeWithPrefix(_ prefix: String) {
        let keysToRemove = storage.keys.filter { $0.hasPrefix(prefix) }
        for key in keysToRemove {
            storage.removeValue(forKey: key)
        }
    }

    /// Clears the entire cache.
    func clearAll() {
        storage.removeAll()
        logger.info("Cache cleared")
    }

    // MARK: - Inspection

    /// Whether the cache contains a non-expired entry for the given key.
    ///
    /// Uses type-erased checking since stored entries are `CacheEntry<T>` for
    /// various concrete `T` types, and Swift's generic invariance prevents
    /// casting `CacheEntry<SomeType>` to `CacheEntry<Any>`.
    func contains(forKey key: String) -> Bool {
        guard let entry = storage[key] else {
            return false
        }
        // Use Mirror to inspect the `isExpired` property without knowing the
        // concrete generic type at compile time.
        let mirror = Mirror(reflecting: entry)
        for child in mirror.children {
            if child.label == "isExpired", let isExpired = child.value as? Bool {
                return !isExpired
            }
        }
        // If we can't read isExpired, assume the entry exists and is valid
        return true
    }

    /// The total number of entries in the cache (including expired).
    var count: Int {
        storage.count
    }

    /// All keys currently in the cache.
    var allKeys: [String] {
        Array(storage.keys)
    }

    // MARK: - Cleanup

    /// Removes all expired entries from the cache.
    ///
    /// Uses Mirror reflection to read the `isExpired` property from each
    /// `CacheEntry<T>` regardless of the concrete generic type `T`.
    func cleanupExpired() {
        var removedCount = 0

        for (key, entry) in storage {
            let mirror = Mirror(reflecting: entry)
            for child in mirror.children {
                if child.label == "isExpired", let isExpired = child.value as? Bool, isExpired {
                    storage.removeValue(forKey: key)
                    removedCount += 1
                    break
                }
            }
        }

        if removedCount > 0 {
            logger.debug("Cleaned up \(removedCount) expired cache entries")
        }
    }

    // MARK: - Private

    /// Starts a periodic timer that removes expired entries.
    private func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(
            withTimeInterval: cleanupInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.cleanupExpired()
            }
        }
    }
}

// MARK: - Cache Key Namespacing

/// Convenience helpers for generating namespaced cache keys.
enum CacheKeys {
    // Scanner
    static func scannerOverview() -> String { "scanner:overview" }
    static func scannerScan(timeframe: String, category: String?) -> String {
        "scanner:scan:\(timeframe):\(category ?? "all")"
    }
    static func scannerAnalysis(symbol: String) -> String {
        "scanner:analysis:\(symbol)"
    }
    static func scannerHeatmap(category: String?) -> String {
        "scanner:heatmap:\(category ?? "all")"
    }

    // Exchange
    static func exchangeQuote(symbol: String) -> String {
        "exchange:quote:\(symbol)"
    }
    static func exchangeHistory(symbol: String, interval: String) -> String {
        "exchange:history:\(symbol):\(interval)"
    }

    // AI
    static func aiConsensus() -> String { "ai:consensus" }
    static func aiModels() -> String { "ai:models" }

    // Council
    static func councilBriefs() -> String { "council:briefs" }
    static func councilActiveBriefs(symbol: String?) -> String {
        "council:active:\(symbol ?? "all")"
    }

    // Executor
    static func executorStatus() -> String { "executor:status" }
    static func executorPositions() -> String { "executor:positions" }

    // Agent
    static func agentStatus() -> String { "agent:status" }
    static func agentPerformance() -> String { "agent:performance" }

    // News
    static func newsLatest(symbol: String?) -> String {
        "news:latest:\(symbol ?? "all")"
    }
    static func newsSentiment() -> String { "news:sentiment" }

    // Notifications
    static func notificationsPreferences() -> String { "notifications:preferences" }

    // Neural
    static func neuralModels() -> String { "neural:models" }

    // Prediction
    static func predictionEvents(symbol: String?, category: String?) -> String {
        "prediction:events:\(symbol ?? "all"):\(category ?? "all")"
    }
}
