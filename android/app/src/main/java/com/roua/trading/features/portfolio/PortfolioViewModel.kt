package com.roua.trading.features.portfolio

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.roua.trading.core.network.RouaApiService
import com.roua.trading.core.network.model.*
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

enum class PortfolioTab(val label: String) {
    BALANCES("Balances"),
    CREDENTIALS("Credentials"),
    AGENT("Agent")
}

data class PortfolioUiState(
    val selectedTab: PortfolioTab = PortfolioTab.BALANCES,
    val isLoading: Boolean = false,
    val error: String? = null,

    // Balances
    val credentials: List<ExchangeCredential> = emptyList(),
    val balances: List<ExchangeBalance> = emptyList(),
    val totalValue: Double = 0.0,
    val dailyPnl: Double = 0.0,
    val exposure: Double = 0.0,
    val margin: Double = 0.0,
    val drawdown: Double = 0.0,

    // Credentials
    val showAddForm: Boolean = false,
    val newExchange: String = "binance",
    val newLabel: String = "",
    val newApiKey: String = "",
    val newApiSecret: String = "",
    val newPassphrase: String = "",
    val newTestnet: Boolean = false,

    // Agent
    val agentStatus: AgentStatusResponse? = null,
    val agentPerformance: AgentPerformance? = null,
    val agentSettings: AgentSettings? = null,
    val selectedStrategy: String = "conservative",
    val riskPerTrade: Float = 2f,
    val maxPositionSize: Float = 10f,
    val maxDailyLoss: Float = 5f,
    val maxOpenPositions: Int = 3
)

@HiltViewModel
class PortfolioViewModel @Inject constructor(
    private val api: RouaApiService
) : ViewModel() {

    private val _uiState = MutableStateFlow(PortfolioUiState())
    val uiState: StateFlow<PortfolioUiState> = _uiState

    init {
        loadData()
    }

    fun selectTab(tab: PortfolioTab) {
        _uiState.value = _uiState.value.copy(selectedTab = tab)
    }

    fun loadData() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)
            try {
                val creds = try { api.getCredentials() } catch (_: Exception) { emptyList() }
                val balances = try { api.getBalances() } catch (_: Exception) { emptyList() }
                val total = balances.mapNotNull { it.totalValue }.sum()
                val portfolio = try { api.getPortfolio() } catch (_: Exception) { null }

                val agentStatus = try { api.getAgentStatus() } catch (_: Exception) { null }
                val agentPerf = try { api.getAgentPerformance() } catch (_: Exception) { null }
                val agentSettings = try { api.getAgentSettings() } catch (_: Exception) { null }

                _uiState.value = _uiState.value.copy(
                    credentials = creds,
                    balances = balances,
                    totalValue = total,
                    dailyPnl = portfolio?.dailyPnl ?: 0.0,
                    exposure = portfolio?.positions?.map { it.entryPrice * it.quantity }?.sum() ?: 0.0,
                    margin = portfolio?.positions?.size?.toDouble() ?: 0.0,
                    drawdown = 0.0,
                    agentStatus = agentStatus,
                    agentPerformance = agentPerf,
                    agentSettings = agentSettings,
                    selectedStrategy = agentSettings?.defaultStrategy ?: "conservative",
                    riskPerTrade = (agentSettings?.riskPerTradePercent ?: 2.0).toFloat(),
                    maxPositionSize = (agentSettings?.maxPositionSizePercent ?: 10.0).toFloat(),
                    maxDailyLoss = (agentSettings?.maxDailyLossPercent ?: 5.0).toFloat(),
                    maxOpenPositions = agentSettings?.maxOpenPositions ?: 3,
                    isLoading = false
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(isLoading = false, error = e.message)
            }
        }
    }

    // ── Credentials ──
    fun toggleAddForm() {
        _uiState.value = _uiState.value.copy(showAddForm = !_uiState.value.showAddForm)
    }

    fun setNewExchange(exchange: String) {
        _uiState.value = _uiState.value.copy(newExchange = exchange)
    }

    fun setNewLabel(label: String) {
        _uiState.value = _uiState.value.copy(newLabel = label)
    }

    fun setNewApiKey(key: String) {
        _uiState.value = _uiState.value.copy(newApiKey = key)
    }

    fun setNewApiSecret(secret: String) {
        _uiState.value = _uiState.value.copy(newApiSecret = secret)
    }

    fun setNewPassphrase(pass: String) {
        _uiState.value = _uiState.value.copy(newPassphrase = pass)
    }

    fun setNewTestnet(testnet: Boolean) {
        _uiState.value = _uiState.value.copy(newTestnet = testnet)
    }

    fun addCredential() {
        val state = _uiState.value
        if (state.newApiKey.isBlank() || state.newApiSecret.isBlank()) return

        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)
            try {
                api.addCredential(
                    AddCredentialRequest(
                        exchange = state.newExchange,
                        label = state.newLabel.ifBlank { state.newExchange.uppercase() },
                        apiKey = state.newApiKey,
                        apiSecret = state.newApiSecret,
                        passphrase = state.newPassphrase.ifBlank { null },
                        testnet = state.newTestnet
                    )
                )
                _uiState.value = _uiState.value.copy(
                    showAddForm = false,
                    newLabel = "",
                    newApiKey = "",
                    newApiSecret = "",
                    newPassphrase = "",
                    newTestnet = false,
                    isLoading = false
                )
                loadData()
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(isLoading = false, error = e.message)
            }
        }
    }

    fun deleteCredential(id: String) {
        viewModelScope.launch {
            try {
                api.deleteCredential(id)
                loadData()
            } catch (_: Exception) { }
        }
    }

    // ── Agent ──
    fun selectStrategy(strategy: String) {
        _uiState.value = _uiState.value.copy(selectedStrategy = strategy)
    }

    fun setRiskPerTrade(value: Float) {
        _uiState.value = _uiState.value.copy(riskPerTrade = value)
    }

    fun setMaxPositionSize(value: Float) {
        _uiState.value = _uiState.value.copy(maxPositionSize = value)
    }

    fun setMaxDailyLoss(value: Float) {
        _uiState.value = _uiState.value.copy(maxDailyLoss = value)
    }

    fun startAgent() {
        val state = _uiState.value
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)
            try {
                api.startAgent(
                    StartAgentRequest(
                        strategy = state.selectedStrategy,
                        maxPositionSizePercent = state.maxPositionSize.toDouble(),
                        maxDailyLossPercent = state.maxDailyLoss.toDouble(),
                        maxOpenPositions = state.maxOpenPositions,
                        riskPerTradePercent = state.riskPerTrade.toDouble()
                    )
                )
                _uiState.value = _uiState.value.copy(isLoading = false)
                loadData()
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(isLoading = false, error = e.message)
            }
        }
    }

    fun stopAgent() {
        viewModelScope.launch {
            try {
                api.stopAgent()
                loadData()
            } catch (_: Exception) { }
        }
    }

    fun changeStrategy() {
        viewModelScope.launch {
            try {
                api.changeStrategy(ChangeStrategyRequest(_uiState.value.selectedStrategy))
                loadData()
            } catch (_: Exception) { }
        }
    }

    fun updateSettings() {
        val state = _uiState.value
        viewModelScope.launch {
            try {
                api.updateAgentSettings(
                    AgentSettings(
                        autoTradingEnabled = state.agentStatus?.isRunning,
                        maxPositionSizePercent = state.maxPositionSize.toDouble(),
                        maxDailyLossPercent = state.maxDailyLoss.toDouble(),
                        maxOpenPositions = state.maxOpenPositions,
                        riskPerTradePercent = state.riskPerTrade.toDouble(),
                        defaultStrategy = state.selectedStrategy
                    )
                )
                loadData()
            } catch (_: Exception) { }
        }
    }
}
