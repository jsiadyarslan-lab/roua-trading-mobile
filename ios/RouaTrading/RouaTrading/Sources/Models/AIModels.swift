// ============================================================================
// AIModels.swift
// RouaTrading — AI / LLM models: analysis, multi-model consensus, briefs,
// council, smart executor, coach, and signals.
// ============================================================================

import Foundation

// MARK: - AI Analysis Request

/// Payload for requesting a single-model AI analysis.
struct AIAnalysisRequest: Codable {
    let prompt: String
    let type: String?
    let symbol: String?
    let language: String?
}

// MARK: - AI Analysis Result

/// Response from a single LLM analysis pass.
struct AIAnalysisResult: Codable {
    let content: String
    let model: String
    let timestamp: String
    let tokensUsed: Int?
}

// MARK: - Multi-Model Result

/// Aggregated results from multiple LLMs for the same prompt.
struct MultiModelResult: Codable {
    /// Keyed by model name.
    let results: [String: AIAnalysisResult]
    let consensus: String?
    let timestamp: String
}

// MARK: - Model Status

/// Availability info for a single LLM model.
struct ModelStatus: Codable, Identifiable, Hashable {
    var id: String { name }

    let name: String
    let provider: String
    let available: Bool
    let latency: Double?
    let lastChecked: String

    /// Formatted latency string, e.g. "1.2s".
    var formattedLatency: String? {
        guard let lat = latency else { return nil }
        return String(format: "%.1fs", lat)
    }
}

// MARK: - Models Status Response

/// Full list of LLM model statuses.
struct ModelsStatusResponse: Codable {
    let models: [ModelStatus]
    let totalAvailable: Int
    let timestamp: String
}

// MARK: - Consensus Request

/// Payload for requesting a multi-model consensus analysis.
struct ConsensusRequest: Codable {
    let symbol: String?
    let language: String?
}

// MARK: - Consensus Result

/// Multi-model consensus for a symbol.
struct ConsensusResult: Codable, Identifiable, Hashable {
    var id: String { symbol }

    let symbol: String
    let consensus: SignalDirection
    /// Confidence 0–100.
    let confidence: Int
    let models: [ModelVote]
    let summary: String
    let timestamp: String

    /// Number of models in agreement with the consensus.
    var agreementCount: Int {
        models.filter { $0.recommendation == consensus }.count
    }
}

// MARK: - Model Vote

/// A single model's vote within a consensus result.
struct ModelVote: Codable, Identifiable, Hashable {
    var id: String { "\(model)-\(provider)" }

    let model: String
    let provider: String
    let recommendation: SignalDirection
    /// Confidence 0–100.
    let confidence: Int
    let reasoning: String?
}

// MARK: - Brief

/// An AI-generated actionable brief for a symbol.
///
/// The backend `/strategic-council/briefs/active` returns:
/// ```json
/// {
///   "id": "...",
///   "pair": "DOGE/USDT",
///   "direction": "SELL",
///   "entryPrice": 0.08296,
///   "stopLoss": 0.08395552,
///   "takeProfit": 0.08096896,
///   "confidence": 82,
///   "timeframe": "M30",
///   "issuedAt": "...",
///   "expiresAt": "...",
///   "isActive": true,
///   "strictRules": { ... },
///   "analysis": "...",
///   "models": [...]
/// }
/// ```
struct Brief: Codable, Identifiable, Hashable {
    let id: String
    /// Backend sends `pair` instead of `symbol`.
    let symbol: String
    let direction: BriefDirection
    /// Confidence 0–100.
    let confidence: Int
    let analysis: String?
    let models: [ModelAnalysis]?
    let createdAt: String
    let expiresAt: String?
    let status: BriefStatus
    let source: String?
    /// Entry price from the brief.
    let entryPrice: Double?
    /// Stop-loss level.
    let stopLoss: Double?
    /// Take-profit level.
    let takeProfit: Double?
    /// Timeframe string, e.g. "M30".
    let timeframe: String?
    /// Whether the brief is currently active.  Backend sends `isActive`.
    let isActiveBrief: Bool?

    // ---- Coding Keys ----

    enum CodingKeys: String, CodingKey {
        case id
        case symbol = "pair"
        case direction
        case confidence
        case analysis
        case models
        case createdAt = "issuedAt"
        case expiresAt
        case status
        case source
        case entryPrice
        case stopLoss
        case takeProfit
        case timeframe
        case isActiveBrief = "isActive"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id           = try c.decode(String.self, forKey: .id)
        symbol       = try c.decode(String.self, forKey: .symbol)
        direction    = try c.decodeIfPresent(BriefDirection.self, forKey: .direction) ?? .neutral
        confidence   = try c.decodeIfPresent(Int.self, forKey: .confidence) ?? 50
        analysis     = try c.decodeIfPresent(String.self, forKey: .analysis)
        models       = try c.decodeIfPresent([ModelAnalysis].self, forKey: .models)
        createdAt    = try c.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
        expiresAt    = try c.decodeIfPresent(String.self, forKey: .expiresAt)
        // Derive status from isActive if not explicitly provided
        if let statusVal = try c.decodeIfPresent(BriefStatus.self, forKey: .status) {
            status = statusVal
        } else {
            let active = try c.decodeIfPresent(Bool.self, forKey: .isActiveBrief) ?? true
            status = active ? .active : .expired
        }
        source       = try c.decodeIfPresent(String.self, forKey: .source)
        entryPrice   = try c.decodeIfPresent(Double.self, forKey: .entryPrice)
        stopLoss     = try c.decodeIfPresent(Double.self, forKey: .stopLoss)
        takeProfit   = try c.decodeIfPresent(Double.self, forKey: .takeProfit)
        timeframe    = try c.decodeIfPresent(String.self, forKey: .timeframe)
        isActiveBrief = try c.decodeIfPresent(Bool.self, forKey: .isActiveBrief)
    }

    /// Whether the brief is still actionable.
    var isActionable: Bool { status == .active }

    /// Confidence label for UI.
    var confidenceLabel: String {
        switch confidence {
        case 80...100: return "High"
        case 50..<80:  return "Medium"
        default:       return "Low"
        }
    }
}

// MARK: - Model Analysis

/// A single model's contribution within a brief.
struct ModelAnalysis: Codable, Identifiable, Hashable {
    var id: String { "\(model)-\(provider)" }

    let model: String
    let provider: String
    let recommendation: String
    /// Confidence 0–100.
    let confidence: Int
    let reasoning: String
    let timestamp: String
}

// MARK: - Briefs Response

/// Wrapper for the active-briefs endpoint.
struct BriefsResponse: Codable {
    let active: [Brief]
    let count: Int
}

// MARK: - Council Session

/// A council-of-agents deliberation session.
struct CouncilSession: Codable, Identifiable, Hashable {
    var id: String { sessionId }

    let sessionId: String
    let status: String
    let pairs: [String]
    let message: String?
}

// MARK: - Council Session Status

/// Current state of the council system.
///
/// Backend `/strategic-council/session/status` returns:
/// ```json
/// { "isRunning": false, "lastSession": null }
/// ```
struct CouncilSessionStatus: Codable {
    let isRunning: Bool
    let lastSession: String?
}

// MARK: - Executor Status

/// High-level status of the Smart Executor.
///
/// Backend `/smart-executor/status` returns:
/// ```json
/// {
///   "isRunning": true,
///   "startedAt": "...",
///   "totalExecutions": 0,
///   "todayExecutions": 0,
///   "todayPnL": 0,
///   "openPositions": 0,
///   "lastCheckAt": "...",
///   "dailyLossLimitReached": false,
///   "lastError": null,
///   "activeBriefs": 23
/// }
/// ```
struct ExecutorStatus: Codable {
    /// Backend sends `isRunning` instead of `isActive`.
    let isActive: Bool
    let startedAt: String?
    let totalExecutions: Int?
    let todayExecutions: Int?
    let todayPnL: Double?
    let openPositions: Int?
    let lastCheckAt: String?
    let dailyLossLimitReached: Bool?
    let lastError: String?
    let activeBriefs: Int?
    /// Mode string (legacy field, may not be present).
    let mode: String?
    /// Total PnL (legacy alias).
    let totalPnl: Double?
    /// Daily PnL (legacy alias).
    let dailyPnl: Double?
    /// Win rate.
    let winRate: Double?
    /// Last activity timestamp.
    let lastActivity: String?
    /// Uptime in seconds.
    let uptime: Double?

    // ---- Coding Keys ----

    enum CodingKeys: String, CodingKey {
        case isActive = "isRunning"
        case startedAt
        case totalExecutions
        case todayExecutions
        case todayPnL
        case openPositions
        case lastCheckAt
        case dailyLossLimitReached
        case lastError
        case activeBriefs
        case mode
        case totalPnl
        case dailyPnl
        case winRate
        case lastActivity
        case uptime
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        isActive              = try c.decode(Bool.self, forKey: .isActive)
        startedAt             = try c.decodeIfPresent(String.self, forKey: .startedAt)
        totalExecutions       = try c.decodeIfPresent(Int.self, forKey: .totalExecutions)
        todayExecutions       = try c.decodeIfPresent(Int.self, forKey: .todayExecutions)
        todayPnL              = try c.decodeIfPresent(Double.self, forKey: .todayPnL)
        openPositions         = try c.decodeIfPresent(Int.self, forKey: .openPositions)
        lastCheckAt           = try c.decodeIfPresent(String.self, forKey: .lastCheckAt)
        dailyLossLimitReached = try c.decodeIfPresent(Bool.self, forKey: .dailyLossLimitReached)
        lastError             = try c.decodeIfPresent(String.self, forKey: .lastError)
        activeBriefs          = try c.decodeIfPresent(Int.self, forKey: .activeBriefs)
        mode                  = try c.decodeIfPresent(String.self, forKey: .mode)
        totalPnl              = try c.decodeIfPresent(Double.self, forKey: .totalPnl) ?? todayPnL
        dailyPnl              = try c.decodeIfPresent(Double.self, forKey: .dailyPnl) ?? todayPnL
        winRate               = try c.decodeIfPresent(Double.self, forKey: .winRate)
        lastActivity          = try c.decodeIfPresent(String.self, forKey: .lastActivity) ?? lastCheckAt
        uptime                = try c.decodeIfPresent(Double.self, forKey: .uptime)
    }

    /// Formatted total PnL string.
    var formattedTotalPnl: String {
        let pnl = totalPnl ?? todayPnL ?? 0
        let prefix = pnl >= 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.2f", pnl))"
    }

    /// Formatted daily PnL string.
    var formattedDailyPnl: String {
        let pnl = dailyPnl ?? todayPnL ?? 0
        let prefix = pnl >= 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.2f", pnl))"
    }

    /// Uptime formatted as "Xd Xh".
    var formattedUptime: String? {
        guard let up = uptime else { return nil }
        let days = Int(up) / 86_400
        let hours = (Int(up) % 86_400) / 3_600
        return days > 0 ? "\(days)d \(hours)h" : "\(hours)h"
    }
}

// MARK: - User Executor State

/// User's personal Smart Executor configuration.
struct UserExecutorState: Codable {
    let enabled: Bool
    let maxOpenPositions: Int
    let riskPerTradePercent: Double
    let autoExecuteSignals: Bool
}

// MARK: - Executor Exposure

/// Current exposure metrics for the Smart Executor.
struct ExecutorExposure: Codable {
    let totalExposure: Double
    let positions: [SmartExecutorPosition]
    let largestPosition: Double
    let concentrationRisk: Double

    /// Number of open positions.
    var positionCount: Int { positions.count }

    /// Concentration risk label.
    var concentrationRiskLabel: String {
        switch concentrationRisk {
        case ..<0.3: return "Low"
        case 0.3..<0.6: return "Medium"
        default: return "High"
        }
    }
}

// MARK: - Smart Executor Position

/// A position managed by the Smart Executor.
struct SmartExecutorPosition: Codable, Identifiable, Hashable {
    let id: String
    let symbol: String
    let side: OrderSide
    let entryPrice: Double
    let currentPrice: Double
    let quantity: Double
    let unrealizedPnl: Double
    let stopLoss: Double?
    let takeProfit: Double?
    let openedAt: String

    /// Formatted unrealized PnL.
    var formattedPnl: String {
        let prefix = unrealizedPnl >= 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.2f", unrealizedPnl))"
    }

    /// Whether the position is profitable.
    var isProfitable: Bool { unrealizedPnl > 0 }
}

// MARK: - Coach Advice

/// A coaching insight generated by the AI Coach.
struct CoachAdvice: Codable, Identifiable, Hashable {
    let id: String
    let type: String
    let advice: String
    let confidence: Double?
    let actionItems: [String]?
    let performanceMetrics: [String: Double]?
    let createdAt: String

    /// Number of actionable items.
    var actionItemCount: Int { actionItems?.count ?? 0 }

    /// Confidence as a percentage string.
    var confidencePct: String? {
        guard let c = confidence else { return nil }
        return String(format: "%.0f%%", c * 100)
    }
}

// MARK: - Coach Question

/// Payload for asking the AI Coach a question.
struct CoachQuestion: Codable {
    let question: String
    let contextAdviceId: String?
    let locale: String?
}

// MARK: - Signal

/// A trading signal generated by the AI / scanner pipeline.
///
/// Flexible decoding: the backend may return signals from different endpoints
/// with slightly different shapes.  All non-essential fields are optional.
struct Signal: Codable, Identifiable, Hashable {
    let id: String
    let symbol: String
    /// Backend may send `direction` as a `BriefDirection` or `SignalDirection`.
    let direction: BriefDirection
    let type: String?
    let entryPrice: Double?
    let stopLoss: Double?
    let takeProfit: Double?
    /// Confidence 0–100.
    let confidence: Int
    let source: String?
    let reasoning: String?
    let status: SignalStatus?
    let createdAt: String
    let expiresAt: String?
    /// Timeframe string, e.g. "M30".
    let timeframe: String?
    /// Whether the signal is currently active.  Backend may send `isActive`.
    let isActiveSignal: Bool?

    // ---- Coding Keys ----

    enum CodingKeys: String, CodingKey {
        case id
        case symbol = "pair"
        case direction
        case type
        case entryPrice
        case stopLoss
        case takeProfit
        case confidence
        case source
        case reasoning
        case status
        case createdAt = "issuedAt"
        case expiresAt
        case timeframe
        case isActiveSignal = "isActive"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(String.self, forKey: .id)
        symbol      = try c.decode(String.self, forKey: .symbol)
        direction   = try c.decodeIfPresent(BriefDirection.self, forKey: .direction) ?? .neutral
        type        = try c.decodeIfPresent(String.self, forKey: .type)
        entryPrice  = try c.decodeIfPresent(Double.self, forKey: .entryPrice)
        stopLoss    = try c.decodeIfPresent(Double.self, forKey: .stopLoss)
        takeProfit  = try c.decodeIfPresent(Double.self, forKey: .takeProfit)
        confidence  = try c.decodeIfPresent(Int.self, forKey: .confidence) ?? 50
        source      = try c.decodeIfPresent(String.self, forKey: .source)
        reasoning   = try c.decodeIfPresent(String.self, forKey: .reasoning)
        // Derive status from isActive if not explicitly provided
        if let statusVal = try c.decodeIfPresent(SignalStatus.self, forKey: .status) {
            status = statusVal
        } else {
            let active = try c.decodeIfPresent(Bool.self, forKey: .isActiveSignal) ?? true
            status = active ? .active : .expired
        }
        createdAt    = try c.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
        expiresAt    = try c.decodeIfPresent(String.self, forKey: .expiresAt)
        timeframe    = try c.decodeIfPresent(String.self, forKey: .timeframe)
        isActiveSignal = try c.decodeIfPresent(Bool.self, forKey: .isActiveSignal)
    }

    /// Direct memberwise init for creating Signal from a Brief or programmatically.
    init(
        id: String,
        symbol: String,
        direction: BriefDirection,
        type: String? = nil,
        entryPrice: Double? = nil,
        stopLoss: Double? = nil,
        takeProfit: Double? = nil,
        confidence: Int = 50,
        source: String? = nil,
        reasoning: String? = nil,
        status: SignalStatus? = nil,
        createdAt: String = "",
        expiresAt: String? = nil,
        timeframe: String? = nil,
        isActiveSignal: Bool? = nil
    ) {
        self.id = id
        self.symbol = symbol
        self.direction = direction
        self.type = type
        self.entryPrice = entryPrice
        self.stopLoss = stopLoss
        self.takeProfit = takeProfit
        self.confidence = confidence
        self.source = source
        self.reasoning = reasoning
        self.status = status ?? (isActiveSignal ?? true ? .active : .expired)
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.timeframe = timeframe
        self.isActiveSignal = isActiveSignal
    }

    /// Whether the signal is still actionable.
    var isActionable: Bool { status == .active }

    /// Risk-reward ratio based on SL/TP.
    var riskRewardRatio: Double? {
        guard let sl = stopLoss, let tp = takeProfit, let entry = entryPrice, sl != entry else { return nil }
        let risk = abs(entry - sl)
        let reward = abs(tp - entry)
        guard risk > 0 else { return nil }
        return reward / risk
    }

    /// Formatted risk-reward, e.g. "1:2.5".
    var formattedRiskReward: String? {
        guard let rr = riskRewardRatio else { return nil }
        return "1:\(String(format: "%.1f", rr))"
    }
}

// MARK: - Signal Execution

/// Payload for executing a signal on a specific credential.
struct SignalExecution: Codable {
    let credentialId: String
    let quantity: Double?
}
