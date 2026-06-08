import Foundation

// MARK: - HTTP Method

/// HTTP methods supported by the API.
enum HTTPMethod: String {
    case GET
    case POST
    case PUT
    case DELETE
    case PATCH
}

// MARK: - API Endpoint

/// Exhaustive mapping of all backend REST endpoints.
///
/// Each case maps to a single backend route. Associated values capture
/// path parameters that are interpolated into the URL at runtime.
///
/// Computed properties:
/// - `path`: The full URL path relative to the API base URL.
/// - `method`: The HTTP method the endpoint expects.
/// - `requiresAuth`: Whether the endpoint requires an authenticated session.
enum APIEndpoint {
    // ──────────────────────────────────────────────
    // MARK: Auth
    // ──────────────────────────────────────────────
    case authRegister
    case authChallenge(email: String)
    case authVerify
    /// Session check — uses /auth/me (Next.js proxy) instead of /auth/session
    case authSession
    case authDeleteSession
    case authRefresh
    case authSessions
    case authDeleteSessionById(id: String)
    case authDeleteAllSessions
    case authRecover(token: String)
    /// OTP-based authentication: send verification code to email
    case authOtpSend
    /// OTP-based authentication: verify the 6-digit code
    case authOtpVerify
    /// Passkey verification — uses /auth/passkey/verify (Next.js proxy)
    case authPasskeyVerify

    // ──────────────────────────────────────────────
    // MARK: Trading V1
    // ──────────────────────────────────────────────
    case tradingAccount
    case tradingOrders
    case tradingCreateOrder
    case tradingDeleteOrder(id: String)
    case tradingOrderById(id: String)
    case tradingPositions
    case tradingPositionsHistory
    case tradingPositionsAll
    case tradingPositionsSummary
    case tradingClosePosition
    case tradingForceClosePosition
    case tradingPositionLevels(id: String)
    case tradingHistory
    case tradingTrades
    case tradingRiskParameters
    case tradingPositionSize

    // ──────────────────────────────────────────────
    // MARK: Trading V2
    // ──────────────────────────────────────────────
    case tradingV2CreateOrder
    case tradingV2Orders
    case tradingV2OrderById(id: String)
    case tradingV2DeleteOrder(id: String)
    case tradingV2Positions
    case tradingV2Portfolio

    // ──────────────────────────────────────────────
    // MARK: Exchange
    // ──────────────────────────────────────────────
    case exchangeQuote(symbol: String)
    case exchangeHistory(symbol: String, interval: String, limit: Int?)
    case exchangeAdapters

    // ──────────────────────────────────────────────
    // MARK: Scanner
    // ──────────────────────────────────────────────
    case scannerScan(timeframe: String?, category: String?)
    case scannerHeatmap(category: String?)
    case scannerAnalysis(symbol: String)
    case scannerMultiTF(symbol: String)
    case scannerOverview
    case scannerRun(timeframe: String?, category: String?)

    // ──────────────────────────────────────────────
    // MARK: AI
    // ──────────────────────────────────────────────
    case aiAnalyze
    case aiAnalyzeAll
    case aiModels
    case aiConsensus
    case aiDiagnose

    // ──────────────────────────────────────────────
    // MARK: Strategic Council
    // ──────────────────────────────────────────────
    case councilBriefs
    case councilActiveBriefs(symbol: String?)
    case councilBriefHistory
    case councilBriefsCount
    case councilTrigger
    case councilSessionStatus
    case councilSessionLast
    case councilDebug(pair: String?)

    // ──────────────────────────────────────────────
    // MARK: Smart Executor
    // ──────────────────────────────────────────────
    case executorStatus
    case executorStart
    case executorStop
    case executorEmergencyStop
    case executorPositions
    case executorUserEnable
    case executorUserDisable
    case executorUserStatus
    case executorPurgePhantoms
    case executorExposure
    case executorDebug

    // ──────────────────────────────────────────────
    // MARK: Coach
    // ──────────────────────────────────────────────
    case coachPerformance
    case coachAsk
    case coachHistory

    // ──────────────────────────────────────────────
    // MARK: Signals
    // ──────────────────────────────────────────────
    case signalGenerate(pair: String)
    case signalsActive
    case signalsHistory
    case signalExecute(id: String)
    case signalDelete(id: String)

    // ──────────────────────────────────────────────
    // MARK: Portfolio
    // ──────────────────────────────────────────────
    case portfolioCredentials
    case portfolioCreateCredential
    case portfolioUpdateCredential(id: String)
    case portfolioDeleteCredential(id: String)
    case portfolioBalances
    case portfolioServerIP
    case portfolioTestConnectivity
    case portfolioSanctuary

    // ──────────────────────────────────────────────
    // MARK: News
    // ──────────────────────────────────────────────
    case newsLatest(symbol: String?, sentiment: String?, category: String?, limit: Int?)
    case newsFeed(symbol: String?, sentiment: String?, category: String?, limit: Int?)
    case newsSentiment
    case newsAnalyze
    case newsFetch
    case newsPipeline

    // ──────────────────────────────────────────────
    // MARK: Notifications
    // ──────────────────────────────────────────────
    case notifications(limit: Int?, offset: Int?, unread: Bool?, type: String?)
    case notificationsUnreadCount
    case notificationsRead
    case notificationsReadAll
    case notificationsPreferences
    case notificationsUpdatePreferences
    case notificationDelete(id: String)

    // ──────────────────────────────────────────────
    // MARK: Agent
    // ──────────────────────────────────────────────
    case agentHealth
    case agentPublicStatus
    case agentStart
    case agentStop
    case agentStatus
    case agentPerformance
    case agentOpenPositions
    case agentUpdateStrategy
    case agentRegimeInfo(symbol: String?)
    case agentUpdateRiskParams
    case agentSettings
    case agentUpdateSettings
    case agentSystemStatus
    case agentUpdateSystemSettings

    // ──────────────────────────────────────────────
    // MARK: Neural Lab
    // ──────────────────────────────────────────────
    case neuralBacktest
    case neuralBacktestCompare
    case neuralTrain
    case neuralPredict
    case neuralModels
    case neuralSwarmStart
    case neuralSwarmById(id: String)
    case neuralSwarmStop(id: String)
    case neuralSwarmList
    case neuralPerformanceHealth
    case neuralPerformanceBySource(source: String)

    // ──────────────────────────────────────────────
    // MARK: Prediction Market
    // ──────────────────────────────────────────────
    case predictionEvents(symbol: String?, category: String?)
    case predictionEventById(id: String)
    case predictionGaps(symbol: String)
    case predictionGapsTop(limit: Int?)
    case predictionVote(symbol: String)
    case predictionPortfolio
    case predictionSync(force: Bool?)
    case predictionAnalyze(id: String)

    // ──────────────────────────────────────────────
    // MARK: Analytics
    // ──────────────────────────────────────────────
    case analyticsAnalyze(symbol: String)
    case analyticsSignals(symbol: String, limit: Int?)

    // ──────────────────────────────────────────────
    // MARK: Engine
    // ──────────────────────────────────────────────
    case engineHealth
    case engineScannerRun
    case engineScannerLast
    case engineMonitorStatus
    case engineBroadcasterQuotes
    case engineBroadcasterTrack

    // ──────────────────────────────────────────────
    // MARK: Health
    // ──────────────────────────────────────────────
    case health
    case diagnosticModules
}

// MARK: - Path

extension APIEndpoint {
    /// The full URL path relative to the API base URL.
    var path: String {
        switch self {
        // Auth
        case .authRegister:                    return "/auth/register"
        case .authChallenge:                   return "/auth/challenge"
        case .authVerify:                      return "/auth/verify"
        // FIX: Next.js proxy exposes /auth/me (not /auth/session) for session checks
        // The backend's /auth/session is a NestJS route NOT proxied by Next.js.
        case .authSession:                     return "/auth/me"
        case .authDeleteSession:               return "/auth/me"
        case .authRefresh:                     return "/auth/refresh"
        case .authSessions:                    return "/auth/sessions"
        case .authDeleteSessionById(let id):   return "/auth/sessions/\(id)"
        case .authDeleteAllSessions:           return "/auth/sessions"
        case .authRecover(let token):          return "/auth/recover/\(token)"
        // OTP-based auth endpoints (Next.js proxy)
        case .authOtpSend:                     return "/auth/otp/send"
        case .authOtpVerify:                   return "/auth/otp/verify"
        // Passkey verification
        case .authPasskeyVerify:               return "/auth/passkey/verify"

        // Trading V1
        case .tradingAccount:                  return "/trading/account"
        case .tradingOrders:                   return "/trading/orders"
        case .tradingCreateOrder:              return "/trading/orders"
        case .tradingDeleteOrder(let id):      return "/trading/orders/\(id)"
        case .tradingOrderById(let id):        return "/trading/orders/\(id)"
        case .tradingPositions:                return "/trading/positions"
        case .tradingPositionsHistory:         return "/trading/positions/history"
        case .tradingPositionsAll:             return "/trading/positions/all"
        case .tradingPositionsSummary:         return "/trading/positions/summary"
        case .tradingClosePosition:            return "/trading/positions/close"
        case .tradingForceClosePosition:       return "/trading/positions/force-close"
        case .tradingPositionLevels(let id):   return "/trading/positions/\(id)/levels"
        case .tradingHistory:                  return "/trading/history"
        case .tradingTrades:                   return "/trading/trades"
        case .tradingRiskParameters:           return "/trading/risk/parameters"
        case .tradingPositionSize:             return "/trading/position-size"

        // Trading V2
        case .tradingV2CreateOrder:            return "/trading/v2/orders"
        case .tradingV2Orders:                 return "/trading/v2/orders"
        case .tradingV2OrderById(let id):      return "/trading/v2/orders/\(id)"
        case .tradingV2DeleteOrder(let id):    return "/trading/v2/orders/\(id)"
        case .tradingV2Positions:              return "/trading/v2/positions"
        case .tradingV2Portfolio:              return "/trading/v2/portfolio"

        // Exchange
        // NOTE: Symbols like "BTC/USD" contain a slash that must be percent-encoded
        // in the URL path so the backend receives a single path parameter.
        // "BTC/USD" → "BTC%2FUSD" — otherwise the backend sees "BTC" + "USD" as
        // two separate segments and returns 404.
        case .exchangeQuote(let symbol):       return "/exchange/quote/\(symbol.replacingOccurrences(of: "/", with: "%2F"))"
        case .exchangeHistory(let symbol, _, _): return "/exchange/history/\(symbol.replacingOccurrences(of: "/", with: "%2F"))"
        case .exchangeAdapters:                return "/exchange/adapters"

        // Scanner
        case .scannerScan:                     return "/scanner/scan"
        case .scannerHeatmap:                  return "/scanner/heatmap"
        case .scannerAnalysis(let symbol):     return "/scanner/analysis/\(symbol)"
        case .scannerMultiTF(let symbol):      return "/scanner/multi-tf/\(symbol)"
        case .scannerOverview:                 return "/scanner/overview"
        case .scannerRun:                      return "/scanner/run"

        // AI
        case .aiAnalyze:                       return "/ai/analyze"
        case .aiAnalyzeAll:                    return "/ai/analyze-all"
        case .aiModels:                        return "/ai/models"
        case .aiConsensus:                     return "/ai/consensus"
        case .aiDiagnose:                      return "/ai/diagnose"

        // Strategic Council
        case .councilBriefs:                   return "/strategic-council/briefs"
        case .councilActiveBriefs:             return "/strategic-council/briefs/active"
        case .councilBriefHistory:             return "/strategic-council/briefs/history"
        case .councilBriefsCount:              return "/strategic-council/briefs/count"
        case .councilTrigger:                  return "/strategic-council/trigger"
        case .councilSessionStatus:            return "/strategic-council/session/status"
        case .councilSessionLast:              return "/strategic-council/session/last"
        case .councilDebug:                    return "/strategic-council/debug"

        // Smart Executor
        case .executorStatus:                  return "/smart-executor/status"
        case .executorStart:                   return "/smart-executor/start"
        case .executorStop:                    return "/smart-executor/stop"
        case .executorEmergencyStop:           return "/smart-executor/emergency-stop"
        case .executorPositions:               return "/smart-executor/positions"
        case .executorUserEnable:              return "/smart-executor/user/enable"
        case .executorUserDisable:             return "/smart-executor/user/disable"
        case .executorUserStatus:              return "/smart-executor/user/status"
        case .executorPurgePhantoms:           return "/smart-executor/purge-phantoms"
        case .executorExposure:                return "/smart-executor/exposure"
        case .executorDebug:                   return "/smart-executor/debug"

        // Coach
        case .coachPerformance:                return "/coach/performance"
        case .coachAsk:                        return "/coach/ask"
        case .coachHistory:                    return "/coach/history"

        // Signals
        case .signalGenerate(let pair):         return "/signals/generate/\(pair)"
        case .signalsActive:                   return "/signals/active"
        case .signalsHistory:                  return "/signals/history"
        case .signalExecute(let id):           return "/signals/\(id)/execute"
        case .signalDelete(let id):            return "/signals/\(id)"

        // Portfolio
        case .portfolioCredentials:            return "/portfolio/credentials"
        case .portfolioCreateCredential:       return "/portfolio/credentials"
        case .portfolioUpdateCredential(let id): return "/portfolio/credentials/\(id)"
        case .portfolioDeleteCredential(let id):  return "/portfolio/credentials/\(id)"
        case .portfolioBalances:               return "/portfolio/credentials/balances"
        case .portfolioServerIP:               return "/portfolio/server-ip"
        case .portfolioTestConnectivity:       return "/portfolio/test-connectivity"
        case .portfolioSanctuary:              return "/portfolio/sanctuary"

        // News
        case .newsLatest:                      return "/news/latest"
        case .newsFeed:                        return "/news/feed"
        case .newsSentiment:                   return "/news/sentiment"
        case .newsAnalyze:                     return "/news/analyze"
        case .newsFetch:                       return "/news/fetch"
        case .newsPipeline:                    return "/news/pipeline"

        // Notifications
        case .notifications:                   return "/notifications"
        case .notificationsUnreadCount:        return "/notifications/unread-count"
        case .notificationsRead:               return "/notifications/read"
        case .notificationsReadAll:            return "/notifications/read-all"
        case .notificationsPreferences:        return "/notifications/preferences"
        case .notificationsUpdatePreferences:  return "/notifications/preferences"
        case .notificationDelete(let id):      return "/notifications/\(id)"

        // Agent
        case .agentHealth:                     return "/agent/trader/health"
        case .agentPublicStatus:               return "/agent/trader/public-status"
        case .agentStart:                      return "/agent/trader/start"
        case .agentStop:                       return "/agent/trader/stop"
        case .agentStatus:                     return "/agent/trader/status"
        case .agentPerformance:                return "/agent/trader/performance"
        case .agentOpenPositions:              return "/agent/trader/open-positions"
        case .agentUpdateStrategy:             return "/agent/trader/strategy"
        case .agentRegimeInfo:                 return "/agent/trader/regime-info"
        case .agentUpdateRiskParams:           return "/agent/trader/risk-params"
        case .agentSettings:                   return "/agent/trader/settings"
        case .agentUpdateSettings:             return "/agent/trader/settings"
        case .agentSystemStatus:               return "/agent/trader/system-status"
        case .agentUpdateSystemSettings:       return "/agent/trader/system-settings"

        // Neural Lab
        case .neuralBacktest:                  return "/neural/backtest"
        case .neuralBacktestCompare:           return "/neural/backtest/compare"
        case .neuralTrain:                     return "/neural/train"
        case .neuralPredict:                   return "/neural/predict"
        case .neuralModels:                    return "/neural/models"
        case .neuralSwarmStart:                return "/neural/swarm/start"
        case .neuralSwarmById(let id):         return "/neural/swarm/\(id)"
        case .neuralSwarmStop(let id):         return "/neural/swarm/\(id)/stop"
        case .neuralSwarmList:                 return "/neural/swarm/list"
        case .neuralPerformanceHealth:         return "/neural/performance/health"
        case .neuralPerformanceBySource:       return "/neural/performance"

        // Prediction Market
        case .predictionEvents:                return "/prediction-market/events"
        case .predictionEventById(let id):     return "/prediction-market/events/\(id)"
        case .predictionGaps(let symbol):      return "/prediction-market/gaps/\(symbol)"
        case .predictionGapsTop:               return "/prediction-market/gaps/top"
        case .predictionVote(let symbol):      return "/prediction-market/vote/\(symbol)"
        case .predictionPortfolio:             return "/prediction-market/portfolio"
        case .predictionSync:                  return "/prediction-market/sync"
        case .predictionAnalyze(let id):       return "/prediction-market/analyze/\(id)"

        // Analytics
        case .analyticsAnalyze(let symbol):    return "/analytics/analyze/\(symbol)"
        case .analyticsSignals(let symbol, _): return "/analytics/signals/\(symbol)"

        // Engine
        case .engineHealth:                    return "/engine/health"
        case .engineScannerRun:                return "/engine/scanner/run"
        case .engineScannerLast:               return "/engine/scanner/last"
        case .engineMonitorStatus:             return "/engine/monitor/status"
        case .engineBroadcasterQuotes:         return "/engine/broadcaster/quotes"
        case .engineBroadcasterTrack:          return "/engine/broadcaster/track"

        // Health
        case .health:                          return "/health"
        case .diagnosticModules:               return "/diagnostic/modules"
        }
    }
}

// MARK: - HTTP Method

extension APIEndpoint {
    /// The HTTP method the endpoint expects.
    var method: HTTPMethod {
        switch self {
        // Auth
        case .authRegister:                    return .POST
        // FIX: Backend expects GET with ?email= for challenge, not POST
        case .authChallenge:                   return .GET
        case .authVerify:                      return .POST
        case .authSession:                     return .GET
        case .authDeleteSession:               return .DELETE
        case .authRefresh:                     return .POST
        case .authSessions:                    return .GET
        case .authDeleteSessionById:           return .DELETE
        case .authDeleteAllSessions:           return .DELETE
        case .authRecover:                     return .POST
        // OTP auth
        case .authOtpSend:                     return .POST
        case .authOtpVerify:                   return .POST
        case .authPasskeyVerify:               return .POST

        // Trading V1
        case .tradingAccount:                  return .GET
        case .tradingOrders:                   return .GET
        case .tradingCreateOrder:              return .POST
        case .tradingDeleteOrder:              return .DELETE
        case .tradingOrderById:                return .GET
        case .tradingPositions:                return .GET
        case .tradingPositionsHistory:         return .GET
        case .tradingPositionsAll:             return .GET
        case .tradingPositionsSummary:         return .GET
        case .tradingClosePosition:            return .POST
        case .tradingForceClosePosition:       return .POST
        case .tradingPositionLevels:           return .GET
        case .tradingHistory:                  return .GET
        case .tradingTrades:                   return .GET
        case .tradingRiskParameters:           return .GET
        case .tradingPositionSize:             return .POST

        // Trading V2
        case .tradingV2CreateOrder:            return .POST
        case .tradingV2Orders:                 return .GET
        case .tradingV2OrderById:              return .GET
        case .tradingV2DeleteOrder:            return .DELETE
        case .tradingV2Positions:              return .GET
        case .tradingV2Portfolio:              return .GET

        // Exchange
        case .exchangeQuote:                   return .GET
        case .exchangeHistory:                 return .GET
        case .exchangeAdapters:                return .GET

        // Scanner
        case .scannerScan:                     return .GET
        case .scannerHeatmap:                  return .GET
        case .scannerAnalysis:                 return .GET
        case .scannerMultiTF:                  return .GET
        case .scannerOverview:                 return .GET
        case .scannerRun:                      return .POST

        // AI
        case .aiAnalyze:                       return .POST
        case .aiAnalyzeAll:                    return .POST
        case .aiModels:                        return .GET
        case .aiConsensus:                     return .POST
        case .aiDiagnose:                      return .GET

        // Strategic Council
        case .councilBriefs:                   return .GET
        case .councilActiveBriefs:             return .GET
        case .councilBriefHistory:             return .GET
        case .councilBriefsCount:              return .GET
        case .councilTrigger:                  return .POST
        case .councilSessionStatus:            return .GET
        case .councilSessionLast:              return .GET
        case .councilDebug:                    return .GET

        // Smart Executor
        case .executorStatus:                  return .GET
        case .executorStart:                   return .POST
        case .executorStop:                    return .POST
        case .executorEmergencyStop:           return .POST
        case .executorPositions:               return .GET
        case .executorUserEnable:              return .POST
        case .executorUserDisable:             return .POST
        case .executorUserStatus:              return .GET
        case .executorPurgePhantoms:           return .POST
        case .executorExposure:                return .GET
        case .executorDebug:                   return .GET

        // Coach
        case .coachPerformance:                return .POST
        case .coachAsk:                        return .POST
        case .coachHistory:                    return .GET

        // Signals
        case .signalGenerate:                  return .POST
        case .signalsActive:                   return .GET
        case .signalsHistory:                  return .GET
        case .signalExecute:                   return .POST
        case .signalDelete:                    return .DELETE

        // Portfolio
        case .portfolioCredentials:            return .GET
        case .portfolioCreateCredential:       return .POST
        case .portfolioUpdateCredential:       return .PUT
        case .portfolioDeleteCredential:       return .DELETE
        case .portfolioBalances:               return .GET
        case .portfolioServerIP:               return .GET
        case .portfolioTestConnectivity:       return .POST
        case .portfolioSanctuary:              return .GET

        // News
        case .newsLatest:                      return .GET
        case .newsFeed:                        return .GET
        case .newsSentiment:                   return .GET
        case .newsAnalyze:                     return .POST
        case .newsFetch:                       return .POST
        case .newsPipeline:                    return .POST

        // Notifications
        case .notifications:                   return .GET
        case .notificationsUnreadCount:        return .GET
        case .notificationsRead:               return .PUT
        case .notificationsReadAll:            return .PUT
        case .notificationsPreferences:        return .GET
        case .notificationsUpdatePreferences:  return .PUT
        case .notificationDelete:              return .DELETE

        // Agent
        case .agentHealth:                     return .GET
        case .agentPublicStatus:               return .GET
        case .agentStart:                      return .POST
        case .agentStop:                       return .POST
        case .agentStatus:                     return .GET
        case .agentPerformance:                return .GET
        case .agentOpenPositions:              return .GET
        case .agentUpdateStrategy:             return .PUT
        case .agentRegimeInfo:                 return .GET
        case .agentUpdateRiskParams:           return .PUT
        case .agentSettings:                   return .GET
        case .agentUpdateSettings:             return .PUT
        case .agentSystemStatus:               return .GET
        case .agentUpdateSystemSettings:       return .PUT

        // Neural Lab
        case .neuralBacktest:                  return .POST
        case .neuralBacktestCompare:           return .POST
        case .neuralTrain:                     return .POST
        case .neuralPredict:                   return .POST
        case .neuralModels:                    return .GET
        case .neuralSwarmStart:                return .POST
        case .neuralSwarmById:                 return .GET
        case .neuralSwarmStop:                 return .POST
        case .neuralSwarmList:                 return .GET
        case .neuralPerformanceHealth:         return .GET
        case .neuralPerformanceBySource:       return .GET

        // Prediction Market
        case .predictionEvents:                return .GET
        case .predictionEventById:             return .GET
        case .predictionGaps:                  return .GET
        case .predictionGapsTop:               return .GET
        case .predictionVote:                  return .GET
        case .predictionPortfolio:             return .GET
        case .predictionSync:                  return .POST
        case .predictionAnalyze:               return .POST

        // Analytics
        case .analyticsAnalyze:                return .POST
        case .analyticsSignals:                return .GET

        // Engine
        case .engineHealth:                    return .GET
        case .engineScannerRun:                return .POST
        case .engineScannerLast:               return .GET
        case .engineMonitorStatus:             return .GET
        case .engineBroadcasterQuotes:         return .GET
        case .engineBroadcasterTrack:          return .POST

        // Health
        case .health:                          return .GET
        case .diagnosticModules:               return .GET
        }
    }
}

// MARK: - Auth Requirement

extension APIEndpoint {
    /// Whether the endpoint requires an authenticated session.
    ///
    /// Endpoints that are part of the authentication flow itself or are public
    /// health checks do not require auth. Many market data endpoints are also
    /// public — marking them correctly avoids sending invalid tokens on public
    /// routes, which can cause 401 errors even on public endpoints.
    var requiresAuth: Bool {
        switch self {
        // ── Auth flow — no auth required ──
        case .authRegister,
             .authChallenge,
             .authVerify,
             .authRefresh,
             .authRecover,
             .authOtpSend,
             .authOtpVerify,
             .authPasskeyVerify,
             .health,
             .diagnosticModules:

            return false

        // ── Scanner — all public ──
        case .scannerScan,
             .scannerHeatmap,
             .scannerAnalysis,
             .scannerMultiTF,
             .scannerOverview:
            return false

        // ── Exchange — all public ──
        case .exchangeQuote,
             .exchangeHistory,
             .exchangeAdapters:
            return false

        // ── News — all public ──
        case .newsLatest,
             .newsFeed,
             .newsSentiment:
            return false

        // ── AI — models and diagnostics are public ──
        case .aiModels,
             .aiDiagnose:
            return false

        // ── Strategic Council — briefs are public ──
        case .councilBriefs,
             .councilActiveBriefs,
             .councilBriefHistory,
             .councilBriefsCount,
             .councilSessionStatus,
             .councilSessionLast:
            return false

        // ── Smart Executor — status is public ──
        case .executorStatus,
             .executorDebug:
            return false

        // ── Agent — health and public status ──
        case .agentHealth,
             .agentPublicStatus:
            return false

        // ── Engine — health ──
        case .engineHealth:
            return false

        // ── Everything else requires auth ──
        default:
            return true
        }
    }
}

// MARK: - Default Query Items

extension APIEndpoint {
    /// Pre-built query items for endpoints that carry associated filter values.
    ///
    /// The `APIClient` merges these with any caller-supplied `queryItems`.
    var defaultQueryItems: [URLQueryItem] {
        switch self {
        case .exchangeHistory(_, let interval, let limit):
            // NOTE: `symbol` is NOT included as a query parameter because it is
            // already encoded in the URL path (`/exchange/history/BTC%2FUSD`).
            // Sending it again as a query param is redundant and can confuse the
            // backend's path-parameter extraction.
            var items: [URLQueryItem] = [
                URLQueryItem(name: "interval", value: interval),
            ]
            if let limit { items.append(URLQueryItem(name: "limit", value: String(limit))) }
            return items

        case .scannerScan(let timeframe, let category):
            var items: [URLQueryItem] = []
            if let timeframe { items.append(URLQueryItem(name: "timeframe", value: timeframe)) }
            if let category { items.append(URLQueryItem(name: "category", value: category)) }
            return items

        case .scannerHeatmap(let category):
            var items: [URLQueryItem] = []
            if let category { items.append(URLQueryItem(name: "category", value: category)) }
            return items

        case .scannerRun(let timeframe, let category):
            var items: [URLQueryItem] = []
            if let timeframe { items.append(URLQueryItem(name: "timeframe", value: timeframe)) }
            if let category { items.append(URLQueryItem(name: "category", value: category)) }
            return items

        case .councilActiveBriefs(let symbol):
            var items: [URLQueryItem] = []
            if let symbol { items.append(URLQueryItem(name: "symbol", value: symbol)) }
            return items

        case .councilDebug(let pair):
            var items: [URLQueryItem] = []
            if let pair { items.append(URLQueryItem(name: "pair", value: pair)) }
            return items

        case .newsLatest(let symbol, let sentiment, let category, let limit):
            var items: [URLQueryItem] = []
            if let symbol { items.append(URLQueryItem(name: "symbol", value: symbol)) }
            if let sentiment { items.append(URLQueryItem(name: "sentiment", value: sentiment)) }
            if let category { items.append(URLQueryItem(name: "category", value: category)) }
            if let limit { items.append(URLQueryItem(name: "limit", value: String(limit))) }
            return items

        case .newsFeed(let symbol, let sentiment, let category, let limit):
            var items: [URLQueryItem] = []
            if let symbol { items.append(URLQueryItem(name: "symbol", value: symbol)) }
            if let sentiment { items.append(URLQueryItem(name: "sentiment", value: sentiment)) }
            if let category { items.append(URLQueryItem(name: "category", value: category)) }
            if let limit { items.append(URLQueryItem(name: "limit", value: String(limit))) }
            return items

        case .notifications(let limit, let offset, let unread, let type):
            var items: [URLQueryItem] = []
            if let limit { items.append(URLQueryItem(name: "limit", value: String(limit))) }
            if let offset { items.append(URLQueryItem(name: "offset", value: String(offset))) }
            if let unread { items.append(URLQueryItem(name: "unread", value: String(unread))) }
            if let type { items.append(URLQueryItem(name: "type", value: type)) }
            return items

        case .agentRegimeInfo(let symbol):
            var items: [URLQueryItem] = []
            if let symbol { items.append(URLQueryItem(name: "symbol", value: symbol)) }
            return items

        case .neuralPerformanceBySource(let source):
            return [URLQueryItem(name: "source", value: source)]

        case .predictionEvents(let symbol, let category):
            var items: [URLQueryItem] = []
            if let symbol { items.append(URLQueryItem(name: "symbol", value: symbol)) }
            if let category { items.append(URLQueryItem(name: "category", value: category)) }
            return items

        case .predictionGapsTop(let limit):
            var items: [URLQueryItem] = []
            if let limit { items.append(URLQueryItem(name: "limit", value: String(limit))) }
            return items

        case .predictionSync(let force):
            var items: [URLQueryItem] = []
            if let force { items.append(URLQueryItem(name: "force", value: String(force))) }
            return items

        case .analyticsSignals(let symbol, let limit):
            var items: [URLQueryItem] = [
                URLQueryItem(name: "symbol", value: symbol),
            ]
            if let limit { items.append(URLQueryItem(name: "limit", value: String(limit))) }
            return items

        case .signalGenerate(let pair):
            return [URLQueryItem(name: "pair", value: pair)]

        // FIX: authChallenge needs email as query parameter
        // Backend expects GET /api/auth/challenge?email=...
        case .authChallenge(let email):
            return [URLQueryItem(name: "email", value: email)]

        default:
            return []
        }
    }
}
