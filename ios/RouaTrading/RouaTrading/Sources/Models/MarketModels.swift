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
        price     = try container.decode(Double.self, forKey: .price)
        change    = try container.decodeIfPresent(Double.self, forKey: .change) ?? 0
        changePct = try container.decode(Double.self, forKey: .changePct)
        volume    = try container.decode(Double.self, forKey: .volume)
        signal    = try container.decode(SignalDirection.self, forKey: .signal)
        strength  = try container.decode(Int.self, forKey: .strength)
        indicators = try container.decodeIfPresent([String: Double].self, forKey: .indicators)
        timeframe  = try container.decodeIfPresent(String.self, forKey: .timeframe)
        category   = try container.decode(MarketCategory.self, forKey: .category)
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
        price          = try container.decode(Double.self, forKey: .price)
        change         = try container.decodeIfPresent(Double.self, forKey: .change) ?? 0
        changePct      = try container.decode(Double.self, forKey: .changePct)
        volume         = try container.decode(Double.self, forKey: .volume)
        category       = try container.decode(MarketCategory.self, forKey: .category)
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
}

// MARK: - Analysis Indicators

/// Technical indicator values embedded in a `DeepAnalysis`.
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
