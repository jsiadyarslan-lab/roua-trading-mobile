// ============================================================================
// MarketModels.swift
// RouaTrading — Market data models: quotes, candles, scanner, heatmap,
// deep analysis, and multi-timeframe results.
// ============================================================================

import Foundation

// MARK: - Quote

/// Real-time or latest quote for a symbol.
struct Quote: Codable, Identifiable, Hashable {
    /// Symbol serves as the unique identifier.
    var id: String { symbol }

    let symbol: String
    let price: Double
    let change: Double
    let changePct: Double
    let high: Double
    let low: Double
    let open: Double
    let volume: Double
    let bid: Double?
    let ask: Double?
    let timestamp: String
    let source: String?

    // ---- Coding Keys (backend field names → Swift) ----

    enum CodingKeys: String, CodingKey {
        case symbol, price, change, high, low, open, volume
        case changePct = "changePercent"
        case bid, ask, timestamp, source
        // Backend also sends: name, exchange, currency, close, marketCap, etc.
        // These are ignored during decoding.
    }

    // ---- Custom decoder with fallback defaults ----

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        symbol    = try c.decode(String.self, forKey: .symbol)
        price     = try c.decode(Double.self, forKey: .price)
        change    = try c.decodeIfPresent(Double.self, forKey: .change) ?? 0
        changePct = try c.decodeIfPresent(Double.self, forKey: .changePct) ?? 0
        high      = try c.decodeIfPresent(Double.self, forKey: .high) ?? 0
        low       = try c.decodeIfPresent(Double.self, forKey: .low) ?? 0
        open      = try c.decodeIfPresent(Double.self, forKey: .open) ?? 0
        volume    = try c.decodeIfPresent(Double.self, forKey: .volume) ?? 0
        bid       = try c.decodeIfPresent(Double.self, forKey: .bid)
        ask       = try c.decodeIfPresent(Double.self, forKey: .ask)
        // Backend may send timestamp as String (ISO-8601) or missing entirely
        if let ts = try? c.decodeIfPresent(String.self, forKey: .timestamp) {
            timestamp = ts
        } else {
            timestamp = ""
        }
        source    = try c.decodeIfPresent(String.self, forKey: .source)
    }

    // ---- Direct memberwise init ----

    init(symbol: String, price: Double, change: Double = 0, changePct: Double = 0,
         high: Double = 0, low: Double = 0, open: Double = 0, volume: Double = 0,
         bid: Double? = nil, ask: Double? = nil, timestamp: String = "", source: String? = nil) {
        self.symbol = symbol
        self.price = price
        self.change = change
        self.changePct = changePct
        self.high = high
        self.low = low
        self.open = open
        self.volume = volume
        self.bid = bid
        self.ask = ask
        self.timestamp = timestamp
        self.source = source
    }

    // ---- Computed helpers ----

    /// Whether the quote shows positive movement.
    var isPositive: Bool { change >= 0 }

    /// Spread between bid and ask.
    var spread: Double? {
        guard let b = bid, let a = ask else { return nil }
        return a - b
    }

    /// Formatted change percentage, e.g. "+2.35%".
    var formattedChangePct: String {
        let prefix = changePct >= 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.2f", changePct))%"
    }
}

// MARK: - Candle Data

/// A single OHLCV candle for chart rendering.
///
/// The backend `/exchange/history/:symbol` returns candles in this format:
/// ```json
/// {
///   "symbol": "BTC/USD",
///   "timestamp": "2026-05-25T03:00:00.000Z",
///   "open": 77108.77, "high": 77169.88, "low": 77002.3, "close": 77026.67,
///   "volume": 198.70522, "source": "Binance"
/// }
/// ```
/// We map `timestamp` (ISO 8601 String) → `time` (Int unix seconds) so the
/// LightweightCharts library can consume it directly.
struct CandleData: Codable, Identifiable, Hashable {
    /// Time serves as the unique identifier.
    var id: Int { time }

    /// Unix timestamp (seconds).
    let time: Int
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double

    // ---- Coding Keys (backend field names → Swift) ----

    enum CodingKeys: String, CodingKey {
        case time        // local unix-time key (set in decoder)
        case timestamp   // backend ISO-8601 key
        case open, high, low, close, volume
        case source
    }

    // ---- Custom decoder: convert ISO-8601 `timestamp` → Int `time` ----

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        open   = try container.decode(Double.self, forKey: .open)
        high   = try container.decode(Double.self, forKey: .high)
        low    = try container.decode(Double.self, forKey: .low)
        close  = try container.decode(Double.self, forKey: .close)
        volume = try container.decode(Double.self, forKey: .volume)

        // The backend sends `timestamp` as ISO-8601 string.
        // If `time` is present (unix int), use it directly; otherwise parse timestamp.
        if let unixTime = try? container.decodeIfPresent(Int.self, forKey: .time) {
            time = unixTime
        } else if let tsString = try? container.decodeIfPresent(String.self, forKey: .timestamp) {
            // Parse ISO-8601 → Date → unix seconds
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: tsString) {
                time = Int(date.timeIntervalSince1970)
            } else {
                // Fallback: try without fractional seconds
                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: tsString) {
                    time = Int(date.timeIntervalSince1970)
                } else {
                    time = 0
                }
            }
        } else {
            time = 0
        }
    }

    // ---- Custom encoder: write `time` as `timestamp` ISO-8601 string ----

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(open, forKey: .open)
        try container.encode(high, forKey: .high)
        try container.encode(low, forKey: .low)
        try container.encode(close, forKey: .close)
        try container.encode(volume, forKey: .volume)
        // Encode the unix `time` back as an ISO-8601 `timestamp` string
        let date = Date(timeIntervalSince1970: TimeInterval(time))
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(formatter.string(from: date), forKey: .timestamp)
    }

    // ---- Direct memberwise init ----

    init(time: Int, open: Double, high: Double, low: Double, close: Double, volume: Double) {
        self.time = time
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
    }

    /// Whether the candle is bullish (close ≥ open).
    var isBullish: Bool { close >= open }

    /// Body size of the candle.
    var bodySize: Double { abs(close - open) }

    /// Upper wick length.
    var upperWick: Double { high - max(open, close) }

    /// Lower wick length.
    var lowerWick: Double { min(open, close) - low }
}

// MARK: - OHLCV

/// Alternative naming for `CandleData` when the API shape differs slightly.
struct OHLCV: Codable, Identifiable, Hashable {
    var id: Int { time }

    let time: Int
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
}

// MARK: - Scanner Result

/// A single result from the market scanner.
///
/// The backend `/scanner/overview` and `/scanner/heatmap` endpoints return items
/// with field names that differ from the original model expectations.  CodingKeys
/// map the wire names to the Swift property names so decoding succeeds while
/// keeping the public API clean.
struct ScannerResult: Codable, Identifiable, Hashable {
    var id: String { symbol }

    let symbol: String
    let name: String?
    let price: Double
    /// Absolute price change (may be 0 if the backend omits it).
    let change: Double
    /// Percentage change.  Backend sends `changePercent`.
    let changePct: Double
    let volume: Double
    /// Signal direction.  Backend sends `direction` as a `SignalDirection` raw value.
    let signal: SignalDirection
    /// Signal strength.  Backend sends `technicalScore` (may be negative).
    let strength: Int
    /// Technical indicators map (RSI, MACD, etc.).  Optional – present in
    /// `/scanner/strongest-signals` but not in `/scanner/overview` top-level items.
    let indicators: [String: Double]?
    /// Timeframe string.  Optional – not always present in overview items.
    let timeframe: String?
    let category: MarketCategory
    /// Market cap.  Backend sends `marketCap` (nullable).
    let marketCap: Double?

    // ---- Coding Keys (backend → Swift) ----

    enum CodingKeys: String, CodingKey {
        case symbol
        case name
        case price
        case change
        case changePct = "changePercent"
        case volume
        case signal = "direction"
        case strength = "technicalScore"
        case indicators
        case timeframe
        case category
        case marketCap
    }

    // ---- Custom decoder with fallback defaults for optional fields ----

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        symbol    = try container.decode(String.self, forKey: .symbol)
        name      = try container.decodeIfPresent(String.self, forKey: .name)
        price     = try container.decodeIfPresent(Double.self, forKey: .price) ?? 0
        change    = try container.decodeIfPresent(Double.self, forKey: .change) ?? 0
        changePct = try container.decodeIfPresent(Double.self, forKey: .changePct) ?? 0
        volume    = try container.decodeIfPresent(Double.self, forKey: .volume) ?? 0
        signal    = try container.decodeIfPresent(SignalDirection.self, forKey: .signal) ?? .neutral
        strength  = try container.decodeIfPresent(Int.self, forKey: .strength) ?? 0
        indicators = try container.decodeIfPresent([String: Double].self, forKey: .indicators)
        timeframe  = try container.decodeIfPresent(String.self, forKey: .timeframe)
        category   = try container.decodeIfPresent(MarketCategory.self, forKey: .category) ?? .all
        marketCap  = try container.decodeIfPresent(Double.self, forKey: .marketCap)
    }

    // ---- Direct memberwise init ----

    init(symbol: String, name: String? = nil, price: Double, change: Double = 0,
         changePct: Double, volume: Double, signal: SignalDirection, strength: Int,
         indicators: [String: Double]? = nil, timeframe: String? = nil,
         category: MarketCategory, marketCap: Double? = nil) {
        self.symbol = symbol
        self.name = name
        self.price = price
        self.change = change
        self.changePct = changePct
        self.volume = volume
        self.signal = signal
        self.strength = strength
        self.indicators = indicators
        self.timeframe = timeframe
        self.category = category
        self.marketCap = marketCap
    }

    // ---- Computed helpers ----

    /// Formatted change percentage.
    var formattedChangePct: String {
        let prefix = changePct >= 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.2f", changePct))%"
    }

    /// Whether the scanner signal is actionable (strong buy / strong sell).
    var isActionable: Bool {
        signal == .strongBuy || signal == .strongSell
    }

    /// Strength bucket label for UI.
    var strengthLabel: String {
        let absStrength = abs(strength)
        switch absStrength {
        case 80...100: return "Very Strong"
        case 60..<80:  return "Strong"
        case 40..<60:  return "Moderate"
        case 20..<40:  return "Weak"
        default:       return "Very Weak"
        }
    }
}

// MARK: - Heatmap Item

/// A single tile on the market heatmap.
///
/// The `/scanner/heatmap` endpoint returns the same shape as `ScannerResult`
/// so this type reuses the same CodingKeys mapping.
struct HeatmapItem: Codable, Identifiable, Hashable {
    var id: String { symbol }

    let symbol: String
    let name: String?
    let price: Double
    let change: Double
    let changePct: Double
    let volume: Double
    let category: MarketCategory
    let marketCap: Double?
    /// Signal direction from backend `direction` field.
    let direction: SignalDirection
    /// Technical score from backend `technicalScore` field.
    let technicalScore: Int

    // ---- Coding Keys ----

    enum CodingKeys: String, CodingKey {
        case symbol
        case name
        case price
        case change
        case changePct = "changePercent"
        case volume
        case category
        case marketCap
        case direction
        case technicalScore
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        symbol         = try container.decode(String.self, forKey: .symbol)
        name           = try container.decodeIfPresent(String.self, forKey: .name)
        price          = try container.decodeIfPresent(Double.self, forKey: .price) ?? 0
        change         = try container.decodeIfPresent(Double.self, forKey: .change) ?? 0
        changePct      = try container.decodeIfPresent(Double.self, forKey: .changePct) ?? 0
        volume         = try container.decodeIfPresent(Double.self, forKey: .volume) ?? 0
        category       = try container.decodeIfPresent(MarketCategory.self, forKey: .category) ?? .all
        marketCap      = try container.decodeIfPresent(Double.self, forKey: .marketCap)
        direction      = try container.decodeIfPresent(SignalDirection.self, forKey: .direction) ?? .neutral
        technicalScore = try container.decodeIfPresent(Int.self, forKey: .technicalScore) ?? 0
    }

    /// Relative size weight for heatmap rendering (market-cap based).
    var sizeWeight: Double { marketCap ?? volume }

    /// Color intensity factor 0…1 based on absolute change percentage.
    var colorIntensity: Double {
        min(abs(changePct) / 10.0, 1.0)
    }

    /// Formatted change percentage, e.g. "+2.35%".
    var formattedChangePct: String {
        let prefix = changePct >= 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.2f", changePct))%"
    }
}

// MARK: - Market Overview

/// Top-level market summary including sentiment indices and movers.
///
/// The backend `/scanner/overview` returns:
/// ```json
/// {
///   "totalScanned": 10,
///   "bullishCount": 2,
///   "bearishCount": 8,
///   "neutralCount": 0,
///   "topGainers": [...],
///   "topLosers": [...],
///   "strongestSignals": [...],
///   "marketSentiment": "BEARISH",
///   "sentimentScore": -20,
///   "timestamp": "..."
/// }
/// ```
struct MarketOverview: Codable {
    let totalScanned: Int?
    let bullishCount: Int?
    let bearishCount: Int?
    let neutralCount: Int?
    let topGainers: [ScannerResult]
    let topLosers: [ScannerResult]
    /// Backend sends `strongestSignals` — we expose it as `strongestSignals`.
    let strongestSignals: [ScannerResult]?
    /// Overall market sentiment, e.g. "BEARISH" or "BULLISH".
    let marketSentiment: String?
    /// Numeric sentiment score (negative = bearish, positive = bullish).
    let sentimentScore: Double?
    let timestamp: String?

    // Legacy optional fields – may be added by the backend in the future.
    let totalMarketCap: Double?
    let totalVolume: Double?
    let btcDominance: Double?
    let fearGreedIndex: Int?
    let fearGreedLabel: String?
    let activeCryptos: Int?

    // ---- Coding Keys ----

    enum CodingKeys: String, CodingKey {
        case totalScanned
        case bullishCount
        case bearishCount
        case neutralCount
        case topGainers
        case topLosers
        case strongestSignals
        case marketSentiment
        case sentimentScore
        case timestamp
        case totalMarketCap
        case totalVolume
        case btcDominance
        case fearGreedIndex
        case fearGreedLabel
        case activeCryptos
    }

    // ---- Custom decoder with safe fallbacks ----

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalScanned    = try c.decodeIfPresent(Int.self, forKey: .totalScanned)
        bullishCount    = try c.decodeIfPresent(Int.self, forKey: .bullishCount)
        bearishCount    = try c.decodeIfPresent(Int.self, forKey: .bearishCount)
        neutralCount    = try c.decodeIfPresent(Int.self, forKey: .neutralCount)
        topGainers      = try c.decodeIfPresent([ScannerResult].self, forKey: .topGainers) ?? []
        topLosers       = try c.decodeIfPresent([ScannerResult].self, forKey: .topLosers) ?? []
        strongestSignals = try c.decodeIfPresent([ScannerResult].self, forKey: .strongestSignals)
        marketSentiment  = try c.decodeIfPresent(String.self, forKey: .marketSentiment)
        // Backend may send sentimentScore as Int or Double; handle both.
        if let score = try c.decodeIfPresent(Double.self, forKey: .sentimentScore) {
            sentimentScore = score
        } else if let scoreInt = try c.decodeIfPresent(Int.self, forKey: .sentimentScore) {
            sentimentScore = Double(scoreInt)
        } else {
            sentimentScore = nil
        }
        timestamp        = try c.decodeIfPresent(String.self, forKey: .timestamp)
        totalMarketCap   = try c.decodeIfPresent(Double.self, forKey: .totalMarketCap)
        totalVolume      = try c.decodeIfPresent(Double.self, forKey: .totalVolume)
        btcDominance     = try c.decodeIfPresent(Double.self, forKey: .btcDominance)
        fearGreedIndex   = try c.decodeIfPresent(Int.self, forKey: .fearGreedIndex)
        fearGreedLabel   = try c.decodeIfPresent(String.self, forKey: .fearGreedLabel)
        activeCryptos    = try c.decodeIfPresent(Int.self, forKey: .activeCryptos)
    }

    /// Computed: trending = strongestSignals (backward compat alias).
    var trending: [ScannerResult] { strongestSignals ?? [] }

    /// Fear & Greed classification for UI coloring.
    var fearGreedCategory: String {
        guard let idx = fearGreedIndex else { return "N/A" }
        switch idx {
        case 0...25:   return "Extreme Fear"
        case 26...45:  return "Fear"
        case 46...55:  return "Neutral"
        case 56...75:  return "Greed"
        case 76...100: return "Extreme Greed"
        default:       return "N/A"
        }
    }
}

// MARK: - Deep Analysis

/// Full technical analysis for a symbol on a given timeframe.
///
/// The backend `/scanner/analysis/:symbol` returns a deeply nested structure:
/// ```json
/// {
///   "symbol": "BTCUSDT",
///   "name": "BTCUSDT",
///   "category": "ALL",
///   "quote": { "price": 0, "change": 0, ... },
///   "technical": { "rsi": null, "macdSignal": null, ... },
///   "signal": { "direction": "NEUTRAL", "confidence": 30, ... },
///   "aiAnalysis": "...",
///   "aiModel": "...",
///   "aiSentiment": "NEUTRAL",
///   "riskLevel": "LOW",
///   "timestamp": "..."
/// }
/// ```
struct DeepAnalysis: Codable, Identifiable, Hashable {
    var id: String { "\(symbol)-\(timeframe)" }

    let symbol: String
    let analysis: String
    let recommendation: SignalDirection
    /// Confidence 0–100.
    let confidence: Int
    let support: [Double]?
    let resistance: [Double]?
    let indicators: AnalysisIndicators
    let timeframe: String
    let timestamp: String
    /// AI model used for analysis.
    let aiModel: String?
    /// AI sentiment classification.
    let aiSentiment: String?
    /// Risk level from backend.
    let riskLevel: String?
    /// Whether the market is currently open.
    let marketOpen: Bool?

    // ---- Coding Keys ----

    enum CodingKeys: String, CodingKey {
        case symbol
        case analysis = "aiAnalysis"
        case recommendation
        case confidence
        case support
        case resistance
        case indicators
        case timeframe
        case timestamp
        case aiModel
        case aiSentiment
        case riskLevel
        case marketOpen
        // Nested backend keys
        case quote
        case technical
        case signal
        case category
        case name
    }

    // ---- Custom decoder that handles the nested backend structure ----

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        symbol      = try c.decode(String.self, forKey: .symbol)
        timestamp   = try c.decodeIfPresent(String.self, forKey: .timestamp) ?? ""
        aiModel     = try c.decodeIfPresent(String.self, forKey: .aiModel)
        aiSentiment = try c.decodeIfPresent(String.self, forKey: .aiSentiment)
        riskLevel   = try c.decodeIfPresent(String.self, forKey: .riskLevel)
        marketOpen  = try c.decodeIfPresent(Bool.self, forKey: .marketOpen)

        // Extract analysis from aiAnalysis or from nested signal
        analysis = try c.decodeIfPresent(String.self, forKey: .analysis) ?? ""

        // Extract signal data from nested "signal" object
        if let signalContainer = try? c.nestedContainer(keyedBy: SignalKeys.self, forKey: .signal) {
            recommendation = try signalContainer.decodeIfPresent(SignalDirection.self, forKey: .direction) ?? .neutral
            confidence     = try signalContainer.decodeIfPresent(Int.self, forKey: .confidence) ?? 0
            support        = try signalContainer.decodeIfPresent([Double].self, forKey: .supportLevels)
            resistance     = try signalContainer.decodeIfPresent([Double].self, forKey: .resistanceLevels)
            timeframe      = try signalContainer.decodeIfPresent(String.self, forKey: .timeframe) ?? ""
        } else {
            recommendation = try c.decodeIfPresent(SignalDirection.self, forKey: .recommendation) ?? .neutral
            confidence     = try c.decodeIfPresent(Int.self, forKey: .confidence) ?? 0
            support        = try c.decodeIfPresent([Double].self, forKey: .support)
            resistance     = try c.decodeIfPresent([Double].self, forKey: .resistance)
            timeframe      = try c.decodeIfPresent(String.self, forKey: .timeframe) ?? ""
        }

        // Extract indicators from nested "technical" object
        if let techContainer = try? c.nestedContainer(keyedBy: AnalysisIndicators.CodingKeys.self, forKey: .technical) {
            indicators = try AnalysisIndicators(from: techContainer)
        } else {
            indicators = try c.decodeIfPresent(AnalysisIndicators.self, forKey: .indicators) ?? AnalysisIndicators()
        }
    }

    /// Coding keys for nested "signal" object.
    private enum SignalKeys: String, CodingKey {
        case direction
        case confidence
        case timeframe
        case supportLevels = "stopLoss"
        case resistanceLevels = "takeProfit"
    }
}

// MARK: - Analysis Indicators

/// Technical indicator values embedded in a `DeepAnalysis`.
///
/// The backend `/scanner/analysis/:symbol` returns these under a `technical` key:
/// ```json
/// {
///   "rsi": null,
///   "macdSignal": null,
///   "macdHistogram": null,
///   "bollingerPosition": null,
///   "stochK": null,
///   "stochD": null,
///   "adx": null,
///   "atr": null,
///   "technicalScore": 0,
///   "summary": "Insufficient data for analysis"
/// }
/// ```
struct AnalysisIndicators: Codable, Hashable {
    let rsi: Double?
    let macd: Double?
    let macdSignal: Double?
    let macdHistogram: Double?
    let sma20: Double?
    let sma50: Double?
    let sma200: Double?
    let ema12: Double?
    let ema26: Double?
    let bollingerUpper: Double?
    let bollingerLower: Double?
    let bollingerMiddle: Double?
    let atr: Double?
    let stochasticK: Double?
    let stochasticD: Double?

    // ---- Coding Keys (backend field names → Swift) ----

    enum CodingKeys: String, CodingKey {
        case rsi
        case macd
        case macdSignal
        case macdHistogram
        case sma20
        case sma50
        case sma200
        case ema12
        case ema26
        case bollingerUpper
        case bollingerLower
        case bollingerMiddle
        case atr
        // Backend uses "stochK" / "stochD" — map to our names
        case stochasticK = "stochK"
        case stochasticD = "stochD"
        // Backend-specific keys we don't use but need to avoid crashing
        case bollingerPosition
        case bollingerBandwidth
        case adx
        case adxTrend
        case atrVolatility
        case vwapPosition
        case technicalScore
        case summary
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        rsi              = try c.decodeIfPresent(Double.self, forKey: .rsi)
        macd             = try c.decodeIfPresent(Double.self, forKey: .macd)
        macdSignal       = try c.decodeIfPresent(Double.self, forKey: .macdSignal)
        macdHistogram    = try c.decodeIfPresent(Double.self, forKey: .macdHistogram)
        sma20            = try c.decodeIfPresent(Double.self, forKey: .sma20)
        sma50            = try c.decodeIfPresent(Double.self, forKey: .sma50)
        sma200           = try c.decodeIfPresent(Double.self, forKey: .sma200)
        ema12            = try c.decodeIfPresent(Double.self, forKey: .ema12)
        ema26            = try c.decodeIfPresent(Double.self, forKey: .ema26)
        bollingerUpper   = try c.decodeIfPresent(Double.self, forKey: .bollingerUpper)
        bollingerLower   = try c.decodeIfPresent(Double.self, forKey: .bollingerLower)
        bollingerMiddle  = try c.decodeIfPresent(Double.self, forKey: .bollingerMiddle)
        atr              = try c.decodeIfPresent(Double.self, forKey: .atr)
        stochasticK      = try c.decodeIfPresent(Double.self, forKey: .stochasticK)
        stochasticD      = try c.decodeIfPresent(Double.self, forKey: .stochasticD)
    }

    /// Empty init for fallback
    init() {
        rsi = nil; macd = nil; macdSignal = nil; macdHistogram = nil
        sma20 = nil; sma50 = nil; sma200 = nil; ema12 = nil; ema26 = nil
        bollingerUpper = nil; bollingerLower = nil; bollingerMiddle = nil
        atr = nil; stochasticK = nil; stochasticD = nil
    }

    /// Whether the MACD crossover is bullish (MACD line above signal).
    var isMacdBullishCross: Bool? {
        guard let m = macd, let s = macdSignal else { return nil }
        return m > s
    }

    /// RSI interpretation.
    var rsiLabel: String? {
        guard let rsi = rsi else { return nil }
        switch rsi {
        case ..<30:  return "Oversold"
        case 30..<40: return "Bearish"
        case 40..<60: return "Neutral"
        case 60..<70: return "Bullish"
        default:     return "Overbought"
        }
    }
}

// MARK: - Multi-Timeframe Result

/// Consolidated analysis across multiple timeframes.
struct MultiTimeframeResult: Codable, Identifiable, Hashable {
    var id: String { symbol }

    let symbol: String
    /// Keyed by timeframe string, e.g. ["1h": DeepAnalysis, "4h": …].
    let timeframes: [String: DeepAnalysis]
    let overallSignal: SignalDirection
    /// Overall strength 0–100.
    let overallStrength: Int

    /// Number of timeframes in agreement with the overall signal.
    var agreementCount: Int {
        timeframes.values.filter { $0.recommendation == overallSignal }.count
    }

    /// Agreement ratio 0…1.
    var agreementRatio: Double {
        guard !timeframes.isEmpty else { return 0 }
        return Double(agreementCount) / Double(timeframes.count)
    }
}
