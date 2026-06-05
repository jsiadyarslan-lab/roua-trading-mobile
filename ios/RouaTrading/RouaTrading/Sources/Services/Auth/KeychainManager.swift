import Foundation
import Security

// MARK: - Keychain Error

/// Errors that can occur during Keychain operations.
enum KeychainError: LocalizedError {
    /// The item was not found in the Keychain.
    case itemNotFound

    /// A Keychain operation returned an unexpected status code.
    case unexpectedStatus(OSStatus)

    /// Failed to encode or decode the value.
    case codingError(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "Item not found in Keychain."
        case .unexpectedStatus(let status):
            return "Keychain error: \(status) — \(SecCopyErrorMessageString(status, nil) as String? ?? "Unknown")"
        case .codingError(let error):
            return "Keychain encoding error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Keychain Manager

/// Secure storage for sensitive data using the iOS Keychain.
///
/// Stores session tokens, refresh tokens, and user data with appropriate
/// security flags (kSecAttrAccessible: `afterFirstUnlockThisDeviceOnly`).
///
/// - Note: All operations are `@MainActor`-isolated to ensure thread safety
///   when accessed from UI services.
@MainActor
final class KeychainManager {

    // MARK: - Singleton

    static let shared = KeychainManager()

    // MARK: - Configuration

    /// The service identifier used for all Keychain items.
    private let service: String = Bundle.main.bundleIdentifier ?? "com.roua.trading"

    /// The access group for shared Keychain items (nil = no sharing).
    private let accessGroup: String? = nil

    // MARK: - Initialization

    private init() {}

    // MARK: - String Storage

    /// Stores a string value in the Keychain.
    ///
    /// If a value already exists for the given key, it is updated.
    ///
    /// - Parameters:
    ///   - key: The unique key for the item.
    ///   - value: The string value to store.
    func store(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        storeData(key: key, data: data)
    }

    /// Retrieves a string value from the Keychain.
    ///
    /// - Parameter key: The key to look up.
    /// - Returns: The stored string, or `nil` if not found.
    func retrieve(key: String) -> String? {
        guard let data = retrieveData(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Deletes a string value from the Keychain.
    ///
    /// - Parameter key: The key to delete.
    func delete(key: String) {
        let query = baseQuery(key: key)
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Codable Storage

    /// Stores a `Codable` value in the Keychain as JSON data.
    ///
    /// - Parameters:
    ///   - key: The unique key for the item.
    ///   - value: The codable value to store.
    func store<T: Codable>(key: String, value: T) {
        do {
            let data = try JSONEncoder().encode(value)
            storeData(key: key, data: data)
        } catch {
            AppLogger.security.error("Failed to encode Keychain value for key '\(key)': \(error)")
        }
    }

    /// Retrieves a `Codable` value from the Keychain.
    ///
    /// - Parameter key: The key to look up.
    /// - Returns: The decoded value, or `nil` if not found or decoding fails.
    func retrieve<T: Codable>(key: String, as type: T.Type) -> T? {
        guard let data = retrieveData(key: key) else { return nil }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            AppLogger.security.error("Failed to decode Keychain value for key '\(key)': \(error)")
            return nil
        }
    }

    // MARK: - Bulk Operations

    /// Removes all Keychain items managed by this app.
    func clearAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            AppLogger.security.error("Failed to clear Keychain: status \(status)")
        }
    }

    /// Checks whether a value exists for the given key without retrieving it.
    func contains(key: String) -> Bool {
        var query = baseQuery(key: key)
        query[kSecReturnData as String] = false
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Private Helpers

    /// Base query dictionary for Keychain operations.
    private func baseQuery(key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        return query
    }

    /// Stores raw `Data` in the Keychain. Updates if the key already exists.
    private func storeData(key: String, data: Data) {
        // First, try to update an existing item
        let query = baseQuery(key: key)

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if updateStatus == errSecSuccess {
            return
        }

        // If the item doesn't exist, create it
        if updateStatus == errSecItemNotFound {
            var createQuery = query
            createQuery.merge(attributes) { _, new in new }

            let createStatus = SecItemAdd(createQuery as CFDictionary, nil)
            if createStatus != errSecSuccess {
                AppLogger.security.error(
                    "Failed to create Keychain item for key '\(key)': status \(createStatus)"
                )
            }
        } else {
            AppLogger.security.error(
                "Failed to update Keychain item for key '\(key)': status \(updateStatus)"
            )
        }
    }

    /// Retrieves raw `Data` from the Keychain.
    private func retrieveData(key: String) -> Data? {
        var query = baseQuery(key: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status != errSecItemNotFound {
                AppLogger.security.error(
                    "Keychain retrieve failed for key '\(key)': status \(status)"
                )
            }
            return nil
        }

        return result as? Data
    }
}
