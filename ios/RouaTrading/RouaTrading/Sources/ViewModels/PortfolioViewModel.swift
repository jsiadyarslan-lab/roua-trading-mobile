// ============================================================================
// PortfolioViewModel.swift
// RouaTrading — Portfolio management ViewModel.
//
// Manages exchange credentials, balances, risk reports, autonomous agent
// state, agent positions, and performance metrics.
// ============================================================================

import Foundation
import SwiftUI

// MARK: - Portfolio ViewModel

/// Manages portfolio data for the Roua Trading app.
///
/// Manages:
/// - **Credentials** — Exchange API keys linked to the user's account
/// - **Balances** — Aggregate balance snapshots across credentials
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

    /// Aggregate balance snapshot across all credentials.
    @Published var balances: Balances?

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
        Task {
            isLoading = true
            errorMessage = nil

            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.loadCredentials() }
                group.addTask { await self.loadBalances() }
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

    // MARK: - Balances

    /// Loads aggregate balances across all credentials.
    func loadBalances() async {
        do {
            let balances: Balances = try await apiClient.request(.portfolioBalances)
            self.balances = balances
        } catch {
            logger.error("Failed to load balances: \(error.localizedDescription)")
            // Don't set errorMessage — balances require auth.
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
    func loadAgentStatus() async {
        do {
            let state: AgentState = try await cache.valueOrFetch(
                forKey: CacheKeys.agentStatus(),
                ttl: AppConfig.defaultCacheTimeout
            ) {
                try await self.apiClient.request(.agentStatus)
            }
            self.agentState = state
        } catch {
            logger.error("Failed to load agent status: \(error.localizedDescription)")
        }
    }

    // MARK: - Agent Positions

    /// Loads positions currently managed by the autonomous agent.
    func loadAgentPositions() async {
        do {
            let positions: [Position] = try await apiClient.request(.agentOpenPositions)
            self.agentPositions = positions
        } catch {
            logger.error("Failed to load agent positions: \(error.localizedDescription)")
        }
    }

    // MARK: - Agent Performance

    /// Loads aggregate trading performance statistics from the agent.
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
