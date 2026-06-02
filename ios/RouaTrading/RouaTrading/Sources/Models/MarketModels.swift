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
struct ScannerResult: Codable, Identifiable, Hashable {
    var id: String { symbol }

    let symbol: String
    let name: String?
    let price: Double
    let change: Double
    let changePct: Double
    let volume: Double
    let signal: SignalDirection
    /// Signal strength 0–100.
    let strength: Int
    let indicators: [String: Double]?
    let timeframe: String
    let category: MarketCategory

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
        switch strength {
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

    /// Relative size weight for heatmap rendering (market-cap based).
    var sizeWeight: Double { marketCap ?? volume }

    /// Color intensity factor 0…1 based on absolute change percentage.
    var colorIntensity: Double {
        min(abs(changePct) / 10.0, 1.0)
    }
}

// MARK: - Market Overview

/// Top-level market summary including sentiment indices and movers.
struct MarketOverview: Codable {
    let totalMarketCap: Double?
    let totalVolume: Double?
    let btcDominance: Double?
    let fearGreedIndex: Int?
    let fearGreedLabel: String?
    let activeCryptos: Int?
    let topGainers: [ScannerResult]
    let topLosers: [ScannerResult]
    let trending: [ScannerResult]

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
