package com.roua.trading.features.portfolio

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.roua.trading.core.network.RouaApiService
import com.roua.trading.core.network.model.ExchangeCredential
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class PortfolioUiState(
    val credentials: List<ExchangeCredential> = emptyList(),
    val totalValue: Double = 0.0,
    val isLoading: Boolean = false
)

@HiltViewModel
class PortfolioViewModel @Inject constructor(
    private val api: RouaApiService
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(PortfolioUiState())
    val uiState: StateFlow<PortfolioUiState> = _uiState
    
    init { loadData() }
    
    fun loadData() {
        viewModelScope.launch {
            try {
                val creds = try { api.getCredentials() } catch (_: Exception) { emptyList() }
                val balances = try { api.getBalances() } catch (_: Exception) { emptyList() }
                val total = balances.mapNotNull { it.totalValue }.sum()
                _uiState.value = PortfolioUiState(credentials = creds, totalValue = total)
            } catch (_: Exception) { }
        }
    }
}
