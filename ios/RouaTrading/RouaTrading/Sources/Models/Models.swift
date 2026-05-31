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

    var isValid: Bool {
        authenticated == true || success == true
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
    var lastPrice: Double { price ?? close ?? 0 }
}

struct QuoteResponse: Codable {
    let success: Bool?
    let data: Quote?
}

// MARK: - Candle Data (for WebSocket + REST)
struct CandleData: Codable, Identifiable {
    var id: TimeInterval { time }
    let time: TimeInterval
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
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
    let stopLoss: Double?
    let takeProfit: Double?
    let highestPrice: Double?
    let lowestPrice: Double?
    let realizedPnl: Double?
    let openedAt: String?
    let credentialId: String?
    let version: Int?
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
    let createdAt: String
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
