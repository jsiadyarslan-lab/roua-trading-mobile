import SwiftUI
import Security
import Foundation
import AuthenticationServices
import SafariServices

// MARK: - ═══════════════════════════════════════
// MARK: - APP ENTRY
// MARK: - ═══════════════════════════════════════

@main
struct RouaTradingApp: App {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    TabBarView()
                } else {
                    AuthView()
                }
            }
            .tint(RouaTheme.Colors.accent)
            .preferredColorScheme(.dark)
            .onAppear { authManager.checkExistingSession() }
        }
    }
}

// MARK: - ═══════════════════════════════════════
// MARK: - THEME & DESIGN SYSTEM
// MARK: - ═══════════════════════════════════════

enum RouaTheme {
    enum Colors {
        static let background = Color(hex: "0A0E17")
        static let surface = Color(hex: "111827")
        static let surfaceElevated = Color(hex: "1A2332")
        static let surfaceOverlay = Color(hex: "1E293B")
        static let accent = Color(hex: "3B82F6")
        static let accentLight = Color(hex: "60A5FA")
        static let accentDark = Color(hex: "2563EB")
        static let profit = Color(hex: "00C853")
        static let profitLight = Color(hex: "69F0AE")
        static let profitBackground = Color(hex: "00C853").opacity(0.1)
        static let loss = Color(hex: "FF1744")
        static let lossLight = Color(hex: "FF5252")
        static let lossBackground = Color(hex: "FF1744").opacity(0.1)
        static let warning = Color(hex: "FFB300")
        static let warningBackground = Color(hex: "FFB300").opacity(0.1)
        static let info = Color(hex: "29B6F6")
        static let textPrimary = Color(hex: "F1F5F9")
        static let textSecondary = Color(hex: "94A3B8")
        static let textTertiary = Color(hex: "64748B")
        static let border = Color(hex: "1E293B")
        static let borderLight = Color(hex: "334155")
        static let buyGradient = LinearGradient(colors: [Color(hex: "00C853"), Color(hex: "00E676")], startPoint: .topLeading, endPoint: .bottomTrailing)
        static let sellGradient = LinearGradient(colors: [Color(hex: "FF1744"), Color(hex: "FF5252")], startPoint: .topLeading, endPoint: .bottomTrailing)
        static let accentGradient = LinearGradient(colors: [Color(hex: "3B82F6"), Color(hex: "8B5CF6")], startPoint: .topLeading, endPoint: .bottomTrailing)
        static let glassBackground = Color.white.opacity(0.05)
        static let glassBorder = Color.white.opacity(0.1)
    }
    enum Spacing {
        static let xs: CGFloat = 4; static let sm: CGFloat = 8; static let md: CGFloat = 12
        static let lg: CGFloat = 16; static let xl: CGFloat = 24; static let xxl: CGFloat = 32
    }
    enum CornerRadius {
        static let sm: CGFloat = 6; static let md: CGFloat = 10; static let lg: CGFloat = 16; static let xl: CGFloat = 24
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - ═══════════════════════════════════════
// MARK: - API CONFIGURATION
// MARK: - ═══════════════════════════════════════

enum APIConfig {
    static let baseURL = "https://roua-trading-production.up.railway.app/api"
    static let wsURL = "wss://roua-trading-production.up.railway.app"
    static let sessionHeader = "x-roua-session"
    static let requestTimeout: TimeInterval = 30
}

// MARK: - ═══════════════════════════════════════
// MARK: - API MODELS
// MARK: - ═══════════════════════════════════════

struct AuthUser: Codable { let id: String; let email: String; let displayName: String?; let tier: String }
struct AuthVerifyResponse: Codable { let success: Bool; let user: AuthUser? }
struct AuthRegisterRequest: Codable { let email: String; let displayName: String? }

struct Quote: Codable {
    let symbol: String; let bid: Double?; let ask: Double?; let last: Double?
    let open: Double?; let high: Double?; let low: Double?; let close: Double?
    let volume: Double?; let change: Double?; let changePercent: Double?; let timestamp: String?
}

struct Position: Codable, Identifiable {
    let id: String; let userId: String; let credentialId: String
    let symbol: String; let side: String; let status: String; let entryPrice: Double
    let currentPrice: Double?; let quantity: Double; let unrealizedPnl: Double?
    let realizedPnl: Double?; let stopLoss: Double?; let takeProfit: Double?
    let source: String?; let createdAt: String; let updatedAt: String
}

struct Trade: Codable, Identifiable {
    let id: String; let symbol: String; let side: String; let type: String
    let quantity: Double; let price: Double; let pnl: Double?; let createdAt: String
}

struct PortfolioSummary: Codable {
    let totalValue: Double; let totalPnl: Double; let dailyPnl: Double
    let positions: [Position]?; let unrealizedPnl: Double?; let realizedPnl: Double?
}

struct PlaceOrderRequest: Codable {
    let exchangeCredentialId: String; let symbol: String; let side: String
    let type: String; let quantity: Double; let price: Double?; let stopLoss: Double
    let takeProfit: Double?; let idempotencyKey: String; let clientOrderId: String?
}

struct V2PlaceOrderResponse: Codable { let success: Bool; let data: V2OrderData }
struct V2OrderData: Codable { let orderId: String; let status: String; let idempotencyKey: String; let riskScore: Double? }

struct ScanResult: Codable, Identifiable {
    let id: String?; let symbol: String; let name: String?; let price: Double
    let change: Double; let changePercent: Double; let volume: Double?; let signal: String?
}

struct HeatmapItem: Codable, Identifiable {
    var id: String { symbol }; let symbol: String; let name: String?
    let change: Double; let volume: Double?
}

struct AIAnalyzeRequest: Codable { let prompt: String; let analysisType: String?; let analysisSymbol: String?; let language: String?; enum CodingKeys: String, CodingKey { case prompt; case analysisType = "type"; case analysisSymbol = "symbol"; case language } }
struct AIAnalyzeResponse: Codable { let analysis: String; let model: String?; let provider: String? }

struct ExchangeCredential: Codable, Identifiable {
    let id: String; let exchange: String; let label: String; let testnet: Bool; let createdAt: String
}

struct UserNotification: Codable, Identifiable {
    let id: String; let type: String; let title: String; let body: String?
    let isRead: Bool; let createdAt: String
}

/// Backend response wrapper: many endpoints return { success: true, data: {...} }
struct ApiResponseWrapper: Codable {
    let success: Bool?
    let data: AnyCodable?
}

/// Type-erased Codable value for dynamic JSON unwrapping
struct AnyCodable: Codable {
    let value: Any
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) { value = int }
        else if let double = try? container.decode(Double.self) { value = double }
        else if let bool = try? container.decode(Bool.self) { value = bool }
        else if let string = try? container.decode(String.self) { value = string }
        else if let array = try? container.decode([AnyCodable].self) { value = array.map { $0.value } }
        else if let dict = try? container.decode([String: AnyCodable].self) { value = dict.mapValues { $0.value } }
        else { value = NSNull() }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let int as Int: try container.encode(int)
        case let double as Double: try container.encode(double)
        case let bool as Bool: try container.encode(bool)
        case let string as String: try container.encode(string)
        case let array as [Any]: try container.encode(array.map { AnyCodable(value: $0) })
        case let dict as [String: Any]: try container.encode(dict.mapValues { AnyCodable(value: $0) })
        default: try container.encodeNil()
        }
    }
    init(value: Any) { self.value = value }
}

enum APIError: LocalizedError {
    case unauthorized; case noConnection; case timeout; case serverError(Int, String); case networkError(String)
    var errorDescription: String? {
        switch self { case .unauthorized: return "Session expired"; case .noConnection: return "No internet"
        case .timeout: return "Timed out"; case .serverError(let c, let m): return "Error \(c): \(m)"
        case .networkError(let m): return m }
    }
}

// MARK: - ═══════════════════════════════════════
// MARK: - API CLIENT
// MARK: - ═══════════════════════════════════════

class APIClient {
    static let shared = APIClient()
    private let session: URLSession
    private let decoder = JSONDecoder()
    
    var sessionToken: String? {
        get { KeychainManager.shared.get(key: "roua_session") }
        set { if let v = newValue { KeychainManager.shared.set(key: "roua_session", value: v) } else { KeychainManager.shared.delete(key: "roua_session") } }
    }
    
    private init() {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = APIConfig.requestTimeout
        c.httpShouldSetCookies = false
        self.session = URLSession(configuration: c)
        // Backend returns camelCase — no conversion needed
        self.decoder.keyDecodingStrategy = .useDefaultKeys
    }
    
    /// Unwrap backend `{ success, data }` wrapper if present
    private func unwrapResponse(_ data: Data) -> Data {
        guard let wrapper = try? decoder.decode(ApiResponseWrapper.self, from: data),
              wrapper.success == true,
              let innerData = wrapper.data else { return data }
        // If the backend wrapped the response in { success, data }, extract the data field
        return try! JSONEncoder().encode(innerData)
    }
    
    func request<T: Codable>(_ path: String, method: String = "GET", body: Encodable? = nil) async throws -> T {
        let url = URL(string: "\(APIConfig.baseURL)\(path)")!
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = sessionToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            req.setValue(token, forHTTPHeaderField: APIConfig.sessionHeader)
        }
        if let body { req.httpBody = try JSONEncoder().encode(body) }
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw APIError.networkError("Invalid response") }
        guard http.statusCode != 401 else { throw APIError.unauthorized }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.serverError(http.statusCode, String(data: data, encoding: .utf8) ?? "Unknown")
        }
        // Try to decode directly first; if that fails, try unwrapping { success, data }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            let unwrapped = unwrapResponse(data)
            return try decoder.decode(T.self, from: unwrapped)
        }
    }
}

// MARK: - ═══════════════════════════════════════
// MARK: - KEYCHAIN
// MARK: - ═══════════════════════════════════════

class KeychainManager {
    static let shared = KeychainManager()
    private let service = "com.roua.trading"
    private init() {}

    func set(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
        var addQuery = query
        addQuery[kSecValueData as String] = data
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    func get(key: String) -> String? {
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
}

// MARK: - ═══════════════════════════════════════
// MARK: - AUTH MANAGER
// MARK: - ═══════════════════════════════════════

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    @Published var isAuthenticated = false
    @Published var currentUser: AuthUser?
    @Published var isLoading = false
    @Published var isGoogleLoading = false
    @Published var isPasskeyLoading = false
    @Published var isOTPLoading = false
    @Published var error: APIError?
    @Published var errorMessage: String?
    @Published var otpSent = false
    private let api = APIClient.shared
    
    func checkExistingSession() {
        guard let _ = KeychainManager.shared.get(key: "roua_session") else { return }
        Task { await validateSession() }
    }
    
    func validateSession() async {
        do {
            let response: AuthVerifyResponse = try await api.request("/auth/me")
            await MainActor.run {
                if response.success, let user = response.user { self.currentUser = user; self.isAuthenticated = true }
                else { self.isAuthenticated = false }
            }
        } catch { await MainActor.run { self.isAuthenticated = false } }
    }
    
    // MARK: - Google Sign-In via ASWebAuthenticationSession
    func signInWithGoogle() async {
        await MainActor.run { isGoogleLoading = true; errorMessage = nil }
        
        let baseURL = "https://roua-trading-production.up.railway.app"
        let googleAuthURL = URL(string: "\(baseURL)/api/auth/signin/google")!
        let callbackScheme = "roua"
        
        do {
            let (url, _) = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(URL, ASWebAuthenticationSession.Callback?), Error>) in
                Task { @MainActor in
                    let session = ASWebAuthenticationSession(
                        url: googleAuthURL,
                        callbackURLScheme: callbackScheme
                    ) { callbackURL, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                            return
                        }
                        guard let callbackURL = callbackURL else {
                            continuation.resume(throwing: NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No callback URL"]))
                            return
                        }
                        continuation.resume(returning: (callbackURL, nil))
                    }
                    session.prefersEphemeralWebBrowserSession = false
                    session.start()
                }
            }
            
            // After Google OAuth, the browser redirects back. But since the backend
            // uses cookie-based sessions, we need to extract the session from cookies.
            // The backend sets a session cookie on callback.
            // Alternative: use the /api/auth/me endpoint to check if we got a session.
            let response: AuthVerifyResponse = try await api.request("/auth/me")
            if response.success, let user = response.user {
                await MainActor.run {
                    self.currentUser = user
                    self.isAuthenticated = true
                    self.isGoogleLoading = false
                }
            } else {
                await MainActor.run {
                    self.errorMessage = "Google login failed - no session"
                    self.isGoogleLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Google login failed: \(error.localizedDescription)"
                self.isGoogleLoading = false
            }
        }
    }
    
    // MARK: - Google Sign-In via SFSafariViewController (opens in-app Safari)
    func signInWithGoogleSafari() {
        guard let url = URL(string: "https://roua-trading-production.up.railway.app/api/auth/signin/google") else { return }
        // We use the share sheet approach - open in Safari, user logs in, then comes back
        UIApplication.shared.open(url)
    }
    
    // MARK: - Passkey / WebAuthn Login
    func signInWithPasskey() async {
        await MainActor.run { isPasskeyLoading = true; errorMessage = nil }
        
        do {
            // Step 1: Get challenge from backend
            let challengeURL = URL(string: "\(APIConfig.baseURL)/auth/challenge?email=passkey@roua.auto")!
            var challengeRequest = URLRequest(url: challengeURL)
            challengeRequest.httpMethod = "GET"
            if let token = APIClient.shared.sessionToken {
                challengeRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                challengeRequest.setValue(token, forHTTPHeaderField: APIConfig.sessionHeader)
            }
            let (challengeData, challengeResponse) = try await URLSession.shared.data(for: challengeRequest)
            guard let httpResp = challengeResponse as? HTTPURLResponse,
                  (200...299).contains(httpResp.statusCode) else {
                throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get passkey challenge"])
            }
            
            struct ChallengeResponse: Codable {
                let challenge: String
                let rpId: String?
                let allowCredentials: [AllowCredential]?
                struct AllowCredential: Codable {
                    let id: String
                    let type: String
                }
            }
            let challengeResp = try JSONDecoder().decode(ChallengeResponse.self, from: challengeData)
            
            // Step 2: Use ASAuthorizationController for Passkey
            let challengeDataBytes = Data(base64Encoded: challengeResp.challenge)
                ?? Data(challengeResp.challenge.utf8)
            
            let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
                relyingPartyIdentifier: challengeResp.rpId ?? "roua-trading-production.up.railway.app"
            )
            
            let request = provider.createCredentialAssertionRequest(challenge: challengeDataBytes)
            
            if let allowCreds = challengeResp.allowCredentials {
                request.allowedCredentials = allowCreds.map { cred in
                    ASAuthorizationPlatformPublicKeyCredentialDescriptor(
                        credentialID: Data(base64Encoded: cred.id) ?? Data(cred.id.utf8),
                        transports: nil
                    )
                }
            }
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            
            let authResult: ASAuthorization = try await withCheckedThrowingContinuation { continuation in
                Task { @MainActor in
                    let delegate = PasskeyAuthDelegate(continuation: continuation)
                    controller.delegate = delegate
                    controller.performRequests()
                    // Keep delegate alive
                    objc_setAssociatedObject(controller, "passkeyDelegate", delegate, .OBJC_ASSOCIATION_RETAIN)
                }
            }
            
            // Step 3: Send assertion to backend for verification
            guard let assertion = authResult.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion else {
                throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid credential type"])
            }
            
            struct PasskeyVerifyRequest: Encodable {
                let credential: PasskeyCredential
                struct PasskeyCredential: Encodable {
                    let id: String
                    let rawId: String
                    let response: PasskeyResponse
                    let type: String
                }
                struct PasskeyResponse: Encodable {
                    let authenticatorData: String
                    let clientDataJSON: String
                    let signature: String
                    let userHandle: String?
                }
            }
            
            let verifyBody = PasskeyVerifyRequest(credential: PasskeyVerifyRequest.PasskeyCredential(
                id: assertion.credentialID.base64EncodedString(),
                rawId: assertion.credentialID.base64EncodedString(),
                response: PasskeyVerifyRequest.PasskeyCredential.PasskeyResponse(
                    authenticatorData: assertion.authenticatorData.base64EncodedString(),
                    clientDataJSON: assertion.clientDataJSON.base64EncodedString(),
                    signature: assertion.signature.base64EncodedString(),
                    userHandle: assertion.userID?.base64EncodedString()
                ),
                type: "public-key"
            ))
            
            var verifyRequest = URLRequest(url: URL(string: "\(APIConfig.baseURL)/auth/passkey/verify")!)
            verifyRequest.httpMethod = "POST"
            verifyRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let token = APIClient.shared.sessionToken {
                verifyRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                verifyRequest.setValue(token, forHTTPHeaderField: APIConfig.sessionHeader)
            }
            verifyRequest.httpBody = try JSONEncoder().encode(verifyBody)
            
            let (_, verifyResponse) = try await URLSession.shared.data(for: verifyRequest)
            guard let verifyHTTP = verifyResponse as? HTTPURLResponse,
                  (200...299).contains(verifyHTTP.statusCode) else {
                throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Passkey verification failed"])
            }
            
            // Step 4: Validate session
            let meResponse: AuthVerifyResponse = try await api.request("/auth/me")
            if meResponse.success, let user = meResponse.user {
                await MainActor.run {
                    self.currentUser = user
                    self.isAuthenticated = true
                    self.isPasskeyLoading = false
                }
            } else {
                await MainActor.run {
                    self.errorMessage = "Passkey login failed"
                    self.isPasskeyLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Passkey failed: \(error.localizedDescription)"
                self.isPasskeyLoading = false
            }
        }
    }
    
    // MARK: - OTP Login
    func sendOTP(email: String) async {
        await MainActor.run { isOTPLoading = true; errorMessage = nil }
        do {
            var request = URLRequest(url: URL(string: "\(APIConfig.baseURL)/auth/otp/send")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(["email": email])
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to send OTP"])
            }
            await MainActor.run { self.otpSent = true; self.isOTPLoading = false }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to send code: \(error.localizedDescription)"
                self.isOTPLoading = false
            }
        }
    }
    
    func verifyOTP(email: String, code: String) async {
        await MainActor.run { isOTPLoading = true; errorMessage = nil }
        do {
            var request = URLRequest(url: URL(string: "\(APIConfig.baseURL)/auth/otp/verify")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(["email": email, "otp": code])
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid code"])
            }
            // Check if authenticated
            struct OTPVerifyResponse: Codable { let authenticated: Bool?; let success: Bool? }
            let otpResp = try? JSONDecoder().decode(OTPVerifyResponse.self, from: data)
            if otpResp?.authenticated == true || otpResp?.success == true {
                // Session is now established via cookies, validate it
                let meResponse: AuthVerifyResponse = try await api.request("/auth/me")
                if meResponse.success, let user = meResponse.user {
                    await MainActor.run {
                        self.currentUser = user
                        self.isAuthenticated = true
                        self.isOTPLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.errorMessage = "Login failed - could not verify session"
                        self.isOTPLoading = false
                    }
                }
            } else {
                await MainActor.run {
                    self.errorMessage = "Invalid verification code"
                    self.isOTPLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Verification failed: \(error.localizedDescription)"
                self.isOTPLoading = false
            }
        }
    }
    
    // MARK: - Direct email login
    func login(email: String) async {
        await MainActor.run { isLoading = true; errorMessage = nil }
        do {
            var request = URLRequest(url: URL(string: "\(APIConfig.baseURL)/auth/me")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(["email": email])
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Login failed"])
            }
            struct MeResponse: Codable { let authenticated: Bool?; let success: Bool?; let user: AuthUser? }
            let meResp = try? JSONDecoder().decode(MeResponse.self, from: data)
            if meResp?.authenticated == true || meResp?.success == true, let user = meResp?.user {
                await MainActor.run {
                    self.currentUser = user
                    self.isAuthenticated = true
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    self.errorMessage = "Login failed - try Google or OTP instead"
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run { self.errorMessage = error.localizedDescription; self.isLoading = false }
        }
    }
    
    func logout() async {
        do { let _: AuthVerifyResponse = try await api.request("/auth/session", method: "DELETE") } catch {}
        await MainActor.run {
            APIClient.shared.sessionToken = nil; KeychainManager.shared.deleteAll()
            currentUser = nil; isAuthenticated = false; otpSent = false
        }
    }
}

// MARK: - Passkey ASAuthorizationController Delegate
private class PasskeyAuthDelegate: NSObject, ASAuthorizationControllerDelegate {
    let continuation: CheckedContinuation<ASAuthorization, Error>
    init(continuation: CheckedContinuation<ASAuthorization, Error>) { self.continuation = continuation }
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation.resume(returning: authorization)
    }
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
    }
}

// MARK: - ═══════════════════════════════════════
// MARK: - VIEWMODELS
// MARK: - ═══════════════════════════════════════

class DashboardViewModel: ObservableObject {
    @Published var portfolioSummary: PortfolioSummary?
    @Published var positions: [Position] = []
    @Published var trades: [Trade] = []
    @Published var isLoading = false
    private let api = APIClient.shared
    
    func loadDashboard() async {
        await MainActor.run { isLoading = true }
        do {
            let portfolio: PortfolioSummary = try await api.request("/trading/v2/portfolio")
            let positions: [Position] = try await api.request("/trading/v2/positions")
            let trades: [Trade] = try await api.request("/trading/history")
            await MainActor.run {
                self.portfolioSummary = portfolio; self.positions = positions
                self.trades = Array(trades.prefix(10)); self.isLoading = false
            }
        } catch { await MainActor.run { isLoading = false } }
    }
}

class TradingViewModel: ObservableObject {
    @Published var symbol = "BTC/USDT"
    @Published var currentQuote: Quote?
    @Published var positions: [Position] = []
    @Published var orderSide = "BUY"
    @Published var orderType = "MARKET"
    @Published var quantity = ""
    @Published var stopLoss = ""
    @Published var takeProfit = ""
    @Published var isPlacingOrder = false
    @Published var orderSuccess: V2PlaceOrderResponse?
    @Published var orderError: String?
    private let api = APIClient.shared
    
    func loadTradingData() async {
        do {
            let quote: Quote = try await api.request("/exchange/quote/\(symbol)")
            let positions: [Position] = try await api.request("/trading/v2/positions")
            await MainActor.run { self.currentQuote = quote; self.positions = positions }
        } catch {}
    }
    
    func placeOrder(credentialId: String) async {
        guard let qty = Double(quantity), qty > 0 else { orderError = "Invalid quantity"; return }
        await MainActor.run { isPlacingOrder = true; orderError = nil }
        let request = PlaceOrderRequest(
            exchangeCredentialId: credentialId, symbol: symbol, side: orderSide, type: orderType,
            quantity: qty, price: nil, stopLoss: Double(stopLoss) ?? 0, takeProfit: Double(takeProfit),
            idempotencyKey: UUID().uuidString, clientOrderId: nil
        )
        do {
            let response: V2PlaceOrderResponse = try await api.request("/trading/v2/orders", method: "POST", body: request)
            await MainActor.run { self.orderSuccess = response; self.isPlacingOrder = false; self.quantity = ""; self.stopLoss = ""; self.takeProfit = "" }
        } catch {
            await MainActor.run { self.orderError = error.localizedDescription; self.isPlacingOrder = false }
        }
    }
}

class AIViewModel: ObservableObject {
    @Published var messages: [(content: String, isUser: Bool, model: String?)] = []
    @Published var inputText = ""
    @Published var isLoading = false
    private let api = APIClient.shared
    
    func sendMessage() async {
        let text = inputText; guard !text.isEmpty else { return }
        inputText = ""
        await MainActor.run { messages.append((content: text, isUser: true, model: nil)); isLoading = true }
        do {
            let request = AIAnalyzeRequest(prompt: text, analysisType: nil, analysisSymbol: nil, language: "ar")
            let response: AIAnalyzeResponse = try await api.request("/ai/analyze", method: "POST", body: request)
            await MainActor.run { messages.append((content: response.analysis, isUser: false, model: response.model)); isLoading = false }
        } catch {
            await MainActor.run { messages.append((content: "Error: \(error.localizedDescription)", isUser: false, model: nil)); isLoading = false }
        }
    }
}

class ScannerViewModel: ObservableObject {
    @Published var results: [ScanResult] = []
    @Published var heatmapData: [HeatmapItem] = []
    @Published var isLoading = false
    private let api = APIClient.shared
    
    func runScan() async {
        await MainActor.run { isLoading = true }
        do {
            let results: [ScanResult] = try await api.request("/scanner/scan")
            let heatmap: [HeatmapItem] = try await api.request("/scanner/heatmap")
            await MainActor.run { self.results = results; self.heatmapData = heatmap; self.isLoading = false }
        } catch { await MainActor.run { isLoading = false } }
    }
}

class PortfolioViewModel: ObservableObject {
    @Published var credentials: [ExchangeCredential] = []
    @Published var totalValue: Double = 0
    private let api = APIClient.shared
    
    func loadData() async {
        do {
            let creds: [ExchangeCredential] = try await api.request("/portfolio/credentials")
            await MainActor.run { self.credentials = creds }
        } catch {}
    }
}

// MARK: - ═══════════════════════════════════════
// MARK: - REUSABLE COMPONENTS
// MARK: - ═══════════════════════════════════════

struct GlassCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content.padding(RouaTheme.Spacing.lg)
            .background(RouaTheme.Colors.glassBackground).background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.lg))
            .overlay(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.lg).stroke(RouaTheme.Colors.glassBorder, lineWidth: 1))
    }
}

struct TradingButton: View {
    let title: String; let style: TradingButtonStyle; let isLoading: Bool; let action: () -> Void
    enum TradingButtonStyle { case buy, sell, primary, secondary, danger }
    private var bgColor: Color {
        switch style { case .buy: return RouaTheme.Colors.profit; case .sell, .danger: return RouaTheme.Colors.loss
        case .primary: return RouaTheme.Colors.accent; case .secondary: return RouaTheme.Colors.surfaceElevated }
    }
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading { ProgressView().tint(.white).controlSize(.small) }
                Text(title).font(.system(size: 14, weight: .semibold))
            }.frame(maxWidth: .infinity).frame(height: 50).foregroundStyle(.white)
            .background(bgColor).clipShape(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md))
        }.disabled(isLoading)
    }
}

struct ChangeBadge: View {
    let value: Double
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: value >= 0 ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill").font(.system(size: 8))
            Text(String(format: "%.2f%%", abs(value))).font(.system(size: 11, weight: .medium, design: .monospaced))
        }.foregroundStyle(value >= 0 ? RouaTheme.Colors.profit : RouaTheme.Colors.loss)
        .padding(.horizontal, 6).padding(.vertical, 3)
        .background(value >= 0 ? RouaTheme.Colors.profitBackground : RouaTheme.Colors.lossBackground)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct PulsingDot: View {
    let color: Color; @State private var isPulsing = false
    init(color: Color = RouaTheme.Colors.profit) { self.color = color }
    var body: some View {
        Circle().fill(color).frame(width: 8, height: 8).scaleEffect(isPulsing ? 1.3 : 1.0).opacity(isPulsing ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isPulsing).onAppear { isPulsing = true }
    }
}

struct ShimmerView: View {
    @State private var isAnimating = false
    var body: some View {
        Rectangle().fill(RouaTheme.Colors.surfaceElevated).frame(height: 20)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(Rectangle().fill(LinearGradient(colors: [.clear, .white.opacity(0.08), .clear], startPoint: .leading, endPoint: .trailing)).offset(x: isAnimating ? 300 : -300))
            .onAppear { withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) { isAnimating = true } }
    }
}

// MARK: - ═══════════════════════════════════════
// MARK: - AUTH VIEW
// MARK: - ═══════════════════════════════════════

struct AuthView: View {
    @ObservedObject var authManager = AuthManager.shared
    @State private var email = ""
    @State private var otpCode = ""
    @State private var authMethod: AuthMethod = .google
    
    enum AuthMethod: String, CaseIterable {
        case google = "Google"
        case passkey = "Passkey"
        case otp = "Email Code"
    }
    
    var body: some View {
        ZStack {
            RouaTheme.Colors.background.ignoresSafeArea()
            Circle().fill(RouaTheme.Colors.accent.opacity(0.05)).frame(width: 400, height: 400).blur(radius: 80).offset(x: -100, y: -200)
            Circle().fill(RouaTheme.Colors.accent.opacity(0.03)).frame(width: 300, height: 300).blur(radius: 60).offset(x: 150, y: 300)
            
            VStack(spacing: RouaTheme.Spacing.lg) {
                Spacer()
                
                // Logo
                VStack(spacing: RouaTheme.Spacing.lg) {
                    ZStack {
                        RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.xl).fill(RouaTheme.Colors.accentGradient).frame(width: 80, height: 80)
                        Image(systemName: "chart.line.uptrend.xyaxis").font(.system(size: 36, weight: .bold)).foregroundStyle(.white)
                    }
                    Text("ROUA TRADING").font(.system(size: 24, weight: .bold, design: .rounded)).foregroundStyle(RouaTheme.Colors.textPrimary).tracking(4)
                    Text("AI-Powered Trading Platform").font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                // Auth Method Picker
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        ForEach(AuthMethod.allCases, id: \.self) { method in
                            Button {
                                withAnimation { authMethod = method }
                            } label: {
                                Text(method.rawValue).font(.system(size: 13, weight: .semibold))
                                    .frame(maxWidth: .infinity).frame(height: 44)
                                    .foregroundStyle(authMethod == method ? .white : RouaTheme.Colors.textTertiary)
                                    .background(authMethod == method ? RouaTheme.Colors.accent : RouaTheme.Colors.surfaceElevated)
                            }
                        }
                    }.clipShape(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md))
                    .padding(.bottom, RouaTheme.Spacing.lg)
                    
                    // Auth Content
                    Group {
                        switch authMethod {
                        case .google:
                            googleSignInView
                        case .passkey:
                            passkeySignInView
                        case .otp:
                            otpSignInView
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: authMethod)
                }
                
                // Error Message
                if let errorMessage = authManager.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(RouaTheme.Colors.loss)
                        Text(errorMessage).font(.system(size: 12)).foregroundStyle(RouaTheme.Colors.loss)
                    }.padding(RouaTheme.Spacing.md).frame(maxWidth: .infinity).background(RouaTheme.Colors.lossBackground)
                    .clipShape(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md))
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill").font(.system(size: 10)).foregroundStyle(RouaTheme.Colors.profit)
                    Text("Secured with WebAuthn & Biometrics").font(.system(size: 10)).foregroundStyle(RouaTheme.Colors.textTertiary)
                }
            }.padding(.horizontal, RouaTheme.Spacing.xl)
        }
    }
    
    // MARK: - Google Sign-In View
    private var googleSignInView: some View {
        VStack(spacing: RouaTheme.Spacing.lg) {
            // Google Button
            Button {
                authManager.signInWithGoogleSafari()
            } label: {
                HStack(spacing: 12) {
                    if authManager.isGoogleLoading {
                        ProgressView().tint(.white).controlSize(.small)
                    } else {
                        // Google "G" SVG
                        Image(systemName: "globe").font(.system(size: 18, weight: .bold)).foregroundStyle(RouaTheme.Colors.accentLight)
                    }
                    Text(authManager.isGoogleLoading ? "Connecting..." : "Sign in with Google")
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity).frame(height: 52)
                .background(RouaTheme.Colors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md))
                .overlay(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md).stroke(RouaTheme.Colors.borderLight, lineWidth: 1))
            }.disabled(authManager.isGoogleLoading)
            
            Text("Fast & secure - use your Google account").font(.system(size: 11)).foregroundStyle(RouaTheme.Colors.textTertiary)
        }
    }
    
    // MARK: - Passkey Sign-In View
    private var passkeySignInView: some View {
        VStack(spacing: RouaTheme.Spacing.lg) {
            Button {
                Task { await authManager.signInWithPasskey() }
            } label: {
                HStack(spacing: 12) {
                    if authManager.isPasskeyLoading {
                        ProgressView().tint(.white).controlSize(.small)
                    } else {
                        Image(systemName: "key.fill").font(.system(size: 18)).foregroundStyle(RouaTheme.Colors.accentLight)
                    }
                    Text(authManager.isPasskeyLoading ? "Verifying..." : "Sign in with Passkey")
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity).frame(height: 52)
                .background(RouaTheme.Colors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md))
                .overlay(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md).stroke(RouaTheme.Colors.borderLight, lineWidth: 1))
            }.disabled(authManager.isPasskeyLoading)
            
            Text("Biometric authentication - no password needed").font(.system(size: 11)).foregroundStyle(RouaTheme.Colors.textTertiary)
        }
    }
    
    // MARK: - OTP Sign-In View
    private var otpSignInView: some View {
        VStack(spacing: RouaTheme.Spacing.lg) {
            // Email Field
            HStack(spacing: RouaTheme.Spacing.md) {
                Image(systemName: "envelope").foregroundStyle(RouaTheme.Colors.textTertiary).frame(width: 20)
                TextField("Email Address", text: $email)
                    .font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textPrimary)
                    .tint(RouaTheme.Colors.accent).textInputAutocapitalization(.never).keyboardType(.emailAddress)
            }.padding(RouaTheme.Spacing.lg).background(RouaTheme.Colors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md))
            
            if authManager.otpSent {
                // OTP Code Field
                HStack(spacing: RouaTheme.Spacing.md) {
                    Image(systemName: "number.circle").foregroundStyle(RouaTheme.Colors.textTertiary).frame(width: 20)
                    TextField("Verification Code", text: $otpCode)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textPrimary)
                        .tint(RouaTheme.Colors.accent).keyboardType(.numberPad)
                }.padding(RouaTheme.Spacing.lg).background(RouaTheme.Colors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md))
                
                TradingButton(title: "Verify Code", style: .primary, isLoading: authManager.isOTPLoading) {
                    Task { await authManager.verifyOTP(email: email, code: otpCode) }
                }
            } else {
                TradingButton(title: "Send Verification Code", style: .primary, isLoading: authManager.isOTPLoading) {
                    Task { await authManager.sendOTP(email: email) }
                }
            }
            
            Text("We will send a code to your email").font(.system(size: 11)).foregroundStyle(RouaTheme.Colors.textTertiary)
        }
    }
}

// MARK: - ═══════════════════════════════════════
// MARK: - DASHBOARD VIEW
// MARK: - ═══════════════════════════════════════

struct DashboardView: View {
    @StateObject private var vm = DashboardViewModel()
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaTheme.Spacing.lg) {
                // Portfolio Summary
                GlassCard {
                    VStack(spacing: RouaTheme.Spacing.md) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Portfolio Value").font(.system(size: 10, weight: .medium)).foregroundStyle(RouaTheme.Colors.textTertiary).textCase(.uppercase)
                                if let p = vm.portfolioSummary {
                                    Text(String(format: "$%.2f", p.totalValue)).font(.system(size: 20, weight: .bold, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textPrimary)
                                } else { ShimmerView() }
                            }
                            Spacer()
                            PulsingDot()
                        }
                        HStack(spacing: RouaTheme.Spacing.lg) {
                            StatMini(title: "Daily P&L", value: vm.portfolioSummary.map { String(format: "$%.2f", $0.dailyPnl) } ?? "---", isPositive: (vm.portfolioSummary?.dailyPnl ?? 0) >= 0)
                            StatMini(title: "Positions", value: "\(vm.positions.count)")
                            StatMini(title: "Total P&L", value: vm.portfolioSummary.map { String(format: "$%.2f", $0.totalPnl) } ?? "---", isPositive: (vm.portfolioSummary?.totalPnl ?? 0) >= 0)
                        }
                    }
                }
                
                // Active Positions
                Text("Active Positions").font(.system(size: 16, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                
                if vm.positions.isEmpty {
                    GlassCard {
                        Text("No open positions").font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textSecondary).frame(maxWidth: .infinity)
                    }
                } else {
                    ForEach(vm.positions) { pos in
                        GlassCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Circle().fill(pos.side == "BUY" ? RouaTheme.Colors.profit : RouaTheme.Colors.loss).frame(width: 8, height: 8)
                                        Text(pos.symbol).font(.system(size: 14, weight: .medium)).foregroundStyle(RouaTheme.Colors.textPrimary)
                                        Text(pos.side).font(.system(size: 10, weight: .medium)).foregroundStyle(pos.side == "BUY" ? RouaTheme.Colors.profit : RouaTheme.Colors.loss)
                                    }
                                    Text("Qty: \(String(format: "%.4f", pos.quantity))").font(.system(size: 11, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textTertiary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    if let pnl = pos.unrealizedPnl { Text(String(format: "%+.2f", pnl)).font(.system(size: 16, weight: .semibold, design: .monospaced)).foregroundStyle(pnl >= 0 ? RouaTheme.Colors.profit : RouaTheme.Colors.loss) }
                                    Text("Entry: \(String(format: "%.2f", pos.entryPrice))").font(.system(size: 11, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textTertiary)
                                }
                            }
                        }
                    }
                }
            }.padding(.horizontal, RouaTheme.Spacing.lg)
        }.background(RouaTheme.Colors.background).refreshable { await vm.loadDashboard() }
        .task { await vm.loadDashboard() }
    }
}

struct StatMini: View {
    let title: String; let value: String; var isPositive: Bool? = nil
    var body: some View {
        VStack(spacing: 2) {
            Text(title).font(.system(size: 10, weight: .medium)).foregroundStyle(RouaTheme.Colors.textTertiary)
            Text(value).font(.system(size: 13, design: .monospaced)).foregroundStyle(
                isPositive == true ? RouaTheme.Colors.profit : isPositive == false ? RouaTheme.Colors.loss : RouaTheme.Colors.textPrimary
            )
        }.padding(.horizontal, 8).padding(.vertical, 4).background(RouaTheme.Colors.surfaceElevated).clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - ═══════════════════════════════════════
// MARK: - TRADING VIEW
// MARK: - ═══════════════════════════════════════

struct TradingView: View {
    @StateObject private var vm = TradingViewModel()
    @State private var showOrderSheet = false
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.symbol).font(.system(size: 22, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary)
                    if let q = vm.currentQuote {
                        HStack(spacing: 4) {
                            Text(String(format: "%.2f", q.last ?? 0)).font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textPrimary)
                            if let ch = q.changePercent { ChangeBadge(value: ch) }
                        }
                    }
                }
                Spacer()
                HStack(spacing: 8) {
                    Button { vm.orderSide = "BUY"; showOrderSheet = true } label: {
                        Text("Buy").font(.system(size: 14, weight: .semibold)).foregroundStyle(.white).frame(width: 70, height: 36)
                            .background(RouaTheme.Colors.buyGradient).clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    Button { vm.orderSide = "SELL"; showOrderSheet = true } label: {
                        Text("Sell").font(.system(size: 14, weight: .semibold)).foregroundStyle(.white).frame(width: 70, height: 36)
                            .background(RouaTheme.Colors.sellGradient).clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }.padding(.horizontal, RouaTheme.Spacing.lg).padding(.vertical, RouaTheme.Spacing.md)
            
            // Chart placeholder
            ZStack {
                RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md).fill(RouaTheme.Colors.surface).frame(height: 200)
                Image(systemName: "chart.line.uptrend.xyaxis").font(.system(size: 40)).foregroundStyle(RouaTheme.Colors.textTertiary)
            }.padding(.horizontal, RouaTheme.Spacing.lg)
            
            // Positions
            ScrollView {
                VStack(spacing: RouaTheme.Spacing.md) {
                    Text("Open Positions").font(.system(size: 16, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, RouaTheme.Spacing.lg)
                    ForEach(vm.positions) { pos in
                        GlassCard {
                            HStack {
                                Text(pos.symbol).font(.system(size: 14, weight: .medium)).foregroundStyle(RouaTheme.Colors.textPrimary)
                                Spacer()
                                Text(pos.side).foregroundStyle(pos.side == "BUY" ? RouaTheme.Colors.profit : RouaTheme.Colors.loss)
                                if let pnl = pos.unrealizedPnl { Text(String(format: "%+.2f", pnl)).font(.system(size: 13, design: .monospaced)).foregroundStyle(pnl >= 0 ? RouaTheme.Colors.profit : RouaTheme.Colors.loss) }
                            }
                        }
                    }
                }.padding(RouaTheme.Spacing.lg)
            }
        }.background(RouaTheme.Colors.background).task { await vm.loadTradingData() }
        .sheet(isPresented: $showOrderSheet) { OrderSheet(vm: vm) }
    }
}

struct OrderSheet: View {
    @ObservedObject var vm: TradingViewModel
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: RouaTheme.Spacing.lg) {
                    // Buy/Sell Toggle
                    HStack(spacing: 0) {
                        Button { vm.orderSide = "BUY" } label: { Text("Buy").font(.system(size: 14, weight: .semibold)).frame(maxWidth: .infinity).frame(height: 44).foregroundStyle(vm.orderSide == "BUY" ? .white : RouaTheme.Colors.textTertiary).background(vm.orderSide == "BUY" ? RouaTheme.Colors.profit : RouaTheme.Colors.surfaceElevated) }
                        Button { vm.orderSide = "SELL" } label: { Text("Sell").font(.system(size: 14, weight: .semibold)).frame(maxWidth: .infinity).frame(height: 44).foregroundStyle(vm.orderSide == "SELL" ? .white : RouaTheme.Colors.textTertiary).background(vm.orderSide == "SELL" ? RouaTheme.Colors.loss : RouaTheme.Colors.surfaceElevated) }
                    }.clipShape(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md))
                    
                    // Quantity
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quantity").font(.system(size: 12, weight: .medium)).foregroundStyle(RouaTheme.Colors.textSecondary)
                        TextField("0.00", text: $vm.quantity).font(.system(size: 16, weight: .semibold, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textPrimary).keyboardType(.decimalPad).padding().background(RouaTheme.Colors.surfaceElevated).clipShape(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md))
                    }
                    
                    // Stop Loss
                    VStack(alignment: .leading, spacing: 4) {
                        HStack { Text("Stop Loss").font(.system(size: 12, weight: .medium)).foregroundStyle(RouaTheme.Colors.textSecondary); Text("(Required)").font(.system(size: 10)).foregroundStyle(RouaTheme.Colors.loss) }
                        TextField("0.00", text: $vm.stopLoss).font(.system(size: 16, weight: .semibold, design: .monospaced)).foregroundStyle(RouaTheme.Colors.loss).keyboardType(.decimalPad).padding().background(RouaTheme.Colors.surfaceElevated).clipShape(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md))
                    }
                    
                    // Take Profit
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Take Profit").font(.system(size: 12, weight: .medium)).foregroundStyle(RouaTheme.Colors.textSecondary)
                        TextField("0.00", text: $vm.takeProfit).font(.system(size: 16, weight: .semibold, design: .monospaced)).foregroundStyle(RouaTheme.Colors.profit).keyboardType(.decimalPad).padding().background(RouaTheme.Colors.surfaceElevated).clipShape(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md))
                    }
                    
                    if let err = vm.orderError {
                        Text(err).font(.system(size: 12)).foregroundStyle(RouaTheme.Colors.loss).padding().frame(maxWidth: .infinity, alignment: .leading).background(RouaTheme.Colors.lossBackground).clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    if let ok = vm.orderSuccess {
                        Text("Order placed! ID: \(ok.data.orderId)").font(.system(size: 12)).foregroundStyle(RouaTheme.Colors.profit).padding().frame(maxWidth: .infinity, alignment: .leading).background(RouaTheme.Colors.profitBackground).clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    TradingButton(title: "\(vm.orderSide == "BUY" ? "Buy" : "Sell") \(vm.symbol)", style: vm.orderSide == "BUY" ? .buy : .sell, isLoading: vm.isPlacingOrder) {
                        Task { await vm.placeOrder(credentialId: "paper-trading") }
                    }
                }.padding(RouaTheme.Spacing.lg)
            }.background(RouaTheme.Colors.background).navigationTitle("Place Order").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Cancel") { dismiss() }.foregroundStyle(RouaTheme.Colors.textSecondary) } }
        }
    }
}

// MARK: - ═══════════════════════════════════════
// MARK: - AI CHAT VIEW
// MARK: - ═══════════════════════════════════════

struct AIChatView: View {
    @StateObject private var vm = AIViewModel()
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: RouaTheme.Spacing.md) {
                        ForEach(vm.messages.indices, id: \.self) { i in
                            let msg = vm.messages[i]
                            HStack {
                                if msg.isUser { Spacer(minLength: 60) }
                                Text(msg.content).font(.system(size: 14)).foregroundStyle(msg.isUser ? .white : RouaTheme.Colors.textPrimary)
                                    .padding(RouaTheme.Spacing.md).background(msg.isUser ? RouaTheme.Colors.accent : RouaTheme.Colors.surfaceElevated)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                if !msg.isUser { Spacer(minLength: 60) }
                            }.id(i)
                        }
                        if vm.isLoading { Text("AI is thinking...").font(.system(size: 12)).foregroundStyle(RouaTheme.Colors.textTertiary).padding(.leading, 16) }
                    }.padding(RouaTheme.Spacing.lg)
                }.onChange(of: vm.messages.count) { _, _ in withAnimation { proxy.scrollTo(vm.messages.count - 1, anchor: .bottom) } }
            }
            
            HStack(spacing: RouaTheme.Spacing.md) {
                TextField("Ask AI...", text: $vm.inputText).font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textPrimary).tint(RouaTheme.Colors.accent).submitLabel(.send).onSubmit { Task { await vm.sendMessage() } }
                Button { Task { await vm.sendMessage() } } label: { Image(systemName: "arrow.up.circle.fill").font(.system(size: 32)).foregroundStyle(vm.inputText.isEmpty ? RouaTheme.Colors.textTertiary : RouaTheme.Colors.accent) }
                .disabled(vm.inputText.isEmpty || vm.isLoading)
            }.padding(RouaTheme.Spacing.md).background(RouaTheme.Colors.surface).clipShape(RoundedRectangle(cornerRadius: 16)).padding(.horizontal, RouaTheme.Spacing.lg).padding(.vertical, RouaTheme.Spacing.sm)
        }.background(RouaTheme.Colors.background).navigationTitle("AI Assistant")
    }
}

// MARK: - ═══════════════════════════════════════
// MARK: - SCANNER VIEW
// MARK: - ═══════════════════════════════════════

struct ScannerView: View {
    @StateObject private var vm = ScannerViewModel()
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaTheme.Spacing.lg) {
                Text("Market Scanner").font(.system(size: 22, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                ForEach(vm.results) { r in
                    GlassCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(r.symbol).font(.system(size: 14, weight: .medium)).foregroundStyle(RouaTheme.Colors.textPrimary)
                                if let n = r.name { Text(n).font(.system(size: 12)).foregroundStyle(RouaTheme.Colors.textTertiary).lineLimit(1) }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(String(format: "%.2f", r.price)).font(.system(size: 13, weight: .semibold, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textPrimary)
                                ChangeBadge(value: r.changePercent)
                            }
                        }
                    }
                }
            }.padding(RouaTheme.Spacing.lg)
        }.background(RouaTheme.Colors.background).task { await vm.runScan() }.refreshable { await vm.runScan() }
    }
}

// MARK: - ═══════════════════════════════════════
// MARK: - PORTFOLIO VIEW
// MARK: - ═══════════════════════════════════════

struct PortfolioView: View {
    @StateObject private var vm = PortfolioViewModel()
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaTheme.Spacing.lg) {
                Text("Portfolio").font(.system(size: 22, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                GlassCard {
                    VStack(spacing: RouaTheme.Spacing.md) {
                        Text("Exchange Accounts").font(.system(size: 16, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                        ForEach(vm.credentials) { cred in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(cred.label).font(.system(size: 14, weight: .medium)).foregroundStyle(RouaTheme.Colors.textPrimary)
                                    Text(cred.exchange.uppercased()).font(.system(size: 10)).foregroundStyle(RouaTheme.Colors.textTertiary)
                                }
                                Spacer()
                                if cred.testnet { Text("TESTNET").font(.system(size: 10, weight: .medium)).foregroundStyle(RouaTheme.Colors.warning).padding(.horizontal, 8).padding(.vertical, 3).background(RouaTheme.Colors.warningBackground).clipShape(Capsule()) }
                            }.padding(.vertical, 4)
                        }
                    }
                }
            }.padding(RouaTheme.Spacing.lg)
        }.background(RouaTheme.Colors.background).task { await vm.loadData() }
    }
}

// MARK: - ═══════════════════════════════════════
// MARK: - SETTINGS VIEW
// MARK: - ═══════════════════════════════════════

struct SettingsView: View {
    @ObservedObject var authManager = AuthManager.shared
    @State private var biometricEnabled = true
    @State private var pushEnabled = true
    @State private var showLogout = false
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaTheme.Spacing.lg) {
                Text("Settings").font(.system(size: 22, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                GlassCard {
                    HStack(spacing: RouaTheme.Spacing.lg) {
                        ZStack { Circle().fill(RouaTheme.Colors.accentGradient).frame(width: 56, height: 56); Image(systemName: "person.fill").font(.system(size: 24)).foregroundStyle(.white) }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authManager.currentUser?.displayName ?? "Trader").font(.system(size: 16, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary)
                            Text(authManager.currentUser?.email ?? "").font(.system(size: 12)).foregroundStyle(RouaTheme.Colors.textSecondary)
                        }
                    }
                }
                GlassCard {
                    VStack(spacing: RouaTheme.Spacing.md) {
                        Toggle(isOn: $biometricEnabled) { Text("Biometric Unlock").font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textPrimary) }.tint(RouaTheme.Colors.accent)
                        Toggle(isOn: $pushEnabled) { Text("Push Notifications").font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textPrimary) }.tint(RouaTheme.Colors.accent)
                    }
                }
                TradingButton(title: "Sign Out", style: .danger, isLoading: false) { showLogout = true }
                .alert("Sign Out", isPresented: $showLogout) { Button("Sign Out", role: .destructive) { Task { await authManager.logout() } }; Button("Cancel", role: .cancel) {} }
            }.padding(RouaTheme.Spacing.lg)
        }.background(RouaTheme.Colors.background)
    }
}

// MARK: - ═══════════════════════════════════════
// MARK: - TAB BAR & NAVIGATION
// MARK: - ═══════════════════════════════════════

struct TabBarView: View {
    @State private var selectedTab = 0
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case 0: NavigationStack { DashboardView() }
                case 1: NavigationStack { TradingView() }
                case 2: NavigationStack { AIChatView() }
                case 3: NavigationStack { PortfolioView() }
                case 4: NavigationStack { SettingsView() }
                default: EmptyView()
                }
            }.padding(.bottom, 80)
            
            VStack(spacing: 0) {
                Divider().background(RouaTheme.Colors.border)
                HStack {
                    ForEach(0..<5) { i in
                        tabItem(i)
                    }
                }.padding(.horizontal, RouaTheme.Spacing.md).padding(.top, RouaTheme.Spacing.sm).padding(.bottom, RouaTheme.Spacing.lg)
                .background(RouaTheme.Colors.surface.opacity(0.95)).background(.ultraThinMaterial)
            }
        }.background(RouaTheme.Colors.background)
    }
    
    private let tabs = [("Dashboard", "square.grid.2x2"), ("Trade", "chart.line.uptrend.xyaxis"), ("AI", "brain"), ("Portfolio", "wallet.pass"), ("Settings", "gearshape")]
    
    private func tabItem(_ index: Int) -> some View {
        Button { withAnimation(.easeInOut(duration: 0.2)) { selectedTab = index } } label: {
            VStack(spacing: 4) {
                Image(systemName: tabs[index].1).font(.system(size: 20)).foregroundStyle(selectedTab == index ? RouaTheme.Colors.accent : RouaTheme.Colors.textTertiary)
                Text(tabs[index].0).font(.system(size: 10, weight: .medium)).foregroundStyle(selectedTab == index ? RouaTheme.Colors.accent : RouaTheme.Colors.textTertiary)
            }.frame(maxWidth: .infinity)
        }
    }
}
