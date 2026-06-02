// ============================================================================
// PredictionModels.swift
// RouaTrading — Prediction market events, user votes, and AI-driven
// price-gap predictions.
// ============================================================================

import Foundation

// MARK: - Prediction Event

/// A prediction market event that users can vote on.
struct PredictionEvent: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let description: String?
    let symbol: String?
    let category: String?
    /// Community-assessed probability 0–1.
    let probability: Double?
    /// AI-assessed probability 0–1.
    let aiProbability: Double?
    let impactAssessment: String?
    let status: String?
    /// Resolved outcome, if the event has concluded.
    let outcome: String?
    let expiresAt: String?
    let createdAt: String

    // ---- Computed helpers ----

    /// Whether the event has expired.
    var isExpired: Bool { status?.lowercased() == "expired" || status?.lowercased() == "resolved" }

    /// Whether the event is still open for voting.
    var isOpen: Bool { status?.lowercased() == "open" || status == nil }

    /// Community probability as a percentage string.
    var formattedProbability: String? {
        guard let p = probability else { return nil }
        return String(format: "%.0f%%", p * 100)
    }

    /// AI probability as a percentage string.
    var formattedAiProbability: String? {
        guard let p = aiProbability else { return nil }
        return String(format: "%.0f%%", p * 100)
    }

    /// Gap between community and AI probabilities.
    var probabilityGap: Double? {
        guard let p = probability, let a = aiProbability else { return nil }
        return abs(p - a)
    }
}

// MARK: - Prediction Vote

/// A user's vote on a prediction event.
struct PredictionVote: Codable {
    let symbol: String
    let direction: String
    /// Voter's confidence 0–100.
    let confidence: Int
    let reasoning: String?
    let timestamp: String

    /// Confidence label.
    var confidenceLabel: String {
        switch confidence {
        case 80...100: return "High"
        case 50..<80:  return "Medium"
        default:       return "Low"
        }
    }
}

// MARK: - Prediction Gap

/// Gap between current price and AI-predicted price for a symbol.
struct PredictionGap: Codable, Identifiable, Hashable {
    var id: String { symbol }

    let symbol: String
    let currentPrice: Double
    let predictedPrice: Double
    /// Absolute price difference.
    let gap: Double
    /// Gap as a percentage of current price.
    let gapPct: Double
    let direction: BriefDirection
    /// Prediction confidence 0–100.
    let confidence: Int

    // ---- Computed helpers ----

    /// Whether the predicted price is above the current price.
    var isBullish: Bool { direction == .bullish }

    /// Formatted gap percentage.
    var formattedGapPct: String {
        let prefix = gapPct >= 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.2f", gapPct))%"
    }

    /// Confidence label.
    var confidenceLabel: String {
        switch confidence {
        case 80...100: return "High"
        case 50..<80:  return "Medium"
        default:       return "Low"
        }
    }

    /// Potential gain/loss label based on direction and gap.
    var potentialLabel: String {
        switch direction {
        case .bullish: return "Potential Upside"
        case .bearish: return "Potential Downside"
        case .neutral: return "Neutral"
        }
    }
}
