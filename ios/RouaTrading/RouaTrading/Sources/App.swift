import SwiftUI
import Security
import Foundation
import AuthenticationServices

// MARK: - ═══════════════════════════════════════
// MARK: - APP ENTRY
// MARK: - ═══════════════════════════════════════

@main
struct RouaTradingApp: App {
    @StateObject private var authManager = AuthManager.shared
    @AppStorage("appLanguage") private var appLanguage = "ar"
    
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
            .environment(\.layoutDirection, appLanguage == "ar" ? .rightToLeft : .leftToRight)
            .environment(\.locale, Locale(identifier: appLanguage))
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
struct AuthVerifyResponse: Codable {
    let authenticated: Bool?
    let success: Bool?
    let user: AuthUser?
    let error: String?
    let message: String?
    /// Returns true if either authenticated or success is true and user exists
    var isValid: Bool { (authenticated == true || success == true) && user != nil }
}
struct AuthRegisterRequest: Codable { let email: String; let displayName: String? }

struct Quote: Codable {
    let symbol: String; let bid: Double?; let ask: Double?; let last: Double?
    let open: Double?; let high: Double?; let low: Double?; let close: Double?
    let volume: Double?; let change: Double?; let changePercent: Double?; let timestamp: String?
}

struct Position: Codable, Identifiable {
    let id: String
    let symbol: String
    let side: String
    let quantity: Double
    let entryPrice: Double
    let currentPrice: Double?
    let unrealizedPnL: Double?
    let stopLoss: Double?
    let takeProfit: Double?
    let exchange: String?
    let openedAt: String?
    let userId: String?
    let credentialId: String?
    let status: String?
    let realizedPnl: Double?
    let source: String?
    let createdAt: String?
    let updatedAt: String?
    /// Computed property for view compatibility
    var unrealizedPnl: Double? { unrealizedPnL }
}

struct Trade: Codable, Identifiable {
    let id: String
    let symbol: String
    let side: String
    let entryPrice: Double?
    let exitPrice: Double?
    let qty: Double?
    let realizedPnl: Double?
    let realizedPct: Double?
    let closeTime: Double?
    let status: String?
    let type: String?
    /// Computed for view compatibility
    var quantity: Double { qty ?? 0 }
    var price: Double { exitPrice ?? entryPrice ?? 0 }
    var pnl: Double? { realizedPnl }
    var createdAt: String {
        if let ct = closeTime {
            let date = Date(timeIntervalSince1970: ct / 1000)
            let formatter = ISO8601DateFormatter()
            return formatter.string(from: date)
        }
        return ""
    }
}

struct PortfolioSummary: Codable {
    let totalBalance: Double?
    let dailyPnL: Double?
    let dailyPnLPercent: Double?
    let totalExposure: Double?
    let usedMargin: Double?
    let openPositionsCount: Int?
    let maxDrawdownPercent: Double?
    let unrealizedPnL: Double?
    let positions: [Position]?
    /// Computed for view compatibility
    var totalValue: Double { totalBalance ?? 0 }
    var dailyPnl: Double { dailyPnL ?? 0 }
    var totalPnl: Double { unrealizedPnL ?? 0 }
    var unrealizedPnl: Double? { unrealizedPnL }
    var realizedPnl: Double? { nil }
}

struct PlaceOrderRequest: Codable {
    let exchangeCredentialId: String; let symbol: String; let side: String
    let type: String; let quantity: Double; let price: Double?; let stopLoss: Double
    let takeProfit: Double?; let idempotencyKey: String; let clientOrderId: String?
}

struct V2PlaceOrderResponse: Codable { let success: Bool; let data: V2OrderData }
struct V2OrderData: Codable { let orderId: String; let status: String; let idempotencyKey: String; let riskScore: Double? }

struct ScanResult: Codable, Identifiable {
    let id: String?
    let symbol: String
    let name: String?
    let price: Double?
    let change: Double?
    let changePercent: Double?
    let volume: Double?
    let signal: String?
    let direction: String?
    let technicalScore: Double?
    let confidence: Double?
    let rsi: Double?
    let category: String?
}

struct HeatmapItem: Codable, Identifiable {
    var id: String { symbol }
    let symbol: String
    let name: String?
    let changePercent: Double?
    let volume: Double?
    let change: Double? { changePercent }
    let direction: String?
    let technicalScore: Double?
    let category: String?
}

struct AIAnalyzeRequest: Codable { let prompt: String; let analysisType: String?; let analysisSymbol: String?; let language: String?; enum CodingKeys: String, CodingKey { case prompt; case analysisType = "type"; case analysisSymbol = "symbol"; case language } }
struct AIAnalyzeResponse: Codable { let analysis: String; let model: String?; let provider: String? }

struct ExchangeCredential: Codable, Identifiable {
    let id: String
    let exchange: String
    let label: String
    let isValid: Bool?
    let permissions: String?
    let lastValidatedAt: String?
    let createdAt: String?
    let updatedAt: String?
    /// Computed for view compatibility
    var testnet: Bool { exchange.lowercased().contains("testnet") || exchange.lowercased().contains("paper") }
}

struct UserNotification: Codable, Identifiable {
    let id: String; let type: String; let title: String; let body: String?
    let isRead: Bool; let createdAt: String
}

// MARK: - NEW MODELS

struct Signal: Codable, Identifiable {
    let id: String; let pair: String; let direction: String?
    let entryPrice: Double?; let stopLoss: Double?; let takeProfit: Double?
    let confidence: Double?; let status: String?; let createdAt: String?
}

struct ExecutorStatus: Codable {
    let active: Bool?; let status: String?; let mode: String?
    let startedAt: String?; let tradesExecuted: Int?; let pnl: Double?
}

struct ExecutorExposure: Codable {
    let totalExposure: Double?; let maxExposure: Double?
    let positions: Int?; let currency: String?
}

struct TradingBrief: Codable, Identifiable {
    let id: String; let symbol: String; let title: String?
    let summary: String?; let action: String?; let confidence: Double?
    let createdAt: String?
}

struct AgentStatus: Codable {
    let running: Bool?; let strategy: String?; let startedAt: String?
    let tradesCount: Int?; let pnl: Double?; let status: String?
}

struct AgentSettings: Codable {
    let maxPositionSize: Double?; let riskLevel: String?
    let autoExecute: Bool?; let allowedPairs: [String]?
}

struct AgentPerformance: Codable {
    let totalTrades: Int?; let winRate: Double?; let totalPnl: Double?
    let sharpeRatio: Double?; let maxDrawdown: Double?
}

struct NewsArticle: Codable, Identifiable {
    let id: String; let title: String; let summary: String?
    let source: String?; let url: String?; let sentiment: String?
    let publishedAt: String?
}

struct MarketSentiment: Codable {
    let overall: String?; let score: Double?; let fearGreedIndex: Int?
}

struct ScannerOverview: Codable {
    let totalScanned: Int?
    let bullishCount: Int?
    let bearishCount: Int?
    let neutralCount: Int?
    let topGainers: [HeatmapItem]?
    let topLosers: [HeatmapItem]?
    let strongestSignals: [ScanResult]?
    let marketSentiment: String?
    let sentimentScore: Int?
    /// Computed for view compatibility
    var bullish: Int? { bullishCount }
    var bearish: Int? { bearishCount }
    var neutral: Int? { neutralCount }
    var topGainer: String? { topGainers?.first?.symbol }
    var topLoser: String? { topLosers?.first?.symbol }
}

struct SymbolAnalysis: Codable {
    let symbol: String; let price: Double?; let change: Double?
    let recommendation: String?; let confidence: Double?
    let support: Double?; let resistance: Double?
}

struct AIModel: Codable, Identifiable {
    var id: String { name }
    let name: String
    let provider: String?
    let available: Bool?
    let model: String?
    var active: Bool? { available }
}

struct AIProviderInfo: Codable {
    let available: Bool?
    let model: String?
}

struct AIConsensusRequest: Codable { let prompt: String; let models: [String]? }
struct AIConsensusResponse: Codable { let consensus: String?; let analyses: [String: String]? }

struct NeuralPredictRequest: Codable { let symbol: String; let horizon: String? }
struct NeuralPredictResponse: Codable { let prediction: Double?; let confidence: Double?; let direction: String?; let model: String? }

struct NeuralBacktestRequest: Codable { let symbol: String; let strategy: String; let startDate: String; let endDate: String }
struct NeuralBacktestResponse: Codable { let totalReturn: Double?; let sharpeRatio: Double?; let maxDrawdown: Double?; let trades: Int? }

struct NewsAnalyzeRequest: Codable { let url: String?; let text: String? }
struct NewsAnalyzeResponse: Codable { let sentiment: String?; let score: Double?; let summary: String? }

struct NotificationPreferences: Codable {
    let pushEnabled: Bool?; let emailEnabled: Bool?
    let tradeAlerts: Bool?; let signalAlerts: Bool?; let newsAlerts: Bool?
}

struct UnreadCount: Codable { let count: Int? }

struct CredentialBalance: Codable, Identifiable {
    var id: String { credentialId }
    let credentialId: String
    let exchange: String?
    let totalBalance: Double?
    let availableBalance: Double?
    let currency: String?
}

struct BalancesResponse: Codable {
    let totalEquityUsd: Double?
    let totalAvailableUsd: Double?
    let totalUsedMargin: Double?
    let exchanges: [ExchangeBalance]?
    let allRealExchangesFailed: Bool?
    let hasRealCredentials: Bool?
}

struct ExchangeBalance: Codable, Identifiable {
    var id: String { credentialId ?? UUID().uuidString }
    let exchange: String?
    let label: String?
    let credentialId: String?
    let isTestnet: Bool?
    let equity: Double?
    let available: Double?
    let currency: String?
    let usedMargin: Double?
}

struct SanctuaryInfo: Codable {
    let enabled: Bool?; let riskScore: Double?; let protectedAmount: Double?
    let stopLossEnabled: Bool?; let maxDrawdown: Double?
}

struct V2Order: Codable, Identifiable {
    let id: String
    let symbol: String
    let side: String
    let type: String
    let quantity: Double
    let price: Double?
    let status: String?
    let createdAt: String?
    let stopLoss: Double?
    let takeProfit: Double?
    let filledQuantity: Double?
    let averagePrice: Double?
    let fee: Double?
    let feeCurrency: String?
    let exchangeOrderId: String?
}

struct AccountInfo: Codable {
    let balance: Double?; let equity: Double?; let availableMargin: Double?
    let unrealizedPnl: Double?; let currency: String?
}

struct ExchangeAdapter: Codable, Identifiable {
    var id: String { name }; let name: String; let enabled: Bool?
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

class APIClient: @unchecked Sendable {
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
    }
    
    /// Raw request returning raw Data
    func rawRequest(_ path: String, method: String = "GET", bodyData: Data? = nil) async throws -> Data {
        let urlString = "\(APIConfig.baseURL)\(path)"
        guard let url = URL(string: urlString) else {
            throw APIError.networkError("Invalid URL: \(urlString)")
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = sessionToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            req.setValue(token, forHTTPHeaderField: APIConfig.sessionHeader)
        }
        if let bodyData { req.httpBody = bodyData }
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw APIError.networkError("Invalid response") }
        print("[API] \(method) \(path) -> \(http.statusCode)")
        guard http.statusCode != 401 else { throw APIError.unauthorized }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown"
            print("[API] Error body: \(body.prefix(500))")
            throw APIError.serverError(http.statusCode, body)
        }
        return data
    }
    
    /// Request that auto-unwraps { success: true, data: T } responses
    func request<T: Codable>(_ path: String, method: String = "GET", bodyData: Data? = nil) async throws -> T {
        let data = try await rawRequest(path, method: method, bodyData: bodyData)
        // Try direct decode first
        if let result = try? JSONDecoder().decode(T.self, from: data) {
            return result
        }
        // Try unwrapping { success, data } wrapper
        let wrapper = try JSONDecoder().decode(ApiResponseWrapper.self, from: data)
        if let innerData = wrapper.data {
            let innerJson = try JSONEncoder().encode(innerData)
            if let result = try? JSONDecoder().decode(T.self, from: innerJson) {
                return result
            }
        }
        // Try extracting from JSON dynamically
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let reData = try JSONSerialization.data(withJSONObject: json)
            if let result = try? JSONDecoder().decode(T.self, from: reData) {
                return result
            }
        }
        print("[API] Failed to decode response from \(path): \(String(data: data, encoding: .utf8)?.prefix(500) ?? "nil")")
        throw APIError.networkError("Failed to decode response")
    }
    
    /// Request that extracts a specific key from the response JSON
    func request<T: Codable>(_ path: String, key: String, method: String = "GET", bodyData: Data? = nil) async throws -> T {
        let data = try await rawRequest(path, method: method, bodyData: bodyData)
        // Try extracting the specific key from the JSON
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let value = json[key] {
            let valueData = try JSONSerialization.data(withJSONObject: value)
            if let result = try? JSONDecoder().decode(T.self, from: valueData) {
                return result
            }
        }
        // Fallback: try unwrapping { success, data } first, then extract key
        if let wrapper = try? JSONDecoder().decode(ApiResponseWrapper.self, from: data),
           let innerData = wrapper.data,
           let innerDict = innerData.value as? [String: Any],
           let value = innerDict[key] {
            let valueData = try JSONSerialization.data(withJSONObject: value)
            if let result = try? JSONDecoder().decode(T.self, from: valueData) {
                return result
            }
        }
        // Final fallback: direct decode
        if let result = try? JSONDecoder().decode(T.self, from: data) {
            return result
        }
        print("[API] Failed to decode key '\(key)' from \(path): \(String(data: data, encoding: .utf8)?.prefix(500) ?? "nil")")
        throw APIError.networkError("Failed to decode response for key '\(key)'")
    }
}

// MARK: - Encoding Helper
extension APIClient {
    func request<T: Codable, B: Encodable>(_ path: String, method: String = "GET", body: B) async throws -> T {
        return try await request(path, method: method, bodyData: try JSONEncoder().encode(body))
    }
}
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

@MainActor
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
    private var webAuthSession: ASWebAuthenticationSession?
    private var webAuthPresenter: WebAuthPresenter?
    
    func checkExistingSession() {
        guard let _ = KeychainManager.shared.get(key: "roua_session") else { return }
        Task { await validateSession() }
    }
    
    func validateSession() async {
        do {
            let response: AuthVerifyResponse = try await api.request("/auth/me")
            if response.isValid, let user = response.user { self.currentUser = user; self.isAuthenticated = true }
            else { self.isAuthenticated = false }
        } catch { self.isAuthenticated = false }
    }
    
    func signInWithGoogle() {
        isGoogleLoading = true; errorMessage = nil

        // Build the Google auth URL with app_redirect_uri parameter.
        // The backend will redirect to roua://auth/callback?token=SESSION_TOKEN
        // after successful Google auth, which ASWebAuthenticationSession captures.
        var components = URLComponents(string: "\(APIConfig.baseURL)/auth/signin/google")!
        components.queryItems = [
            URLQueryItem(name: "app_redirect_uri", value: "roua://auth/callback")
        ]
        guard let googleAuthURL = components.url else {
            errorMessage = "Invalid Google auth URL"
            isGoogleLoading = false
            return
        }

        // ALWAYS provide presentationContextProvider — without it on iOS 13+
        // the session immediately cancels with error code 2 (canceledLogin)
        let presenter = Self.findPresentationWindow()

        let session = ASWebAuthenticationSession(url: googleAuthURL, callbackURLScheme: "roua") { [weak self] callbackURL, error in
            Task { @MainActor in
                guard let self = self else { return }
                self.webAuthSession = nil
                self.webAuthPresenter = nil

                if let error = error {
                    let nsError = error as NSError
                    if nsError.domain == ASWebAuthenticationSessionErrorDomain && nsError.code == 2 {
                        self.errorMessage = "Google login was cancelled"
                    } else {
                        self.errorMessage = "Google login failed: \(error.localizedDescription)"
                    }
                    self.isGoogleLoading = false
                    return
                }
                guard let callbackURL = callbackURL else {
                    self.errorMessage = "No callback URL received"
                    self.isGoogleLoading = false
                    return
                }
                self.handleGoogleCallback(callbackURL)
            }
        }
        session.prefersEphemeralWebBrowserSession = false
        session.presentationContextProvider = presenter

        // Retain BOTH the session AND the presenter
        self.webAuthSession = session
        self.webAuthPresenter = presenter
        session.start()
    }

    /// Process the roua://auth/callback?token=xxx URL from ASWebAuthenticationSession
    func handleGoogleCallback(_ url: URL) {
        // Extract session token from callback URL
        // Backend sends: roua://auth/callback?token=SESSION_TOKEN&refresh=REFRESH_TOKEN&userId=USER_ID
        var token: String?
        var refreshToken: String?

        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            token = components.queryItems?.first(where: { $0.name == "token" })?.value
            refreshToken = components.queryItems?.first(where: { $0.name == "refresh" })?.value
        }

        // Fallback: try parsing from raw string
        if token == nil {
            let urlString = url.absoluteString
            if urlString.contains("token=") {
                token = urlString.components(separatedBy: "token=").last?.components(separatedBy: "&").first
            }
        }

        guard let token = token, !token.isEmpty else {
            self.errorMessage = "فشل المصادقة: لم يتم استلام التوكن من Google"
            self.isGoogleLoading = false
            return
        }

        // Store the token immediately
        APIClient.shared.sessionToken = token

        // Also store refresh token for future use
        if let refreshToken = refreshToken, !refreshToken.isEmpty {
            KeychainManager.shared.set(key: "roua_refresh", value: refreshToken)
        }

        // Verify the session with backend — retry up to 3 times with delay
        // to handle race condition (session may not be committed to DB yet)
        Task {
            var lastError: String?
            for attempt in 1...3 {
                do {
                    if attempt > 1 {
                        try await Task.sleep(nanoseconds: UInt64(attempt) * 500_000_000) // 0.5s, 1s delays
                    }
                    let response: AuthVerifyResponse = try await self.api.request("/auth/me")
                    if response.isValid, let user = response.user {
                        self.currentUser = user; self.isAuthenticated = true; self.isGoogleLoading = false
                        return
                    } else {
                        lastError = "فشل التحقق من الجلسة - محاولة \(attempt)/3"
                    }
                } catch {
                    lastError = "خطأ التحقق: \(error.localizedDescription) - محاولة \(attempt)/3"
                }
            }
            // All retries failed
            self.errorMessage = lastError ?? "فشل تسجيل الدخول بحساب Google"
            self.isGoogleLoading = false
        }
    }

    /// Find the current UIWindow for ASWebAuthenticationSession presentation
    private static func findPresentationWindow() -> WebAuthPresenter {
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
           let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first {
            return WebAuthPresenter(window: window)
        }
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
           let window = scene.windows.first {
            return WebAuthPresenter(window: window)
        }
        let window = UIWindow()
        return WebAuthPresenter(window: window)
    }
    
    func signInWithPasskey() async {
        isPasskeyLoading = true; errorMessage = nil
        do {
            let challengeURL = URL(string: "\(APIConfig.baseURL)/auth/challenge?email=passkey@roua.auto")!
            var challengeRequest = URLRequest(url: challengeURL)
            challengeRequest.httpMethod = "GET"
            if let token = APIClient.shared.sessionToken {
                challengeRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                challengeRequest.setValue(token, forHTTPHeaderField: APIConfig.sessionHeader)
            }
            let (challengeData, challengeResponse) = try await URLSession.shared.data(for: challengeRequest)
            guard let httpResp = challengeResponse as? HTTPURLResponse, (200...299).contains(httpResp.statusCode) else {
                throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get passkey challenge"])
            }
            struct ChallengeResponse: Codable { let challenge: String; let rpId: String?; let allowCredentials: [AllowCredential]?; struct AllowCredential: Codable { let id: String; let type: String } }
            let challengeResp = try JSONDecoder().decode(ChallengeResponse.self, from: challengeData)
            let challengeDataBytes = Data(base64Encoded: challengeResp.challenge) ?? Data(challengeResp.challenge.utf8)
            let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: challengeResp.rpId ?? "roua-trading-production.up.railway.app")
            let passkeyRequest = provider.createCredentialAssertionRequest(challenge: challengeDataBytes)
            if let allowCreds = challengeResp.allowCredentials {
                passkeyRequest.allowedCredentials = allowCreds.map { cred in
                    ASAuthorizationPlatformPublicKeyCredentialDescriptor(credentialID: Data(base64Encoded: cred.id) ?? Data(cred.id.utf8))
                }
            }
            let controller = ASAuthorizationController(authorizationRequests: [passkeyRequest])
            let authResult: ASAuthorization = try await Self._passkeyAuth(controller: controller)
            guard let assertion = authResult.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion else {
                throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid credential type"])
            }
            struct PasskeyVerifyRequest: Encodable { let credential: PasskeyCredential; struct PasskeyCredential: Encodable { let id: String; let rawId: String; let response: PasskeyResponse; let type: String }; struct PasskeyResponse: Encodable { let authenticatorData: String; let clientDataJSON: String; let signature: String; let userHandle: String? } }
            let verifyBody = PasskeyVerifyRequest(credential: PasskeyVerifyRequest.PasskeyCredential(
                id: assertion.credentialID.base64EncodedString(), rawId: assertion.credentialID.base64EncodedString(),
                response: PasskeyVerifyRequest.PasskeyResponse(
                    authenticatorData: assertion.rawAuthenticatorData.base64EncodedString(),
                    clientDataJSON: assertion.rawClientDataJSON.base64EncodedString(),
                    signature: assertion.signature.base64EncodedString(),
                    userHandle: assertion.userID?.base64EncodedString()
                ), type: "public-key"
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
            guard let verifyHTTP = verifyResponse as? HTTPURLResponse, (200...299).contains(verifyHTTP.statusCode) else {
                throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Passkey verification failed"])
            }
            let meResponse: AuthVerifyResponse = try await api.request("/auth/me")
            if meResponse.isValid, let user = meResponse.user {
                self.currentUser = user; self.isAuthenticated = true; self.isPasskeyLoading = false
            } else {
                self.errorMessage = "Passkey login failed"; self.isPasskeyLoading = false
            }
        } catch {
            self.errorMessage = "Passkey failed: \(error.localizedDescription)"; self.isPasskeyLoading = false
        }
    }
    
    private nonisolated static func _passkeyAuth(controller: ASAuthorizationController) async throws -> ASAuthorization {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ASAuthorization, Error>) in
            let delegate = PasskeyAuthDelegate(continuation: continuation)
            controller.delegate = delegate
            objc_setAssociatedObject(controller, Unmanaged.passUnretained(delegate).toOpaque(), delegate, .OBJC_ASSOCIATION_RETAIN)
            controller.performRequests()
        }
    }
    
    func sendOTP(email: String) async {
        isOTPLoading = true; errorMessage = nil
        do {
            var request = URLRequest(url: URL(string: "\(APIConfig.baseURL)/auth/otp/send")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(["email": email])
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to send OTP"])
            }
            self.otpSent = true; self.isOTPLoading = false
        } catch {
            self.errorMessage = "Failed to send code: \(error.localizedDescription)"; self.isOTPLoading = false
        }
    }
    
    func verifyOTP(email: String, code: String) async {
        isOTPLoading = true; errorMessage = nil
        do {
            var request = URLRequest(url: URL(string: "\(APIConfig.baseURL)/auth/otp/verify")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(["email": email, "otp": code])
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid code"])
            }
            // Try to extract session token from response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Check for token in response
                if let token = json["token"] as? String, !token.isEmpty {
                    APIClient.shared.sessionToken = token
                }
                // Also check for token in nested data
                if let dataObj = json["data"] as? [String: Any], let token = dataObj["token"] as? String, !token.isEmpty {
                    APIClient.shared.sessionToken = token
                }
            }
            // Check for Set-Cookie header with roua_session
            if let httpResponse = response as? HTTPURLResponse,
               let setCookie = httpResponse.allHeaderFields["Set-Cookie"] as? String,
               let tokenRange = setCookie.range(of: "roua_session=") {
                let afterToken = setCookie[tokenRange.upperBound...]
                let token = afterToken.components(separatedBy: ";").first?.trimmingCharacters(in: .whitespaces) ?? ""
                if !token.isEmpty {
                    APIClient.shared.sessionToken = token
                }
            }
            // Now verify session with /auth/me
            struct OTPVerifyResponse: Codable { let authenticated: Bool?; let success: Bool? }
            let otpResp = try? JSONDecoder().decode(OTPVerifyResponse.self, from: data)
            if otpResp?.authenticated == true || otpResp?.success == true || APIClient.shared.sessionToken != nil {
                // Retry /auth/me up to 3 times
                for attempt in 1...3 {
                    if attempt > 1 {
                        try? await Task.sleep(nanoseconds: UInt64(attempt) * 500_000_000)
                    }
                    let meResponse: AuthVerifyResponse = try await api.request("/auth/me")
                    if meResponse.isValid, let user = meResponse.user {
                        self.currentUser = user; self.isAuthenticated = true; self.isOTPLoading = false
                        return
                    }
                }
                self.errorMessage = "Login failed - could not verify session"; self.isOTPLoading = false
            } else {
                self.errorMessage = "Invalid verification code"; self.isOTPLoading = false
            }
        } catch {
            self.errorMessage = "Verification failed: \(error.localizedDescription)"; self.isOTPLoading = false
        }
    }
    
    func login(email: String) async {
        isLoading = true; errorMessage = nil
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
                self.currentUser = user; self.isAuthenticated = true; self.isLoading = false
            } else {
                self.errorMessage = "Login failed - try Google or OTP instead"; self.isLoading = false
            }
        } catch {
            self.errorMessage = error.localizedDescription; self.isLoading = false
        }
    }
    
    func logout() async {
        do { let _: AuthVerifyResponse = try await api.request("/auth/me", method: "DELETE") } catch {}
        APIClient.shared.sessionToken = nil; KeychainManager.shared.deleteAll()
        currentUser = nil; isAuthenticated = false; otpSent = false
    }
}

// MARK: - Passkey Helper Classes

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

/// Provides the UIWindow for ASWebAuthenticationSession presentation
private class WebAuthPresenter: NSObject, ASWebAuthenticationPresentationContextProviding {
    let window: UIWindow
    init(window: UIWindow) { self.window = window }
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor { window }
}

// MARK: - ═══════════════════════════════════════
// MARK: - VIEWMODELS
// MARK: - ═══════════════════════════════════════

class DashboardViewModel: ObservableObject {
    @Published var portfolioSummary: PortfolioSummary?
    @Published var positions: [Position] = []
    @Published var trades: [Trade] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    private let api = APIClient.shared
    
    func loadDashboard() async {
        await MainActor.run { isLoading = true; errorMessage = nil }
        do {
            // /trading/v2/portfolio returns { success, data: { totalBalance, ... } }
            let portfolio: PortfolioSummary = try await api.request("/trading/v2/portfolio")
            // /trading/v2/positions returns { success, data: [...] }
            let positions: [Position] = try await api.request("/trading/v2/positions")
            // /trading/history returns { success, trades: [...] } - extract "trades" key
            let trades: [Trade] = try await api.request("/trading/history", key: "trades")
            await MainActor.run {
                self.portfolioSummary = portfolio; self.positions = positions
                self.trades = Array(trades.prefix(10)); self.isLoading = false
            }
        } catch {
            print("[Dashboard] Error: \(error)")
            await MainActor.run { self.errorMessage = error.localizedDescription; self.isLoading = false }
        }
    }
}

class TradingViewModel: ObservableObject {
    @Published var symbol = "BTC/USDT"
    @Published var currentQuote: Quote?
    @Published var positions: [Position] = []
    @Published var orders: [V2Order] = []
    @Published var trades: [Trade] = []
    @Published var accountInfo: AccountInfo?
    @Published var orderSide = "BUY"
    @Published var orderType = "MARKET"
    @Published var quantity = ""
    @Published var stopLoss = ""
    @Published var takeProfit = ""
    @Published var isPlacingOrder = false
    @Published var orderSuccess: V2PlaceOrderResponse?
    @Published var orderError: String?
    @Published var isLoadingOrders = false
    private let api = APIClient.shared
    
    func loadTradingData() async {
        do {
            let encodedSymbol = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
            // /exchange/quote/BTC%2FUSDT returns { success, data: { symbol, price, ... } }
            let quote: Quote = try await api.request("/exchange/quote/\(encodedSymbol)", key: "data")
            let positions: [Position] = try await api.request("/trading/v2/positions")
            await MainActor.run { self.currentQuote = quote; self.positions = positions }
        } catch {
            print("[Trading] loadTradingData error: \(error)")
        }
    }
    
    func loadOrders() async {
        await MainActor.run { isLoadingOrders = true }
        do {
            let orders: [V2Order] = try await api.request("/trading/v2/orders")
            let trades: [Trade] = try await api.request("/trading/history", key: "trades")
            await MainActor.run { self.orders = orders; self.trades = Array(trades.prefix(20)); self.isLoadingOrders = false }
        } catch { await MainActor.run { isLoadingOrders = false } }
    }
    
    func cancelOrder(id: String) async {
        do {
            let _: V2PlaceOrderResponse = try await api.request("/trading/v2/orders/\(id)", method: "DELETE")
            await loadOrders()
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
    @Published var availableModels: [AIModel] = []
    @Published var selectedModel: String?
    @Published var consensusResult: AIConsensusResponse?
    @Published var isConsensusLoading = false
    private let api = APIClient.shared
    
    func loadModels() async {
        do {
            // /ai/models returns { success, data: { groq: { available, model }, ... } }
            let data = try await api.rawRequest("/ai/models")
            // Try extracting from { success, data: {...} } wrapper
            var modelsDict: [String: Any] = [:]
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let innerData = json["data"] as? [String: Any] {
                    modelsDict = innerData
                } else {
                    // Maybe data is at top level without wrapper
                    modelsDict = json
                }
            }
            let models = modelsDict.compactMap { (key, value) -> AIModel? in
                guard let info = value as? [String: Any] else { return nil }
                return AIModel(
                    name: key,
                    provider: key,
                    available: info["available"] as? Bool,
                    model: info["model"] as? String
                )
            }
            await MainActor.run { self.availableModels = models }
        } catch {
            print("[AI] loadModels error: \(error)")
        }
    }
    
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
    
    func runConsensus(prompt: String) async {
        await MainActor.run { isConsensusLoading = true }
        do {
            let request = AIConsensusRequest(prompt: prompt, models: nil)
            let response: AIConsensusResponse = try await api.request("/ai/consensus", method: "POST", body: request)
            await MainActor.run { self.consensusResult = response; self.isConsensusLoading = false }
        } catch {
            await MainActor.run { self.isConsensusLoading = false }
        }
    }
}

class ScannerViewModel: ObservableObject {
    @Published var results: [ScanResult] = []
    @Published var heatmapData: [HeatmapItem] = []
    @Published var overview: ScannerOverview?
    @Published var symbolAnalysis: SymbolAnalysis?
    @Published var selectedSymbol: String?
    @Published var isLoading = false
    @Published var timeframe: String = "1h"
    @Published var category: String = "crypto"
    private let api = APIClient.shared
    
    func runScan() async {
        await MainActor.run { isLoading = true }
        do {
            // /scanner/scan returns { success, items: [...] } - items at top level
            let results: [ScanResult] = try await api.request("/scanner/scan?timeframe=\(timeframe)&category=\(category)", key: "items")
            // /scanner/heatmap returns { success, data: [...] }
            let heatmap: [HeatmapItem] = try await api.request("/scanner/heatmap?category=\(category)", key: "data")
            await MainActor.run { self.results = results; self.heatmapData = heatmap; self.isLoading = false }
        } catch {
            print("[Scanner] runScan error: \(error)")
            await MainActor.run { isLoading = false }
        }
    }
    
    func loadOverview() async {
        do {
            // /scanner/overview returns { success, data: { totalScanned, bullishCount, ... } }
            let overview: ScannerOverview = try await api.request("/scanner/overview", key: "data")
            await MainActor.run { self.overview = overview }
        } catch {
            print("[Scanner] loadOverview error: \(error)")
        }
    }
    
    func loadAnalysis(symbol: String) async {
        await MainActor.run { selectedSymbol = symbol }
        do {
            let analysis: SymbolAnalysis = try await api.request("/scanner/analysis/\(symbol)")
            await MainActor.run { self.symbolAnalysis = analysis }
        } catch { await MainActor.run { self.symbolAnalysis = nil } }
    }
}

class PortfolioViewModel: ObservableObject {
    @Published var credentials: [ExchangeCredential] = []
    @Published var balanceResponse: BalancesResponse?
    @Published var sanctuary: SanctuaryInfo?
    @Published var totalValue: Double = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    private let api = APIClient.shared
    
    /// Computed for view compatibility
    var balances: [ExchangeBalance] { balanceResponse?.exchanges ?? [] }
    
    func loadData() async {
        await MainActor.run { isLoading = true }
        do {
            let creds: [ExchangeCredential] = try await api.request("/portfolio/credentials")
            await MainActor.run { self.credentials = creds; self.isLoading = false }
        } catch {
            print("[Portfolio] loadData error: \(error)")
            await MainActor.run { self.isLoading = false }
        }
    }
    
    func loadBalances() async {
        do {
            // /portfolio/credentials/balances returns { success, data: { totalEquityUsd, exchanges: [...] } }
            let balances: BalancesResponse = try await api.request("/portfolio/credentials/balances")
            await MainActor.run {
                self.balanceResponse = balances
                self.totalValue = balances.totalEquityUsd ?? 0
            }
        } catch {
            print("[Portfolio] loadBalances error: \(error)")
        }
    }
    
    func loadSanctuary() async {
        do {
            let sanctuary: SanctuaryInfo = try await api.request("/portfolio/sanctuary")
            await MainActor.run { self.sanctuary = sanctuary }
        } catch {}
    }
    
    func deleteCredential(id: String) async {
        do {
            let _: ApiResponseWrapper = try await api.request("/portfolio/credentials/\(id)", method: "DELETE")
            await loadData()
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }
}

// MARK: - NEW VIEWMODELS

class AgentViewModel: ObservableObject {
    @Published var status: AgentStatus?
    @Published var performance: AgentPerformance?
    @Published var settings: AgentSettings?
    @Published var isLoading = false
    @Published var isToggling = false
    @Published var errorMessage: String?
    @Published var selectedStrategy = "momentum"
    @Published var maxPositionSize = ""
    @Published var riskLevel = "medium"
    private let api = APIClient.shared
    
    func loadStatus() async {
        await MainActor.run { isLoading = true }
        do {
            let status: AgentStatus = try await api.request("/agent/trader/status")
            await MainActor.run { self.status = status; self.isLoading = false }
        } catch { await MainActor.run { isLoading = false } }
    }
    
    func loadPerformance() async {
        do {
            let perf: AgentPerformance = try await api.request("/agent/trader/performance")
            await MainActor.run { self.performance = perf }
        } catch {}
    }
    
    func loadSettings() async {
        do {
            let settings: AgentSettings = try await api.request("/agent/trader/settings")
            await MainActor.run { self.settings = settings; self.riskLevel = settings.riskLevel ?? "medium"; self.selectedStrategy = "momentum" }
        } catch {}
    }
    
    func startAgent() async {
        await MainActor.run { isToggling = true }
        do {
            let _: ApiResponseWrapper = try await api.request("/agent/trader/start", method: "POST", body: ["strategy": selectedStrategy])
            await MainActor.run { isToggling = false }; await loadStatus()
        } catch { await MainActor.run { errorMessage = error.localizedDescription; isToggling = false } }
    }
    
    func stopAgent() async {
        await MainActor.run { isToggling = true }
        do {
            let _: ApiResponseWrapper = try await api.request("/agent/trader/stop", method: "POST")
            await MainActor.run { isToggling = false }; await loadStatus()
        } catch { await MainActor.run { errorMessage = error.localizedDescription; isToggling = false } }
    }
    
    func updateSettings() async {
        let body: [String: Any] = [
            "maxPositionSize": Double(maxPositionSize) ?? 100,
            "riskLevel": riskLevel,
            "autoExecute": false
        ]
        do {
            let bodyData = try JSONSerialization.data(withJSONObject: body)
            let _: ApiResponseWrapper = try await api.request("/agent/trader/settings", method: "PUT", bodyData: bodyData)
            await loadSettings()
        } catch { await MainActor.run { errorMessage = error.localizedDescription } }
    }
    
    func updateStrategy() async {
        do {
            let _: ApiResponseWrapper = try await api.request("/agent/trader/strategy", method: "PUT", body: ["strategy": selectedStrategy])
            await loadStatus()
        } catch { await MainActor.run { errorMessage = error.localizedDescription } }
    }
}

class SignalsViewModel: ObservableObject {
    @Published var activeSignals: [Signal] = []
    @Published var signalHistory: [Signal] = []
    @Published var isLoading = false
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var generatePair = "BTC/USDT"
    private let api = APIClient.shared
    
    func loadActiveSignals() async {
        await MainActor.run { isLoading = true }
        do {
            let signals: [Signal] = try await api.request("/signals/active")
            await MainActor.run { self.activeSignals = signals; self.isLoading = false }
        } catch { await MainActor.run { isLoading = false } }
    }
    
    func loadHistory() async {
        do {
            let history: [Signal] = try await api.request("/signals/history")
            await MainActor.run { self.signalHistory = history }
        } catch {}
    }
    
    func generateSignal() async {
        await MainActor.run { isGenerating = true; errorMessage = nil }
        do {
            let _: ApiResponseWrapper = try await api.request("/signals/generate/\(generatePair)", method: "POST")
            await MainActor.run { isGenerating = false }; await loadActiveSignals()
        } catch { await MainActor.run { errorMessage = error.localizedDescription; isGenerating = false } }
    }
    
    func executeSignal(id: String) async {
        do {
            let _: ApiResponseWrapper = try await api.request("/signals/\(id)/execute", method: "POST")
            await loadActiveSignals()
        } catch { await MainActor.run { errorMessage = error.localizedDescription } }
    }
}

class ExecutorViewModel: ObservableObject {
    @Published var status: ExecutorStatus?
    @Published var exposure: ExecutorExposure?
    @Published var userEnabled: Bool?
    @Published var isLoading = false
    @Published var isToggling = false
    @Published var errorMessage: String?
    private let api = APIClient.shared
    
    func loadStatus() async {
        await MainActor.run { isLoading = true }
        do {
            let status: ExecutorStatus = try await api.request("/smart-executor/status")
            await MainActor.run { self.status = status; self.isLoading = false }
        } catch { await MainActor.run { isLoading = false } }
    }
    
    func loadExposure() async {
        do {
            let exposure: ExecutorExposure = try await api.request("/smart-executor/exposure")
            await MainActor.run { self.exposure = exposure }
        } catch {}
    }
    
    func loadUserStatus() async {
        do {
            let resp: ExecutorStatus = try await api.request("/smart-executor/user/status")
            await MainActor.run { self.userEnabled = resp.active }
        } catch {}
    }
    
    func start() async {
        await MainActor.run { isToggling = true }
        do {
            let _: ApiResponseWrapper = try await api.request("/smart-executor/start", method: "POST")
            await MainActor.run { isToggling = false }; await loadStatus()
        } catch { await MainActor.run { errorMessage = error.localizedDescription; isToggling = false } }
    }
    
    func stop() async {
        await MainActor.run { isToggling = true }
        do {
            let _: ApiResponseWrapper = try await api.request("/smart-executor/stop", method: "POST")
            await MainActor.run { isToggling = false }; await loadStatus()
        } catch { await MainActor.run { errorMessage = error.localizedDescription; isToggling = false } }
    }
    
    func emergencyStop() async {
        do {
            let _: ApiResponseWrapper = try await api.request("/smart-executor/emergency-stop", method: "POST")
            await loadStatus()
        } catch { await MainActor.run { errorMessage = error.localizedDescription } }
    }
    
    func enableUser() async {
        do {
            let _: ApiResponseWrapper = try await api.request("/smart-executor/user/enable", method: "POST")
            await MainActor.run { userEnabled = true }; await loadUserStatus()
        } catch { await MainActor.run { errorMessage = error.localizedDescription } }
    }
    
    func disableUser() async {
        do {
            let _: ApiResponseWrapper = try await api.request("/smart-executor/user/disable", method: "POST")
            await MainActor.run { userEnabled = false }; await loadUserStatus()
        } catch { await MainActor.run { errorMessage = error.localizedDescription } }
    }
}

class CouncilViewModel: ObservableObject {
    @Published var activeBriefs: [TradingBrief] = []
    @Published var briefHistory: [TradingBrief] = []
    @Published var isLoading = false
    @Published var isTriggering = false
    @Published var errorMessage: String?
    @Published var triggerSymbol = ""
    private let api = APIClient.shared
    
    func loadActiveBriefs() async {
        await MainActor.run { isLoading = true }
        var path = "/strategic-council/briefs/active"
        if !triggerSymbol.isEmpty { path += "?symbol=\(triggerSymbol)" }
        do {
            let briefs: [TradingBrief] = try await api.request(path)
            await MainActor.run { self.activeBriefs = briefs; self.isLoading = false }
        } catch { await MainActor.run { isLoading = false } }
    }
    
    func loadHistory() async {
        do {
            let history: [TradingBrief] = try await api.request("/strategic-council/briefs/history")
            await MainActor.run { self.briefHistory = history }
        } catch {}
    }
    
    func triggerCouncil() async {
        await MainActor.run { isTriggering = true; errorMessage = nil }
        let body: [String: String] = triggerSymbol.isEmpty ? [:] : ["symbol": triggerSymbol]
        do {
            let _: ApiResponseWrapper = try await api.request("/strategic-council/trigger", method: "POST", body: body)
            await MainActor.run { isTriggering = false }; await loadActiveBriefs()
        } catch { await MainActor.run { errorMessage = error.localizedDescription; isTriggering = false } }
    }
}

class NewsViewModel: ObservableObject {
    @Published var articles: [NewsArticle] = []
    @Published var sentiment: MarketSentiment?
    @Published var analysisResult: NewsAnalyzeResponse?
    @Published var isLoading = false
    @Published var isAnalyzing = false
    @Published var errorMessage: String?
    @Published var symbol: String = ""
    private let api = APIClient.shared
    
    func loadLatest() async {
        await MainActor.run { isLoading = true }
        var path = "/news/latest?limit=20"
        if !symbol.isEmpty { path += "&symbol=\(symbol)" }
        do {
            let articles: [NewsArticle] = try await api.request(path)
            await MainActor.run { self.articles = articles; self.isLoading = false }
        } catch { await MainActor.run { isLoading = false } }
    }
    
    func loadSentiment() async {
        do {
            let sentiment: MarketSentiment = try await api.request("/news/sentiment")
            await MainActor.run { self.sentiment = sentiment }
        } catch {}
    }
    
    func analyzeNews(text: String) async {
        await MainActor.run { isAnalyzing = true; errorMessage = nil }
        do {
            let request = NewsAnalyzeRequest(url: nil, text: text)
            let response: NewsAnalyzeResponse = try await api.request("/news/analyze", method: "POST", body: request)
            await MainActor.run { self.analysisResult = response; self.isAnalyzing = false }
        } catch { await MainActor.run { errorMessage = error.localizedDescription; isAnalyzing = false } }
    }
}

class NotificationsViewModel: ObservableObject {
    @Published var notifications: [UserNotification] = []
    @Published var unreadCount: Int = 0
    @Published var preferences: NotificationPreferences?
    @Published var isLoading = false
    @Published var errorMessage: String?
    private let api = APIClient.shared
    
    func loadNotifications() async {
        await MainActor.run { isLoading = true }
        do {
            let notifications: [UserNotification] = try await api.request("/notifications?limit=50&unread=false")
            await MainActor.run { self.notifications = notifications; self.isLoading = false }
        } catch { await MainActor.run { isLoading = false } }
    }
    
    func loadUnreadCount() async {
        do {
            let count: UnreadCount = try await api.request("/notifications/unread-count")
            await MainActor.run { self.unreadCount = count.count ?? 0 }
        } catch {}
    }
    
    func markRead(id: String) async {
        do {
            let _: ApiResponseWrapper = try await api.request("/notifications/read", method: "PUT", body: ["id": id])
            await loadNotifications(); await loadUnreadCount()
        } catch {}
    }
    
    func markAllRead() async {
        do {
            let _: ApiResponseWrapper = try await api.request("/notifications/read-all", method: "PUT")
            await loadNotifications(); await loadUnreadCount()
        } catch {}
    }
    
    func loadPreferences() async {
        do {
            let prefs: NotificationPreferences = try await api.request("/notifications/preferences")
            await MainActor.run { self.preferences = prefs }
        } catch {}
    }
    
    func updatePreferences(pushEnabled: Bool?, emailEnabled: Bool?, tradeAlerts: Bool?, signalAlerts: Bool?, newsAlerts: Bool?) async {
        var body: [String: Any] = [:]
        if let v = pushEnabled { body["pushEnabled"] = v }
        if let v = emailEnabled { body["emailEnabled"] = v }
        if let v = tradeAlerts { body["tradeAlerts"] = v }
        if let v = signalAlerts { body["signalAlerts"] = v }
        if let v = newsAlerts { body["newsAlerts"] = v }
        do {
            let bodyData = try JSONSerialization.data(withJSONObject: body)
            let _: ApiResponseWrapper = try await api.request("/notifications/preferences", method: "PUT", bodyData: bodyData)
            await loadPreferences()
        } catch { await MainActor.run { errorMessage = error.localizedDescription } }
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
                
                VStack(spacing: RouaTheme.Spacing.lg) {
                    ZStack {
                        RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.xl).fill(RouaTheme.Colors.accentGradient).frame(width: 80, height: 80)
                        Image(systemName: "chart.line.uptrend.xyaxis").font(.system(size: 36, weight: .bold)).foregroundStyle(.white)
                    }
                    Text("ROUA TRADING").font(.system(size: 24, weight: .bold, design: .rounded)).foregroundStyle(RouaTheme.Colors.textPrimary).tracking(4)
                    Text("AI-Powered Trading Platform").font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textSecondary)
                }
                
                Spacer()
                
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
                    
                    Group {
                        switch authMethod {
                        case .google: googleSignInView
                        case .passkey: passkeySignInView
                        case .otp: otpSignInView
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: authMethod)
                }
                
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
    
    private var googleSignInView: some View {
        VStack(spacing: RouaTheme.Spacing.lg) {
            Button {
                authManager.signInWithGoogle()
            } label: {
                HStack(spacing: 12) {
                    if authManager.isGoogleLoading {
                        ProgressView().tint(.white).controlSize(.small)
                    } else {
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
    
    private var otpSignInView: some View {
        VStack(spacing: RouaTheme.Spacing.lg) {
            HStack(spacing: RouaTheme.Spacing.md) {
                Image(systemName: "envelope").foregroundStyle(RouaTheme.Colors.textTertiary).frame(width: 20)
                TextField("Email Address", text: $email)
                    .font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textPrimary)
                    .tint(RouaTheme.Colors.accent).textInputAutocapitalization(.never).keyboardType(.emailAddress)
            }.padding(RouaTheme.Spacing.lg).background(RouaTheme.Colors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md))
            
            if authManager.otpSent {
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
// MARK: - TRADING VIEW (ENHANCED)
// MARK: - ═══════════════════════════════════════

struct TradingView: View {
    @StateObject private var vm = TradingViewModel()
    @State private var showOrderSheet = false
    @State private var selectedSegment = 0
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
            
            // Segment Picker
            Picker("Segment", selection: $selectedSegment) {
                Text("Positions").tag(0)
                Text("Orders").tag(1)
                Text("History").tag(2)
            }.pickerStyle(.segmented).padding(.horizontal, RouaTheme.Spacing.lg).padding(.bottom, RouaTheme.Spacing.sm)
            
            // Content
            ScrollView {
                VStack(spacing: RouaTheme.Spacing.md) {
                    switch selectedSegment {
                    case 0:
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
                                        if let pnl = pos.unrealizedPnl { Text(String(format: "%+.2f", pnl)).font(.system(size: 14, weight: .semibold, design: .monospaced)).foregroundStyle(pnl >= 0 ? RouaTheme.Colors.profit : RouaTheme.Colors.loss) }
                                        Text("Entry: \(String(format: "%.2f", pos.entryPrice))").font(.system(size: 11, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textTertiary)
                                    }
                                }
                            }
                        }
                        if vm.positions.isEmpty {
                            GlassCard { Text("No open positions").font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textSecondary).frame(maxWidth: .infinity) }
                        }
                    case 1:
                        ForEach(vm.orders) { order in
                            GlassCard {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(order.symbol).font(.system(size: 14, weight: .medium)).foregroundStyle(RouaTheme.Colors.textPrimary)
                                        Text("\(order.side) · \(order.type)").font(.system(size: 11)).foregroundStyle(RouaTheme.Colors.textTertiary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        if let status = order.status { Text(status.uppercased()).font(.system(size: 10, weight: .medium)).foregroundStyle(RouaTheme.Colors.accent) }
                                        Button { Task { await vm.cancelOrder(id: order.id) } } label: {
                                            Text("Cancel").font(.system(size: 11, weight: .medium)).foregroundStyle(RouaTheme.Colors.loss)
                                        }
                                    }
                                }
                            }
                        }
                        if vm.orders.isEmpty {
                            GlassCard { Text("No open orders").font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textSecondary).frame(maxWidth: .infinity) }
                        }
                    case 2:
                        ForEach(vm.trades) { trade in
                            GlassCard {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(trade.symbol).font(.system(size: 14, weight: .medium)).foregroundStyle(RouaTheme.Colors.textPrimary)
                                        Text("\(trade.side) · \(trade.type)").font(.system(size: 11)).foregroundStyle(RouaTheme.Colors.textTertiary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(String(format: "%.4f @ %.2f", trade.quantity, trade.price)).font(.system(size: 12, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textPrimary)
                                        if let pnl = trade.pnl { Text(String(format: "%+.2f", pnl)).font(.system(size: 12, weight: .semibold, design: .monospaced)).foregroundStyle(pnl >= 0 ? RouaTheme.Colors.profit : RouaTheme.Colors.loss) }
                                    }
                                }
                            }
                        }
                        if vm.trades.isEmpty {
                            GlassCard { Text("No trade history").font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textSecondary).frame(maxWidth: .infinity) }
                        }
                    default: EmptyView()
                    }
                }.padding(RouaTheme.Spacing.lg)
            }
        }.background(RouaTheme.Colors.background).task { await vm.loadTradingData(); await vm.loadOrders() }
        .refreshable { await vm.loadTradingData(); await vm.loadOrders() }
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
                    HStack(spacing: 0) {
                        Button { vm.orderSide = "BUY" } label: { Text("Buy").font(.system(size: 14, weight: .semibold)).frame(maxWidth: .infinity).frame(height: 44).foregroundStyle(vm.orderSide == "BUY" ? .white : RouaTheme.Colors.textTertiary).background(vm.orderSide == "BUY" ? RouaTheme.Colors.profit : RouaTheme.Colors.surfaceElevated) }
                        Button { vm.orderSide = "SELL" } label: { Text("Sell").font(.system(size: 14, weight: .semibold)).frame(maxWidth: .infinity).frame(height: 44).foregroundStyle(vm.orderSide == "SELL" ? .white : RouaTheme.Colors.textTertiary).background(vm.orderSide == "SELL" ? RouaTheme.Colors.loss : RouaTheme.Colors.surfaceElevated) }
                    }.clipShape(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quantity").font(.system(size: 12, weight: .medium)).foregroundStyle(RouaTheme.Colors.textSecondary)
                        TextField("0.00", text: $vm.quantity).font(.system(size: 16, weight: .semibold, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textPrimary).keyboardType(.decimalPad).padding().background(RouaTheme.Colors.surfaceElevated).clipShape(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack { Text("Stop Loss").font(.system(size: 12, weight: .medium)).foregroundStyle(RouaTheme.Colors.textSecondary); Text("(Required)").font(.system(size: 10)).foregroundStyle(RouaTheme.Colors.loss) }
                        TextField("0.00", text: $vm.stopLoss).font(.system(size: 16, weight: .semibold, design: .monospaced)).foregroundStyle(RouaTheme.Colors.loss).keyboardType(.decimalPad).padding().background(RouaTheme.Colors.surfaceElevated).clipShape(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md))
                    }
                    
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
// MARK: - AI CHAT VIEW (ENHANCED)
// MARK: - ═══════════════════════════════════════

struct AIChatView: View {
    @StateObject private var vm = AIViewModel()
    @State private var showModelPicker = false
    @State private var showConsensus = false
    @State private var consensusPrompt = ""
    var body: some View {
        VStack(spacing: 0) {
            // Model bar
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: RouaTheme.Spacing.md) {
                        ForEach(vm.messages.indices, id: \.self) { i in
                            let msg = vm.messages[i]
                            HStack {
                                if msg.isUser { Spacer(minLength: 60) }
                                VStack(alignment: msg.isUser ? .trailing : .leading, spacing: 4) {
                                    Text(msg.content).font(.system(size: 14)).foregroundStyle(msg.isUser ? .white : RouaTheme.Colors.textPrimary)
                                        .padding(RouaTheme.Spacing.md).background(msg.isUser ? RouaTheme.Colors.accent : RouaTheme.Colors.surfaceElevated)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    if let model = msg.model, !msg.isUser {
                                        Text(model).font(.system(size: 9, weight: .medium)).foregroundStyle(RouaTheme.Colors.textTertiary).padding(.horizontal, 4)
                                    }
                                }
                                if !msg.isUser { Spacer(minLength: 60) }
                            }.id(i)
                        }
                        if vm.isLoading { HStack(spacing: 8) { PulsingDot(); Text("AI is thinking...").font(.system(size: 12)).foregroundStyle(RouaTheme.Colors.textTertiary) }.padding(.leading, 16) }
                        
                        // Consensus result
                        if let consensus = vm.consensusResult {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack { Image(systemName: "brain.head.profile").foregroundStyle(RouaTheme.Colors.accent); Text("AI Consensus").font(.system(size: 14, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary) }
                                    if let c = consensus.consensus { Text(c).font(.system(size: 13)).foregroundStyle(RouaTheme.Colors.textSecondary) }
                                }
                            }
                        }
                    }.padding(RouaTheme.Spacing.lg)
                }.onChange(of: vm.messages.count) { _, _ in withAnimation { proxy.scrollTo(vm.messages.count - 1, anchor: .bottom) } }
            }
            
            HStack(spacing: RouaTheme.Spacing.md) {
                Button { showConsensus = true } label: {
                    Image(systemName: "brain.head.profile").font(.system(size: 20)).foregroundStyle(RouaTheme.Colors.accent)
                }
                TextField("Ask AI...", text: $vm.inputText).font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textPrimary).tint(RouaTheme.Colors.accent).submitLabel(.send).onSubmit { Task { await vm.sendMessage() } }
                Button { Task { await vm.sendMessage() } } label: { Image(systemName: "arrow.up.circle.fill").font(.system(size: 32)).foregroundStyle(vm.inputText.isEmpty ? RouaTheme.Colors.textTertiary : RouaTheme.Colors.accent) }
                .disabled(vm.inputText.isEmpty || vm.isLoading)
            }.padding(RouaTheme.Spacing.md).background(RouaTheme.Colors.surface).clipShape(RoundedRectangle(cornerRadius: 16)).padding(.horizontal, RouaTheme.Spacing.lg).padding(.vertical, RouaTheme.Spacing.sm)
        }.background(RouaTheme.Colors.background).navigationTitle("AI Assistant")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(vm.availableModels, id: \.name) { model in
                        Button { vm.selectedModel = model.name } label: {
                            HStack { Text(model.name); if vm.selectedModel == model.name { Image(systemName: "checkmark") } }
                        }
                    }
                } label: {
                    Image(systemName: "cpu").foregroundStyle(RouaTheme.Colors.accent)
                }
            }
        }
        .task { await vm.loadModels() }
        .alert("AI Consensus", isPresented: $showConsensus) {
            TextField("Enter prompt for consensus", text: $consensusPrompt)
            Button("Run") { Task { await vm.runConsensus(prompt: consensusPrompt); consensusPrompt = "" } }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - ═══════════════════════════════════════
// MARK: - SCANNER VIEW (ENHANCED)
// MARK: - ═══════════════════════════════════════

struct ScannerView: View {
    @StateObject private var vm = ScannerViewModel()
    @State private var showAnalysis = false
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaTheme.Spacing.lg) {
                Text("Market Scanner").font(.system(size: 22, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                
                // Overview
                if let overview = vm.overview {
                    GlassCard {
                        VStack(spacing: RouaTheme.Spacing.md) {
                            Text("Market Overview").font(.system(size: 14, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                            HStack(spacing: RouaTheme.Spacing.lg) {
                                StatMini(title: "Bullish", value: "\(overview.bullish ?? 0)", isPositive: true)
                                StatMini(title: "Bearish", value: "\(overview.bearish ?? 0)", isPositive: false)
                                StatMini(title: "Neutral", value: "\(overview.neutral ?? 0)")
                            }
                            HStack {
                                if let gainer = overview.topGainer { Text("Top Gainer: \(gainer)").font(.system(size: 11)).foregroundStyle(RouaTheme.Colors.profit) }
                                Spacer()
                                if let loser = overview.topLoser { Text("Top Loser: \(loser)").font(.system(size: 11)).foregroundStyle(RouaTheme.Colors.loss) }
                            }
                        }
                    }
                }
                
                // Filters
                HStack(spacing: RouaTheme.Spacing.md) {
                    Picker("Timeframe", selection: $vm.timeframe) {
                        ForEach(["5m", "15m", "1h", "4h", "1d"], id: \.self) { Text($0) }
                    }.pickerStyle(.menu).tint(RouaTheme.Colors.accent)
                    
                    Picker("Category", selection: $vm.category) {
                        ForEach(["crypto", "forex", "stocks"], id: \.self) { Text($0.capitalized) }
                    }.pickerStyle(.menu).tint(RouaTheme.Colors.accent)
                    
                    Spacer()
                    
                    Button { Task { await vm.runScan() } } label: {
                        Image(systemName: "arrow.clockwise").foregroundStyle(RouaTheme.Colors.accent)
                    }
                }.padding(.horizontal, RouaTheme.Spacing.xs)
                
                // Scan Results
                ForEach(vm.results) { r in
                    GlassCard {
                        Button { Task { await vm.loadAnalysis(symbol: r.symbol); showAnalysis = true } } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(r.symbol).font(.system(size: 14, weight: .medium)).foregroundStyle(RouaTheme.Colors.textPrimary)
                                    if let n = r.name { Text(n).font(.system(size: 12)).foregroundStyle(RouaTheme.Colors.textTertiary).lineLimit(1) }
                                    if let signal = r.signal { Text(signal.uppercased()).font(.system(size: 10, weight: .medium)).foregroundStyle(RouaTheme.Colors.accent) }
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(String(format: "%.2f", r.price ?? 0)).font(.system(size: 13, weight: .semibold, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textPrimary)
                                    ChangeBadge(value: r.changePercent ?? 0)
                                }
                            }
                        }
                    }
                }
            }.padding(RouaTheme.Spacing.lg)
        }.background(RouaTheme.Colors.background).task { await vm.runScan(); await vm.loadOverview() }.refreshable { await vm.runScan() }
        .sheet(isPresented: $showAnalysis) {
            NavigationStack {
                SymbolAnalysisView(vm: vm)
            }
        }
    }
}

struct SymbolAnalysisView: View {
    @ObservedObject var vm: ScannerViewModel
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ScrollView {
            VStack(spacing: RouaTheme.Spacing.lg) {
                if let analysis = vm.symbolAnalysis {
                    GlassCard {
                        VStack(spacing: RouaTheme.Spacing.md) {
                            Text(analysis.symbol).font(.system(size: 22, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary)
                            if let price = analysis.price { Text(String(format: "$%.2f", price)).font(.system(size: 18, weight: .bold, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textPrimary) }
                            if let change = analysis.change { ChangeBadge(value: change) }
                        }
                    }
                    GlassCard {
                        VStack(spacing: RouaTheme.Spacing.md) {
                            if let rec = analysis.recommendation {
                                HStack { Text("Recommendation").font(.system(size: 12, weight: .medium)).foregroundStyle(RouaTheme.Colors.textTertiary); Spacer(); Text(rec.uppercased()).font(.system(size: 14, weight: .semibold)).foregroundStyle(rec.lowercased() == "buy" ? RouaTheme.Colors.profit : rec.lowercased() == "sell" ? RouaTheme.Colors.loss : RouaTheme.Colors.warning) }
                            }
                            if let conf = analysis.confidence {
                                HStack { Text("Confidence").font(.system(size: 12, weight: .medium)).foregroundStyle(RouaTheme.Colors.textTertiary); Spacer(); Text(String(format: "%.0f%%", conf * 100)).font(.system(size: 14, weight: .semibold, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textPrimary) }
                            }
                            if let support = analysis.support {
                                HStack { Text("Support").font(.system(size: 12, weight: .medium)).foregroundStyle(RouaTheme.Colors.textTertiary); Spacer(); Text(String(format: "%.2f", support)).font(.system(size: 13, design: .monospaced)).foregroundStyle(RouaTheme.Colors.profit) }
                            }
                            if let resistance = analysis.resistance {
                                HStack { Text("Resistance").font(.system(size: 12, weight: .medium)).foregroundStyle(RouaTheme.Colors.textTertiary); Spacer(); Text(String(format: "%.2f", resistance)).font(.system(size: 13, design: .monospaced)).foregroundStyle(RouaTheme.Colors.loss) }
                            }
                        }
                    }
                } else {
                    GlassCard { Text("No analysis available").font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textSecondary) }
                }
            }.padding(RouaTheme.Spacing.lg)
        }.background(RouaTheme.Colors.background).navigationTitle("Analysis").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
    }
}

// MARK: - ═══════════════════════════════════════
// MARK: - PORTFOLIO VIEW (ENHANCED)
// MARK: - ═══════════════════════════════════════

struct PortfolioView: View {
    @StateObject private var vm = PortfolioViewModel()
    @State private var showDeleteAlert = false
    @State private var credentialToDelete: String?
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaTheme.Spacing.lg) {
                Text("Portfolio").font(.system(size: 22, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                
                // Balances
                if !vm.balances.isEmpty {
                    GlassCard {
                        VStack(spacing: RouaTheme.Spacing.md) {
                            Text("Balances").font(.system(size: 16, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                            ForEach(vm.balances) { bal in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(bal.exchange?.uppercased() ?? "Exchange").font(.system(size: 14, weight: .medium)).foregroundStyle(RouaTheme.Colors.textPrimary)
                                        Text(bal.currency?.uppercased() ?? "USD").font(.system(size: 11)).foregroundStyle(RouaTheme.Colors.textTertiary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        if let total = bal.equity { Text(String(format: "$%.2f", total)).font(.system(size: 14, weight: .semibold, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textPrimary) }
                                        if let avail = bal.available { Text("Avail: \(String(format: "%.2f", avail))").font(.system(size: 11, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textTertiary) }
                                    }
                                }.padding(.vertical, 4)
                            }
                        }
                    }
                }
                
                // Exchange Accounts
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
                                HStack(spacing: 8) {
                                    if cred.testnet { Text("TESTNET").font(.system(size: 10, weight: .medium)).foregroundStyle(RouaTheme.Colors.warning).padding(.horizontal, 8).padding(.vertical, 3).background(RouaTheme.Colors.warningBackground).clipShape(Capsule()) }
                                    Button { credentialToDelete = cred.id; showDeleteAlert = true } label: {
                                        Image(systemName: "trash").font(.system(size: 12)).foregroundStyle(RouaTheme.Colors.loss)
                                    }
                                }
                            }.padding(.vertical, 4)
                        }
                        if vm.credentials.isEmpty {
                            Text("No exchange accounts linked").font(.system(size: 13)).foregroundStyle(RouaTheme.Colors.textSecondary).frame(maxWidth: .infinity)
                        }
                    }
                }
                
                // Sanctuary
                if let sanctuary = vm.sanctuary {
                    GlassCard {
                        VStack(spacing: RouaTheme.Spacing.md) {
                            HStack { Image(systemName: "shield.checkered").foregroundStyle(RouaTheme.Colors.accent); Text("Sanctuary").font(.system(size: 16, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary) }
                            if let enabled = sanctuary.enabled {
                                HStack { Text("Status").font(.system(size: 12)).foregroundStyle(RouaTheme.Colors.textTertiary); Spacer(); Text(enabled ? "Active" : "Inactive").font(.system(size: 13, weight: .medium)).foregroundStyle(enabled ? RouaTheme.Colors.profit : RouaTheme.Colors.loss) }
                            }
                            if let risk = sanctuary.riskScore {
                                HStack { Text("Risk Score").font(.system(size: 12)).foregroundStyle(RouaTheme.Colors.textTertiary); Spacer(); Text(String(format: "%.0f%%", risk * 100)).font(.system(size: 13, design: .monospaced)).foregroundStyle(risk > 0.7 ? RouaTheme.Colors.loss : RouaTheme.Colors.warning) }
                            }
                            if let protected = sanctuary.protectedAmount {
                                HStack { Text("Protected").font(.system(size: 12)).foregroundStyle(RouaTheme.Colors.textTertiary); Spacer(); Text(String(format: "$%.2f", protected)).font(.system(size: 13, design: .monospaced)).foregroundStyle(RouaTheme.Colors.profit) }
                            }
                        }
                    }
                }
            }.padding(RouaTheme.Spacing.lg)
        }.background(RouaTheme.Colors.background).task { await vm.loadData(); await vm.loadBalances(); await vm.loadSanctuary() }
        .refreshable { await vm.loadData(); await vm.loadBalances(); await vm.loadSanctuary() }
        .alert("Delete Credential", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { if let id = credentialToDelete { Task { await vm.deleteCredential(id: id) } } }
            Button("Cancel", role: .cancel) { credentialToDelete = nil }
        } message: { Text("Are you sure? This will remove the exchange credential.") }
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
// MARK: - AGENT VIEW
// MARK: - ═══════════════════════════════════════

struct AgentView: View {
    @StateObject private var vm = AgentViewModel()
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaTheme.Spacing.lg) {
                Text("AI Agent Trader").font(.system(size: 22, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                
                // Status Card
                GlassCard {
                    VStack(spacing: RouaTheme.Spacing.md) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Status").font(.system(size: 12, weight: .medium)).foregroundStyle(RouaTheme.Colors.textTertiary)
                                HStack(spacing: 8) {
                                    if vm.status?.running == true { PulsingDot() } else { Circle().fill(RouaTheme.Colors.textTertiary).frame(width: 8, height: 8) }
                                    Text(vm.status?.running == true ? "Running" : "Stopped").font(.system(size: 18, weight: .semibold)).foregroundStyle(vm.status?.running == true ? RouaTheme.Colors.profit : RouaTheme.Colors.textSecondary)
                                }
                            }
                            Spacer()
                            if let strategy = vm.status?.strategy {
                                Text(strategy.capitalized).font(.system(size: 12, weight: .medium)).foregroundStyle(RouaTheme.Colors.accent).padding(.horizontal, 10).padding(.vertical, 4).background(RouaTheme.Colors.accent.opacity(0.15)).clipShape(Capsule())
                            }
                        }
                        HStack(spacing: RouaTheme.Spacing.lg) {
                            if let trades = vm.status?.tradesCount { StatMini(title: "Trades", value: "\(trades)") }
                            if let pnl = vm.status?.pnl { StatMini(title: "P&L", value: String(format: "$%.2f", pnl), isPositive: pnl >= 0) }
                            if let startedAt = vm.status?.startedAt { StatMini(title: "Started", value: String(startedAt.prefix(10))) }
                        }
                    }
                }
                
                // Performance
                if let perf = vm.performance {
                    GlassCard {
                        VStack(spacing: RouaTheme.Spacing.md) {
                            Text("Performance").font(.system(size: 14, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                            HStack(spacing: RouaTheme.Spacing.lg) {
                                if let wr = perf.winRate { StatMini(title: "Win Rate", value: String(format: "%.0f%%", wr * 100), isPositive: wr > 0.5) }
                                if let sr = perf.sharpeRatio { StatMini(title: "Sharpe", value: String(format: "%.2f", sr)) }
                                if let dd = perf.maxDrawdown { StatMini(title: "Max DD", value: String(format: "%.1f%%", dd * 100), isPositive: false) }
                            }
                            if let totalPnl = perf.totalPnl {
                                HStack { Text("Total P&L").font(.system(size: 12)).foregroundStyle(RouaTheme.Colors.textTertiary); Spacer(); Text(String(format: "$%.2f", totalPnl)).font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundStyle(totalPnl >= 0 ? RouaTheme.Colors.profit : RouaTheme.Colors.loss) }
                            }
                        }
                    }
                }
                
                // Strategy Selection
                GlassCard {
                    VStack(spacing: RouaTheme.Spacing.md) {
                        Text("Strategy").font(.system(size: 14, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                        Picker("Strategy", selection: $vm.selectedStrategy) {
                            ForEach(["momentum", "mean-reversion", "breakout", "scalping", "swing"], id: \.self) { s in Text(s.capitalized).tag(s) }
                        }.pickerStyle(.segmented)
                        TradingButton(title: "Update Strategy", style: .primary, isLoading: false) { Task { await vm.updateStrategy() } }
                    }
                }
                
                // Settings
                GlassCard {
                    VStack(spacing: RouaTheme.Spacing.md) {
                        Text("Settings").font(.system(size: 14, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                        HStack { Text("Max Position Size").font(.system(size: 13)).foregroundStyle(RouaTheme.Colors.textSecondary); Spacer(); TextField("100", text: $vm.maxPositionSize).font(.system(size: 13, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textPrimary).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 80) }
                        HStack { Text("Risk Level").font(.system(size: 13)).foregroundStyle(RouaTheme.Colors.textSecondary); Spacer(); Picker("", selection: $vm.riskLevel) { ForEach(["low", "medium", "high"], id: \.self) { Text($0.capitalized).tag($0) } }.pickerStyle(.menu) }
                        TradingButton(title: "Save Settings", style: .secondary, isLoading: false) { Task { await vm.updateSettings() } }
                    }
                }
                
                // Start / Stop
                HStack(spacing: RouaTheme.Spacing.md) {
                    TradingButton(title: "Start Agent", style: .buy, isLoading: vm.isToggling) { Task { await vm.startAgent() } }
                    TradingButton(title: "Stop Agent", style: .danger, isLoading: vm.isToggling) { Task { await vm.stopAgent() } }
                }
                
                if let err = vm.errorMessage {
                    Text(err).font(.system(size: 12)).foregroundStyle(RouaTheme.Colors.loss).padding().frame(maxWidth: .infinity, alignment: .leading).background(RouaTheme.Colors.lossBackground).clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }.padding(RouaTheme.Spacing.lg)
        }.background(RouaTheme.Colors.background).task { await vm.loadStatus(); await vm.loadPerformance(); await vm.loadSettings() }
        .refreshable { await vm.loadStatus(); await vm.loadPerformance() }
    }
}

// MARK: - ═══════════════════════════════════════
// MARK: - SIGNALS VIEW
// MARK: - ═══════════════════════════════════════

struct SignalsView: View {
    @StateObject private var vm = SignalsViewModel()
    @State private var selectedTab = 0
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaTheme.Spacing.lg) {
                Text("Trading Signals").font(.system(size: 22, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                
                // Generate Signal
                GlassCard {
                    VStack(spacing: RouaTheme.Spacing.md) {
                        Text("Generate Signal").font(.system(size: 14, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                        HStack {
                            TextField("Pair (e.g. BTC/USDT)", text: $vm.generatePair).font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textPrimary).tint(RouaTheme.Colors.accent).padding().background(RouaTheme.Colors.surfaceElevated).clipShape(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md))
                        }
                        TradingButton(title: "Generate Signal", style: .primary, isLoading: vm.isGenerating) { Task { await vm.generateSignal() } }
                    }
                }
                
                // Tab Picker
                Picker("Signals", selection: $selectedTab) {
                    Text("Active").tag(0)
                    Text("History").tag(1)
                }.pickerStyle(.segmented)
                
                // Active / History
                let signals = selectedTab == 0 ? vm.activeSignals : vm.signalHistory
                ForEach(signals) { signal in
                    GlassCard {
                        VStack(spacing: RouaTheme.Spacing.sm) {
                            HStack {
                                Text(signal.pair).font(.system(size: 14, weight: .medium)).foregroundStyle(RouaTheme.Colors.textPrimary)
                                Spacer()
                                if let dir = signal.direction {
                                    Text(dir.uppercased()).font(.system(size: 12, weight: .semibold)).foregroundStyle(dir.lowercased() == "buy" ? RouaTheme.Colors.profit : RouaTheme.Colors.loss)
                                        .padding(.horizontal, 8).padding(.vertical, 3).background(dir.lowercased() == "buy" ? RouaTheme.Colors.profitBackground : RouaTheme.Colors.lossBackground).clipShape(Capsule())
                                }
                            }
                            HStack(spacing: RouaTheme.Spacing.lg) {
                                if let ep = signal.entryPrice { StatMini(title: "Entry", value: String(format: "%.2f", ep)) }
                                if let sl = signal.stopLoss { StatMini(title: "Stop", value: String(format: "%.2f", sl), isPositive: false) }
                                if let tp = signal.takeProfit { StatMini(title: "Target", value: String(format: "%.2f", tp), isPositive: true) }
                                if let conf = signal.confidence { StatMini(title: "Confidence", value: String(format: "%.0f%%", conf * 100)) }
                            }
                            if selectedTab == 0 {
                                TradingButton(title: "Execute Signal", style: .primary, isLoading: false) { Task { await vm.executeSignal(id: signal.id) } }
                            }
                        }
                    }
                }
                
                if signals.isEmpty {
                    GlassCard { Text(selectedTab == 0 ? "No active signals" : "No signal history").font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textSecondary).frame(maxWidth: .infinity) }
                }
                
                if let err = vm.errorMessage {
                    Text(err).font(.system(size: 12)).foregroundStyle(RouaTheme.Colors.loss).padding().frame(maxWidth: .infinity, alignment: .leading).background(RouaTheme.Colors.lossBackground).clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }.padding(RouaTheme.Spacing.lg)
        }.background(RouaTheme.Colors.background).task { await vm.loadActiveSignals(); await vm.loadHistory() }
        .refreshable { await vm.loadActiveSignals(); await vm.loadHistory() }
    }
}

// MARK: - ═══════════════════════════════════════
// MARK: - EXECUTOR VIEW
// MARK: - ═══════════════════════════════════════

struct ExecutorView: View {
    @StateObject private var vm = ExecutorViewModel()
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaTheme.Spacing.lg) {
                Text("Smart Executor").font(.system(size: 22, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                
                // Status
                GlassCard {
                    VStack(spacing: RouaTheme.Spacing.md) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Executor Status").font(.system(size: 12, weight: .medium)).foregroundStyle(RouaTheme.Colors.textTertiary)
                                HStack(spacing: 8) {
                                    if vm.status?.active == true { PulsingDot() } else { Circle().fill(RouaTheme.Colors.textTertiary).frame(width: 8, height: 8) }
                                    Text(vm.status?.active == true ? "Active" : "Inactive").font(.system(size: 18, weight: .semibold)).foregroundStyle(vm.status?.active == true ? RouaTheme.Colors.profit : RouaTheme.Colors.textSecondary)
                                }
                            }
                            Spacer()
                            if let mode = vm.status?.mode {
                                Text(mode.uppercased()).font(.system(size: 12, weight: .medium)).foregroundStyle(RouaTheme.Colors.accent).padding(.horizontal, 10).padding(.vertical, 4).background(RouaTheme.Colors.accent.opacity(0.15)).clipShape(Capsule())
                            }
                        }
                        HStack(spacing: RouaTheme.Spacing.lg) {
                            if let trades = vm.status?.tradesExecuted { StatMini(title: "Trades", value: "\(trades)") }
                            if let pnl = vm.status?.pnl { StatMini(title: "P&L", value: String(format: "$%.2f", pnl), isPositive: pnl >= 0) }
                        }
                    }
                }
                
                // Exposure
                if let exposure = vm.exposure {
                    GlassCard {
                        VStack(spacing: RouaTheme.Spacing.md) {
                            Text("Exposure").font(.system(size: 14, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                            if let total = exposure.totalExposure { HStack { Text("Total Exposure").font(.system(size: 13)).foregroundStyle(RouaTheme.Colors.textSecondary); Spacer(); Text(String(format: "$%.2f", total)).font(.system(size: 14, weight: .semibold, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textPrimary) } }
                            if let max = exposure.maxExposure { HStack { Text("Max Exposure").font(.system(size: 13)).foregroundStyle(RouaTheme.Colors.textSecondary); Spacer(); Text(String(format: "$%.2f", max)).font(.system(size: 14, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textTertiary) } }
                            if let pos = exposure.positions { HStack { Text("Open Positions").font(.system(size: 13)).foregroundStyle(RouaTheme.Colors.textSecondary); Spacer(); Text("\(pos)").font(.system(size: 14, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textPrimary) } }
                        }
                    }
                }
                
                // User Enable/Disable
                GlassCard {
                    VStack(spacing: RouaTheme.Spacing.md) {
                        Text("Your Executor").font(.system(size: 14, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                        HStack {
                            Text(vm.userEnabled == true ? "Enabled" : "Disabled").font(.system(size: 14, weight: .medium)).foregroundStyle(vm.userEnabled == true ? RouaTheme.Colors.profit : RouaTheme.Colors.textSecondary)
                            Spacer()
                            if vm.userEnabled == true {
                                TradingButton(title: "Disable", style: .secondary, isLoading: false) { Task { await vm.disableUser() } }
                            } else {
                                TradingButton(title: "Enable", style: .primary, isLoading: false) { Task { await vm.enableUser() } }
                            }
                        }
                    }
                }
                
                // Controls
                HStack(spacing: RouaTheme.Spacing.md) {
                    TradingButton(title: "Start", style: .buy, isLoading: vm.isToggling) { Task { await vm.start() } }
                    TradingButton(title: "Stop", style: .danger, isLoading: vm.isToggling) { Task { await vm.stop() } }
                }
                TradingButton(title: "Emergency Stop", style: .danger, isLoading: false) { Task { await vm.emergencyStop() } }
                
                if let err = vm.errorMessage {
                    Text(err).font(.system(size: 12)).foregroundStyle(RouaTheme.Colors.loss).padding().frame(maxWidth: .infinity, alignment: .leading).background(RouaTheme.Colors.lossBackground).clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }.padding(RouaTheme.Spacing.lg)
        }.background(RouaTheme.Colors.background).task { await vm.loadStatus(); await vm.loadExposure(); await vm.loadUserStatus() }
        .refreshable { await vm.loadStatus(); await vm.loadExposure() }
    }
}

// MARK: - ═══════════════════════════════════════
// MARK: - COUNCIL VIEW
// MARK: - ═══════════════════════════════════════

struct CouncilView: View {
    @StateObject private var vm = CouncilViewModel()
    @State private var selectedTab = 0
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaTheme.Spacing.lg) {
                Text("Strategic Council").font(.system(size: 22, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                
                // Trigger
                GlassCard {
                    VStack(spacing: RouaTheme.Spacing.md) {
                        Text("Trigger Council").font(.system(size: 14, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                        HStack {
                            TextField("Symbol (optional)", text: $vm.triggerSymbol).font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textPrimary).tint(RouaTheme.Colors.accent).padding().background(RouaTheme.Colors.surfaceElevated).clipShape(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md))
                        }
                        TradingButton(title: "Trigger New Council", style: .primary, isLoading: vm.isTriggering) { Task { await vm.triggerCouncil() } }
                    }
                }
                
                Picker("Briefs", selection: $selectedTab) {
                    Text("Active").tag(0)
                    Text("History").tag(1)
                }.pickerStyle(.segmented)
                
                let briefs = selectedTab == 0 ? vm.activeBriefs : vm.briefHistory
                ForEach(briefs) { brief in
                    GlassCard {
                        VStack(spacing: RouaTheme.Spacing.sm) {
                            HStack {
                                Text(brief.symbol).font(.system(size: 14, weight: .medium)).foregroundStyle(RouaTheme.Colors.textPrimary)
                                Spacer()
                                if let action = brief.action {
                                    Text(action.uppercased()).font(.system(size: 12, weight: .semibold)).foregroundStyle(action.lowercased() == "buy" ? RouaTheme.Colors.profit : action.lowercased() == "sell" ? RouaTheme.Colors.loss : RouaTheme.Colors.warning)
                                        .padding(.horizontal, 8).padding(.vertical, 3).background(action.lowercased() == "buy" ? RouaTheme.Colors.profitBackground : action.lowercased() == "sell" ? RouaTheme.Colors.lossBackground : RouaTheme.Colors.warningBackground).clipShape(Capsule())
                                }
                            }
                            if let title = brief.title { Text(title).font(.system(size: 13)).foregroundStyle(RouaTheme.Colors.textSecondary).frame(maxWidth: .infinity, alignment: .leading) }
                            if let summary = brief.summary { Text(summary).font(.system(size: 12)).foregroundStyle(RouaTheme.Colors.textTertiary).lineLimit(3).frame(maxWidth: .infinity, alignment: .leading) }
                            HStack(spacing: RouaTheme.Spacing.lg) {
                                if let conf = brief.confidence { StatMini(title: "Confidence", value: String(format: "%.0f%%", conf * 100)) }
                                if let date = brief.createdAt { StatMini(title: "Date", value: String(date.prefix(10))) }
                            }
                        }
                    }
                }
                
                if briefs.isEmpty {
                    GlassCard { Text(selectedTab == 0 ? "No active briefs" : "No brief history").font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textSecondary).frame(maxWidth: .infinity) }
                }
                
                if let err = vm.errorMessage {
                    Text(err).font(.system(size: 12)).foregroundStyle(RouaTheme.Colors.loss).padding().frame(maxWidth: .infinity, alignment: .leading).background(RouaTheme.Colors.lossBackground).clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }.padding(RouaTheme.Spacing.lg)
        }.background(RouaTheme.Colors.background).task { await vm.loadActiveBriefs(); await vm.loadHistory() }
        .refreshable { await vm.loadActiveBriefs(); await vm.loadHistory() }
    }
}

// MARK: - ═══════════════════════════════════════
// MARK: - NEWS VIEW
// MARK: - ═══════════════════════════════════════

struct NewsView: View {
    @StateObject private var vm = NewsViewModel()
    @State private var analyzeText = ""
    @State private var showAnalyze = false
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaTheme.Spacing.lg) {
                Text("Market News").font(.system(size: 22, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                
                // Sentiment Gauge
                if let sentiment = vm.sentiment {
                    GlassCard {
                        VStack(spacing: RouaTheme.Spacing.md) {
                            Text("Market Sentiment").font(.system(size: 14, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                            HStack(spacing: RouaTheme.Spacing.xl) {
                                if let overall = sentiment.overall {
                                    VStack(spacing: 4) {
                                        Text(overall.capitalized).font(.system(size: 20, weight: .bold)).foregroundStyle(overall.lowercased() == "bullish" ? RouaTheme.Colors.profit : overall.lowercased() == "bearish" ? RouaTheme.Colors.loss : RouaTheme.Colors.warning)
                                        Text("Overall").font(.system(size: 10)).foregroundStyle(RouaTheme.Colors.textTertiary)
                                    }
                                }
                                if let score = sentiment.score {
                                    VStack(spacing: 4) {
                                        Text(String(format: "%.0f", score * 100)).font(.system(size: 20, weight: .bold, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textPrimary)
                                        Text("Score").font(.system(size: 10)).foregroundStyle(RouaTheme.Colors.textTertiary)
                                    }
                                }
                                if let fgi = sentiment.fearGreedIndex {
                                    VStack(spacing: 4) {
                                        Text("\(fgi)").font(.system(size: 20, weight: .bold, design: .monospaced)).foregroundStyle(fgi > 60 ? RouaTheme.Colors.profit : fgi < 40 ? RouaTheme.Colors.loss : RouaTheme.Colors.warning)
                                        Text("Fear/Greed").font(.system(size: 10)).foregroundStyle(RouaTheme.Colors.textTertiary)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Symbol Filter
                HStack {
                    TextField("Filter by symbol", text: $vm.symbol).font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textPrimary).tint(RouaTheme.Colors.accent).padding().background(RouaTheme.Colors.surfaceElevated).clipShape(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md))
                    Button { Task { await vm.loadLatest() } } label: { Image(systemName: "arrow.clockwise").foregroundStyle(RouaTheme.Colors.accent).padding() }
                }
                
                // Analyze Button
                Button { showAnalyze = true } label: {
                    HStack { Image(systemName: "text.magnifyingglass"); Text("Analyze News Text") }.font(.system(size: 14, weight: .medium)).foregroundStyle(RouaTheme.Colors.accent).frame(maxWidth: .infinity).padding().background(RouaTheme.Colors.accent.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md))
                }
                
                // Analysis Result
                if let result = vm.analysisResult {
                    GlassCard {
                        VStack(spacing: RouaTheme.Spacing.sm) {
                            Text("Analysis Result").font(.system(size: 14, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                            if let sent = result.sentiment { HStack { Text("Sentiment").font(.system(size: 12)).foregroundStyle(RouaTheme.Colors.textTertiary); Spacer(); Text(sent.capitalized).font(.system(size: 13, weight: .medium)).foregroundStyle(sent.lowercased() == "positive" ? RouaTheme.Colors.profit : sent.lowercased() == "negative" ? RouaTheme.Colors.loss : RouaTheme.Colors.warning) } }
                            if let score = result.score { HStack { Text("Score").font(.system(size: 12)).foregroundStyle(RouaTheme.Colors.textTertiary); Spacer(); Text(String(format: "%.2f", score)).font(.system(size: 13, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textPrimary) } }
                            if let summary = result.summary { Text(summary).font(.system(size: 12)).foregroundStyle(RouaTheme.Colors.textSecondary).frame(maxWidth: .infinity, alignment: .leading) }
                        }
                    }
                }
                
                // Articles
                ForEach(vm.articles) { article in
                    GlassCard {
                        VStack(spacing: RouaTheme.Spacing.sm) {
                            Text(article.title).font(.system(size: 14, weight: .medium)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                            if let summary = article.summary { Text(summary).font(.system(size: 12)).foregroundStyle(RouaTheme.Colors.textTertiary).lineLimit(2).frame(maxWidth: .infinity, alignment: .leading) }
                            HStack {
                                if let source = article.source { Text(source).font(.system(size: 10)).foregroundStyle(RouaTheme.Colors.textTertiary) }
                                Spacer()
                                if let sentiment = article.sentiment {
                                    Text(sentiment.capitalized).font(.system(size: 10, weight: .medium)).foregroundStyle(sentiment.lowercased() == "positive" ? RouaTheme.Colors.profit : sentiment.lowercased() == "negative" ? RouaTheme.Colors.loss : RouaTheme.Colors.warning)
                                }
                                if let date = article.publishedAt { Text(String(date.prefix(10))).font(.system(size: 10)).foregroundStyle(RouaTheme.Colors.textTertiary) }
                            }
                        }
                    }
                }
                
                if vm.articles.isEmpty && !vm.isLoading {
                    GlassCard { Text("No news articles").font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textSecondary).frame(maxWidth: .infinity) }
                }
            }.padding(RouaTheme.Spacing.lg)
        }.background(RouaTheme.Colors.background).task { await vm.loadLatest(); await vm.loadSentiment() }
        .refreshable { await vm.loadLatest(); await vm.loadSentiment() }
        .alert("Analyze News", isPresented: $showAnalyze) {
            TextField("Paste news text", text: $analyzeText)
            Button("Analyze") { Task { await vm.analyzeNews(text: analyzeText); analyzeText = "" } }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - ═══════════════════════════════════════
// MARK: - NOTIFICATIONS VIEW
// MARK: - ═══════════════════════════════════════

struct NotificationsView: View {
    @StateObject private var vm = NotificationsViewModel()
    @State private var pushEnabled = true
    @State private var tradeAlerts = true
    @State private var signalAlerts = true
    @State private var newsAlerts = false
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaTheme.Spacing.lg) {
                HStack {
                    Text("Notifications").font(.system(size: 22, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary)
                    Spacer()
                    if vm.unreadCount > 0 {
                        Text("\(vm.unreadCount)").font(.system(size: 12, weight: .bold)).foregroundStyle(.white).padding(.horizontal, 8).padding(.vertical, 4).background(RouaTheme.Colors.accent).clipShape(Capsule())
                    }
                    Button { Task { await vm.markAllRead() } } label: {
                        Text("Mark All Read").font(.system(size: 12, weight: .medium)).foregroundStyle(RouaTheme.Colors.accent)
                    }
                }
                
                // Preferences
                GlassCard {
                    VStack(spacing: RouaTheme.Spacing.md) {
                        Text("Preferences").font(.system(size: 14, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                        Toggle(isOn: $pushEnabled) { Text("Push Notifications").font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textPrimary) }.tint(RouaTheme.Colors.accent).onChange(of: pushEnabled) { _, newVal in Task { await vm.updatePreferences(pushEnabled: newVal, emailEnabled: nil, tradeAlerts: nil, signalAlerts: nil, newsAlerts: nil) } }
                        Toggle(isOn: $tradeAlerts) { Text("Trade Alerts").font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textPrimary) }.tint(RouaTheme.Colors.accent).onChange(of: tradeAlerts) { _, newVal in Task { await vm.updatePreferences(pushEnabled: nil, emailEnabled: nil, tradeAlerts: newVal, signalAlerts: nil, newsAlerts: nil) } }
                        Toggle(isOn: $signalAlerts) { Text("Signal Alerts").font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textPrimary) }.tint(RouaTheme.Colors.accent).onChange(of: signalAlerts) { _, newVal in Task { await vm.updatePreferences(pushEnabled: nil, emailEnabled: nil, tradeAlerts: nil, signalAlerts: newVal, newsAlerts: nil) } }
                        Toggle(isOn: $newsAlerts) { Text("News Alerts").font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textPrimary) }.tint(RouaTheme.Colors.accent).onChange(of: newsAlerts) { _, newVal in Task { await vm.updatePreferences(pushEnabled: nil, emailEnabled: nil, tradeAlerts: nil, signalAlerts: nil, newsAlerts: newVal) } }
                    }
                }
                
                // Notification List
                ForEach(vm.notifications) { notif in
                    GlassCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    if !notif.isRead { Circle().fill(RouaTheme.Colors.accent).frame(width: 6, height: 6) }
                                    Text(notif.title).font(.system(size: 14, weight: notif.isRead ? .regular : .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary)
                                }
                                if let body = notif.body { Text(body).font(.system(size: 12)).foregroundStyle(RouaTheme.Colors.textSecondary).lineLimit(2) }
                                Text(String(notif.createdAt.prefix(16))).font(.system(size: 10)).foregroundStyle(RouaTheme.Colors.textTertiary)
                            }
                            Spacer()
                            if !notif.isRead {
                                Button { Task { await vm.markRead(id: notif.id) } } label: {
                                    Image(systemName: "checkmark.circle").foregroundStyle(RouaTheme.Colors.accent)
                                }
                            }
                        }
                    }
                }
                
                if vm.notifications.isEmpty && !vm.isLoading {
                    GlassCard { Text("No notifications").font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textSecondary).frame(maxWidth: .infinity) }
                }
            }.padding(RouaTheme.Spacing.lg)
        }.background(RouaTheme.Colors.background).task { await vm.loadNotifications(); await vm.loadUnreadCount(); await vm.loadPreferences() }
        .refreshable { await vm.loadNotifications(); await vm.loadUnreadCount() }
    }
}

// MARK: - ═══════════════════════════════════════
// MARK: - MORE MENU VIEW
// MARK: - ═══════════════════════════════════════

struct MoreMenuView: View {
    struct MenuItem: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let color: Color
        let destination: MoreDestination
    }
    
    enum MoreDestination {
        case portfolio, scanner, agent, signals, executor, council, news, notifications, settings
    }
    
    let menuItems: [MenuItem] = [
        MenuItem(title: "Portfolio", icon: "wallet.pass", color: RouaTheme.Colors.accent, destination: .portfolio),
        MenuItem(title: "Scanner", icon: "magnifyingglass", color: RouaTheme.Colors.info, destination: .scanner),
        MenuItem(title: "AI Agent", icon: "robot", color: RouaTheme.Colors.profit, destination: .agent),
        MenuItem(title: "Signals", icon: "antenna.radiowaves.left.and.right", color: RouaTheme.Colors.warning, destination: .signals),
        MenuItem(title: "Smart Executor", icon: "bolt.circle", color: RouaTheme.Colors.accentLight, destination: .executor),
        MenuItem(title: "Strategic Council", icon: "person.3", color: Color(hex: "8B5CF6"), destination: .council),
        MenuItem(title: "News", icon: "newspaper", color: RouaTheme.Colors.info, destination: .news),
        MenuItem(title: "Notifications", icon: "bell", color: RouaTheme.Colors.warning, destination: .notifications),
        MenuItem(title: "Settings", icon: "gearshape", color: RouaTheme.Colors.textTertiary, destination: .settings)
    ]
    
    var body: some View {
        List(menuItems) { item in
            NavigationLink(value: item.destination) {
                HStack(spacing: RouaTheme.Spacing.lg) {
                    ZStack {
                        RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md).fill(item.color.opacity(0.15)).frame(width: 40, height: 40)
                        Image(systemName: item.icon).font(.system(size: 16, weight: .medium)).foregroundStyle(item.color)
                    }
                    Text(item.title).font(.system(size: 16, weight: .medium)).foregroundStyle(RouaTheme.Colors.textPrimary)
                }
                .padding(.vertical, RouaTheme.Spacing.xs)
                .listRowBackground(Color.clear)
            }
        }.listStyle(.plain)
        .background(RouaTheme.Colors.background)
        .navigationTitle("More")
        .navigationDestination(for: MoreDestination.self) { destination in
            switch destination {
            case .portfolio: PortfolioView()
            case .scanner: ScannerView()
            case .agent: AgentView()
            case .signals: SignalsView()
            case .executor: ExecutorView()
            case .council: CouncilView()
            case .news: NewsView()
            case .notifications: NotificationsView()
            case .settings: SettingsView()
            }
        }
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
                case 3: NavigationStack { MoreMenuView() }
                default: EmptyView()
                }
            }.padding(.bottom, 80)
            
            VStack(spacing: 0) {
                Divider().background(RouaTheme.Colors.border)
                HStack {
                    ForEach(0..<4, id: \.self) { i in
                        tabItem(i)
                    }
                }.padding(.horizontal, RouaTheme.Spacing.md).padding(.top, RouaTheme.Spacing.sm).padding(.bottom, RouaTheme.Spacing.lg)
                .background(RouaTheme.Colors.surface.opacity(0.95)).background(.ultraThinMaterial)
            }
        }.background(RouaTheme.Colors.background)
    }
    
    private let tabs = [("Dashboard", "square.grid.2x2"), ("Trade", "chart.line.uptrend.xyaxis"), ("AI", "brain"), ("More", "ellipsis")]
    
    private func tabItem(_ index: Int) -> some View {
        Button { withAnimation(.easeInOut(duration: 0.2)) { selectedTab = index } } label: {
            VStack(spacing: 4) {
                Image(systemName: tabs[index].1).font(.system(size: 20)).foregroundStyle(selectedTab == index ? RouaTheme.Colors.accent : RouaTheme.Colors.textTertiary)
                Text(tabs[index].0).font(.system(size: 10, weight: .medium)).foregroundStyle(selectedTab == index ? RouaTheme.Colors.accent : RouaTheme.Colors.textTertiary)
            }.frame(maxWidth: .infinity)
        }
    }
}
