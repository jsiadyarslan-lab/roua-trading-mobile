import Foundation

// MARK: - API Error

/// Errors that can occur during API requests.
enum APIError: LocalizedError {
    /// The server returned a non-2xx status code.
    case httpError(statusCode: Int, message: String?)

    /// The response could not be decoded into the expected type.
    case decodingError(underlying: Error)

    /// The request was rejected due to rate limiting (HTTP 429).
    case rateLimited(retryAfter: TimeInterval?)

    /// The session has expired and could not be refreshed.
    case sessionExpired

    /// A network-level failure (no internet, DNS, timeout, etc.).
    case networkError(underlying: Error)

    /// The request was explicitly cancelled.
    case cancelled

    /// A transient failure that may succeed on retry.
    case transientFailure(underlying: Error)

    /// An unexpected error.
    case unexpected(String)

    var errorDescription: String? {
        switch self {
        case .httpError(let code, let message):
            return message ?? "HTTP error \(code)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .rateLimited(let retryAfter):
            if let retryAfter {
                return "Rate limited. Try again in \(Int(retryAfter)) seconds."
            }
            return "Rate limited. Please try again later."
        case .sessionExpired:
            return "Session expired. Please sign in again."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .cancelled:
            return "Request cancelled."
        case .transientFailure(let error):
            return "Temporary failure: \(error.localizedDescription)"
        case .unexpected(let message):
            return message
        }
    }
}

// MARK: - Response Wrappers

/// Standard envelope returned by most backend endpoints.
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
    let error: String?
}

/// Envelope used by some paginated endpoints.
struct APIItemsResponse<T: Codable>: Codable {
    let items: [T]
    let total: Int?
    let page: Int?
    let pageSize: Int?
}

/// Envelope that wraps data under a `data` key without `success`.
struct APIDataEnvelope<T: Codable>: Codable {
    let data: T
}

// MARK: - API Client

/// Production-ready HTTP client for the Roua Trading backend.
///
/// Features:
/// - Automatic auth header injection from `KeychainManager`
/// - 401 handling with automatic token refresh + retry
/// - Smart decoding that handles multiple backend response shapes
/// - Configurable retry for transient failures
/// - Rate-limit awareness (429 handling)
/// - Request cancellation support
/// - DEBUG-only request/response logging
@MainActor
final class APIClient {

    // MARK: - Singleton

    static let shared = APIClient()

    // MARK: - Properties

    private let session: URLSession
    private let keychain = KeychainManager.shared
    private let logger = AppLogger.network

    /// Active tasks that can be cancelled.
    /// Keyed by endpoint path for selective cancellation.
    private var activeTasks: [String: URLSessionTask] = [:]

    /// Stores the task ID associated with each in-flight request URL,
    /// so we can cancel requests by endpoint path.
    private var taskIDToPath: [Int: String] = [:]

    /// Whether a token refresh is currently in progress (prevents concurrent refreshes).
    private var isRefreshing = false

    /// Maximum number of automatic retries for transient failures.
    private let maxRetries = 2

    // MARK: - Initialization

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConfig.requestTimeout
        config.timeoutIntervalForResource = AppConfig.resourceTimeout
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.httpShouldSetCookies = false // We manage cookies manually
        config.httpAdditionalHeaders = [
            "Accept": "application/json",
            "X-App-Version": AppConfig.appVersion,
            "X-Platform": "ios",
        ]
        self.session = URLSession(configuration: config)
    }

    // MARK: - Public API

    /// Performs a decoded request against the given endpoint.
    ///
    /// The response is decoded using a smart strategy that tries multiple
    /// envelope shapes the backend may return:
    /// 1. `APIResponse<T>`  — `{ "success": true, "data": T }`
    /// 2. `T` directly      — when the response is the object itself
    /// 3. `APIDataEnvelope<T>` — `{ "data": T }`
    ///
    /// - Parameters:
    ///   - endpoint: The API endpoint to call.
    ///   - body: An optional encodable body (sent as JSON).
    ///   - queryItems: Additional query items to append.
    /// - Returns: The decoded `T` value.
    func request<T: Codable>(
        _ endpoint: APIEndpoint,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        let data = try await executeRequest(endpoint, body: body, queryItems: queryItems)
        return try smartDecode(data)
    }

    /// Performs a request and returns the raw `Data` without decoding.
    func requestRaw(
        _ endpoint: APIEndpoint,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> Data {
        try await executeRequest(endpoint, body: body, queryItems: queryItems)
    }

    /// Uploads raw data to the given endpoint.
    ///
    /// - Parameters:
    ///   - endpoint: Target endpoint.
    ///   - data: Raw data to upload.
    ///   - mimeType: MIME type of the uploaded content.
    /// - Returns: The raw response data.
    func upload(
        _ endpoint: APIEndpoint,
        data: Data,
        mimeType: String
    ) async throws -> Data {
        let request = try buildURLRequest(endpoint, queryItems: nil)
        var mutableRequest = request
        mutableRequest.httpMethod = endpoint.method.rawValue
        mutableRequest.setValue(mimeType, forHTTPHeaderField: "Content-Type")
        try await injectAuthHeaders(into: &mutableRequest, requiresAuth: endpoint.requiresAuth)

        let taskID = UUID().uuidString
        defer { activeTasks.removeValue(forKey: taskID) }

        logger.debug("⬆️ UPLOAD \(endpoint.path)")

        do {
            let (responseData, response) = try await session.upload(for: mutableRequest, from: data)
            try handleHTTPResponse(response, data: responseData)
            return responseData
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(underlying: error)
        }
    }

    /// Cancels the in-flight request for the given endpoint path, if any.
    ///
    /// - Note: Due to the async nature of `URLSession.data(for:)`, we cannot
    ///   directly cancel individual requests. This method cancels all tracked
    ///   tasks with the matching path prefix.
    func cancelRequest(for endpointPath: String) {
        let keysToRemove = activeTasks.keys.filter { $0 == endpointPath }
        for key in keysToRemove {
            activeTasks[key]?.cancel()
            activeTasks.removeValue(forKey: key)
        }
    }

    /// Cancels all active requests.
    func cancelAllRequests() {
        activeTasks.values.forEach { $0.cancel() }
        activeTasks.removeAll()
        taskIDToPath.removeAll()
    }

    // MARK: - Request Execution

    /// Core request pipeline: build → auth → execute → handle → retry if needed.
    private func executeRequest(
        _ endpoint: APIEndpoint,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil,
        retryCount: Int = 0
    ) async throws -> Data {
        let request = try buildURLRequest(endpoint, queryItems: queryItems)
        var mutableRequest = request

        // Encode body
        if let body {
            mutableRequest.httpBody = try JSONEncoder().encode(body)
            if mutableRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                mutableRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }

        // Auth headers
        try await injectAuthHeaders(into: &mutableRequest, requiresAuth: endpoint.requiresAuth)

        let taskID = endpoint.path
        logRequest(mutableRequest, body: body)

        do {
            // Use a manual URLSessionDataTask + continuation so we can track
            // the task for cancellation. The built-in session.data(for:) hides
            // the underlying task, making it impossible to cancel per-request.
            let (responseData, response) = try await executeTask(
                request: mutableRequest,
                taskID: taskID
            )

            defer { activeTasks.removeValue(forKey: taskID) }

            logResponse(response, data: responseData, for: endpoint.path)

            // Handle HTTP-level errors
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    break // success
                case 401 where retryCount == 0:
                    // Attempt token refresh then retry (for both auth-required and
                    // public endpoints — an invalid token on any endpoint should trigger
                    // a refresh attempt)
                    return try await handleUnauthorizedAndRetry(
                        endpoint: endpoint,
                        body: body,
                        queryItems: queryItems,
                        retryCount: retryCount
                    )

                case 403 where retryCount == 0:
                    // 403 Forbidden can mean the session is invalid or the user
                    // lacks permissions. Treat it like 401 and try refreshing.
                    logger.warning("🚫 403 Forbidden for \(endpoint.path) — attempting token refresh")
                    return try await handleUnauthorizedAndRetry(
                        endpoint: endpoint,
                        body: body,
                        queryItems: queryItems,
                        retryCount: retryCount
                    )
                case 429:
                    let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                        .flatMap { TimeInterval($0) }
                    throw APIError.rateLimited(retryAfter: retryAfter)
                default:
                    let message = try? JSONDecoder().decode(APIErrorBody.self, from: responseData)
                    throw APIError.httpError(
                        statusCode: httpResponse.statusCode,
                        message: message?.error ?? message?.message
                    )
                }
            }

            return responseData

        } catch let error as APIError {
            throw error
        } catch let urlError as URLError where isTransient(urlError) && retryCount < maxRetries {
            logger.warning("🔄 Transient failure for \(endpoint.path), retry \(retryCount + 1)/\(maxRetries)")
            return try await executeRequest(
                endpoint,
                body: body,
                queryItems: queryItems,
                retryCount: retryCount + 1
            )
        } catch is CancellationError {
            throw APIError.cancelled
        } catch {
            throw APIError.networkError(underlying: error)
        }
    }

    // MARK: - Task Execution Helper

    /// Creates a URLSessionDataTask with a completion handler, bridges the
    /// result to async/await via a continuation, and stores the task in
    /// `activeTasks` so it can be cancelled by path.
    private func executeTask(
        request: URLRequest,
        taskID: String
    ) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data, let response {
                    continuation.resume(returning: (data, response))
                } else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                }
            }
            activeTasks[taskID] = task
            task.resume()
        }
    }

    // MARK: - URL Request Building

    private func buildURLRequest(
        _ endpoint: APIEndpoint,
        queryItems: [URLQueryItem]?
    ) throws -> URLRequest {
        // FIX: Use string concatenation instead of appendingPathComponent.
        // appendingPathComponent with paths starting with "/" can produce
        // incorrect URLs (double-slash or percent-encoded "/" characters),
        // causing all API requests to 404 or fail silently.
        let urlString = AppConfig.apiBaseURL.absoluteString + endpoint.path
        guard let url = URL(string: urlString) else {
            throw APIError.unexpected("Failed to build URL: \(urlString)")
        }

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw APIError.unexpected("Failed to parse URL components for: \(urlString)")
        }

        // Merge default query items with caller-supplied items
        var allQueryItems = endpoint.defaultQueryItems
        if let queryItems {
            allQueryItems.append(contentsOf: queryItems)
        }
        if !allQueryItems.isEmpty {
            components.queryItems = allQueryItems
        }

        guard let finalURL = components.url else {
            throw APIError.unexpected("Failed to build URL for endpoint: \(endpoint.path)")
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = endpoint.method.rawValue
        return request
    }

    // MARK: - Auth Injection

    private func injectAuthHeaders(
        into request: inout URLRequest,
        requiresAuth: Bool
    ) async throws {
        // Always inject auth headers if we have a token, even for public endpoints.
        // The backend can use the token to personalize responses, and having
        // an invalid token on a public endpoint won't cause a 401.
        if let sessionToken = keychain.retrieve(key: AppConfig.sessionTokenKey) {
            // Send the session token via multiple mechanisms for maximum
            // backend compatibility:
            // 1. Custom header (x-roua-session)
            request.setValue(sessionToken, forHTTPHeaderField: "x-roua-session")
            // 2. Standard Authorization Bearer header
            request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
            // 3. Cookie header — the backend's session middleware expects
            //    the roua_session cookie. Even though we disabled automatic
            //    cookie management (httpShouldSetCookies = false), we must
            //    manually include the session cookie so the backend can
            //    identify the user.
            var cookieParts = ["roua_session=\(sessionToken)"]
            // Also include the refresh token if available
            if let refreshToken = keychain.retrieve(key: AppConfig.refreshTokenKey) {
                cookieParts.append("roua_refresh=\(refreshToken)")
            }
            request.setValue(cookieParts.joined(separator: "; "), forHTTPHeaderField: "Cookie")
        } else if requiresAuth, let refreshToken = keychain.retrieve(key: AppConfig.refreshTokenKey) {
            // Fallback: include refresh token as cookie header (only for auth-required endpoints)
            request.setValue("roua_refresh=\(refreshToken)", forHTTPHeaderField: "Cookie")
        }
    }

    // MARK: - 401 Handling

    private func handleUnauthorizedAndRetry(
        endpoint: APIEndpoint,
        body: Encodable?,
        queryItems: [URLQueryItem]?,
        retryCount: Int
    ) async throws -> Data {
        logger.info("🔐 401 received — attempting token refresh")

        // Prevent concurrent refreshes
        guard !isRefreshing else {
            throw APIError.sessionExpired
        }

        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let refreshed = try await refreshSession()
            guard refreshed else {
                throw APIError.sessionExpired
            }

            // Retry the original request
            return try await executeRequest(
                endpoint,
                body: body,
                queryItems: queryItems,
                retryCount: retryCount + 1
            )
        } catch {
            logger.error("Token refresh failed: \(error)")
            throw APIError.sessionExpired
        }
    }

    /// Attempts to refresh the session token.
    /// - Returns: `true` if the refresh succeeded.
    @discardableResult
    func refreshSession() async throws -> Bool {
        guard let refreshToken = keychain.retrieve(key: AppConfig.refreshTokenKey) else {
            return false
        }

        // FIX: Use /auth/refresh path (relative to apiBaseURL which already contains /api)
        let url = URL(string: AppConfig.apiBaseURL.absoluteString + "/auth/refresh")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Send refresh token as Cookie header AND as JSON body for maximum compatibility
        request.setValue("roua_refresh=\(refreshToken)", forHTTPHeaderField: "Cookie")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            return false
        }

        // Extract new session token from response or Set-Cookie header
        if let newSession = extractSessionToken(from: httpResponse, data: data) {
            keychain.store(key: AppConfig.sessionTokenKey, value: newSession)
        }

        // Extract new refresh token if provided
        if let newRefresh = extractRefreshToken(from: httpResponse, data: data) {
            keychain.store(key: AppConfig.refreshTokenKey, value: newRefresh)
        }

        // FIX: Also check response body for token data
        // The backend may return tokens in the JSON body for mobile clients
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let dataDict = json["data"] as? [String: Any] {
                if let token = dataDict["token"] as? String ?? dataDict["sessionToken"] as? String {
                    keychain.store(key: AppConfig.sessionTokenKey, value: token)
                }
                if let refresh = dataDict["refresh"] as? String ?? dataDict["refreshToken"] as? String {
                    keychain.store(key: AppConfig.refreshTokenKey, value: refresh)
                }
            }
        }

        return true
    }

    // MARK: - Smart Decoding

    /// Tries to decode the response using multiple envelope shapes.
    ///
    /// Strategy:
    /// 1. Try `APIResponse<T>` — standard envelope with `success` + `data`
    /// 2. Try `APIDataEnvelope<T>` — just `{ "data": T }`
    /// 3. Try `T` directly — raw object
    /// 4. Try extracting `items` array via JSONSerialization (handles `{"items":[...]}`)
    /// 5. Try `APIItemsResponse<DynamicCodable>` as fallback
    /// 6. Try `APIResponse<DynamicCodable>` with array data
    private func smartDecode<T: Codable>(_ data: Data) throws -> T {
        // Strategy 1: APIResponse<T>
        if let response = try? JSONDecoder().decode(APIResponse<T>.self, from: data) {
            if let value = response.data {
                return value
            }
            // success=true but data is null — this means "no data available".
            // Do NOT create empty objects from "{}" as that produces misleading
            // zero-value data (e.g., Balances with $0, RiskReport with low risk).
            // Instead, fall through to other strategies or throw a decoding error.
        }

        // Strategy 2: APIDataEnvelope<T>
        if let envelope = try? JSONDecoder().decode(APIDataEnvelope<T>.self, from: data) {
            return envelope.data
        }

        // Strategy 3: T directly
        if let value = try? JSONDecoder().decode(T.self, from: data) {
            return value
        }

        // Strategy 4: Extract `items` array via JSONSerialization.
        // The backend scanner endpoints return `{"success":true,"items":[...],"meta":{...}}`
        // which none of the typed wrappers above handle correctly (they all expect a `data` key).
        // We extract the raw `items` array and decode it directly as T.
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let itemsArray = json["items"] {
            let itemsData = try JSONSerialization.data(withJSONObject: itemsArray)
            if let value = try? JSONDecoder().decode(T.self, from: itemsData) {
                return value
            }
        }

        // Strategy 5: For array types, try { "items": [...] } via APIItemsResponse
        // (fallback — less reliable than Strategy 4 because DynamicCodable loses field data)
        if let itemsResponse = try? JSONDecoder().decode(APIItemsResponse<DynamicCodable>.self, from: data) {
            let itemsData = try JSONEncoder().encode(itemsResponse.items)
            if let value = try? JSONDecoder().decode(T.self, from: itemsData) {
                return value
            }
        }

        // Strategy 6: APIResponse with array data
        if let arrayResponse = try? JSONDecoder().decode(APIResponse<DynamicCodable>.self, from: data),
           let arrayData = arrayResponse.data {
            let encoded = try JSONEncoder().encode(arrayData)
            if let value = try? JSONDecoder().decode(T.self, from: encoded) {
                return value
            }
        }

        let snippet = String(data: data.prefix(500), encoding: .utf8) ?? "n/a"
        logger.error("Decoding failed for type \(T.self). Response snippet: \(snippet)")
        throw APIError.decodingError(
            underlying: DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Could not decode response as \(T.self). Snippet: \(snippet)")
            )
        )
    }

    // MARK: - Response Handling

    private func handleHTTPResponse(_ response: URLResponse?, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else { return }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.sessionExpired
        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap { TimeInterval($0) }
            throw APIError.rateLimited(retryAfter: retryAfter)
        default:
            let errorBody = try? JSONDecoder().decode(APIErrorBody.self, from: data)
            throw APIError.httpError(
                statusCode: httpResponse.statusCode,
                message: errorBody?.error ?? errorBody?.message
            )
        }
    }

    // MARK: - Token Extraction

    private func extractSessionToken(from response: HTTPURLResponse, data: Data) -> String? {
        // First check response body for sessionToken (mobile-optimized endpoints)
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let token = json["sessionToken"] as? String ?? json["token"] as? String {
                return token
            }
            // Check nested data object
            if let dataDict = json["data"] as? [String: Any],
               let token = dataDict["sessionToken"] as? String ?? dataDict["token"] as? String {
                return token
            }
        }

        // Then check Set-Cookie header
        if let cookies = response.allHeaderFields["Set-Cookie"] as? String {
            if let match = cookies.range(of: "roua_session=([^;]+)", options: .regularExpression) {
                let cookieValue = String(cookies[match])
                    .replacingOccurrences(of: "roua_session=", with: "")
                    .components(separatedBy: ";").first?
                    .trimmingCharacters(in: .whitespaces)
                if let cookieValue, !cookieValue.isEmpty {
                    return cookieValue
                }
            }
        }

        return nil
    }

    private func extractRefreshToken(from response: HTTPURLResponse, data: Data? = nil) -> String? {
        // First check response body for refreshToken (mobile-optimized endpoints)
        if let data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let token = json["refreshToken"] as? String ?? json["refresh"] as? String {
                return token
            }
            if let dataDict = json["data"] as? [String: Any],
               let token = dataDict["refreshToken"] as? String ?? dataDict["refresh"] as? String {
                return token
            }
        }

        // Then check Set-Cookie header
        if let cookies = response.allHeaderFields["Set-Cookie"] as? String {
            if let match = cookies.range(of: "roua_refresh=([^;]+)", options: .regularExpression) {
                let cookieValue = String(cookies[match])
                    .replacingOccurrences(of: "roua_refresh=", with: "")
                    .components(separatedBy: ";").first?
                    .trimmingCharacters(in: .whitespaces)
                return cookieValue
            }
        }
        return nil
    }

    // MARK: - Transient Error Detection

    private func isTransient(_ error: URLError) -> Bool {
        switch error.code {
        case .timedOut,
             .cannotConnectToHost,
             .networkConnectionLost,
             .dnsLookupFailed,
             .notConnectedToInternet,
             .internationalRoamingOff,
             .callIsActive:
            return true
        default:
            return false
        }
    }

    // MARK: - Logging

    private func logRequest(_ request: URLRequest, body: Encodable?) {
        #if DEBUG
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "unknown"
        logger.debug("⬆️ \(method) \(url)")

        if let body, let bodyData = try? JSONEncoder().encode(body) {
            let bodyString = String(data: bodyData, encoding: .utf8) ?? "n/a"
            logger.debug("📦 Body: \(bodyString.prefix(500))")
        }

        if let headers = request.allHTTPHeaderFields {
            let sanitized = headers.merging(["Authorization": "***REDACTED***"]) { _, _ in "***REDACTED***" }
            logger.debug("📋 Headers: \(sanitized)")
        }
        #endif
    }

    private func logResponse(_ response: URLResponse?, data: Data, for path: String) {
        #if DEBUG
        if let httpResponse = response as? HTTPURLResponse {
            logger.debug("⬇️ \(httpResponse.statusCode) \(path)")
        }
        let bodyString = String(data: data.prefix(1000), encoding: .utf8) ?? "n/a"
        logger.debug("📦 Response (\(data.count) bytes): \(bodyString)")
        #endif
    }
}

// MARK: - Helper Types

/// Used internally for dynamic decoding attempts.
private struct DynamicCodable: Codable {}

/// Error body returned by the backend.
private struct APIErrorBody: Codable {
    let error: String?
    let message: String?
}
