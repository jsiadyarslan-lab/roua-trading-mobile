// ============================================================================
// TradingModels.swift
// RouaTrading — Core trading domain models: orders, positions, portfolio,
// trade history, risk, and position-sizing.
// ============================================================================

import Foundation

// MARK: - Order

/// A placed (or pending) order on an exchange via a linked credential.
struct Order: Codable, Identifiable, Hashable {
    let id: String
    let credentialId: String
    let symbol: String
    let side: OrderSide
    let type: OrderType
    let quantity: Double
    let price: Double?
    let stopLoss: Double?
    let takeProfit: Double?
    let status: OrderStatus
    let idempotencyKey: String?
    let clientOrderId: String?
    let riskScore: Double?
    let createdAt: String
    let updatedAt: String?

    // ---- Computed helpers ----

    /// Notional value of the order at the specified (or market) price.
    var notionalValue: Double? {
        guard let p = price else { return nil }
        return quantity * p
    }

    /// Whether the order can still be cancelled.
    var isCancellable: Bool {
        switch status {
        case .pending, .accepted, .partiallyFilled:
            return true
        default:
            return false
        }
    }
}

// MARK: - Order Request

/// Payload for creating a new order.
struct OrderRequest: Codable {
    let exchangeCredentialId: String
    let symbol: String
    let side: OrderSide
    let type: OrderType
    let quantity: Double
    let price: Double?
    let stopLoss: Double?
    let takeProfit: Double?
    let idempotencyKey: String?
    let clientOrderId: String?
    let signalId: String?

    // ---- Coding keys (snake_case from backend) ----
    enum CodingKeys: String, CodingKey {
        case exchangeCredentialId
        case symbol
        case side
        case type
        case quantity
        case price
        case stopLoss
        case takeProfit
        case idempotencyKey
        case clientOrderId
        case signalId
    }
}

// MARK: - Order Execution Result

/// Returned after a successful order submission.
struct OrderExecutionResult: Codable {
    let orderId: String
    let status: OrderStatus
    let idempotencyKey: String?
    let riskScore: Double?
}

// MARK: - Position

/// An open (or closed) position on an exchange.
struct Position: Codable, Identifiable, Hashable {
    let id: String
    let symbol: String
    let side: OrderSide
    let entryPrice: Double
    let currentPrice: Double?
    let quantity: Double
    let unrealizedPnl: Double
    let unrealizedPnlPct: Double?
    let stopLoss: Double?
    let takeProfit: Double?
    let leverage: Double?
    let margin: Double?
    let openedAt: String
    let closedAt: String?
    let status: PositionStatus
    /// Position type from backend (may differ from OrderSide).
    let type: String?

    // ---- Computed helpers ----

    /// Current notional value of the position.
    var currentValue: Double {
        (currentPrice ?? entryPrice) * quantity
    }

    /// Formatted unrealized PnL string with sign.
    var formattedPnl: String {
        let prefix = unrealizedPnl >= 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.2f", unrealizedPnl))"
    }

    /// Whether the position is currently profitable.
    var isProfitable: Bool { unrealizedPnl > 0 }

    /// Leverage display string, e.g. "5×".
    var leverageLabel: String {
        guard let lev = leverage, lev > 1 else { return "1×" }
        return "\(Int(lev))×"
    }

    /// Whether this is a long position.
    var isLong: Bool { side.isLong }
}

// MARK: - Position Summary

/// Aggregated view of all open positions.
struct PositionSummary: Codable {
    let totalUnrealizedPnl: Double
    let totalPositionValue: Double
    let positionCount: Int
    let positions: [Position]

    /// Net PnL percentage across all positions.
    var totalPnlPct: Double {
        guard totalPositionValue > 0 else { return 0 }
        return (totalUnrealizedPnl / totalPositionValue) * 100
    }
}

// MARK: - Portfolio Summary

/// Full portfolio snapshot including balance and positions.
///
/// The backend `/trading/v2/portfolio` returns:
/// ```json
/// {
///   "totalBalance": 0,
///   "dailyPnL": 0,
///   "dailyPnLPercent": 0,
///   "totalExposure": 0,
///   "usedMargin": 0,
///   "openPositionsCount": 0,
///   "maxDrawdownPercent": 0,
///   "unrealizedPnL": 0,
///   "positions": []
/// }
/// ```
struct PortfolioSummary: Codable {
    let totalBalance: Double
    let dailyPnL: Double
    let dailyPnLPercent: Double
    let totalExposure: Double
    /// Backend sends `usedMargin`; we expose as `marginUsed` for backward compat.
    let marginUsed: Double
    let openPositionsCount: Int
    let maxDrawdownPercent: Double
    let unrealizedPnl: Double
    let positions: [Position]

    // Legacy / optional fields not always present in the API response
    let availableBalance: Double?
    let totalPnl: Double?
    let totalPnlPct: Double?
    let marginAvailable: Double?

    // ---- Coding Keys ----

    enum CodingKeys: String, CodingKey {
        case totalBalance
        case dailyPnL
        case dailyPnLPercent
        case totalExposure
        case marginUsed = "usedMargin"
        case openPositionsCount
        case maxDrawdownPercent
        case unrealizedPnl
        case positions
        case availableBalance
        case totalPnl
        case totalPnlPct
        case marginAvailable
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalBalance        = try c.decode(Double.self, forKey: .totalBalance)
        dailyPnL            = try c.decodeIfPresent(Double.self, forKey: .dailyPnL) ?? 0
        dailyPnLPercent     = try c.decodeIfPresent(Double.self, forKey: .dailyPnLPercent) ?? 0
        totalExposure       = try c.decodeIfPresent(Double.self, forKey: .totalExposure) ?? 0
        marginUsed          = try c.decodeIfPresent(Double.self, forKey: .marginUsed) ?? 0
        openPositionsCount  = try c.decodeIfPresent(Int.self, forKey: .openPositionsCount) ?? 0
        maxDrawdownPercent  = try c.decodeIfPresent(Double.self, forKey: .maxDrawdownPercent) ?? 0
        unrealizedPnl       = try c.decodeIfPresent(Double.self, forKey: .unrealizedPnl) ?? 0
        positions           = try c.decodeIfPresent([Position].self, forKey: .positions) ?? []
        availableBalance    = try c.decodeIfPresent(Double.self, forKey: .availableBalance)
        totalPnl            = try c.decodeIfPresent(Double.self, forKey: .totalPnl) ?? dailyPnL
        totalPnlPct         = try c.decodeIfPresent(Double.self, forKey: .totalPnlPct) ?? dailyPnLPercent
        marginAvailable     = try c.decodeIfPresent(Double.self, forKey: .marginAvailable)
    }

    /// Convenience init for creating default / fallback portfolio.
    init(totalBalance: Double = 0, availableBalance: Double = 0, totalPnl: Double = 0,
         totalPnlPct: Double = 0, unrealizedPnl: Double = 0, marginUsed: Double = 0,
         marginAvailable: Double = 0, positions: [Position] = [],
         dailyPnL: Double = 0, dailyPnLPercent: Double = 0,
         totalExposure: Double = 0, openPositionsCount: Int = 0,
         maxDrawdownPercent: Double = 0) {
        self.totalBalance = totalBalance
        self.availableBalance = availableBalance
        self.totalPnl = totalPnl
        self.totalPnlPct = totalPnlPct
        self.unrealizedPnl = unrealizedPnl
        self.marginUsed = marginUsed
        self.marginAvailable = marginAvailable
        self.positions = positions
        self.dailyPnL = dailyPnL
        self.dailyPnLPercent = dailyPnLPercent
        self.totalExposure = totalExposure
        self.openPositionsCount = openPositionsCount
        self.maxDrawdownPercent = maxDrawdownPercent
    }

    /// Margin usage ratio (0.0 … 1.0).
    var marginUsageRatio: Double {
        guard totalBalance > 0 else { return 0 }
        return marginUsed / totalBalance
    }

    /// Whether margin utilization exceeds 80 %.
    var isHighMarginUsage: Bool { marginUsageRatio > 0.8 }
}

// MARK: - Trade

/// A completed (closed) trade with realized PnL.
struct Trade: Codable, Identifiable, Hashable {
    let id: String
    let symbol: String
    let side: OrderSide
    let entryPrice: Double
    let exitPrice: Double
    let qty: Double
    let realizedPnl: Double
    let realizedPnlPct: Double
    let closeTime: String
    let status: PositionStatus

    /// Formatted realized PnL string.
    var formattedPnl: String {
        let prefix = realizedPnl >= 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.2f", realizedPnl))"
    }

    /// Whether the trade was a winner.
    var isWinner: Bool { realizedPnl > 0 }
}

// MARK: - Trade History

/// Paginated wrapper for closed trades.
struct TradeHistory: Codable {
    let trades: [Trade]
    let total: Int
}

// MARK: - Close Position Request

/// Request body for closing a position (full or partial).
struct ClosePositionRequest: Codable {
    let positionId: String
    let quantity: Double?

    /// Whether this is a full close (no quantity specified).
    var isFullClose: Bool { quantity == nil }
}

// MARK: - Force Close Request

/// Emergency close request with optional reason.
struct ForceCloseRequest: Codable {
    let positionId: String
    let reason: String?
}

// MARK: - Position Levels Request

/// Update stop-loss / take-profit levels on an existing position.
struct PositionLevelsRequest: Codable {
    let stopLoss: Double?
    let takeProfit: Double?
}

// MARK: - Risk Parameters

/// Risk management configuration for the user or agent.
struct RiskParameters: Codable, Hashable {
    let maxPositionSize: Double
    let maxDailyLoss: Double
    let maxOpenPositions: Int
    let defaultStopLossPct: Double
    let defaultTakeProfitPct: Double
}

// MARK: - Position Size Request

/// Input for position-sizing calculator.
struct PositionSizeRequest: Codable {
    let portfolioValue: Double
    let entryPrice: Double
    let stopLossPrice: Double
    let riskPercent: Double?

    /// Risk percent with default fallback (1 %).
    var effectiveRiskPercent: Double { riskPercent ?? 1.0 }
}

// MARK: - Position Size Result

/// Output of the position-sizing calculator.
struct PositionSizeResult: Codable {
    let quantity: Double
    let riskAmount: Double
    let riskPercent: Double

    /// Formatted risk amount string.
    var formattedRiskAmount: String {
        String(format: "%.2f", riskAmount)
    }
}
