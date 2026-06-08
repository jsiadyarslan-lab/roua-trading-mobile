package com.roua.trading.features.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.roua.trading.core.network.RouaApiService
import com.roua.trading.core.network.model.AIModelStatus
import com.roua.trading.core.network.model.ExecutorStatus
import com.roua.trading.core.network.model.NewsArticle
import com.roua.trading.core.network.model.PortfolioSummary
import com.roua.trading.core.network.model.Position
import com.roua.trading.core.network.model.ScanResult
import com.roua.trading.core.network.model.Signal
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class DashboardUiState(
    val portfolioSummary: PortfolioSummary? = null,
    val positions: List<Position> = emptyList(),
    val scannerResults: List<ScanResult> = emptyList(),
    val aiModels: List<AIModelStatus> = emptyList(),
    val executorStatus: ExecutorStatus? = null,
    val news: List<NewsArticle> = emptyList(),
    val signals: List<Signal> = emptyList(),
    val isLoading: Boolean = true,
    val isRefreshing: Boolean = false,
    val error: String? = null
)

@HiltViewModel
class DashboardViewModel @Inject constructor(
    private val api: RouaApiService
) : ViewModel() {

    private val _uiState = MutableStateFlow(DashboardUiState())
    val uiState: StateFlow<DashboardUiState> = _uiState.asStateFlow()

    init {
        loadDashboard()
    }

    fun loadDashboard() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            try {
                val portfolioDeferred = async { runCatching { api.getPortfolio() } }
                val positionsDeferred = async { runCatching { api.getV2Positions() } }
                val scannerDeferred = async { runCatching { api.scan() } }
                val aiModelsDeferred = async { runCatching { api.getAIModels() } }
                val executorDeferred = async { runCatching { api.getExecutorStatus() } }
                val newsDeferred = async { runCatching { api.getLatestNews(limit = 10) } }
                val signalsDeferred = async { runCatching { api.getActiveSignals() } }

                val portfolio = portfolioDeferred.await().getOrNull()
                val positions = positionsDeferred.await().getOrNull() ?: emptyList()
                val scannerResults = scannerDeferred.await().getOrNull() ?: emptyList()
                val aiModelsResponse = aiModelsDeferred.await().getOrNull()
                val executorStatus = executorDeferred.await().getOrNull()
                val news = newsDeferred.await().getOrNull() ?: emptyList()
                val signals = signalsDeferred.await().getOrNull() ?: emptyList()

                _uiState.value = DashboardUiState(
                    portfolioSummary = portfolio,
                    positions = positions,
                    scannerResults = scannerResults,
                    aiModels = aiModelsResponse?.models ?: emptyList(),
                    executorStatus = executorStatus,
                    news = news.take(3),
                    signals = signals,
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

    fun refresh() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isRefreshing = true)
            try {
                val portfolioDeferred = async { runCatching { api.getPortfolio() } }
                val positionsDeferred = async { runCatching { api.getV2Positions() } }
                val scannerDeferred = async { runCatching { api.scan() } }
                val aiModelsDeferred = async { runCatching { api.getAIModels() } }
                val executorDeferred = async { runCatching { api.getExecutorStatus() } }
                val newsDeferred = async { runCatching { api.getLatestNews(limit = 10) } }
                val signalsDeferred = async { runCatching { api.getActiveSignals() } }

                val portfolio = portfolioDeferred.await().getOrNull()
                val positions = positionsDeferred.await().getOrNull() ?: emptyList()
                val scannerResults = scannerDeferred.await().getOrNull() ?: emptyList()
                val aiModelsResponse = aiModelsDeferred.await().getOrNull()
                val executorStatus = executorDeferred.await().getOrNull()
                val news = newsDeferred.await().getOrNull() ?: emptyList()
                val signals = signalsDeferred.await().getOrNull() ?: emptyList()

                _uiState.value = _uiState.value.copy(
                    portfolioSummary = portfolio,
                    positions = positions,
                    scannerResults = scannerResults,
                    aiModels = aiModelsResponse?.models ?: emptyList(),
                    executorStatus = executorStatus,
                    news = news.take(3),
                    signals = signals,
                    isRefreshing = false
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(isRefreshing = false)
            }
        }
    }
}
