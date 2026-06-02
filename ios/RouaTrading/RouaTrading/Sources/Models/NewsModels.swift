// ============================================================================
// NewsModels.swift
// RouaTrading — News feed, sentiment analysis, and article models.
// ============================================================================

import Foundation

// MARK: - News Item

/// A single news article or headline.
struct NewsItem: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String?
    let content: String?
    let url: String?
    let source: String?
    let imageUrl: String?
    let symbol: String?
    let sentiment: Sentiment
    let category: String?
    let publishedAt: String
    let impactScore: Double?

    // ---- Computed helpers ----

    /// Whether the article has a link to read more.
    var hasExternalLink: Bool { url != nil }

    /// Impact score label for UI badges.
    var impactLabel: String? {
        guard let score = impactScore else { return nil }
        switch score {
        case 0.7...1.0: return "High Impact"
        case 0.4..<0.7: return "Medium Impact"
        case 0.1..<0.4: return "Low Impact"
        default:         return "Minimal"
        }
    }

    /// Short summary truncated to a given character count.
    func truncatedSummary(maxLength: Int = 120) -> String {
        guard let s = summary else { return "" }
        if s.count <= maxLength { return s }
        return String(s.prefix(maxLength)) + "…"
    }
}

// MARK: - Sentiment Data

/// Aggregate sentiment across multiple articles or sources.
struct SentimentData: Codable {
    let overall: Sentiment
    /// Normalized score, typically –1.0 … +1.0.
    let score: Double
    /// Total number of articles analyzed.
    let articles: Int
    /// Per-source or per-category sentiment breakdown.
    let breakdown: [String: Double]
    let timestamp: String

    /// Human-readable score label.
    var scoreLabel: String {
        switch score {
        case 0.3...1.0: return "Bullish"
        case -0.3..<0.3: return "Neutral"
        default:         return "Bearish"
        }
    }
}

// MARK: - News Analysis Request

/// Payload for requesting AI sentiment analysis on a text.
struct NewsAnalysisRequest: Codable {
    let text: String
    let symbol: String?
}
