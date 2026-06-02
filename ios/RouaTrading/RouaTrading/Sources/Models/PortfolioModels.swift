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
struct RiskReport: Codable {
    let overallRisk: Double
    let riskLevel: RiskLevel
    let positionConcentration: Double
    let leverageExposure: Double
    let liquidityRisk: Double
    let diversificationScore: Double
    let recommendations: [String]

    /// Number of risk recommendations.
    var recommendationCount: Int { recommendations.count }

    /// Diversification grade A–F.
    var diversificationGrade: String {
        switch diversificationScore {
        case 0.8...1.0: return "A"
        case 0.6..<0.8: return "B"
        case 0.4..<0.6: return "C"
        case 0.2..<0.4: return "D"
        default:         return "F"
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
struct PerformanceMetrics: Codable, Hashable {
    let totalTrades: Int
    let winRate: Double
    let totalPnl: Double
    let totalPnlPct: Double
    let sharpeRatio: Double?
    let maxDrawdown: Double?
    let avgWin: Double
    let avgLoss: Double
    let profitFactor: Double?
    let dailyReturn: Double?

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
