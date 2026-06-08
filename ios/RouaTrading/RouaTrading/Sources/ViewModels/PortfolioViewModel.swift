// ============================================================================
// PortfolioViewModel.swift
// RouaTrading — Portfolio management ViewModel.
//
// Manages exchange credentials, portfolio summary, risk reports, autonomous
// agent state, agent positions, and performance metrics.
//
// Key fix: The backend does not have `/portfolio/credentials/balances` or
// `/agent/trader/*` endpoints. We use `/trading/v2/portfolio` for balance
// data and `/trading/v2/positions` for agent positions instead.
// ============================================================================

import Foundation
import SwiftUI

// MARK: - Portfolio ViewModel

/// Manages portfolio data for the Roua Trading app.
///
/// Manages:
/// - **Credentials** — Exchange API keys linked to the user's account
/// - **Portfolio Summary** — Aggregate balance and position snapshot
/// - **Risk Report** — Comprehensive risk assessment (Sanctuary)
/// - **Agent State** — Autonomous trading agent status
/// - **Agent Positions** — Positions managed by the agent
/// - **Performance** — Aggregate trading performance statistics
///
/// Usage:
/// ```swift
/// @StateObject private var portfolioVM = PortfolioViewModel()
///
/// .task { await portfolioVM.loadAll() }
/// ```
@MainActor
final class PortfolioViewModel: ObservableObject {

    // MARK: - Published State

    /// Exchange API key credentials linked to the user.
    @Published var credentials: [Credential] = []

    /// Portfolio summary with total balance, daily PnL, positions, etc.
    /// Replaces the old `Balances` model — the backend's
    /// `/portfolio/credentials/balances` endpoint doesn't exist, but
    /// `/trading/v2/portfolio` does and returns richer data.
    @Published var portfolioSummary: PortfolioSummary?

    /// Comprehensive risk assessment for the portfolio.
    @Published var riskReport: RiskReport?

    /// Current state of the autonomous trading agent.
    @Published var agentState: AgentState?

    /// Positions currently managed by the autonomous agent.
    @Published var agentPositions: [Position] = []

    /// Aggregate trading performance statistics.
    @Published var performance: PerformanceMetrics?

    /// Whether a loading operation is in progress.
    @Published var isLoading: Bool = false

    /// The most recent error message, if any.
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let apiClient = APIClient.shared
    private let cache = CacheManager.shared
    private let logger = AppLogger.general

    // MARK: - Load All

    /// Loads all portfolio data in parallel.
    func loadAll() {
        isLoading = true
        errorMessage = nil

        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.loadCredentials() }
                group.addTask { await self.loadPortfolioSummary() }
                group.addTask { await self.loadRiskReport() }
                group.addTask { await self.loadAgentStatus() }
                group.addTask { await self.loadAgentPositions() }
                group.addTask { await self.loadAgentPerformance() }
            }

            isLoading = false
        }
    }

    // MARK: - Credentials

    /// Loads exchange API key credentials.
    func loadCredentials() async {
        do {
            let credentials: [Credential] = try await apiClient.request(.portfolioCredentials)
            self.credentials = credentials
        } catch {
            logger.error("Failed to load credentials: \(error.localizedDescription)")
            // Don't set errorMessage — credentials require auth and may fail
            // for unauthenticated users. Show empty state instead of error.
        }
    }

    // MARK: - Portfolio Summary (was Balances)

    /// Loads portfolio summary via `/trading/v2/portfolio`.
    ///
    /// The backend's `/portfolio/credentials/balances` endpoint returns 404.
    /// `/trading/v2/portfolio` exists and returns `PortfolioSummary` with
    /// total balance, daily PnL, unrealized PnL, positions, and more.
    func loadPortfolioSummary() async {
        do {
            let summary: PortfolioSummary = try await apiClient.request(.tradingV2Portfolio)
            self.portfolioSummary = summary
        } catch {
            logger.error("Failed to load portfolio summary: \(error.localizedDescription)")
            // Don't set errorMessage — portfolio summary requires auth.
            // Show empty/default state instead of blocking the UI.
        }
    }

    // MARK: - Risk Report

    /// Loads the comprehensive risk assessment (Sanctuary).
    func loadRiskReport() async {
        do {
            let report: RiskReport = try await apiClient.request(.portfolioSanctuary)
            self.riskReport = report
        } catch {
            logger.error("Failed to load risk report: \(error.localizedDescription)")
            // Don't set errorMessage — sanctuary requires auth.
        }
    }

    // MARK: - Agent Status

    /// Loads the current autonomous trading agent state.
    ///
    /// The backend's `/agent/trader/status` endpoint returns 404 in the
    /// current deployment. We provide a default inactive state as fallback.
    func loadAgentStatus() async {
        do {
            let state: AgentState = try await cache.valueOrFetch(
                forKey: CacheKeys.agentStatus(),
                ttl: AppConfig.defaultCacheTimeout
            ) {
                do {
                    return try await self.apiClient.request(.agentStatus)
                } catch {
                    // Backend may not have the agent endpoints deployed.
                    // Return a default inactive agent state.
                    return AgentState(isActive: false, strategy: nil, startTime: nil,
                                      totalTrades: nil, winRate: nil, totalPnl: nil,
                                      currentPositions: nil, settings: nil)
                }
            }
            self.agentState = state
        } catch {
            logger.error("Failed to load agent status: \(error.localizedDescription)")
            // Provide a default inactive state
            if agentState == nil {
                self.agentState = AgentState(isActive: false, strategy: nil, startTime: nil,
                                              totalTrades: nil, winRate: nil, totalPnl: nil,
                                              currentPositions: nil, settings: nil)
            }
        }
    }

    // MARK: - Agent Positions

    /// Loads positions currently managed by the autonomous agent.
    ///
    /// The backend's `/agent/trader/open-positions` endpoint returns 404.
    /// We use `/trading/v2/positions` instead, which returns the same
    /// `Position` objects for the authenticated user.
    func loadAgentPositions() async {
        do {
            let positions: [Position] = try await apiClient.request(.tradingV2Positions)
            self.agentPositions = positions
        } catch {
            logger.error("Failed to load agent positions: \(error.localizedDescription)")
        }
    }

    // MARK: - Agent Performance

    /// Loads aggregate trading performance statistics from the agent.
    ///
    /// The backend's `/agent/trader/performance` endpoint returns 404.
    /// We provide a default empty metrics as fallback.
    func loadAgentPerformance() async {
        do {
            let metrics: PerformanceMetrics = try await cache.valueOrFetch(
                forKey: CacheKeys.agentPerformance(),
                ttl: AppConfig.defaultCacheTimeout
            ) {
                try await self.apiClient.request(.agentPerformance)
            }
            self.performance = metrics
        } catch {
            logger.error("Failed to load agent performance: \(error.localizedDescription)")
            // Provide a default empty performance if none exists
            if performance == nil {
                self.performance = PerformanceMetrics(
                    totalTrades: 0,
                    winRate: 0,
                    totalPnl: 0,
                    totalPnlPct: nil,
                    sharpeRatio: nil,
                    maxDrawdown: nil,
                    avgWin: 0,
                    avgLoss: 0,
                    profitFactor: nil,
                    dailyReturn: nil,
                    winningTrades: nil,
                    losingTrades: nil,
                    bestTrade: nil,
                    worstTrade: nil,
                    consecutiveWins: nil,
                    consecutiveLosses: nil,
                    averageHoldingTime: nil,
                    period: nil
                )
            }
        }
    }

    // MARK: - Start Agent

    /// Starts the autonomous trading agent with the given configuration.
    ///
    /// After successfully starting, the agent status and positions are
    /// refreshed automatically.
    ///
    /// - Parameter request: The agent start configuration.
    func startAgent(_ request: AgentStartRequest) async {
        isLoading = true
        errorMessage = nil

        do {
            let _: Data = try await apiClient.requestRaw(.agentStart, body: request)
            logger.info("Agent started with strategy: \(request.strategy.rawValue)")

            // Refresh agent state
            await loadAgentStatus()
            await loadAgentPositions()
        } catch {
            errorMessage = error.localizedDescription
            logger.error("Failed to start agent: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Stop Agent

    /// Stops the autonomous trading agent.
    ///
    /// - Parameter emergency: If `true`, performs an emergency stop which
    ///   immediately closes all positions. Defaults to `false`.
    func stopAgent(emergency: Bool = false) async {
        isLoading = true
        errorMessage = nil

        do {
            let request = AgentStopRequest(emergency: emergency)
            let _: Data = try await apiClient.requestRaw(.agentStop, body: request)
            logger.info("Agent stopped (emergency: \(emergency))")

            // Refresh agent state and positions
            await loadAgentStatus()
            await loadAgentPositions()
        } catch {
            errorMessage = error.localizedDescription
            logger.error("Failed to stop agent: \(error.localizedDescription)")
        }

        isLoading = false
    }
}
