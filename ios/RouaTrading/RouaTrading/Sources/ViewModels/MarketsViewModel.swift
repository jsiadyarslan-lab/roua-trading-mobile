// ============================================================================
// MarketsViewModel.swift
// RouaTrading — Scanner and market data ViewModel.
//
// Manages market scanner results, heatmap data, market overview,
// deep analysis, news, and manual scan triggers.
// ============================================================================

import Foundation
import SwiftUI

// MARK: - Markets ViewModel

/// Provides scanner and market data for the Markets screen.
///
/// Manages:
/// - Market scanner results filtered by timeframe and category
/// - Heatmap visualization data
/// - Market overview (fear/greed, BTC dominance, top movers)
/// - Deep technical analysis for individual symbols
/// - Latest news
/// - Manual scan triggers
///
/// Results are cached via `CacheManager` to avoid redundant network calls.
///
/// Usage:
/// ```swift
/// @StateObject private var marketsVM = MarketsViewModel()
///
/// .task { await marketsVM.loadAll() }
/// ```
@MainActor
final class MarketsViewModel: ObservableObject {

    // MARK: - Published State

    /// Scanner results for the current timeframe and category.
    @Published var scanResults: [ScannerResult] = []

    /// Heatmap data for visualization.
    @Published var heatmapData: [HeatmapItem] = []

    /// Market overview summary.
    @Published var marketOverview: MarketOverview?

    /// Deep technical analysis for the selected symbol.
    @Published var deepAnalysis: DeepAnalysis?

    /// Currently selected timeframe for scanning.
    @Published var selectedTimeframe: TimeFrame = .oneHour

    /// Currently selected market category filter.
    @Published var selectedCategory: MarketCategory = .all

    /// Latest news articles.
    @Published var newsItems: [NewsItem] = []

    /// Whether a loading operation is in progress.
    @Published var isLoading: Bool = false

    /// The most recent error message, if any.
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let apiClient = APIClient.shared
    private let cache = CacheManager.shared
    private let logger = AppLogger.general

    // MARK: - Load All

    /// Loads scanner results, heatmap, overview, and news in parallel.
    func loadAll() {
        Task {
            isLoading = true
            errorMessage = nil

            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.loadScanner() }
                group.addTask { await self.loadHeatmap() }
                group.addTask { await self.loadOverview() }
                group.addTask { await self.loadNews() }
            }

            isLoading = false
        }
    }

    // MARK: - Scanner

    /// Loads scanner results for the selected timeframe and category.
    func loadScanner() async {
        do {
            let timeframe = selectedTimeframe.rawValue
            let category = selectedCategory == .all ? nil : selectedCategory.rawValue

            let results: [ScannerResult] = try await cache.valueOrFetch(
                forKey: CacheKeys.scannerScan(timeframe: timeframe, category: category),
                ttl: AppConfig.marketDataCacheTimeout
            ) {
                try await self.apiClient.request(
                    .scannerScan(timeframe: timeframe, category: category)
                )
            }
            self.scanResults = results
        } catch {
            logger.error("Failed to load scanner: \(error.localizedDescription)")
            errorMessage = "Failed to load scanner results."
        }
    }

    // MARK: - Heatmap

    /// Loads heatmap data for the selected category.
    func loadHeatmap() async {
        do {
            let category = selectedCategory == .all ? nil : selectedCategory.rawValue

            let items: [HeatmapItem] = try await cache.valueOrFetch(
                forKey: CacheKeys.scannerHeatmap(category: category),
                ttl: AppConfig.marketDataCacheTimeout
            ) {
                try await self.apiClient.request(
                    .scannerHeatmap(category: category)
                )
            }
            self.heatmapData = items
        } catch {
            logger.error("Failed to load heatmap: \(error.localizedDescription)")
            errorMessage = "Failed to load heatmap data."
        }
    }

    // MARK: - Market Overview

    /// Loads the market overview summary.
    func loadOverview() async {
        do {
            let overview: MarketOverview = try await cache.valueOrFetch(
                forKey: CacheKeys.scannerOverview(),
                ttl: AppConfig.marketDataCacheTimeout
            ) {
                try await self.apiClient.request(.scannerOverview)
            }
            self.marketOverview = overview
        } catch {
            logger.error("Failed to load market overview: \(error.localizedDescription)")
            errorMessage = "Failed to load market overview."
        }
    }

    // MARK: - Deep Analysis

    /// Loads deep technical analysis for a specific symbol.
    ///
    /// - Parameter symbol: The trading symbol to analyze (e.g., "BTCUSDT").
    func loadDeepAnalysis(symbol: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let analysis: DeepAnalysis = try await cache.valueOrFetch(
                forKey: CacheKeys.scannerAnalysis(symbol: symbol),
                ttl: AppConfig.marketDataCacheTimeout
            ) {
                try await self.apiClient.request(.scannerAnalysis(symbol: symbol))
            }
            self.deepAnalysis = analysis
        } catch {
            logger.error("Failed to load deep analysis for \(symbol): \(error.localizedDescription)")
            errorMessage = "Failed to load analysis for \(symbol)."
        }

        isLoading = false
    }

    // MARK: - News

    /// Loads the latest news articles.
    func loadNews() async {
        do {
            let news: [NewsItem] = try await cache.valueOrFetch(
                forKey: CacheKeys.newsLatest(symbol: nil),
                ttl: AppConfig.defaultCacheTimeout
            ) {
                try await self.apiClient.request(
                    .newsLatest(symbol: nil, sentiment: nil, category: nil, limit: 20)
                )
            }
            self.newsItems = news
        } catch {
            logger.error("Failed to load news: \(error.localizedDescription)")
            errorMessage = "Failed to load news."
        }
    }

    // MARK: - Run Scan

    /// Triggers a manual scanner run for the selected timeframe and category.
    ///
    /// This POST request initiates a new scan on the backend. After the scan
    /// completes, the scanner results are refreshed.
    func runScan() async {
        isLoading = true
        errorMessage = nil

        do {
            let timeframe = selectedTimeframe.rawValue
            let category = selectedCategory == .all ? nil : selectedCategory.rawValue

            let _: Data = try await apiClient.requestRaw(
                .scannerRun(timeframe: timeframe, category: category)
            )
            logger.info("Scan triggered successfully")

            // Invalidate cached scanner results so we fetch fresh data
            cache.removeWithPrefix("scanner:scan:")

            // Reload scanner results
            await loadScanner()
        } catch {
            errorMessage = error.localizedDescription
            logger.error("Failed to trigger scan: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Filter Changes

    /// Updates the selected timeframe and reloads scanner data.
    ///
    /// - Parameter timeframe: The new timeframe.
    func updateTimeframe(_ timeframe: TimeFrame) {
        guard timeframe != selectedTimeframe else { return }
        selectedTimeframe = timeframe
        deepAnalysis = nil

        Task {
            await loadScanner()
        }
    }

    /// Updates the selected category and reloads scanner and heatmap data.
    ///
    /// - Parameter category: The new market category.
    func updateCategory(_ category: MarketCategory) {
        guard category != selectedCategory else { return }
        selectedCategory = category
        deepAnalysis = nil

        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.loadScanner() }
                group.addTask { await self.loadHeatmap() }
            }
        }
    }
}
