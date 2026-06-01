package com.roua.trading.features.trading

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.roua.trading.core.network.RouaApiService
import com.roua.trading.core.network.model.Position
import com.roua.trading.core.network.model.Quote
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class TradingUiState(
    val symbol: String = "BTC/USDT",
    val currentQuote: Quote? = null,
    val positions: List<Position> = emptyList(),
    val isLoading: Boolean = false
)

@HiltViewModel
class TradingViewModel @Inject constructor(
    private val api: RouaApiService
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(TradingUiState())
    val uiState: StateFlow<TradingUiState> = _uiState
    
    init { loadTradingData() }
    
    fun loadTradingData() {
        viewModelScope.launch {
            try {
                val quote = try { api.getQuote(_uiState.value.symbol) } catch (_: Exception) { null }
                val positions = try { api.getV2Positions() } catch (_: Exception) { emptyList() }
                _uiState.value = TradingUiState(
                    symbol = _uiState.value.symbol,
                    currentQuote = quote,
                    positions = positions
                )
            } catch (_: Exception) { }
        }
    }
    
    fun onBuyClick() { /* Navigate to order placement */ }
    fun onSellClick() { /* Navigate to order placement */ }
}
