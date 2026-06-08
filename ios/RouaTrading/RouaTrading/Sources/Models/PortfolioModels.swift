// ============================================================================
// PortfolioModels.swift
// RouaTrading — Portfolio, credential, balance, risk, agent, and
// performance models.
// ============================================================================

import Foundation

// MARK: - Credential

/// An exchange API key credential linked to the user's account.
struct Credential: Codable, Identifiable, Hashable {
    let id: String
    let exchange: String
    let label: String
    let testnet: Bool
    let keyType: String?
    let createdAt: String
    let lastValidatedAt: String?
    let status: String?

    /// Display label for pickers, including exchange name.
    var displayLabel: String {
        testnet ? "\(label) (\(exchange) – Testnet)" : "\(label) (\(exchange))"
    }

    /// Whether the credential has been validated recently (within 24h).
    var isRecentlyValidated: Bool {
        guard let last = lastValidatedAt else { return false }
        // Simple check – production code should use a DateFormatter.
        return !last.isEmpty
    }
}

// MARK: - Create Credential Request

/// Payload for registering a new exchange API key.
struct CreateCredentialRequest: Codable {
    let exchange: String
    let label: String
    let apiKey: String
    let apiSecret: String
    let passphrase: String?
    let testnet: Bool?
    let keyType: String?
}

// MARK: - Balances

/// Aggregate balance snapshot for a credential.
struct Balances: Codable {
    let totalBalance: Double
    let availableBalance: Double
    let totalPnl: Double
    let assets: [AssetBalance]

    /// Number of non-zero asset positions.
    var activeAssetCount: Int {
        assets.filter { $0.total > 0 }.count
    }
}

// MARK: - Asset Balance

/// Balance for a single asset within a credential.
struct AssetBalance: Codable, Identifiable, Hashable {
    var id: String { asset }

    let asset: String
    let free: Double
    let used: Double
    let total: Double
    let usdValue: Double
    let pnl: Double?
    let pnlPct: Double?

    /// Formatted PnL string.
    var formattedPnl: String? {
        guard let pnl = pnl else { return nil }
        let prefix = pnl >= 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.2f", pnl))"
    }

    /// Whether this asset has an open position.
    var hasPosition: Bool { used > 0 }

    /// Utilization ratio (used / total).
    var utilizationRatio: Double {
        guard total > 0 else { return 0 }
        return used / total
    }
}

// MARK: - Risk Report

/// Comprehensive risk assessment for the user's portfolio.
///
/// The backend `/portfolio/sanctuary` returns:
/// ```json
/// {
///   "summary": "...",
///   "riskScore": 16,
///   "totalValue": 0,
///   "currency": "USD",
///   "positions": [],
///   "metrics": {
///     "concentrationRisk": 0,
///     "diversificationScore": 100,
///     "largestPositionWeight": 0,
///     "positionCount": 0,
///     "varEstimate": 0,
///     "volatilityEstimate": 0
///   },
///   "recommendations": ["..."],
///   "aiAnalysis": "..."
/// }
/// ```
struct RiskReport: Codable {
    /// Human-readable risk summary.
    let summary: String?
    /// Numeric risk score 0–100.
    let overallRisk: Double
    /// Risk severity classification.
    let riskLevel: RiskLevel
    /// Concentration risk 0–1.
    let positionConcentration: Double
    /// Leverage exposure ratio.
    let leverageExposure: Double
    /// Liquidity risk 0–1.
    let liquidityRisk: Double
    /// Diversification score 0–100.
    let diversificationScore: Double
    /// Actionable risk recommendations.
    let recommendations: [String]
    /// AI-generated detailed risk analysis.
    let aiAnalysis: String?
    /// Total portfolio value in base currency.
    let totalValue: Double?
    /// Base currency code (e.g. "USD").
    let currency: String?

    // ---- Coding Keys (backend → Swift) ----

    enum CodingKeys: String, CodingKey {
        case summary
        case overallRisk = "riskScore"
        case riskLevel
        case positionConcentration = "concentrationRisk"
        case leverageExposure
        case liquidityRisk
        case diversificationScore
        case recommendations
        case aiAnalysis
        case totalValue
        case currency
    }

    /// Coding key used only during decoding to access the nested `metrics` object.
    private enum MetricsCodingKey: String, CodingKey {
        case metrics
    }

    // ---- Custom decoder with fallback for nested metrics ----

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        summary             = try c.decodeIfPresent(String.self, forKey: .summary)
        overallRisk         = try c.decodeIfPresent(Double.self, forKey: .overallRisk) ?? 0
        // Derive riskLevel from riskScore
        let score = try c.decodeIfPresent(Double.self, forKey: .overallRisk) ?? 0
        switch score {
        case 0..<25:  riskLevel = .low
        case 25..<50: riskLevel = .medium
        case 50..<75: riskLevel = .high
        default:      riskLevel = .critical
        }
        recommendations     = try c.decodeIfPresent([String].self, forKey: .recommendations) ?? []
        aiAnalysis          = try c.decodeIfPresent(String.self, forKey: .aiAnalysis)
        totalValue          = try c.decodeIfPresent(Double.self, forKey: .totalValue)
        currency            = try c.decodeIfPresent(String.self, forKey: .currency)

        // The backend nests some values inside a "metrics" object.
        // Extract them if present; fall back to flat fields or defaults.
        let mc = try decoder.container(keyedBy: MetricsCodingKey.self)
        if let metricsContainer = try? mc.nestedContainer(keyedBy: MetricsKeys.self, forKey: .metrics) {
            positionConcentration = try metricsContainer.decodeIfPresent(Double.self, forKey: .concentrationRisk) ?? 0
            diversificationScore  = try metricsContainer.decodeIfPresent(Double.self, forKey: .diversificationScore) ?? 0
            leverageExposure      = try metricsContainer.decodeIfPresent(Double.self, forKey: .largestPositionWeight) ?? 0
            liquidityRisk         = try metricsContainer.decodeIfPresent(Double.self, forKey: .varEstimate) ?? 0
        } else {
            positionConcentration = try c.decodeIfPresent(Double.self, forKey: .positionConcentration) ?? 0
            diversificationScore  = try c.decodeIfPresent(Double.self, forKey: .diversificationScore) ?? 0
            leverageExposure      = try c.decodeIfPresent(Double.self, forKey: .leverageExposure) ?? 0
            liquidityRisk         = try c.decodeIfPresent(Double.self, forKey: .liquidityRisk) ?? 0
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(summary, forKey: .summary)
        try c.encode(overallRisk, forKey: .overallRisk)
        try c.encode(riskLevel, forKey: .riskLevel)
        try c.encode(positionConcentration, forKey: .positionConcentration)
        try c.encode(leverageExposure, forKey: .leverageExposure)
        try c.encode(liquidityRisk, forKey: .liquidityRisk)
        try c.encode(diversificationScore, forKey: .diversificationScore)
        try c.encode(recommendations, forKey: .recommendations)
        try c.encodeIfPresent(aiAnalysis, forKey: .aiAnalysis)
        try c.encodeIfPresent(totalValue, forKey: .totalValue)
        try c.encodeIfPresent(currency, forKey: .currency)
    }

    /// Coding keys for the nested `metrics` object.
    private enum MetricsKeys: String, CodingKey {
        case concentrationRisk
        case diversificationScore
        case largestPositionWeight
        case positionCount
        case varEstimate
        case volatilityEstimate
    }

    /// Number of risk recommendations.
    var recommendationCount: Int { recommendations.count }

    /// Diversification grade A–F.
    var diversificationGrade: String {
        switch diversificationScore {
        case 80...100: return "A"
        case 60..<80:  return "B"
        case 40..<60:  return "C"
        case 20..<40:  return "D"
        default:       return "F"
        }
    }
}

// MARK: - Agent State

/// Current state of the autonomous trading agent.
struct AgentState: Codable {
    let isActive: Bool
    let strategy: String?
    let startTime: String?
    let totalTrades: Int?
    let winRate: Double?
    let totalPnl: Double?
    let currentPositions: Int?
    let settings: [String: String]?

    /// Direct memberwise init for programmatic creation.
    init(isActive: Bool, strategy: String? = nil, startTime: String? = nil,
         totalTrades: Int? = nil, winRate: Double? = nil, totalPnl: Double? = nil,
         currentPositions: Int? = nil, settings: [String: String]? = nil) {
        self.isActive = isActive
        self.strategy = strategy
        self.startTime = startTime
        self.totalTrades = totalTrades
        self.winRate = winRate
        self.totalPnl = totalPnl
        self.currentPositions = currentPositions
        self.settings = settings
    }

    /// Formatted total PnL.
    var formattedTotalPnl: String? {
        guard let pnl = totalPnl else { return nil }
        let prefix = pnl >= 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.2f", pnl))"
    }
}

// MARK: - Agent Start Request

/// Payload for starting the autonomous trading agent.
struct AgentStartRequest: Codable {
    let strategy: AgentStrategy
    let credentialId: String?
    let symbols: [String]?
    let maxPositionSizePercent: Double?
    let maxDailyLossPercent: Double?
    let maxOpenPositions: Int?
    let riskPerTradePercent: Double?
    let strategyParams: [String: String]?
}

// MARK: - Agent Stop Request

/// Payload for stopping the autonomous trading agent.
struct AgentStopRequest: Codable {
    let emergency: Bool?

    /// Whether this is an emergency stop.
    var isEmergency: Bool { emergency ?? false }
}

// MARK: - Performance Metrics

/// Aggregate trading performance statistics.
///
/// The backend `/agent/trader/performance` returns:
/// ```json
/// {
///   "totalTrades": 0,
///   "winningTrades": 0,
///   "losingTrades": 0,
///   "winRate": 0,
///   "totalPnL": 0,
///   "averageWin": 0,
///   "averageLoss": 0,
///   "profitFactor": 0,
///   "maxDrawdown": 0,
///   "maxDrawdownPercent": 0,
///   "sharpeRatio": 0,
///   "averageHoldingTime": 0,
///   "bestTrade": 0,
///   "worstTrade": 0,
///   "consecutiveWins": 0,
///   "consecutiveLosses": 0,
///   "startDate": "...",
///   "period": "WEEKLY"
/// }
/// ```
struct PerformanceMetrics: Codable, Hashable {
    let totalTrades: Int
    let winRate: Double
    let totalPnl: Double
    var totalPnlPct: Double?
    let sharpeRatio: Double?
    let maxDrawdown: Double?
    let avgWin: Double
    let avgLoss: Double
    let profitFactor: Double?
    let dailyReturn: Double?
    /// Number of winning trades.
    let winningTrades: Int?
    /// Number of losing trades.
    let losingTrades: Int?
    /// Best single trade PnL.
    let bestTrade: Double?
    /// Worst single trade PnL.
    let worstTrade: Double?
    /// Current consecutive wins streak.
    let consecutiveWins: Int?
    /// Current consecutive losses streak.
    let consecutiveLosses: Int?
    /// Average holding time in seconds.
    let averageHoldingTime: Double?
    /// Period for the stats, e.g. "WEEKLY".
    let period: String?

    // ---- Coding Keys (backend → Swift) ----

    enum CodingKeys: String, CodingKey {
        case totalTrades
        case winRate
        case totalPnl = "totalPnL"
        case totalPnlPct
        case sharpeRatio
        case maxDrawdown
        case avgWin = "averageWin"
        case avgLoss = "averageLoss"
        case profitFactor
        case dailyReturn
        case winningTrades
        case losingTrades
        case bestTrade
        case worstTrade
        case consecutiveWins
        case consecutiveLosses
        case averageHoldingTime
        case period
    }

    /// Coding key used only during decoding to read the backend's `maxDrawdownPercent` field.
    private enum DecodingOnlyKeys: String, CodingKey {
        case maxDrawdownPercent
    }

    /// Direct memberwise init for programmatic creation (e.g., default fallback).
    init(
        totalTrades: Int = 0,
        winRate: Double = 0,
        totalPnl: Double = 0,
        totalPnlPct: Double? = nil,
        sharpeRatio: Double? = nil,
        maxDrawdown: Double? = nil,
        avgWin: Double = 0,
        avgLoss: Double = 0,
        profitFactor: Double? = nil,
        dailyReturn: Double? = nil,
        winningTrades: Int? = nil,
        losingTrades: Int? = nil,
        bestTrade: Double? = nil,
        worstTrade: Double? = nil,
        consecutiveWins: Int? = nil,
        consecutiveLosses: Int? = nil,
        averageHoldingTime: Double? = nil,
        period: String? = nil
    ) {
        self.totalTrades = totalTrades
        self.winRate = winRate
        self.totalPnl = totalPnl
        self.totalPnlPct = totalPnlPct
        self.sharpeRatio = sharpeRatio
        self.maxDrawdown = maxDrawdown
        self.avgWin = avgWin
        self.avgLoss = avgLoss
        self.profitFactor = profitFactor
        self.dailyReturn = dailyReturn
        self.winningTrades = winningTrades
        self.losingTrades = losingTrades
        self.bestTrade = bestTrade
        self.worstTrade = worstTrade
        self.consecutiveWins = consecutiveWins
        self.consecutiveLosses = consecutiveLosses
        self.averageHoldingTime = averageHoldingTime
        self.period = period
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalTrades         = try c.decodeIfPresent(Int.self, forKey: .totalTrades) ?? 0
        winRate             = try c.decodeIfPresent(Double.self, forKey: .winRate) ?? 0
        totalPnl            = try c.decodeIfPresent(Double.self, forKey: .totalPnl) ?? 0
        totalPnlPct         = try c.decodeIfPresent(Double.self, forKey: .totalPnlPct)
        sharpeRatio         = try c.decodeIfPresent(Double.self, forKey: .sharpeRatio)
        maxDrawdown         = try c.decodeIfPresent(Double.self, forKey: .maxDrawdown)
        avgWin              = try c.decodeIfPresent(Double.self, forKey: .avgWin) ?? 0
        avgLoss             = try c.decodeIfPresent(Double.self, forKey: .avgLoss) ?? 0
        profitFactor        = try c.decodeIfPresent(Double.self, forKey: .profitFactor)
        dailyReturn         = try c.decodeIfPresent(Double.self, forKey: .dailyReturn)
        winningTrades       = try c.decodeIfPresent(Int.self, forKey: .winningTrades)
        losingTrades        = try c.decodeIfPresent(Int.self, forKey: .losingTrades)
        bestTrade           = try c.decodeIfPresent(Double.self, forKey: .bestTrade)
        worstTrade          = try c.decodeIfPresent(Double.self, forKey: .worstTrade)
        consecutiveWins     = try c.decodeIfPresent(Int.self, forKey: .consecutiveWins)
        consecutiveLosses   = try c.decodeIfPresent(Int.self, forKey: .consecutiveLosses)
        averageHoldingTime  = try c.decodeIfPresent(Double.self, forKey: .averageHoldingTime)
        period              = try c.decodeIfPresent(String.self, forKey: .period)
        // Derive totalPnlPct from maxDrawdownPercent if not present
        if totalPnlPct == nil {
            let extra = try decoder.container(keyedBy: DecodingOnlyKeys.self)
            if let mddPct = try extra.decodeIfPresent(Double.self, forKey: .maxDrawdownPercent) {
                totalPnlPct = mddPct
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(totalTrades, forKey: .totalTrades)
        try c.encode(winRate, forKey: .winRate)
        try c.encode(totalPnl, forKey: .totalPnl)
        try c.encodeIfPresent(totalPnlPct, forKey: .totalPnlPct)
        try c.encodeIfPresent(sharpeRatio, forKey: .sharpeRatio)
        try c.encodeIfPresent(maxDrawdown, forKey: .maxDrawdown)
        try c.encode(avgWin, forKey: .avgWin)
        try c.encode(avgLoss, forKey: .avgLoss)
        try c.encodeIfPresent(profitFactor, forKey: .profitFactor)
        try c.encodeIfPresent(dailyReturn, forKey: .dailyReturn)
        try c.encodeIfPresent(winningTrades, forKey: .winningTrades)
        try c.encodeIfPresent(losingTrades, forKey: .losingTrades)
        try c.encodeIfPresent(bestTrade, forKey: .bestTrade)
        try c.encodeIfPresent(worstTrade, forKey: .worstTrade)
        try c.encodeIfPresent(consecutiveWins, forKey: .consecutiveWins)
        try c.encodeIfPresent(consecutiveLosses, forKey: .consecutiveLosses)
        try c.encodeIfPresent(averageHoldingTime, forKey: .averageHoldingTime)
        try c.encodeIfPresent(period, forKey: .period)
    }

    /// Formatted win rate percentage.
    var formattedWinRate: String {
        String(format: "%.1f%%", winRate * 100)
    }

    /// Formatted total PnL.
    var formattedTotalPnl: String {
        let prefix = totalPnl >= 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.2f", totalPnl))"
    }

    /// Profit factor label.
    var profitFactorLabel: String? {
        guard let pf = profitFactor else { return nil }
        if pf > 2.0 { return "Excellent" }
        if pf > 1.5 { return "Good" }
        if pf > 1.0 { return "Moderate" }
        return "Poor"
    }

    /// Maximum drawdown formatted as percentage.
    var formattedMaxDrawdown: String? {
        guard let md = maxDrawdown else { return nil }
        return String(format: "%.1f%%", md * 100)
    }
}

// MARK: - Regime Info

/// Market regime classification and suggested strategies.
struct RegimeInfo: Codable, Identifiable, Hashable {
    var id: String { symbol }

    let symbol: String
    let regime: MarketRegime
    /// Confidence 0–100.
    let confidence: Int
    let suggestedStrategies: [AgentStrategy]

    /// Confidence label.
    var confidenceLabel: String {
        switch confidence {
        case 80...100: return "High"
        case 50..<80:  return "Medium"
        default:       return "Low"
        }
    }
}
