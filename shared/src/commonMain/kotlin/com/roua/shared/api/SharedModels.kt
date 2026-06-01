package com.roua.shared.api

import kotlinx.serialization.Serializable

// MARK: - Configuration
object RouaConfig {
    const val BASE_URL = "https://roua-trading-production.up.railway.app/api"
    const val WS_URL = "wss://roua-trading-production.up.railway.app"
    const val SESSION_HEADER = "x-roua-session"
}

// MARK: - Shared Models
@Serializable
data class AuthUser(val id: String, val email: String, val displayName: String? = null, val tier: String = "FREE")

@Serializable
data class PortfolioSummary(val totalValue: Double = 0.0, val totalPnl: Double = 0.0, val dailyPnl: Double = 0.0)

@Serializable
data class Position(
    val id: String, val symbol: String, val side: String, val status: String,
    val entryPrice: Double, val quantity: Double, val unrealizedPnl: Double? = null,
    val realizedPnl: Double? = null, val stopLoss: Double? = null, val takeProfit: Double? = null
)

@Serializable
data class Quote(
    val symbol: String, val last: Double? = null, val bid: Double? = null,
    val ask: Double? = null, val high: Double? = null, val low: Double? = null,
    val volume: Double? = null, val change: Double? = null, val changePercent: Double? = null
)

@Serializable
data class OrderResponse(
    val id: String, val symbol: String, val side: String, val type: String,
    val quantity: Double, val status: String, val createdAt: String
)

@Serializable
data class Signal(
    val id: String, val pair: String, val action: String, val confidence: Double,
    val entryPrice: Double? = null, val stopLoss: Double? = null, val takeProfit: Double? = null
)

@Serializable
data class AgentStatus(val isRunning: Boolean? = null, val strategy: String? = null, val dailyPnl: Double? = null)

// MARK: - Result wrapper
sealed class ApiResult<out T> {
    data class Success<T>(val data: T) : ApiResult<T>()
    data class Error(val code: Int, val message: String) : ApiResult<Nothing>()
    data object NetworkError : ApiResult<Nothing>()
    data object Unauthorized : ApiResult<Nothing>()
}

// MARK: - Strategy enum
enum class TradingStrategy {
    AUTO, SWING, GRID, MEAN_REVERSION, MOMENTUM_BREAKOUT, DCA, VWAP_RSI
}

// MARK: - Market category
enum class MarketCategory { ALL, CRYPTO, FOREX, STOCK, COMMODITY }
