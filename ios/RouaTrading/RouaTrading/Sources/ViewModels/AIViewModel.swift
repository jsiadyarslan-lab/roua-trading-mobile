// ============================================================================
// AIViewModel.swift
// RouaTrading — All AI features ViewModel.
//
// Manages strategic council briefs, consensus, smart executor, AI coach,
// signals, and AI model status.
// ============================================================================

import Foundation
import SwiftUI

// MARK: - Request Body Types

/// Payload for enabling the Smart Executor for the current user.
private struct ExecutorEnableRequest: Codable {
    let maxOpenPositions: Int
    let riskPerTradePercent: Double
}

/// Payload for triggering a strategic council session.
private struct CouncilTriggerRequest: Codable {
    let pairs: [String]
}

// MARK: - AI ViewModel

/// Centralizes all AI-powered features for the Roua Trading app.
///
/// Manages:
/// - **Strategic Council** — AI briefs, session triggering, and status
/// - **Consensus** — Multi-model agreement analysis
/// - **Smart Executor** — Autonomous trading agent with user controls
/// - **AI Coach** — Trading performance coaching and Q&A
/// - **Signals** — AI-generated trading signals and execution
/// - **AI Models** — LLM availability and status
///
/// Usage:
/// ```swift
/// @StateObject private var aiVM = AIViewModel()
///
/// .task { await aiVM.loadAll() }
/// ```
@MainActor
final class AIViewModel: ObservableObject {

    // MARK: - Published State

    /// Active strategic council briefs.
    @Published var councilBriefs: [Brief] = []

    /// Multi-model consensus result for a symbol.
    @Published var consensusResult: ConsensusResult?

    /// Smart Executor global status.
    @Published var executorStatus: ExecutorStatus?

    /// Positions managed by the Smart Executor.
    @Published var executorPositions: [SmartExecutorPosition] = []

    /// The user's personal Smart Executor configuration.
    @Published var userExecutorState: UserExecutorState?

    /// Current exposure metrics for the Smart Executor.
    @Published var executorExposure: ExecutorExposure?

    /// AI Coach advice entries.
    @Published var coachAdvice: [CoachAdvice] = []

    /// Active trading signals.
    @Published var activeSignals: [Signal] = []

    /// AI/LLM model availability status.
    @Published var aiModels: ModelsStatusResponse?

    /// Current council session status.
    @Published var councilSession: CouncilSessionStatus?

    /// Whether a loading operation is in progress.
    @Published var isLoading: Bool = false

    /// The most recent error message, if any.
    @Published var errorMessage: String?

    /// Whether a council trigger is currently in progress.
    @Published var isTriggeringCouncil: Bool = false

    /// Chat messages for the AI Coach interface.
    @Published var coachMessages: [CoachMessage] = []

    /// Whether the AI Coach is currently thinking/generating a response.
    @Published var isCoachThinking: Bool = false

    // MARK: - Computed

    /// Briefs that are no longer active (history).
    var briefHistory: [Brief] {
        councilBriefs.filter { $0.status != .active }
    }

    // MARK: - Dependencies

    private let apiClient = APIClient.shared
    private let cache = CacheManager.shared
    private let logger = AppLogger.general

    // MARK: - Load All

    /// Loads all AI feature data in parallel.
    func loadAll() {
        Task {
            isLoading = true
            errorMessage = nil

            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.loadBriefs() }
                group.addTask { await self.loadExecutorStatus() }
                group.addTask { await self.loadUserExecutorState() }
                group.addTask { await self.loadExecutorPositions() }
                group.addTask { await self.loadSignals() }
                group.addTask { await self.loadAIModels() }
            }

            isLoading = false
        }
    }

    // MARK: - Strategic Council

    /// Loads active strategic council briefs.
    func loadBriefs() async {
        do {
            let response: BriefsResponse = try await cache.valueOrFetch(
                forKey: CacheKeys.councilBriefs(),
                ttl: AppConfig.defaultCacheTimeout
            ) {
                try await self.apiClient.request(.councilBriefs)
            }
            self.councilBriefs = response.active
        } catch {
            logger.error("Failed to load council briefs: \(error.localizedDescription)")
            errorMessage = "Failed to load council briefs."
        }
    }

    /// Triggers a new strategic council session for the given trading pairs.
    ///
    /// - Parameter pairs: The trading pairs to analyze (e.g., ["BTCUSDT", "ETHUSDT"]).
    func triggerCouncil(pairs: [String]) async {
        isTriggeringCouncil = true
        errorMessage = nil

        do {
            let session: CouncilSession = try await apiClient.request(
                .councilTrigger,
                body: CouncilTriggerRequest(pairs: pairs)
            )
            logger.info("Council session triggered: \(session.sessionId)")

            // Refresh briefs and session status after triggering
            await loadBriefs()
            await loadCouncilSessionStatus()
        } catch {
            errorMessage = error.localizedDescription
            logger.error("Failed to trigger council: \(error.localizedDescription)")
        }

        isTriggeringCouncil = false
    }

    /// Loads the current council session status.
    func loadCouncilSessionStatus() async {
        do {
            let status: CouncilSessionStatus = try await apiClient.request(.councilSessionStatus)
            self.councilSession = status
        } catch {
            logger.error("Failed to load council session status: \(error.localizedDescription)")
        }
    }

    // MARK: - Consensus

    /// Loads multi-model consensus analysis for a symbol.
    ///
    /// - Parameter symbol: The trading symbol to get consensus for.
    func loadConsensus(symbol: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let result: ConsensusResult = try await apiClient.request(
                .aiConsensus,
                body: ConsensusRequest(symbol: symbol, language: nil)
            )
            self.consensusResult = result
        } catch {
            errorMessage = error.localizedDescription
            logger.error("Failed to load consensus for \(symbol): \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Smart Executor Status

    /// Loads the global Smart Executor status.
    func loadExecutorStatus() async {
        do {
            let status: ExecutorStatus = try await cache.valueOrFetch(
                forKey: CacheKeys.executorStatus(),
                ttl: AppConfig.marketDataCacheTimeout
            ) {
                try await self.apiClient.request(.executorStatus)
            }
            self.executorStatus = status
        } catch {
            logger.error("Failed to load executor status: \(error.localizedDescription)")
        }
    }

    /// Loads the user's personal Smart Executor state.
    func loadUserExecutorState() async {
        do {
            let state: UserExecutorState = try await apiClient.request(.executorUserStatus)
            self.userExecutorState = state
        } catch {
            logger.error("Failed to load user executor state: \(error.localizedDescription)")
        }
    }

    /// Loads positions managed by the Smart Executor.
    func loadExecutorPositions() async {
        do {
            let positions: [SmartExecutorPosition] = try await cache.valueOrFetch(
                forKey: CacheKeys.executorPositions(),
                ttl: AppConfig.marketDataCacheTimeout
            ) {
                try await self.apiClient.request(.executorPositions)
            }
            self.executorPositions = positions
        } catch {
            logger.error("Failed to load executor positions: \(error.localizedDescription)")
        }
    }

    /// Loads current exposure metrics for the Smart Executor.
    func loadExposure() async {
        do {
            let exposure: ExecutorExposure = try await apiClient.request(.executorExposure)
            self.executorExposure = exposure
            self.executorPositions = exposure.positions
        } catch {
            logger.error("Failed to load executor exposure: \(error.localizedDescription)")
            errorMessage = "Failed to load exposure data."
        }
    }

    // MARK: - Smart Executor Controls

    /// Enables the Smart Executor for the current user.
    ///
    /// - Parameters:
    ///   - maxPositions: Maximum number of concurrent open positions.
    ///   - riskPercent: Risk percentage per trade (e.g., 2.0 for 2%).
    func enableExecutor(maxPositions: Int, riskPercent: Double) async {
        isLoading = true
        errorMessage = nil

        do {
            let _: Data = try await apiClient.requestRaw(
                .executorUserEnable,
                body: ExecutorEnableRequest(
                    maxOpenPositions: maxPositions,
                    riskPerTradePercent: riskPercent
                )
            )
            logger.info("Smart Executor enabled (maxPositions: \(maxPositions), risk: \(riskPercent)%)")

            // Refresh state
            await loadUserExecutorState()
        } catch {
            errorMessage = error.localizedDescription
            logger.error("Failed to enable executor: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Disables the Smart Executor for the current user.
    func disableExecutor() async {
        isLoading = true
        errorMessage = nil

        do {
            let _: Data = try await apiClient.requestRaw(.executorUserDisable)
            logger.info("Smart Executor disabled")

            // Refresh state
            await loadUserExecutorState()
        } catch {
            errorMessage = error.localizedDescription
            logger.error("Failed to disable executor: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Toggles the Smart Executor on or off.
    ///
    /// - Parameter enabled: `true` to enable, `false` to disable.
    func toggleExecutor(enabled: Bool) {
        if enabled {
            let maxPos = userExecutorState?.maxOpenPositions ?? 3
            let risk = userExecutorState?.riskPerTradePercent ?? 1.0
            Task { await enableExecutor(maxPositions: maxPos, riskPercent: risk) }
        } else {
            Task { await disableExecutor() }
        }
    }

    /// Updates the Smart Executor configuration.
    ///
    /// - Parameters:
    ///   - maxPositions: Maximum number of concurrent open positions.
    ///   - riskPercent: Risk percentage per trade.
    ///   - autoExecute: Whether to auto-execute signals.
    func updateExecutorConfig(maxPositions: Int, riskPercent: Double, autoExecute: Bool) {
        Task {
            // TODO: Pass autoExecute to the executor enable endpoint once backend supports it
            _ = autoExecute
            await enableExecutor(maxPositions: maxPositions, riskPercent: riskPercent)
        }
    }

    /// Triggers an emergency stop for the Smart Executor.
    ///
    /// This immediately closes all executor-managed positions and disables
    /// the executor. Use with caution.
    func emergencyStop() async {
        isLoading = true
        errorMessage = nil

        do {
            let _: Data = try await apiClient.requestRaw(.executorEmergencyStop)
            logger.warning("Smart Executor EMERGENCY STOP triggered")

            // Refresh all executor state
            await loadExecutorStatus()
            await loadUserExecutorState()
            await loadExecutorPositions()
        } catch {
            errorMessage = error.localizedDescription
            logger.error("Failed to emergency stop executor: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - AI Coach

    /// Asks the AI Coach a question.
    ///
    /// - Parameter question: The user's question about trading or strategy.
    func askCoach(question: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let advice: CoachAdvice = try await apiClient.request(
                .coachAsk,
                body: CoachQuestion(question: question, contextAdviceId: nil, locale: nil)
            )
            self.coachAdvice.insert(advice, at: 0)
            logger.info("Coach advice received for question")
        } catch {
            errorMessage = error.localizedDescription
            logger.error("Failed to ask coach: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Loads AI Coach performance metrics and recent advice.
    func loadCoachPerformance() async {
        do {
            let performance: [CoachAdvice] = try await apiClient.request(.coachPerformance)
            self.coachAdvice = performance
        } catch {
            logger.error("Failed to load coach performance: \(error.localizedDescription)")
            errorMessage = "Failed to load coach performance."
        }
    }

    // MARK: - AI Coach Message

    /// Sends a user message to the AI Coach and appends the response.
    ///
    /// - Parameter text: The user's question or message.
    func sendCoachMessage(_ text: String) {
        let userMsg = CoachMessage(text: text, isUser: true, timestamp: Date.now.formatted())
        coachMessages.append(userMsg)
        isCoachThinking = true
        Task {
            await askCoach(question: text)
            isCoachThinking = false
            // The response gets added to coachAdvice, also add a simplified version to coachMessages
            if let latest = coachAdvice.first {
                let responseMsg = CoachMessage(text: latest.advice, isUser: false, timestamp: latest.createdAt)
                coachMessages.append(responseMsg)
            }
        }
    }

    // MARK: - Signals

    /// Loads active trading signals.
    func loadSignals() async {
        do {
            let signals: [Signal] = try await apiClient.request(.signalsActive)
            self.activeSignals = signals
        } catch {
            logger.error("Failed to load signals: \(error.localizedDescription)")
        }
    }

    /// Generates a new trading signal for the given pair.
    ///
    /// - Parameter pair: The trading pair (e.g., "BTCUSDT").
    func generateSignal(pair: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let signal: Signal = try await apiClient.request(.signalGenerate(pair: pair))
            // Insert the new signal at the top of the active list
            self.activeSignals.insert(signal, at: 0)
            logger.info("Signal generated for \(pair)")
        } catch {
            errorMessage = error.localizedDescription
            logger.error("Failed to generate signal for \(pair): \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Executes a trading signal on a specific exchange credential.
    ///
    /// - Parameters:
    ///   - id: The signal identifier.
    ///   - credentialId: The exchange credential to execute the trade on.
    func executeSignal(id: String, credentialId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let _: Data = try await apiClient.request(
                .signalExecute(id: id),
                body: SignalExecution(credentialId: credentialId, quantity: nil)
            )
            logger.info("Signal \(id) executed on credential \(credentialId)")

            // Refresh signals after execution
            await loadSignals()
        } catch {
            errorMessage = error.localizedDescription
            logger.error("Failed to execute signal \(id): \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - AI Models

    /// Dismisses a signal by removing it from the active list.
    ///
    /// - Parameter id: The signal identifier to dismiss.
    func dismissSignal(id: String) {
        activeSignals.removeAll { $0.id == id }
    }

    /// Signal history — non-active signals derived from activeSignals.
    var signalHistory: [Signal] {
        activeSignals.filter { $0.status != .active }
    }

    // MARK: - AI Models

    /// Loads the status of all available AI/LLM models.
    func loadAIModels() async {
        do {
            let models: ModelsStatusResponse = try await cache.valueOrFetch(
                forKey: CacheKeys.aiModels(),
                ttl: AppConfig.defaultCacheTimeout
            ) {
                try await self.apiClient.request(.aiModels)
            }
            self.aiModels = models
        } catch {
            logger.error("Failed to load AI models: \(error.localizedDescription)")
        }
    }
}
