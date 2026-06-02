// ============================================================================
// NeuralModels.swift
// RouaTrading — Neural network, backtesting, swarm, and system-health
// models.
// ============================================================================

import Foundation

// MARK: - Backtest Request

/// Payload for requesting a strategy backtest.
struct BacktestRequest: Codable {
    let symbol: String
    let strategy: String?
    let periodStart: String
    let periodEnd: String
    let initialCapital: Double?
    let positionSize: Double?
    let stopLoss: Double?
    let takeProfit: Double?
    let language: String?
}

// MARK: - Backtest Result

/// Full results of a completed backtest.
struct BacktestResult: Codable, Identifiable, Hashable {
    var id: String { "\(symbol)-\(strategy)" }

    let symbol: String
    let strategy: String
    let totalTrades: Int
    let winRate: Double
    let totalReturn: Double
    let maxDrawdown: Double
    let sharpeRatio: Double
    let trades: [BacktestTrade]
    /// Equity curve data points.
    let equity: [Double]
    let periodStart: String
    let periodEnd: String

    // ---- Computed helpers ----

    /// Formatted win rate.
    var formattedWinRate: String {
        String(format: "%.1f%%", winRate * 100)
    }

    /// Formatted total return.
    var formattedTotalReturn: String {
        let prefix = totalReturn >= 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.2f", totalReturn))%"
    }

    /// Whether the strategy was profitable.
    var isProfitable: Bool { totalReturn > 0 }

    /// Number of winning trades.
    var winningTrades: Int {
        trades.filter { $0.pnl > 0 }.count
    }

    /// Number of losing trades.
    var losingTrades: Int {
        trades.filter { $0.pnl <= 0 }.count
    }
}

// MARK: - Backtest Trade

/// A single trade executed during a backtest.
struct BacktestTrade: Codable, Identifiable, Hashable {
    var id: String {
        "\(symbol)-\(side)-\(entryTime)-\(exitTime)"
    }

    let symbol: String
    let side: OrderSide
    let entryPrice: Double
    let exitPrice: Double
    let quantity: Double
    let pnl: Double
    let pnlPct: Double
    let entryTime: String
    let exitTime: String

    /// Whether the trade was a winner.
    var isWinner: Bool { pnl > 0 }

    /// Formatted PnL.
    var formattedPnl: String {
        let prefix = pnl >= 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.2f", pnl))"
    }
}

// MARK: - Compare Result

/// Multi-strategy comparison result.
struct CompareResult: Codable {
    let comparison: [StrategyComparison]
    let symbol: String

    /// Number of strategies compared.
    var strategyCount: Int { comparison.count }

    /// The best-performing strategy (highest total return).
    var bestStrategy: StrategyComparison? {
        comparison
            .filter { $0.result != nil }
            .max(by: { ($0.result?.totalReturn ?? 0) < ($1.result?.totalReturn ?? 0) })
    }
}

// MARK: - Strategy Comparison

/// A single strategy within a comparison.
struct StrategyComparison: Codable, Identifiable, Hashable {
    var id: String { strategy }

    let strategy: String
    let result: BacktestResult?
    let error: String?

    /// Whether the strategy backtest succeeded.
    var isSuccess: Bool { result != nil && error == nil }
}

// MARK: - Neural Train Request

/// Payload for training a neural network model.
struct NeuralTrainRequest: Codable {
    let symbol: String
    let architecture: String?
    let horizon: String?
    let lookbackDays: Int?
    let epochs: Int?
    let language: String?
}

// MARK: - Neural Model Info

/// Metadata about a trained neural network model.
struct NeuralModelInfo: Codable, Identifiable, Hashable {
    let id: String
    let symbol: String
    let architecture: String
    let status: String
    let accuracy: Double?
    let loss: Double?
    let trainedAt: String
    let version: String?

    /// Whether the model is ready for predictions.
    var isReady: Bool { status.lowercased() == "ready" || status.lowercased() == "completed" }

    /// Formatted accuracy percentage.
    var formattedAccuracy: String? {
        guard let acc = accuracy else { return nil }
        return String(format: "%.1f%%", acc * 100)
    }
}

// MARK: - Neural Predict Request

/// Payload for requesting a neural network prediction.
struct NeuralPredictRequest: Codable {
    let symbol: String
    let steps: Int?
    let horizon: String?
    let language: String?
}

// MARK: - Neural Predict Result

/// Output from a neural network prediction run.
struct NeuralPredictResult: Codable, Identifiable, Hashable {
    var id: String { symbol }

    let symbol: String
    let predictions: [PredictionPoint]
    let model: String
    let confidence: Double?
    let timestamp: String

    /// Number of predicted steps.
    var stepCount: Int { predictions.count }

    /// The final predicted price.
    var finalPredictedPrice: Double? {
        predictions.last?.price
    }
}

// MARK: - Prediction Point

/// A single point in a prediction series.
struct PredictionPoint: Codable, Identifiable, Hashable {
    var id: Int { time }

    let time: Int
    let price: Double
    let lower: Double?
    let upper: Double?

    /// Confidence interval width.
    var intervalWidth: Double? {
        guard let l = lower, let u = upper else { return nil }
        return u - l
    }

    /// Midpoint of the confidence interval.
    var intervalMidpoint: Double? {
        guard let l = lower, let u = upper else { return nil }
        return (l + u) / 2.0
    }
}

// MARK: - Swarm Request

/// Payload for initiating a swarm-of-agents session.
struct SwarmRequest: Codable {
    let agents: Int?
    let symbols: [String]?
    let strategy: String?
    let riskTolerance: Double?
    let language: String?
}

// MARK: - Swarm Result

/// Outcome of a swarm-of-agents session.
struct SwarmResult: Codable, Identifiable, Hashable {
    let id: String
    let status: String
    let agents: [String]?
    let results: [String]?
    let startTime: String
    let endTime: String?
    let totalPnl: Double?
    let totalTrades: Int?

    /// Whether the swarm has completed.
    var isComplete: Bool { status.lowercased() == "completed" }

    /// Formatted total PnL.
    var formattedTotalPnl: String? {
        guard let pnl = totalPnl else { return nil }
        let prefix = pnl >= 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.2f", pnl))"
    }
}

// MARK: - System Health

/// Backend system health status.
struct SystemHealth: Codable {
    let status: String
    let components: [String: String]?
    let uptime: Double?
    let memory: Double?
    let cpu: Double?

    /// Whether the system is healthy.
    var isHealthy: Bool { status.lowercased() == "ok" || status.lowercased() == "healthy" }

    /// Formatted uptime string.
    var formattedUptime: String? {
        guard let up = uptime else { return nil }
        let days = Int(up) / 86_400
        let hours = (Int(up) % 86_400) / 3_600
        let minutes = (Int(up) % 3_600) / 60
        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }

    /// Formatted CPU usage.
    var formattedCpu: String? {
        guard let c = cpu else { return nil }
        return String(format: "%.1f%%", c)
    }

    /// Formatted memory usage.
    var formattedMemory: String? {
        guard let m = memory else { return nil }
        return String(format: "%.1f%%", m)
    }
}

// MARK: - Source Performance

/// Performance metrics for a data source.
struct SourcePerformance: Codable, Identifiable, Hashable {
    var id: String { source }

    let source: String
    let metrics: [String: Double]
    let period: String
    let timestamp: String

    /// Uptime metric if present.
    var uptime: Double? { metrics["uptime"] }

    /// Latency metric if present.
    var latency: Double? { metrics["latency"] }

    /// Error rate metric if present.
    var errorRate: Double? { metrics["errorRate"] }
}
