package com.roua.trading.features.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.roua.trading.core.network.RouaApiService
import com.roua.trading.core.network.model.Position
import com.roua.trading.core.network.model.PortfolioSummary
import com.roua.trading.core.network.model.Trade
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class DashboardUiState(
    val portfolioSummary: PortfolioSummary? = null,
    val positions: List<Position> = emptyList(),
    val recentTrades: List<Trade> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null
)

@HiltViewModel
class DashboardViewModel @Inject constructor(
    private val api: RouaApiService
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(DashboardUiState())
    val uiState: StateFlow<DashboardUiState> = _uiState
    
    init {
        loadDashboard()
    }
    
    fun loadDashboard() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)
            try {
                val portfolio = try { api.getPortfolio() } catch (_: Exception) { null }
                val positions = try { api.getV2Positions() } catch (_: Exception) { emptyList() }
                val trades = try { api.getHistory() } catch (_: Exception) { emptyList() }
                
                _uiState.value = DashboardUiState(
                    portfolioSummary = portfolio,
                    positions = positions,
                    recentTrades = trades.take(10),
                    isLoading = false
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.message
                )
            }
        }
    }
}
