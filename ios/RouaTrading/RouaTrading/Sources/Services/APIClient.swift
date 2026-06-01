import Foundation

// MARK: - API Client with Retry + Smart Response Parsing
@MainActor
class APIClient {
    static let shared = APIClient()
    private let session: URLSession
    private let decoder = JSONDecoder()

    var sessionToken: String? {
        get { KeychainManager.shared.sessionToken }
        set {
            if let v = newValue {
                KeychainManager.shared.set(key: "roua_session", value: v)
            } else {
                KeychainManager.shared.delete(key: "roua_session")
            }
        }
    }

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfig.requestTimeout
        config.httpShouldSetCookies = false
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
        self.decoder.keyDecodingStrategy = .useDefaultKeys
    }

    // MARK: - Core Request with Retry
    func request<T: Codable>(_ path: String, method: String = "GET", body: (any Encodable)? = nil, retryCount: Int = 0) async throws -> T {
        guard let url = URL(string: "\(APIConfig.baseURL)\(path)") else {
            print("[API] ❌ Invalid URL: \(APIConfig.baseURL)\(path)")
            throw APIError.networkError("Invalid URL: \(path)")
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("RouaTrading/2.0 (iOS; Mobile)", forHTTPHeaderField: "User-Agent")

        if let token = sessionToken {
            // Send token in ALL three auth methods (like the web proxy does)
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            req.setValue(token, forHTTPHeaderField: APIConfig.sessionHeader)
            req.setValue("roua_session=\(token)", forHTTPHeaderField: "Cookie")
            print("[API] → \(method) \(path) [auth: token=\(token.prefix(8))...]")
        } else {
            print("[API] → \(method) \(path) [NO AUTH TOKEN]")
        }

        if let body {
            req.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            if retryCount < APIConfig.maxRetryCount {
                print("[API] ⚠️ Network error, retrying (\(retryCount + 1)/\(APIConfig.maxRetryCount)): \(path) — \(error.localizedDescription)")
                try await Task.sleep(nanoseconds: APIConfig.retryDelay * UInt64(retryCount + 1))
                return try await request(path, method: method, body: body, retryCount: retryCount + 1)
            }
            print("[API] ❌ Network error after \(retryCount + 1) attempts: \(path) — \(error.localizedDescription)")
            throw APIError.networkError(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError("Invalid response type")
        }

        print("[API] ← \(http.statusCode) \(method) \(path) [\(data.count) bytes]")

        // Handle 401 Unauthorized
        if http.statusCode == 401 {
            if retryCount == 0, let refreshToken = KeychainManager.shared.refreshToken {
                print("[API] 🔑 401 received, attempting token refresh...")
                do {
                    let refreshed = try await refreshSession(refreshToken: refreshToken)
                    if refreshed {
                        print("[API] 🔑 Token refreshed successfully, retrying request")
                        return try await request(path, method: method, body: body, retryCount: 1)
                    }
                } catch {
                    print("[API] 🔑 Token refresh failed: \(error.localizedDescription)")
                }
            }
            print("[API] ❌ Unauthorized — user needs to re-login")
            throw APIError.unauthorized
        }

        // Handle server errors
        guard (200...299).contains(http.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown"
            print("[API] ❌ Error \(http.statusCode) on \(method) \(path): \(errorBody.prefix(300))")
            if retryCount < APIConfig.maxRetryCount && http.statusCode >= 500 {
                try await Task.sleep(nanoseconds: APIConfig.retryDelay * UInt64(retryCount + 1))
                return try await request(path, method: method, body: body, retryCount: retryCount + 1)
            }
            throw APIError.serverError(http.statusCode, errorBody)
        }

        // Smart decode: try multiple strategies
        return try smartDecode(T.self, from: data, path: path)
    }

    // MARK: - Smart Decode (handles multiple API response formats)
    private func smartDecode<T: Codable>(_ type: T.Type, from data: Data, path: String) throws -> T {
        // Strategy 1: Direct decode (works for raw arrays/objects like /trading/positions)
        if let result = try? decoder.decode(T.self, from: data) {
            print("[API] ✅ Decoded directly as \(T.self) from \(path)")
            return result
        }

        // Strategy 2: Unwrap { success, data: ... } wrapper
        if let wrapper = try? decoder.decode(ApiResponseWrapper.self, from: data) {
            // Try data field
            if let innerData = wrapper.data {
                if let encoded = try? JSONEncoder().encode(innerData),
                   let result = try? decoder.decode(T.self, from: encoded) {
                    print("[API] ✅ Decoded via .data wrapper as \(T.self) from \(path)")
                    return result
                }
            }
            // Try items field (scanner/scan)
            if let innerItems = wrapper.items {
                if let encoded = try? JSONEncoder().encode(innerItems),
                   let result = try? decoder.decode(T.self, from: encoded) {
                    print("[API] ✅ Decoded via .items wrapper as \(T.self) from \(path)")
                    return result
                }
            }
            // Try trades field (trading/history)
            if let innerTrades = wrapper.trades {
                if let encoded = try? JSONEncoder().encode(innerTrades),
                   let result = try? decoder.decode(T.self, from: encoded) {
                    print("[API] ✅ Decoded via .trades wrapper as \(T.self) from \(path)")
                    return result
                }
            }
        }

        // Strategy 3: Unwrap { authenticated, user } for auth responses
        if let authResp = try? decoder.decode(AuthVerifyResponse.self, from: data) as? T {
            print("[API] ✅ Decoded as AuthVerifyResponse from \(path)")
            return authResp
        }

        // All strategies failed — log and throw with detailed error
        let raw = String(data: data, encoding: .utf8)?.prefix(500) ?? "nil"
        print("[API] ❌ ALL decode strategies failed for \(path)")
        print("[API] Expected type: \(T.self)")
        print("[API] Response body: \(raw)")

        // Try to get more detail about why decode failed
        let decodeAttempt = try? decoder.decode(T.self, from: data)
        print("[API] Direct decode attempt result: \(decodeAttempt != nil ? "success" : "failed")")

        throw APIError.decodingError("فشل تحليل الاستجابة من \(path)")
    }

    // MARK: - Session Refresh
    private func refreshSession(refreshToken: String) async throws -> Bool {
        guard let url = URL(string: "\(APIConfig.baseURL)/auth/refresh") else { return false }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Send refresh token via Authorization header AND custom header
        // The server now checks both for mobile client support
        req.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")
        req.setValue(refreshToken, forHTTPHeaderField: "x-roua-refresh")
        // Also send as cookie for maximum compatibility
        req.setValue("roua_refresh=\(refreshToken)", forHTTPHeaderField: "Cookie")
        print("[API] 🔑 Refreshing session with refresh token...")

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            print("[API] 🔑 Refresh failed: invalid response type")
            return false
        }

        print("[API] 🔑 Refresh response: \(http.statusCode)")

        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8)?.prefix(200) ?? "nil"
            print("[API] 🔑 Refresh failed: \(http.statusCode) - \(body)")
            return false
        }

        // Try to parse the response — it may have different formats
        // Format 1: { success: true, data: { token, refresh } }
        // Format 2: { refreshed: true, authenticated: true, user: {...} }
        // The server sets new cookies, but for mobile we need to extract tokens from response
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // Check if authenticated
            let isAuthenticated = json["authenticated"] as? Bool ?? (json["success"] as? Bool ?? false)

            if isAuthenticated {
                // The server creates new session tokens but returns them via Set-Cookie headers
                // For mobile, we need to extract from the response or headers
                // Check if there's a data field with tokens
                if let tokenData = json["data"] as? [String: Any] {
                    if let newToken = tokenData["token"] as? String {
                        KeychainManager.shared.set(key: "roua_session", value: newToken)
                        print("[API] 🔑 New session token saved from data.token")
                    }
                    if let newRefresh = tokenData["refresh"] as? String {
                        KeychainManager.shared.set(key: "roua_refresh", value: newRefresh)
                        print("[API] 🔑 New refresh token saved from data.refresh")
                    }
                    return true
                }

                // If no token in response body, the session was refreshed via sliding session
                // The new tokens are in Set-Cookie headers which mobile can't read from cross-origin
                // We need to re-validate to get the new session state
                print("[API] 🔑 Session refreshed (sliding), re-validating...")
                return true
            }
        }

        print("[API] 🔑 Refresh response format unexpected: \(String(data: data, encoding: .utf8)?.prefix(200) ?? "nil")")
        return false
    }

    // MARK: - Raw Data Request
    func rawDataRequest(_ path: String, method: String = "GET", body: (any Encodable)? = nil) async throws -> Data {
        guard let url = URL(string: "\(APIConfig.baseURL)\(path)") else {
            throw APIError.networkError("Invalid URL: \(path)")
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = sessionToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            req.setValue(token, forHTTPHeaderField: APIConfig.sessionHeader)
            req.setValue("roua_session=\(token)", forHTTPHeaderField: "Cookie")
        }
        if let body { req.httpBody = try JSONEncoder().encode(body) }
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw APIError.networkError("Invalid response") }
        print("[API] ← \(http.statusCode) \(method) \(path) [\(data.count) bytes, raw]")
        guard (200...299).contains(http.statusCode) else {
            throw APIError.serverError(http.statusCode, String(data: data, encoding: .utf8) ?? "Unknown")
        }
        return data
    }
}
