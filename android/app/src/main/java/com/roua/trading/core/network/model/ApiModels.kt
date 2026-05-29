package com.roua.trading.core.network.model

import kotlinx.serialization.Serializable
import kotlinx.serialization.SerialName

// MARK: - Auth
@Serializable
data class AuthRegisterRequest(val email: String, val displayName: String? = null)

@Serializable
data class AuthVerifyRequest(
    val credential: RegistrationCredentialJSON? = null,
    val assertion: AuthenticationCredentialJSON? = null,
    val email: String
)

@Serializable
data class RegistrationCredentialJSON(val id: String, val rawId: String, val response: RegistrationResponseData, val type: String)

@Serializable
data class RegistrationResponseData(val attestationObject: String, val clientDataJSON: String)

@Serializable
data class AuthenticationCredentialJSON(val id: String, val rawId: String, val response: AuthenticationResponseData, val type: String)

@Serializable
data class AuthenticationResponseData(val authenticatorData: String, val clientDataJSON: String, val signature: String, val userHandle: String? = null)

@Serializable
data class ChallengeResponse(val challenge: String, val rpId: String? = null, val allowCredentials: List<Map<String, String>>? = null)

@Serializable
data class AuthVerifyResponse(val success: Boolean, val user: AuthUser? = null)

@Serializable
data class AuthUser(val id: String, val email: String, val displayName: String? = null, val tier: String = "FREE")

// MARK: - Trading
@Serializable
data class PlaceOrderRequest(
    @SerialName("exchangeCredentialId") val exchangeCredentialId: String,
    val symbol: String, val side: String, val type: String, val quantity: Double,
    val price: Double? = null, val stopLoss: Double, val takeProfit: Double? = null,
    val idempotencyKey: String, val clientOrderId: String? = null
)

@Serializable
data class PlaceOrderV1Request(
    @SerialName("credentialId") val credentialId: String,
    val symbol: String, val side: String, val type: String, val quantity: Double,
    val price: Double? = null, val stopLoss: Double, val takeProfit: Double? = null, val signalId: String? = null
)

@Serializable
data class V2PlaceOrderResponse(val success: Boolean, val data: V2OrderData)

@Serializable
data class V2OrderData(val orderId: String, val status: String, val idempotencyKey: String, val riskScore: Double? = null)

@Serializable
data class OrderResponse(
    val id: String, val userId: String, @SerialName("exchangeCredentialId") val exchangeCredentialId: String,
    val symbol: String, val side: String, val type: String, val quantity: Double, val price: Double? = null,
    val stopLoss: Double? = null, val takeProfit: Double? = null, val status: String,
    val idempotencyKey: String? = null, val createdAt: String, val updatedAt: String
)

@Serializable
data class Position(
    val id: String, val userId: String, @SerialName("credentialId") val credentialId: String,
    val symbol: String, val side: String, val status: String, val entryPrice: Double,
    val currentPrice: Double? = null, val quantity: Double, val unrealizedPnl: Double? = null,
    val realizedPnl: Double? = null, val stopLoss: Double? = null, val takeProfit: Double? = null,
    val source: String? = null, val createdAt: String, val updatedAt: String
)

@Serializable
data class Trade(
    val id: String, val userId: String, val orderId: String? = null, val positionId: String? = null,
    val symbol: String, val side: String, val type: String, val quantity: Double, val price: Double,
    val pnl: Double? = null, val source: String? = null, val createdAt: String
)

@Serializable
data class ClosePositionRequest(val positionId: String, val quantity: Double? = null)

@Serializable
data class PortfolioSummary(
    val totalValue: Double = 0.0, val totalPnl: Double = 0.0, val dailyPnl: Double = 0.0,
    val positions: List<Position> = emptyList(), val unrealizedPnl: Double? = null, val realizedPnl: Double? = null
)

// MARK: - AI
@Serializable
data class AIAnalyzeRequest(val prompt: String, val type: String? = null, val symbol: String? = null, val language: String? = "ar")

@Serializable
data class AIAnalyzeResponse(val analysis: String, val model: String? = null, val provider: String? = null, val confidence: Double? = null)

@Serializable
data class AIConsensusRequest(val symbol: String? = "BTC/USD", val language: String? = "ar")

@Serializable
data class AIConsensusResponse(val consensus: String, val models: List<ModelOpinion>? = null, val overallSignal: String? = null, val confidence: Double? = null)

@Serializable
data class ModelOpinion(val model: String, val provider: String, val opinion: String, val signal: String? = null, val confidence: Double? = null)

@Serializable
data class AIModelsResponse(val models: List<AIModelStatus>)

@Serializable
data class AIModelStatus(val id: String? = null, val name: String, val provider: String, val isAvailable: Boolean, val latency: Double? = null)

// MARK: - Market Data
@Serializable
data class Quote(
    val symbol: String, val bid: Double? = null, val ask: Double? = null, val last: Double? = null,
    val open: Double? = null, val high: Double? = null, val low: Double? = null, val close: Double? = null,
    val volume: Double? = null, val change: Double? = null, val changePercent: Double? = null, val timestamp: String? = null
)

@Serializable
data class OHLCVCandle(val timestamp: String, val open: Double, val high: Double, val low: Double, val close: Double, val volume: Double)

@Serializable
data class ExchangeAdapter(val name: String, val isAvailable: Boolean)

// MARK: - Scanner
@Serializable
data class ScanResult(
    val id: String? = null, val symbol: String, val name: String? = null, val price: Double,
    val change: Double = 0.0, val changePercent: Double = 0.0, val volume: Double? = null,
    val signal: String? = null, val strength: Double? = null, val category: String? = null
)

@Serializable
data class HeatmapItem(val symbol: String, val name: String? = null, val change: Double, val volume: Double? = null, val marketCap: Double? = null, val category: String? = null)

@Serializable
data class MarketOverview(
    val sentiment: String? = null, val fearGreedIndex: Int? = null, val topGainers: List<ScanResult>? = null,
    val topLosers: List<ScanResult>? = null, val activeSignals: Int? = null, val marketStatus: String? = null
)

@Serializable
data class SymbolAnalysis(val symbol: String, val analysis: String? = null, val signals: List<Signal>? = null)

// MARK: - Signals
@Serializable
data class Signal(
    val id: String, val userId: String? = null, val pair: String, val action: String, val confidence: Double,
    val entryPrice: Double? = null, val stopLoss: Double? = null, val takeProfit: Double? = null,
    val status: String? = null, val reasoning: String? = null, val createdAt: String
)

@Serializable
data class ExecuteSignalRequest(val credentialId: String, val quantity: Double? = null)

// MARK: - Executor
@Serializable
data class ExecutorStatus(val isRunning: Boolean? = null, val activePositions: Int? = null, val totalExposure: Double? = null, val dailyPnl: Double? = null)

@Serializable
data class EnableExecutorRequest(val maxOpenPositions: Int? = null, val riskPerTradePercent: Double? = null)

@Serializable
data class ExposureSummary(val totalExposure: Double? = null, val bySymbol: Map<String, Double>? = null, val bySide: Map<String, Double>? = null, val maxExposure: Double? = null)

// MARK: - Council
@Serializable
data class TradingBrief(
    val id: String, val pair: String, val direction: String? = null, val entryPrice: Double? = null,
    val stopLoss: Double? = null, val takeProfit: Double? = null, val confidence: Double? = null,
    val timeframe: String? = null, val reasoning: String? = null, val createdAt: String
)

@Serializable
data class CouncilTriggerRequest(val pairs: List<String>)

@Serializable
data class CouncilTriggerResponse(val success: Boolean, val data: CouncilData? = null)

@Serializable
data class CouncilData(val sessionId: String, val status: String, val pairs: List<String>)

// MARK: - Agent
@Serializable
data class StartAgentRequest(
    val strategy: String, val credentialId: String? = null, val symbols: List<String>? = null,
    val maxPositionSizePercent: Double? = null, val maxDailyLossPercent: Double? = null,
    val maxOpenPositions: Int? = null, val riskPerTradePercent: Double? = null
)

@Serializable
data class ChangeStrategyRequest(val strategy: String)

@Serializable
data class AgentStatusResponse(val isRunning: Boolean? = null, val strategy: String? = null, val dailyPnl: Double? = null, val activePositions: Int? = null)

@Serializable
data class AgentPerformance(
    val totalPnl: Double? = null, val winRate: Double? = null, val totalTrades: Int? = null,
    val sharpeRatio: Double? = null, val maxDrawdown: Double? = null, val dailyPnl: Double? = null, val activePositions: Int? = null
)

@Serializable
data class AgentSettings(
    val autoTradingEnabled: Boolean? = null, val paperBalance: Double? = null, val defaultStrategy: String? = null,
    val maxPositionSizePercent: Double? = null, val maxDailyLossPercent: Double? = null, val maxOpenPositions: Int? = null,
    val riskPerTradePercent: Double? = null, val defaultSymbols: List<String>? = null
)

// MARK: - Neural
@Serializable
data class BacktestRequest(
    val symbol: String, val strategy: String? = null, val periodStart: String, val periodEnd: String,
    val initialCapital: Double? = 10000.0, val positionSize: Double? = null, val stopLoss: Double? = null, val takeProfit: Double? = null
)

@Serializable
data class BacktestResult(val totalReturn: Double? = null, val maxDrawdown: Double? = null, val sharpeRatio: Double? = null, val winRate: Double? = null, val totalTrades: Int? = null)

@Serializable
data class NeuralPredictRequest(val symbol: String, val steps: Int? = 5, val horizon: String? = "1d", val includeConfidence: Boolean? = true)

@Serializable
data class PredictionResult(val predictions: List<PricePrediction>? = null, val model: String? = null, val accuracy: Double? = null)

@Serializable
data class PricePrediction(val step: Int, val price: Double, val confidence: Double? = null, val timestamp: String? = null)

@Serializable
data class NeuralModel(val id: String, val name: String, val type: String? = null, val accuracy: Double? = null)

@Serializable
data class SwarmStartRequest(val agents: Int? = 3, val symbols: List<String>? = null, val strategy: String? = null, val riskTolerance: Double? = 50.0)

@Serializable
data class SwarmStatus(val id: String, val status: String, val agents: Int? = null, val symbols: List<String>? = null, val strategy: String? = null)

// MARK: - News
@Serializable
data class NewsArticle(
    val id: String, val source: String? = null, val title: String, val summary: String? = null,
    val sentiment: String? = null, val category: String? = null, val symbol: String? = null, val publishedAt: String? = null
)

@Serializable
data class MarketSentiment(val fearGreedIndex: Int? = null, val fearGreedLabel: String? = null, val marketMood: String? = null)

@Serializable
data class NewsAnalyzeRequest(val text: String, val symbol: String? = null)

// MARK: - Portfolio
@Serializable
data class ExchangeCredential(val id: String, val exchange: String, val label: String, val testnet: Boolean, val keyType: String? = null, val createdAt: String)

@Serializable
data class AddCredentialRequest(val exchange: String, val label: String, val apiKey: String, val apiSecret: String, val passphrase: String? = null, val testnet: Boolean? = false)

@Serializable
data class ExchangeBalance(val exchange: String, val totalValue: Double? = null, val currencies: List<CurrencyBalance>? = null)

@Serializable
data class CurrencyBalance(val currency: String, val available: Double, val total: Double, val usdValue: Double? = null)

@Serializable
data class SanctuaryRisk(val overallRisk: String? = null, val riskScore: Double? = null, val recommendations: List<String>? = null)

// MARK: - Notifications
@Serializable
data class UserNotification(
    val id: String, val userId: String, val type: String, val priority: String? = null, val title: String,
    val body: String? = null, val isRead: Boolean, val source: String? = null, val pair: String? = null, val createdAt: String
)

@Serializable
data class UnreadCountResponse(val count: Int)

@Serializable
data class MarkReadRequest(val ids: List<String>? = null)

@Serializable
data class NotificationPreferences(
    val enabled: Boolean? = null, val pushEnabled: Boolean? = null, val signalAlerts: Boolean? = null,
    val tradeAlerts: Boolean? = null, val aiAlerts: Boolean? = null, val riskAlerts: Boolean? = null, val autoExecuteEnabled: Boolean? = null
)

// MARK: - Health
@Serializable
data class HealthResponse(val status: String, val database: String? = null, val redis: String? = null)
