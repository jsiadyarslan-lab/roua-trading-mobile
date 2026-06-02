// ============================================================================
// CommonModels.swift
// RouaTrading — Shared types used across the entire data layer.
//
// The NestJS backend returns ISO-8601 date strings; all date fields in the
// models use `String` to avoid DecodingError issues.  Convert to `Date`
// at the view layer with `ISO8601DateFormatter` when needed.
// ============================================================================

import Foundation

// MARK: - Paginated Response

/// Generic wrapper for paginated list endpoints.
///
/// Backend shape: `{ items, total, page, pageSize }`.
struct PaginatedResponse<T: Codable>: Codable {
    /// The page of results.
    let items: [T]
    /// Total number of records across all pages.
    let total: Int
    /// Current 1-based page index.
    let page: Int
    /// Number of items per page.
    let pageSize: Int

    // ---- Computed helpers ----

    /// Total number of pages.
    var totalPages: Int {
        guard pageSize > 0 else { return 0 }
        return (total + pageSize - 1) / pageSize
    }

    /// Whether a subsequent page exists.
    var hasNextPage: Bool { page < totalPages }

    /// Whether a previous page exists.
    var hasPreviousPage: Bool { page > 1 }
}

// MARK: - Time Frame

/// Candle / chart timeframe supported by the backend.
enum TimeFrame: String, Codable, CaseIterable, Identifiable {
    case oneMin    = "1min"
    case fiveMin   = "5min"
    case fifteenMin = "15min"
    case oneHour   = "1h"
    case fourHour  = "4h"
    case oneDay    = "1day"
    case oneWeek   = "1week"

    var id: String { rawValue }

    /// Human-readable label for UI pickers.
    var displayName: String {
        switch self {
        case .oneMin:      return "1 Min"
        case .fiveMin:     return "5 Min"
        case .fifteenMin:  return "15 Min"
        case .oneHour:     return "1 Hour"
        case .fourHour:    return "4 Hour"
        case .oneDay:      return "1 Day"
        case .oneWeek:     return "1 Week"
        }
    }

    /// The interval in seconds – useful for chart granularity calculations.
    var intervalSeconds: Int {
        switch self {
        case .oneMin:      return 60
        case .fiveMin:     return 300
        case .fifteenMin:  return 900
        case .oneHour:     return 3_600
        case .fourHour:    return 14_400
        case .oneDay:      return 86_400
        case .oneWeek:     return 604_800
        }
    }
}

// MARK: - Order Side

/// Direction of a trade order.
enum OrderSide: String, Codable {
    case buy  = "BUY"
    case sell = "SELL"

    /// UI-friendly label.
    var displayName: String {
        switch self {
        case .buy:  return "Buy"
        case .sell: return "Sell"
        }
    }

    /// Whether this side is a long position.
    var isLong: Bool { self == .buy }
}

// MARK: - Order Type

/// Execution type of an order.
enum OrderType: String, Codable {
    case market     = "MARKET"
    case limit      = "LIMIT"
    case stopLimit  = "STOP_LIMIT"

    var displayName: String {
        switch self {
        case .market:    return "Market"
        case .limit:     return "Limit"
        case .stopLimit: return "Stop Limit"
        }
    }
}

// MARK: - Order Status

/// Lifecycle status of an order.
enum OrderStatus: String, Codable {
    case pending           = "PENDING"
    case accepted          = "ACCEPTED"
    case filled            = "FILLED"
    case partiallyFilled   = "PARTIALLY_FILLED"
    case cancelled         = "CANCELLED"
    case rejected          = "REJECTED"
    case expired           = "EXPIRED"

    var displayName: String {
        switch self {
        case .pending:          return "Pending"
        case .accepted:         return "Accepted"
        case .filled:           return "Filled"
        case .partiallyFilled:  return "Partially Filled"
        case .cancelled:        return "Cancelled"
        case .rejected:         return "Rejected"
        case .expired:          return "Expired"
        }
    }

    /// Whether the order is in a terminal (no further changes) state.
    var isTerminal: Bool {
        switch self {
        case .filled, .cancelled, .rejected, .expired:
            return true
        default:
            return false
        }
    }
}

// MARK: - Position Status

/// Lifecycle status of an open position.
enum PositionStatus: String, Codable {
    case open       = "OPEN"
    case closed     = "CLOSED"
    case liquidated = "LIQUIDATED"

    var displayName: String {
        switch self {
        case .open:       return "Open"
        case .closed:     return "Closed"
        case .liquidated: return "Liquidated"
        }
    }

    var isActive: Bool { self == .open }
}

// MARK: - Market Category

/// Asset class filter used by market endpoints.
enum MarketCategory: String, Codable, CaseIterable, Identifiable {
    case all       = "ALL"
    case crypto    = "CRYPTO"
    case forex     = "FOREX"
    case stock     = "STOCK"
    case commodity = "COMMODITY"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all:       return "All"
        case .crypto:    return "Crypto"
        case .forex:     return "Forex"
        case .stock:     return "Stocks"
        case .commodity: return "Commodities"
        }
    }
}

// MARK: - Candle Interval

/// Re-exports `TimeFrame` semantics for chart rendering contexts where the
/// name "CandleInterval" is clearer.
enum CandleInterval: String, Codable, CaseIterable, Identifiable {
    case oneMin     = "1min"
    case fiveMin    = "5min"
    case fifteenMin = "15min"
    case oneHour    = "1h"
    case fourHour   = "4h"
    case oneDay     = "1day"
    case oneWeek    = "1week"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .oneMin:     return "1 Min"
        case .fiveMin:    return "5 Min"
        case .fifteenMin: return "15 Min"
        case .oneHour:    return "1 Hour"
        case .fourHour:   return "4 Hour"
        case .oneDay:     return "1 Day"
        case .oneWeek:    return "1 Week"
        }
    }

    /// Convert to the equivalent `TimeFrame`.
    var timeFrame: TimeFrame {
        switch self {
        case .oneMin:     return .oneMin
        case .fiveMin:    return .fiveMin
        case .fifteenMin: return .fifteenMin
        case .oneHour:    return .oneHour
        case .fourHour:   return .fourHour
        case .oneDay:     return .oneDay
        case .oneWeek:    return .oneWeek
        }
    }
}

// MARK: - Signal Direction (shared by AI & Signal models)

/// Directional bias shared across signals, briefs, and consensus.
enum SignalDirection: String, Codable {
    case strongBuy  = "STRONG_BUY"
    case buy        = "BUY"
    case neutral    = "NEUTRAL"
    case sell       = "SELL"
    case strongSell = "STRONG_SELL"

    var displayName: String {
        switch self {
        case .strongBuy:  return "Strong Buy"
        case .buy:        return "Buy"
        case .neutral:    return "Neutral"
        case .sell:       return "Sell"
        case .strongSell: return "Strong Sell"
        }
    }

    /// Numeric weight for aggregation – useful in consensus calculations.
    var numericValue: Int {
        switch self {
        case .strongBuy:  return 2
        case .buy:        return 1
        case .neutral:    return 0
        case .sell:       return -1
        case .strongSell: return -2
        }
    }
}

// MARK: - Brief Direction

/// Direction for AI briefs (3-level).
enum BriefDirection: String, Codable {
    case bullish  = "BULLISH"
    case bearish  = "BEARISH"
    case neutral  = "NEUTRAL"

    var displayName: String {
        switch self {
        case .bullish:  return "Bullish"
        case .bearish:  return "Bearish"
        case .neutral:  return "Neutral"
        }
    }
}

// MARK: - Brief Status

/// Lifecycle status of an AI brief.
enum BriefStatus: String, Codable {
    case active    = "ACTIVE"
    case expired   = "EXPIRED"
    case executed  = "EXECUTED"
    case dismissed = "DISMISSED"

    var displayName: String {
        switch self {
        case .active:    return "Active"
        case .expired:   return "Expired"
        case .executed:  return "Executed"
        case .dismissed: return "Dismissed"
        }
    }
}

// MARK: - Signal Status

/// Lifecycle status of a trading signal.
enum SignalStatus: String, Codable {
    case active    = "ACTIVE"
    case executed  = "EXECUTED"
    case expired   = "EXPIRED"
    case cancelled = "CANCELLED"

    var displayName: String {
        switch self {
        case .active:    return "Active"
        case .executed:  return "Executed"
        case .expired:   return "Expired"
        case .cancelled: return "Cancelled"
        }
    }
}

// MARK: - Sentiment

/// Sentiment polarity used in news / social analysis.
enum Sentiment: String, Codable {
    case positive = "POSITIVE"
    case negative = "NEGATIVE"
    case neutral  = "NEUTRAL"

    var displayName: String {
        switch self {
        case .positive: return "Positive"
        case .negative: return "Negative"
        case .neutral:  return "Neutral"
        }
    }
}

// MARK: - Risk Level

/// Risk severity classification.
enum RiskLevel: String, Codable {
    case low      = "LOW"
    case medium   = "MEDIUM"
    case high     = "HIGH"
    case critical = "CRITICAL"

    var displayName: String {
        switch self {
        case .low:      return "Low"
        case .medium:   return "Medium"
        case .high:     return "High"
        case .critical: return "Critical"
        }
    }
}

// MARK: - Market Regime

/// Market regime classification from the neural / agent layer.
enum MarketRegime: String, Codable {
    case trendingUp   = "TRENDING_UP"
    case trendingDown = "TRENDING_DOWN"
    case ranging      = "RANGING"
    case volatile_    = "VOLATILE"

    var displayName: String {
        switch self {
        case .trendingUp:   return "Trending Up"
        case .trendingDown: return "Trending Down"
        case .ranging:      return "Ranging"
        case .volatile_:    return "Volatile"
        }
    }
}

// MARK: - Agent Strategy

/// Trading strategy identifiers for the autonomous agent.
enum AgentStrategy: String, Codable, CaseIterable {
    case auto             = "AUTO"
    case scalping         = "SCALPING"
    case swing            = "SWING"
    case grid             = "GRID"
    case meanReversion    = "MEAN_REVERSION"
    case momentumBreakout = "MOMENTUM_BREAKOUT"
    case dca              = "DCA"
    case vwapRsi          = "VWAP_RSI"

    var displayName: String {
        switch self {
        case .auto:             return "Auto"
        case .scalping:         return "Scalping"
        case .swing:            return "Swing"
        case .grid:             return "Grid"
        case .meanReversion:    return "Mean Reversion"
        case .momentumBreakout: return "Momentum Breakout"
        case .dca:              return "DCA"
        case .vwapRsi:          return "VWAP + RSI"
        }
    }
}

// MARK: - User Tier

/// Subscription tier that determines feature access.
enum UserTier: String, Codable {
    case free          = "FREE"
    case pro           = "PRO"
    case institutional = "INSTITUTIONAL"

    var displayName: String {
        switch self {
        case .free:          return "Free"
        case .pro:           return "Pro"
        case .institutional: return "Institutional"
        }
    }

    /// Whether this tier is at least Pro.
    var isProOrAbove: Bool { self != .free }
}
