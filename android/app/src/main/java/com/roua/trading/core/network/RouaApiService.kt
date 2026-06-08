package com.roua.trading.core.network

import com.roua.trading.core.network.model.*
import retrofit2.http.*

interface RouaApiService {
    
    // MARK: - Auth
    @POST("auth/register")
    suspend fun register(@Body request: AuthRegisterRequest): AuthVerifyResponse
    
    @GET("auth/challenge")
    suspend fun getChallenge(@Query("email") email: String): ChallengeResponse
    
    @POST("auth/verify")
    suspend fun verify(@Body request: AuthVerifyRequest): AuthVerifyResponse
    
    @GET("auth/me")
    suspend fun getSession(): AuthMeResponse
    
    @DELETE("auth/me")
    suspend fun logout(): AuthMeResponse
    
    @POST("auth/refresh")
    suspend fun refreshSession(): RefreshResponse
    
    // MARK: - OTP Auth
    @POST("auth/otp/send")
    suspend fun sendOtp(@Body request: OtpSendRequest): OtpSendResponse
    
    @POST("auth/otp/verify")
    suspend fun verifyOtp(@Body request: OtpVerifyRequest): AuthMeResponse
    
    // MARK: - Trading V1
    @GET("trading/account")
    suspend fun getAccount(): PortfolioSummary
    
    @POST("trading/orders")
    suspend fun placeOrderV1(@Body request: PlaceOrderV1Request): OrderResponse
    
    @DELETE("trading/orders/{id}")
    suspend fun cancelOrder(@Path("id") id: String): OrderResponse
    
    @GET("trading/orders")
    suspend fun getOrders(
        @Query("symbol") symbol: String? = null,
        @Query("status") status: String? = null,
        @Query("limit") limit: Int? = null
    ): List<OrderResponse>
    
    @GET("trading/positions")
    suspend fun getPositions(): List<Position>
    
    @GET("trading/history")
    suspend fun getHistory(): List<Trade>
    
    @POST("trading/positions/close")
    suspend fun closePosition(@Body request: ClosePositionRequest): Position
    
    // MARK: - Trading V2
    @POST("trading/v2/orders")
    suspend fun placeOrder(@Body request: PlaceOrderRequest): V2PlaceOrderResponse
    
    @GET("trading/v2/orders")
    suspend fun getV2Orders(
        @Query("symbol") symbol: String? = null,
        @Query("status") status: String? = null
    ): List<OrderResponse>
    
    @DELETE("trading/v2/orders/{id}")
    suspend fun cancelV2Order(@Path("id") id: String): OrderResponse
    
    @GET("trading/v2/positions")
    suspend fun getV2Positions(): List<Position>
    
    @GET("trading/v2/portfolio")
    suspend fun getPortfolio(): PortfolioSummary
    
    // MARK: - AI
    @POST("ai/analyze")
    suspend fun analyzeAI(@Body request: AIAnalyzeRequest): AIAnalyzeResponse
    
    @GET("ai/models")
    suspend fun getAIModels(): AIModelsResponse
    
    @POST("ai/consensus")
    suspend fun getConsensus(@Body request: AIConsensusRequest): AIConsensusResponse
    
    // MARK: - Exchange
    @GET("exchange/quote/{symbol}")
    suspend fun getQuote(@Path("symbol") symbol: String): Quote
    
    @GET("exchange/history/{symbol}")
    suspend fun getHistory(
        @Path("symbol") symbol: String,
        @Query("interval") interval: String = "1hour",
        @Query("startDate") startDate: String? = null,
        @Query("endDate") endDate: String? = null
    ): List<OHLCVCandle>
    
    @GET("exchange/adapters")
    suspend fun getAdapters(): List<ExchangeAdapter>
    
    // MARK: - Scanner
    @GET("scanner/scan")
    suspend fun scan(
        @Query("timeframe") timeframe: String? = null,
        @Query("category") category: String? = null
    ): List<ScanResult>
    
    @GET("scanner/heatmap")
    suspend fun getHeatmap(@Query("category") category: String? = null): List<HeatmapItem>
    
    @GET("scanner/overview")
    suspend fun getOverview(): MarketOverview
    
    @GET("scanner/analysis/{symbol}")
    suspend fun analyzeSymbol(@Path("symbol") symbol: String): SymbolAnalysis
    
    // MARK: - Portfolio
    @GET("portfolio/credentials")
    suspend fun getCredentials(): List<ExchangeCredential>
    
    @POST("portfolio/credentials")
    suspend fun addCredential(@Body request: AddCredentialRequest): ExchangeCredential
    
    @DELETE("portfolio/credentials/{id}")
    suspend fun deleteCredential(@Path("id") id: String): Unit
    
    @GET("portfolio/credentials/balances")
    suspend fun getBalances(): List<ExchangeBalance>
    
    @GET("portfolio/sanctuary")
    suspend fun getSanctuary(): SanctuaryRisk
    
    // MARK: - Signals
    @POST("signals/generate/{pair}")
    suspend fun generateSignal(@Path("pair") pair: String): Signal
    
    @GET("signals/active")
    suspend fun getActiveSignals(): List<Signal>
    
    @GET("signals/history")
    suspend fun getSignalHistory(): List<Signal>
    
    @POST("signals/{id}/execute")
    suspend fun executeSignal(@Path("id") id: String, @Body request: ExecuteSignalRequest): OrderResponse
    
    // MARK: - Smart Executor
    @GET("smart-executor/status")
    suspend fun getExecutorStatus(): ExecutorStatus
    
    @POST("smart-executor/start")
    suspend fun startExecutor(): ExecutorStatus
    
    @POST("smart-executor/stop")
    suspend fun stopExecutor(): ExecutorStatus
    
    @POST("smart-executor/emergency-stop")
    suspend fun emergencyStop(): ExecutorStatus
    
    @GET("smart-executor/user/status")
    suspend fun getUserExecutorStatus(): ExecutorStatus
    
    @POST("smart-executor/user/enable")
    suspend fun enableUserExecutor(@Body request: EnableExecutorRequest): ExecutorStatus
    
    @POST("smart-executor/user/disable")
    suspend fun disableUserExecutor(): ExecutorStatus
    
    @GET("smart-executor/exposure")
    suspend fun getExposure(): ExposureSummary
    
    // MARK: - Strategic Council
    @GET("strategic-council/briefs/active")
    suspend fun getActiveBriefs(@Query("symbol") symbol: String? = null): List<TradingBrief>
    
    @GET("strategic-council/briefs/history")
    suspend fun getBriefHistory(): List<TradingBrief>
    
    @POST("strategic-council/trigger")
    suspend fun triggerCouncil(@Body request: CouncilTriggerRequest): CouncilTriggerResponse
    
    // MARK: - Agent Trader
    @POST("agent/trader/start")
    suspend fun startAgent(@Body request: StartAgentRequest): AgentStatusResponse
    
    @POST("agent/trader/stop")
    suspend fun stopAgent(): AgentStatusResponse
    
    @GET("agent/trader/status")
    suspend fun getAgentStatus(): AgentStatusResponse
    
    @GET("agent/trader/performance")
    suspend fun getAgentPerformance(): AgentPerformance
    
    @GET("agent/trader/settings")
    suspend fun getAgentSettings(): AgentSettings
    
    @PUT("agent/trader/settings")
    suspend fun updateAgentSettings(@Body request: AgentSettings): AgentSettings
    
    @PUT("agent/trader/strategy")
    suspend fun changeStrategy(@Body request: ChangeStrategyRequest): AgentStatusResponse
    
    // MARK: - Neural
    @POST("neural/backtest")
    suspend fun runBacktest(@Body request: BacktestRequest): BacktestResult
    
    @POST("neural/predict")
    suspend fun predict(@Body request: NeuralPredictRequest): PredictionResult
    
    @GET("neural/models")
    suspend fun getNeuralModels(): List<NeuralModel>
    
    @POST("neural/swarm/start")
    suspend fun startSwarm(@Body request: SwarmStartRequest): SwarmStatus
    
    // MARK: - News
    @GET("news/latest")
    suspend fun getLatestNews(
        @Query("symbol") symbol: String? = null,
        @Query("limit") limit: Int? = 20
    ): List<NewsArticle>
    
    @GET("news/sentiment")
    suspend fun getMarketSentiment(): MarketSentiment
    
    @POST("news/analyze")
    suspend fun analyzeNews(@Body request: NewsAnalyzeRequest): NewsAnalysis
    
    // MARK: - Notifications
    @GET("notifications")
    suspend fun getNotifications(
        @Query("limit") limit: Int? = null,
        @Query("unread") unread: Boolean? = null
    ): List<UserNotification>
    
    @GET("notifications/unread-count")
    suspend fun getUnreadCount(): UnreadCountResponse
    
    @PUT("notifications/read")
    suspend fun markAsRead(@Body request: MarkReadRequest): Unit
    
    @PUT("notifications/read-all")
    suspend fun markAllRead(): Unit
    
    @GET("notifications/preferences")
    suspend fun getNotificationPreferences(): NotificationPreferences
    
    @PUT("notifications/preferences")
    suspend fun updateNotificationPreferences(@Body request: NotificationPreferences): NotificationPreferences
    
    // MARK: - Health
    @GET("health")
    suspend fun healthCheck(): HealthResponse
}
