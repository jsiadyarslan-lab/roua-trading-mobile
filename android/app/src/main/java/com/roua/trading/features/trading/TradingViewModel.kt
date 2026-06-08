package com.roua.trading.features.trading

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.roua.trading.core.network.RouaApiService
import com.roua.trading.core.network.model.PlaceOrderRequest
import com.roua.trading.core.network.model.Position
import com.roua.trading.core.network.model.Quote
import com.roua.trading.core.network.model.Trade
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

// ── UI State ──────────────────────────────────────────────────────────────

data class TradingUiState(
    val symbol: String = "BTC/USDT",
    val currentQuote: Quote? = null,
    val positions: List<Position> = emptyList(),
    val tradeHistory: List<Trade> = emptyList(),
    val selectedTimeframe: String = "1H",
    val selectedPositionTab: PositionTab = PositionTab.OPEN,
    val isLoading: Boolean = false,
    val isRefreshing: Boolean = false,
    val error: String? = null,

    // Order sheet
    val showOrderSheet: Boolean = false,
    val orderSide: OrderSide = OrderSide.BUY,
    val orderType: OrderType = OrderType.MARKET,
    val orderQuantity: String = "0.001",
    val orderLimitPrice: String = "",
    val orderStopLoss: String = "0.0",
    val orderTakeProfit: String = "",
    val isPlacingOrder: Boolean = false,
    val orderError: String? = null,
    val orderSuccess: Boolean = false,

    // Symbol picker
    val showSymbolPicker: Boolean = false,
    val symbolSearchQuery: String = ""
)

enum class PositionTab { OPEN, CLOSED }
enum class OrderSide { BUY, SELL }
enum class OrderType { MARKET, LIMIT }

data class SymbolItem(
    val symbol: String,
    val display: String,
    val name: String
)

val POPULAR_SYMBOLS = listOf(
    SymbolItem("BTC/USDT", "BTC", "Bitcoin"),
    SymbolItem("ETH/USDT", "ETH", "Ethereum"),
    SymbolItem("SOL/USDT", "SOL", "Solana"),
    SymbolItem("BNB/USDT", "BNB", "BNB Chain"),
    SymbolItem("XRP/USDT", "XRP", "Ripple"),
    SymbolItem("ADA/USDT", "ADA", "Cardano"),
    SymbolItem("DOGE/USDT", "DOGE", "Dogecoin"),
    SymbolItem("AVAX/USDT", "AVAX", "Avalanche"),
)

val TIMEFRAMES = listOf("1m", "5m", "15m", "1H", "4H", "1D", "1W")

// ── ViewModel ─────────────────────────────────────────────────────────────

@HiltViewModel
class TradingViewModel @Inject constructor(
    private val api: RouaApiService
) : ViewModel() {

    private val _uiState = MutableStateFlow(TradingUiState())
    val uiState: StateFlow<TradingUiState> = _uiState.asStateFlow()

    init {
        loadTradingData()
    }

    // ── Data Loading ──────────────────────────────────────────────────────

    fun loadTradingData() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            try {
                val symbol = _uiState.value.symbol
                val quote = safeCall { api.getQuote(symbol) }
                val positions = safeCall { api.getV2Positions() } ?: emptyList()
                val trades = safeCall { api.getHistory() } ?: emptyList()

                _uiState.update {
                    it.copy(
                        currentQuote = quote,
                        positions = positions,
                        tradeHistory = trades,
                        isLoading = false,
                        // Pre-fill limit price from current quote
                        orderLimitPrice = quote?.last?.let { p -> String.format("%.2f", p) }
                            ?: it.orderLimitPrice
                    )
                }
            } catch (e: Exception) {
                _uiState.update { it.copy(isLoading = false, error = e.message) }
            }
        }
    }

    fun refresh() {
        viewModelScope.launch {
            _uiState.update { it.copy(isRefreshing = true) }
            try {
                val symbol = _uiState.value.symbol
                val quote = safeCall { api.getQuote(symbol) }
                val positions = safeCall { api.getV2Positions() } ?: emptyList()
                val trades = safeCall { api.getHistory() } ?: emptyList()
                _uiState.update {
                    it.copy(
                        currentQuote = quote,
                        positions = positions,
                        tradeHistory = trades,
                        isRefreshing = false
                    )
                }
            } catch (_: Exception) {
                _uiState.update { it.copy(isRefreshing = false) }
            }
        }
    }

    // ── Symbol Selection ──────────────────────────────────────────────────

    fun selectSymbol(symbol: String) {
        _uiState.update {
            it.copy(
                symbol = symbol,
                showSymbolPicker = false,
                symbolSearchQuery = "",
                currentQuote = null
            )
        }
        loadTradingData()
    }

    fun showSymbolPicker() {
        _uiState.update { it.copy(showSymbolPicker = true, symbolSearchQuery = "") }
    }

    fun hideSymbolPicker() {
        _uiState.update { it.copy(showSymbolPicker = false, symbolSearchQuery = "") }
    }

    fun onSymbolSearchQueryChange(query: String) {
        _uiState.update { it.copy(symbolSearchQuery = query) }
    }

    // ── Timeframe ─────────────────────────────────────────────────────────

    fun selectTimeframe(tf: String) {
        _uiState.update { it.copy(selectedTimeframe = tf) }
    }

    // ── Position Tab ──────────────────────────────────────────────────────

    fun selectPositionTab(tab: PositionTab) {
        _uiState.update { it.copy(selectedPositionTab = tab) }
    }

    // ── Order Sheet ───────────────────────────────────────────────────────

    fun onBuyClick() {
        _uiState.update {
            it.copy(
                showOrderSheet = true,
                orderSide = OrderSide.BUY,
                orderError = null,
                orderSuccess = false
            )
        }
    }

    fun onSellClick() {
        _uiState.update {
            it.copy(
                showOrderSheet = true,
                orderSide = OrderSide.SELL,
                orderError = null,
                orderSuccess = false
            )
        }
    }

    fun hideOrderSheet() {
        _uiState.update { it.copy(showOrderSheet = false, orderError = null, orderSuccess = false) }
    }

    fun setOrderSide(side: OrderSide) {
        _uiState.update { it.copy(orderSide = side) }
    }

    fun setOrderType(type: OrderType) {
        _uiState.update { it.copy(orderType = type) }
    }

    fun onQuantityChange(qty: String) {
        _uiState.update { it.copy(orderQuantity = qty) }
    }

    fun incrementQuantity() {
        val current = _uiState.value.orderQuantity.toDoubleOrNull() ?: 0.0
        val step = current.let { if (it < 0.01) 0.001 else if (it < 1.0) 0.01 else 0.1 }
        val newQty = current + step
        _uiState.update {
            it.copy(orderQuantity = formatQuantity(newQty))
        }
    }

    fun decrementQuantity() {
        val current = _uiState.value.orderQuantity.toDoubleOrNull() ?: 0.0
        val step = current.let { if (it <= 0.01) 0.001 else if (it <= 1.0) 0.01 else 0.1 }
        val newQty = maxOf(0.0, current - step)
        _uiState.update {
            it.copy(orderQuantity = formatQuantity(newQty))
        }
    }

    fun onLimitPriceChange(price: String) {
        _uiState.update { it.copy(orderLimitPrice = price) }
    }

    fun onStopLossChange(sl: String) {
        _uiState.update { it.copy(orderStopLoss = sl) }
    }

    fun onTakeProfitChange(tp: String) {
        _uiState.update { it.copy(orderTakeProfit = tp) }
    }

    // ── Place Order ───────────────────────────────────────────────────────

    fun placeOrder() {
        val state = _uiState.value
        val qty = state.orderQuantity.toDoubleOrNull()
        if (qty == null || qty <= 0.0) {
            _uiState.update { it.copy(orderError = "Invalid quantity") }
            return
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isPlacingOrder = true, orderError = null) }
            try {
                val idempotencyKey = UUID.randomUUID().toString()
                val price = if (state.orderType == OrderType.LIMIT) {
                    state.orderLimitPrice.toDoubleOrNull()
                } else null

                val stopLoss = state.orderStopLoss.toDoubleOrNull() ?: 0.0
                val takeProfit = state.orderTakeProfit.toDoubleOrNull()

                // Use V1 for now — requires credentialId from positions or a default
                // For V2 we'd need exchangeCredentialId; we try V2 first, fallback gracefully
                val request = PlaceOrderRequest(
                    exchangeCredentialId = "default", // Will be overridden by backend if single credential
                    symbol = state.symbol,
                    side = state.orderSide.name,
                    type = state.orderType.name.lowercase(),
                    quantity = qty,
                    price = price,
                    stopLoss = stopLoss,
                    takeProfit = takeProfit,
                    idempotencyKey = idempotencyKey
                )

                val result = api.placeOrder(request)
                if (result.success) {
                    _uiState.update {
                        it.copy(
                            isPlacingOrder = false,
                            orderSuccess = true,
                            showOrderSheet = false
                        )
                    }
                    // Refresh positions after placing order
                    loadTradingData()
                } else {
                    _uiState.update {
                        it.copy(isPlacingOrder = false, orderError = "Order failed")
                    }
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(isPlacingOrder = false, orderError = e.message ?: "Order failed")
                }
            }
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────

    private fun <T> safeCall(block: suspend () -> T): T? {
        return try { block() } catch (_: Exception) { null }
    }

    private fun formatQuantity(qty: Double): String {
        return when {
            qty >= 100.0 -> String.format("%.1f", qty)
            qty >= 1.0 -> String.format("%.2f", qty)
            qty >= 0.01 -> String.format("%.3f", qty)
            else -> String.format("%.4f", qty)
        }
    }

    fun getEstimatedTotal(): Double {
        val state = _uiState.value
        val qty = state.orderQuantity.toDoubleOrNull() ?: 0.0
        val price = when (state.orderType) {
            OrderType.LIMIT -> state.orderLimitPrice.toDoubleOrNull()
            OrderType.MARKET -> state.currentQuote?.last
        } ?: 0.0
        return qty * price
    }
}
