import Foundation
import Security

// MARK: - Keychain Manager (Native Security framework — no SPM dependency)
class KeychainManager {
    static let shared = KeychainManager()
    private let service = "com.roua.trading"

    private init() {}

    // MARK: - Keys
    enum Key: String {
        case sessionToken = "roua_session"
        case refreshToken = "roua_refresh"
        case userId = "roua_user_id"
        case userEmail = "roua_user_email"
        case userTier = "roua_user_tier"
        case appLanguage = "roua_app_language"
    }

    // MARK: - CRUD
    func set(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    func readValue(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }

    func deleteAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Convenience Methods
    func saveSession(token: String, refresh: String?, userId: String?) {
        set(key: Key.sessionToken.rawValue, value: token)
        if let refresh = refresh { set(key: Key.refreshToken.rawValue, value: refresh) }
        if let userId = userId { set(key: Key.userId.rawValue, value: userId) }
    }

    var sessionToken: String? { return readValue(key: Key.sessionToken.rawValue) }
    var refreshToken: String? { return readValue(key: Key.refreshToken.rawValue) }
    var savedUserId: String? { return readValue(key: Key.userId.rawValue) }
    var savedLanguage: String? { return readValue(key: Key.appLanguage.rawValue) }

    func clearSession() {
        delete(key: Key.sessionToken.rawValue)
        delete(key: Key.refreshToken.rawValue)
        delete(key: Key.userId.rawValue)
    }
}
