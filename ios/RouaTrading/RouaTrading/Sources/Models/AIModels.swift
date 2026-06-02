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
struct Brief: Codable, Identifiable, Hashable {
    let id: String
    let symbol: String
    let direction: BriefDirection
    /// Confidence 0–100.
    let confidence: Int
    let analysis: String
    let models: [ModelAnalysis]
    let createdAt: String
    let expiresAt: String?
    let status: BriefStatus
    let source: String

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
struct CouncilSessionStatus: Codable {
    let isRunning: Bool
    let lastSession: String?
}

// MARK: - Executor Status

/// High-level status of the Smart Executor.
struct ExecutorStatus: Codable {
    let isActive: Bool
    let mode: String
    let totalPositions: Int
    let totalPnl: Double
    let dailyPnl: Double
    let winRate: Double?
    let lastActivity: String?
    let uptime: Double?

    /// Formatted total PnL string.
    var formattedTotalPnl: String {
        let prefix = totalPnl >= 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.2f", totalPnl))"
    }

    /// Formatted daily PnL string.
    var formattedDailyPnl: String {
        let prefix = dailyPnl >= 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.2f", dailyPnl))"
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
struct Signal: Codable, Identifiable, Hashable {
    let id: String
    let symbol: String
    let direction: BriefDirection
    let type: String
    let entryPrice: Double
    let stopLoss: Double?
    let takeProfit: Double?
    /// Confidence 0–100.
    let confidence: Int
    let source: String
    let reasoning: String?
    let status: SignalStatus
    let createdAt: String
    let expiresAt: String?

    /// Whether the signal is still actionable.
    var isActionable: Bool { status == .active }

    /// Risk-reward ratio based on SL/TP.
    var riskRewardRatio: Double? {
        guard let sl = stopLoss, let tp = takeProfit, sl != entryPrice else { return nil }
        let risk = abs(entryPrice - sl)
        let reward = abs(tp - entryPrice)
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
