import Foundation

// MARK: - Auth Models
struct AuthUser: Codable {
    let id: String
    let email: String
    let displayName: String?
    let tier: String
}

// Auth/me returns { authenticated: true, user: {...} }
struct AuthVerifyResponse: Codable {
    let authenticated: Bool?
    let success: Bool?       // fallback for other endpoints
    let user: AuthUser?
    let error: String?       // for error cases like EMAIL_NOT_VERIFIED
    let message: String?     // optional message from backend

    var isValid: Bool {
        (authenticated == true || success == true) && user != nil
    }
}

struct AuthRegisterRequest: Codable {
    let email: String
    let displayName: String?
}

struct GoogleAuthCallback: Codable {
    let token: String
    let refresh: String?
    let userId: String?
}

// MARK: - Market Data Models

// GET /api/exchange/quote/:symbol → { success: true, data: UnifiedQuoteDto }
struct Quote: Codable {
    let symbol: String
    let name: String?
    let exchange: String?
    let currency: String?
    let price: Double?
    let change: Double?
    let changePercent: Double?
    let open: Double?
    let high: Double?
    let low: Double?
    let close: Double?
    let volume: Double?
    let marketCap: Double?
    let source: String?
    let timestamp: String?
    let cached: Bool?

    // Computed helpers
    var last: Double? { price ?? close }
    var lastPrice: Double { price ?? close ?? 0 }
}

struct QuoteResponse: Codable {
    let success: Bool?
    let data: Quote?
}

// MARK: - Candle Data (for WebSocket + REST)
// Backend returns `timestamp` as ISO string "2026-05-23T14:00:00.000Z"
// and also has `datetime` field. We accept both timestamp (string or number)
// and fall back to `time` (for WebSocket candles which use numeric seconds).
struct CandleData: Codable, Identifiable {
    var id: TimeInterval { resolvedTime }
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double

    // Backend fields (can be string or number)
    private let timestamp: TimestampValue?
    private let datetime: String?

    // Computed: resolve to seconds since epoch
    var resolvedTime: TimeInterval {
        if let ts = timestamp {
            return ts.timeInterval
        }
        // Fallback: parse datetime string
        if let dt = datetime {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dt) {
                return date.timeIntervalSince1970
            }
        }
        return 0
    }

    // Convenience for chart (alias)
    var time: TimeInterval { resolvedTime }

    // Manual init for WebSocket live candles (numeric time)
    init(time: TimeInterval, open: Double, high: Double, low: Double, close: Double, volume: Double) {
        self.timestamp = TimestampValue(value: time)
        self.datetime = nil
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
    }
}

// Type that can decode both String and Number timestamps
struct TimestampValue: Codable {
    let value: TimeInterval

    init(value: TimeInterval) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let stringVal = try? container.decode(String.self) {
            // ISO date string -> epoch seconds
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: stringVal) {
                value = date.timeIntervalSince1970
            } else {
                value = Double(stringVal) ?? 0
            }
        } else {
            value = 0
        }
    }

    var timeInterval: TimeInterval { value }
}

// MARK: - Trading Models

// GET /api/trading/positions → raw array of Position
struct Position: Codable, Identifiable {
    let id: String
    let userId: String
    let exchange: String?
    let symbol: String
    let side: String            // "BUY" or "SELL"
    let status: String
    let quantity: Double
    let entryPrice: Double
    let currentPrice: Double?
    let unrealizedPnl: Double?
    let unrealizedPnL: Double?  // backend uses PnL (capital L)
    let stopLoss: Double?
    let takeProfit: Double?
    let highestPrice: Double?
    let lowestPrice: Double?
    let realizedPnl: Double?
    let openedAt: String?
    let credentialId: String?
    let version: Int?

    // Computed alias for view compatibility
    var unrealizedPnlValue: Double? { unrealizedPnl ?? unrealizedPnL }
}

// GET /api/trading/history → { success: true, trades: [...] }
// NOTE: Field names differ from Position! side is "long"/"short", qty not quantity
struct Trade: Codable, Identifiable {
    let id: String
    let symbol: String
    let side: String            // "long" or "short" (NOT "BUY"/"SELL")
    let entryPrice: Double?
    let exitPrice: Double?
    let qty: Double?
    let realizedPnl: Double?
    let realizedPct: Double?
    let closeTime: Int64?       // epoch milliseconds
    let status: String?

    // Computed for view compatibility
    var quantity: Double { qty ?? 0 }
    var price: Double { exitPrice ?? entryPrice ?? 0 }
    var pnl: Double? { realizedPnl }
    var createdAt: String {
        if let ct = closeTime {
            let date = Date(timeIntervalSince1970: Double(ct) / 1000)
            let formatter = ISO8601DateFormatter()
            return formatter.string(from: date)
        }
        return ""
    }
}

struct TradeHistoryResponse: Codable {
    let success: Bool?
    let trades: [Trade]?
}

// GET /api/trading/account → raw object
struct AccountOverview: Codable {
    let totalPositions: Int?
    let totalValue: Double?
    let totalUnrealizedPnl: Double?
    let totalRealizedPnl: Double?
    let usedMargin: Double?
    let positions: [Position]?
}

// PortfolioSummary for UI (derived from AccountOverview)
struct PortfolioSummary {
    let totalValue: Double
    let totalPnl: Double
    let dailyPnl: Double
    let positions: [Position]?
    let unrealizedPnl: Double?
    let realizedPnl: Double?
}

// POST /api/trading/orders
struct PlaceOrderRequest: Codable {
    let exchangeCredentialId: String
    let symbol: String
    let side: String
    let type: String
    let quantity: Double
    let price: Double?
    let stopLoss: Double?
    let takeProfit: Double?
    let idempotencyKey: String
    let clientOrderId: String?
}

struct V2PlaceOrderResponse: Codable {
    let success: Bool?
    let data: V2OrderData?
    let orderId: String?        // some endpoints return flat
    let status: String?
}

struct V2OrderData: Codable {
    let orderId: String?
    let status: String?
    let idempotencyKey: String?
    let riskScore: Double?
}

// MARK: - Scanner Models

// GET /api/scanner/scan → { items: [...], meta: {...} }
struct ScannerScanResponse: Codable {
    let success: Bool?
    let items: [ScanResult]?
    let meta: ScannerMeta?
}

struct ScannerMeta: Codable {
    let timeframe: String?
    let category: String?
    let symbolsScanned: Int?
    let source: String?
    let timestamp: String?
    let nextScanInSeconds: Int?
}

struct ScanResult: Codable, Identifiable {
    var id: String { symbol }
    let symbol: String
    let name: String?
    let category: String?
    let price: Double?
    let change: Double?
    let changePercent: Double?
    let volume: Double?
    let direction: String?     // "BUY" / "SELL" / "NEUTRAL"
    let signalClass: String?
    let signal: String?        // alias for signalClass (some endpoints use this)
    let technicalScore: Int?
    let confidence: Int?
    let rsi: Double?
    let macdSignal: String?
    let reasons: [String]?
    let reasonsAr: [String]?
    let sparkline: [Double]?
}

// GET /api/scanner/heatmap → raw array or { success, data: [...] }
struct HeatmapItem: Codable, Identifiable {
    var id: String { symbol }
    let symbol: String
    let name: String?
    let category: String?
    let changePercent: Double?
    let volume: Double?
    let direction: String?
    let technicalScore: Int?

    // Computed for view compatibility
    var change: Double? { changePercent }
}

// MARK: - AI Models
struct AIAnalyzeRequest: Codable {
    let prompt: String
    let type: String?
    let symbol: String?
    let language: String?

    init(prompt: String, type: String? = nil, symbol: String? = nil, language: String? = nil) {
        self.prompt = prompt
        self.type = type
        self.symbol = symbol
        self.language = language
    }
}

struct AIAnalyzeResponse: Codable {
    let analysis: String?
    let result: String?        // some endpoints use "result" instead
    let model: String?
    let provider: String?

    var text: String { analysis ?? result ?? "لا توجد استجابة" }
}

// MARK: - Portfolio Models

// GET /api/portfolio/credentials → { success: true, data: [...] }
struct ExchangeCredential: Codable, Identifiable {
    let id: String
    let exchange: String
    let label: String
    let testnet: Bool
    let isValid: Bool?
    let permissions: String?
    let lastValidatedAt: String?
    let createdAt: String?

    // Computed for view compatibility
    var isTestnet: Bool { testnet || exchange.lowercased().contains("testnet") || exchange.lowercased().contains("paper") }
}

struct CredentialsResponse: Codable {
    let success: Bool?
    let data: [ExchangeCredential]?
}

// MARK: - Notification Model
struct UserNotification: Codable, Identifiable {
    let id: String
    let type: String
    let title: String
    let body: String?
    let isRead: Bool?
    let createdAt: String
}

// MARK: - Historical Candles (for chart)
// GET /api/exchange/history/:symbol?interval=1h&limit=500
struct CandleHistoryResponse: Codable {
    let success: Bool?
    let data: [CandleData]?
}

// MARK: - API Response Wrappers
struct ApiResponseWrapper: Codable {
    let success: Bool?
    let authenticated: Bool?
    let data: AnyCodable?
    let items: AnyCodable?     // for scanner scan
    let trades: AnyCodable?    // for trading history
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

// MARK: - API Error
enum APIError: LocalizedError {
    case unauthorized
    case noConnection
    case timeout
    case serverError(Int, String)
    case networkError(String)
    case decodingError(String)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً"
        case .noConnection: return "لا يوجد اتصال بالإنترنت"
        case .timeout: return "انتهت مهلة الطلب"
        case .serverError(let code, let msg): return "خطأ الخادم \(code): \(msg)"
        case .networkError(let msg): return msg
        case .decodingError(let msg): return "خطأ في تحليل البيانات: \(msg)"
        case .unknown(let error): return error.localizedDescription
        }
    }
}

// MARK: - Extended Models (for advanced features)

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
