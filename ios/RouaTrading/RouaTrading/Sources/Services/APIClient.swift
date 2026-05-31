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
        }
        if let body {
            req.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            if retryCount < APIConfig.maxRetryCount {
                print("[API] Request failed, retrying (\(retryCount + 1)/\(APIConfig.maxRetryCount)): \(path)")
                try await Task.sleep(nanoseconds: APIConfig.retryDelay * UInt64(retryCount + 1))
                return try await request(path, method: method, body: body, retryCount: retryCount + 1)
            }
            throw APIError.networkError(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError("Invalid response type")
        }

        // Handle 401 Unauthorized
        if http.statusCode == 401 {
            if retryCount == 0, let refreshToken = KeychainManager.shared.refreshToken {
                print("[API] 401 received, attempting token refresh...")
                do {
                    let refreshed = try await refreshSession(refreshToken: refreshToken)
                    if refreshed {
                        return try await request(path, method: method, body: body, retryCount: 1)
                    }
                } catch {
                    print("[API] Token refresh failed: \(error.localizedDescription)")
                }
            }
            throw APIError.unauthorized
        }

        // Handle server errors
        guard (200...299).contains(http.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown"
            print("[API] Error \(http.statusCode) on \(method) \(path): \(errorBody.prefix(200))")
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
            return result
        }

        // Strategy 2: Unwrap { success, data: ... } wrapper
        if let wrapper = try? decoder.decode(ApiResponseWrapper.self, from: data) {
            // Try data field
            if let innerData = wrapper.data {
                if let encoded = try? JSONEncoder().encode(innerData),
                   let result = try? decoder.decode(T.self, from: encoded) {
                    return result
                }
            }
            // Try items field (scanner/scan)
            if let innerItems = wrapper.items {
                if let encoded = try? JSONEncoder().encode(innerItems),
                   let result = try? decoder.decode(T.self, from: encoded) {
                    return result
                }
            }
            // Try trades field (trading/history)
            if let innerTrades = wrapper.trades {
                if let encoded = try? JSONEncoder().encode(innerTrades),
                   let result = try? decoder.decode(T.self, from: encoded) {
                    return result
                }
            }
        }

        // Strategy 3: Unwrap { authenticated, user } for auth responses
        if let authResp = try? decoder.decode(AuthVerifyResponse.self, from: data) as? T {
            return authResp
        }

        // All strategies failed — log and throw
        let raw = String(data: data, encoding: .utf8)?.prefix(500) ?? "nil"
        print("[API] All decode strategies failed for \(path)")
        print("[API] Response was: \(raw)")
        throw APIError.decodingError("فشل تحليل الاستجابة من \(path)")
    }

    // MARK: - Session Refresh
    private func refreshSession(refreshToken: String) async throws -> Bool {
        guard let url = URL(string: "\(APIConfig.baseURL)/auth/refresh") else { return false }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            return false
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let success = json["success"] as? Bool, success,
           let tokenData = json["data"] as? [String: Any] {
            if let newToken = tokenData["token"] as? String {
                KeychainManager.shared.set(key: "roua_session", value: newToken)
            }
            if let newRefresh = tokenData["refresh"] as? String {
                KeychainManager.shared.set(key: "roua_refresh", value: newRefresh)
            }
            return true
        }
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
        guard (200...299).contains(http.statusCode) else {
            throw APIError.serverError(http.statusCode, String(data: data, encoding: .utf8) ?? "Unknown")
        }
        return data
    }
}
