// ============================================================================
// HomeViewModel.swift
// RouaTrading — Dashboard data aggregator ViewModel.
//
// Loads market overview, top movers, news, signals, and portfolio
// summary in parallel for the home/dashboard screen.
// ============================================================================

import Foundation
import SwiftUI

// MARK: - Home ViewModel

/// Aggregates dashboard data from multiple backend services for the
/// home screen of the Roua Trading app.
///
/// Loads the following data in parallel via `async let`:
/// - Market overview (scanner)
/// - Recent news
/// - Active signals
/// - Positions summary
/// - Portfolio summary
///
/// Results are cached via `CacheManager` to reduce redundant network calls
/// on subsequent loads.
///
/// Usage:
/// ```swift
/// @StateObject private var homeVM = HomeViewModel()
///
/// .task { await homeVM.loadDashboard() }
/// .refreshable { await homeVM.refresh() }
/// ```
@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: - Published State

    /// Market overview including fear/greed index, BTC dominance, and top movers.
    @Published var marketOverview: MarketOverview?

    /// Top gaining symbols from the scanner.
    @Published var topGainers: [ScannerResult] = []

    /// Top losing symbols from the scanner.
    @Published var topLosers: [ScannerResult] = []

    /// Recent news articles.
    @Published var recentNews: [NewsItem] = []

    /// Currently active trading signals.
    @Published var activeSignals: [Signal] = []

    /// Aggregated open positions summary.
    @Published var positionsSummary: PositionSummary?

    /// Full portfolio snapshot including balances and positions.
    @Published var portfolioSummary: PortfolioSummary?

    /// Whether a loading operation is in progress.
    @Published var isLoading: Bool = false

    /// The most recent error message, if any.
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let apiClient = APIClient.shared
    private let cache = CacheManager.shared
    private let logger = AppLogger.general

    // MARK: - Cancellation Support

    private var loadTask: Task<Void, Never>?

    // MARK: - Load Dashboard

    /// Fetches all dashboard data in parallel.
    ///
    /// Loads market overview, news, active signals, positions, and portfolio
    /// summary concurrently. If any individual request fails, the others
    /// continue and the first error is captured in `errorMessage`.
    func loadDashboard() {
        loadTask?.cancel()
        loadTask = Task {
            isLoading = true
            errorMessage = nil

            // Fetch all data in parallel
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.loadMarketOverview() }
                group.addTask { await self.loadNews() }
                group.addTask { await self.loadSignals() }
                group.addTask { await self.loadPositions() }
                group.addTask { await self.loadPortfolio() }
            }

            isLoading = false
        }
    }

    /// Reloads all dashboard data (equivalent to pull-to-refresh).
    func refresh() {
        // Clear cached data to force fresh fetches
        cache.removeWithPrefix("scanner:")
        cache.removeWithPrefix("news:")
        cache.removeWithPrefix("signals:")
        loadDashboard()
    }

    // MARK: - Individual Data Loaders

    /// Loads the market overview including top gainers and losers.
    private func loadMarketOverview() async {
        do {
            let overview: MarketOverview = try await cache.valueOrFetch(
                forKey: CacheKeys.scannerOverview(),
                ttl: AppConfig.marketDataCacheTimeout
            ) {
                try await self.apiClient.request(.scannerOverview)
            }
            self.marketOverview = overview
            self.topGainers = overview.topGainers
            self.topLosers = overview.topLosers
        } catch {
            logger.error("Failed to load market overview: \(error.localizedDescription)")
            // If we have cached data, don't show error — just keep existing data
            if marketOverview == nil && errorMessage == nil {
                errorMessage = "تعذر تحميل بيانات السوق. اسحب للتحديث."
            }
        }
    }

    /// Loads the latest news articles.
    private func loadNews() async {
        do {
            let news: [NewsItem] = try await cache.valueOrFetch(
                forKey: CacheKeys.newsLatest(symbol: nil),
                ttl: AppConfig.defaultCacheTimeout
            ) {
                try await self.apiClient.request(.newsLatest(symbol: nil, sentiment: nil, category: nil, limit: 10))
            }
            self.recentNews = news
        } catch {
            logger.error("Failed to load news: \(error.localizedDescription)")
            // Don't overwrite errorMessage from other concurrent requests
            // News is supplementary — not critical for dashboard
        }
    }

    /// Loads active trading signals.
    private func loadSignals() async {
        do {
            let signals: [Signal] = try await apiClient.request(.signalsActive)
            self.activeSignals = signals
        } catch {
            logger.error("Failed to load signals: \(error.localizedDescription)")
            // Try council briefs as fallback — they're public and always available
            if activeSignals.isEmpty {
                await loadCouncilBriefsAsSignals()
            }
        }
    }

    /// Fallback: loads council briefs and maps them to signal-like objects
    /// so the home screen still shows AI activity even when /signals/active fails.
    ///
    /// The backend `/strategic-council/briefs/active` returns:
    /// `{ "success": true, "data": [...] }` — a flat array of Brief objects.
    /// The smartDecode in APIClient unwraps the envelope, so we decode
    /// directly as `[Brief]`.
    private func loadCouncilBriefsAsSignals() async {
        do {
            let briefs: [Brief] = try await apiClient.request(.councilActiveBriefs(symbol: nil))
            // Convert Briefs to Signals so the home screen can display them.
            // Briefs have all the fields needed for the signal card (symbol/pair,
            // direction, confidence, entryPrice, etc.)
            self.activeSignals = briefs.map { brief in
                Signal(
                    id: brief.id,
                    symbol: brief.symbol,
                    direction: brief.direction,
                    type: brief.timeframe,
                    entryPrice: brief.entryPrice,
                    stopLoss: brief.stopLoss,
                    takeProfit: brief.takeProfit,
                    confidence: brief.confidence,
                    source: brief.source,
                    reasoning: brief.analysis,
                    status: .active,
                    createdAt: brief.createdAt,
                    expiresAt: brief.expiresAt,
                    timeframe: brief.timeframe,
                    isActiveSignal: brief.isActiveBrief
                )
            }
        } catch {
            logger.error("Failed to load council briefs fallback: \(error.localizedDescription)")
        }
    }

    /// Loads the open positions summary.
    private func loadPositions() async {
        do {
            let summary: PositionSummary = try await apiClient.request(.tradingPositionsSummary)
            self.positionsSummary = summary
        } catch {
            logger.error("Failed to load positions: \(error.localizedDescription)")
            // Positions may be empty for new users — create a default summary
            if positionsSummary == nil {
                self.positionsSummary = PositionSummary(
                    totalUnrealizedPnl: 0,
                    totalPositionValue: 0,
                    positionCount: 0,
                    positions: []
                )
            }
        }
    }

    /// Loads the full portfolio summary including balance and positions.
    private func loadPortfolio() async {
        do {
            let portfolio: PortfolioSummary = try await apiClient.request(.tradingV2Portfolio)
            self.portfolioSummary = portfolio
        } catch {
            logger.error("Failed to load portfolio: \(error.localizedDescription)")
            // Create a default portfolio summary so the UI shows $0.00 instead of nothing
            if portfolioSummary == nil {
                self.portfolioSummary = PortfolioSummary(
                    totalBalance: 0,
                    availableBalance: 0,
                    totalPnl: 0,
                    totalPnlPct: 0,
                    unrealizedPnl: 0,
                    marginUsed: 0,
                    marginAvailable: 0,
                    positions: []
                )
            }
        }
    }
}
