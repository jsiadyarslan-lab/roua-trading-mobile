// ============================================================================
// NewsModels.swift
// RouaTrading — News feed, sentiment analysis, and article models.
// ============================================================================

import Foundation

// MARK: - News Item

/// A single news article or headline.
///
/// The backend `/news/latest` endpoint returns:
/// ```json
/// {
///   "id": "...",
///   "title": "...",
///   "summary": "...",
///   "content": "...",
///   "url": "...",
///   "source": "TradingView",
///   "imageUrl": "...",
///   "sentiment": -0.7,
///   "sentimentLabel": "negative",
///   "impactLevel": "high",
///   "category": "Economy",
///   "publishedAt": "2026-06-05T21:31:21.646Z",
///   "affectedAssets": [...],
///   "keyTakeaways": [...],
///   ...
/// }
/// ```
struct NewsItem: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let translatedTitle: String?
    let summary: String?
    let content: String?
    let translatedContent: String?
    let fullContent: String?
    let url: String?
    let source: String?
    let imageUrl: String?
    let symbol: String?
    /// Raw sentiment score from backend (–1.0 … +1.0).
    let sentimentScore: Double?
    /// Human-readable label: "positive", "negative", or "neutral".
    let sentimentLabel: String?
    /// Impact level: "high", "medium", "low".
    let impactLevel: String?
    let category: String?
    /// Arabic category name.
    let categoryAr: String?
    let publishedAt: String?
    /// News type, e.g. "live".
    let newsType: String?
    /// Language code.
    let lang: String?
    /// Key takeaway strings.
    let keyTakeaways: [String]?
    /// Affected asset details.
    let affectedAssets: [AffectedAsset]?
    /// Legacy: kept for backward compat with views that use `Sentiment` enum.
    let impactScore: Double?

    // ---- Coding Keys ----

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case translatedTitle
        case summary
        case content
        case translatedContent
        case fullContent
        case url
        case source
        case imageUrl
        case symbol
        case sentimentScore = "sentiment"
        case sentimentLabel
        case impactLevel
        case category
        case categoryAr
        case publishedAt
        case newsType
        case lang
        case keyTakeaways
        case affectedAssets
        case impactScore
    }

    // ---- Custom decoder ----

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                  = try c.decode(String.self, forKey: .id)
        title               = try c.decode(String.self, forKey: .title)
        translatedTitle     = try c.decodeIfPresent(String.self, forKey: .translatedTitle)
        summary             = try c.decodeIfPresent(String.self, forKey: .summary)
        content             = try c.decodeIfPresent(String.self, forKey: .content)
        translatedContent   = try c.decodeIfPresent(String.self, forKey: .translatedContent)
        fullContent         = try c.decodeIfPresent(String.self, forKey: .fullContent)
        url                 = try c.decodeIfPresent(String.self, forKey: .url)
        source              = try c.decodeIfPresent(String.self, forKey: .source)
        imageUrl            = try c.decodeIfPresent(String.self, forKey: .imageUrl)
        symbol              = try c.decodeIfPresent(String.self, forKey: .symbol)
        sentimentScore      = try c.decodeIfPresent(Double.self, forKey: .sentimentScore)
        sentimentLabel      = try c.decodeIfPresent(String.self, forKey: .sentimentLabel)
        impactLevel         = try c.decodeIfPresent(String.self, forKey: .impactLevel)
        category            = try c.decodeIfPresent(String.self, forKey: .category)
        categoryAr          = try c.decodeIfPresent(String.self, forKey: .categoryAr)
        publishedAt         = try c.decodeIfPresent(String.self, forKey: .publishedAt)
        newsType            = try c.decodeIfPresent(String.self, forKey: .newsType)
        lang                = try c.decodeIfPresent(String.self, forKey: .lang)
        keyTakeaways        = try c.decodeIfPresent([String].self, forKey: .keyTakeaways)
        affectedAssets      = try c.decodeIfPresent([AffectedAsset].self, forKey: .affectedAssets)
        // Derive impactScore from impactLevel if not present
        if let score = try c.decodeIfPresent(Double.self, forKey: .impactScore) {
            impactScore = score
        } else if let level = impactLevel {
            switch level.lowercased() {
            case "high":   impactScore = 0.8
            case "medium": impactScore = 0.5
            case "low":    impactScore = 0.2
            default:       impactScore = nil
            }
        } else {
            impactScore = nil
        }
    }

    // ---- Computed helpers ----

    /// Computed `Sentiment` enum derived from `sentimentLabel` or `sentimentScore`.
    var sentiment: Sentiment {
        if let label = sentimentLabel?.lowercased() {
            switch label {
            case "positive": return .positive
            case "negative": return .negative
            default:         return .neutral
            }
        }
        if let score = sentimentScore {
            if score > 0.1 { return .positive }
            if score < -0.1 { return .negative }
        }
        return .neutral
    }

    /// Whether the article has a link to read more.
    var hasExternalLink: Bool { url != nil }

    /// Impact score label for UI badges.
    var impactLabel: String? {
        if let level = impactLevel {
            switch level.lowercased() {
            case "high":   return "High Impact"
            case "medium": return "Medium Impact"
            case "low":    return "Low Impact"
            default:       return level.capitalized
            }
        }
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

// MARK: - Affected Asset

/// An asset referenced in a news article.
struct AffectedAsset: Codable, Hashable {
    let name: String?
    let reason: String?
    let symbol: String?
    let direction: String?
    let isTradable: Bool?
    let impactDegree: String?
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
