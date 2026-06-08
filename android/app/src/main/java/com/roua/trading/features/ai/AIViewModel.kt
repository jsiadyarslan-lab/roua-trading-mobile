package com.roua.trading.features.ai

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.roua.trading.core.network.RouaApiService
import com.roua.trading.core.network.model.*
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

// ── Chat Message ──
data class ChatMessage(
    val content: String,
    val isUser: Boolean,
    val model: String? = null,
    val timestamp: Long = System.currentTimeMillis()
)

// ── AI Tab enum ──
enum class AITab(val label: String) {
    COUNCIL("Council"),
    EXECUTOR("Executor"),
    SIGNALS("Signals"),
    COACH("Coach"),
    MODELS("Models")
}

// ── UI State ──
data class AIUiState(
    val selectedTab: AITab = AITab.COUNCIL,
    val isLoading: Boolean = false,
    val error: String? = null,

    // Council
    val councilSessionStatus: String = "idle",
    val councilSessionId: String? = null,
    val activeBriefs: List<TradingBrief> = emptyList(),
    val briefHistory: List<TradingBrief> = emptyList(),

    // Executor
    val executorStatus: ExecutorStatus? = null,
    val executorEnabled: Boolean = false,
    val exposure: ExposureSummary? = null,

    // Signals
    val activeSignals: List<Signal> = emptyList(),
    val signalHistory: List<Signal> = emptyList(),

    // Coach
    val messages: List<ChatMessage> = emptyList(),
    val inputText: String = "",

    // Models
    val aiModels: List<AIModelStatus> = emptyList()
)

@HiltViewModel
class AIViewModel @Inject constructor(
    private val api: RouaApiService
) : ViewModel() {

    private val _uiState = MutableStateFlow(AIUiState())
    val uiState: StateFlow<AIUiState> = _uiState

    init {
        loadAll()
    }

    fun selectTab(tab: AITab) {
        _uiState.value = _uiState.value.copy(selectedTab = tab)
    }

    private fun loadAll() {
        loadCouncil()
        loadExecutor()
        loadSignals()
        loadModels()
    }

    // ── Council ──
    fun loadCouncil() {
        viewModelScope.launch {
            try {
                val briefs = api.getActiveBriefs()
                _uiState.value = _uiState.value.copy(activeBriefs = briefs)
            } catch (_: Exception) { }
        }
    }

    fun triggerCouncil(pairs: List<String> = listOf("BTC/USD", "ETH/USD")) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)
            try {
                val response = api.triggerCouncil(CouncilTriggerRequest(pairs))
                _uiState.value = _uiState.value.copy(
                    councilSessionStatus = response.data?.status ?: "running",
                    councilSessionId = response.data?.sessionId,
                    isLoading = false
                )
                loadCouncil()
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(isLoading = false, error = e.message)
            }
        }
    }

    // ── Executor ──
    fun loadExecutor() {
        viewModelScope.launch {
            try {
                val status = api.getUserExecutorStatus()
                val exposure = try { api.getExposure() } catch (_: Exception) { null }
                _uiState.value = _uiState.value.copy(
                    executorStatus = status,
                    executorEnabled = status.isRunning == true,
                    exposure = exposure
                )
            } catch (_: Exception) { }
        }
    }

    fun toggleExecutor(enable: Boolean) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)
            try {
                if (enable) {
                    api.enableUserExecutor(EnableExecutorRequest())
                } else {
                    api.disableUserExecutor()
                }
                _uiState.value = _uiState.value.copy(executorEnabled = enable, isLoading = false)
                loadExecutor()
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(isLoading = false, error = e.message)
            }
        }
    }

    fun emergencyStop() {
        viewModelScope.launch {
            try {
                api.emergencyStop()
                _uiState.value = _uiState.value.copy(executorEnabled = false)
                loadExecutor()
            } catch (_: Exception) { }
        }
    }

    // ── Signals ──
    fun loadSignals() {
        viewModelScope.launch {
            try {
                val active = api.getActiveSignals()
                val history = try { api.getSignalHistory() } catch (_: Exception) { emptyList() }
                _uiState.value = _uiState.value.copy(activeSignals = active, signalHistory = history)
            } catch (_: Exception) { }
        }
    }

    fun generateSignal(pair: String = "BTC/USD") {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)
            try {
                api.generateSignal(pair)
                loadSignals()
                _uiState.value = _uiState.value.copy(isLoading = false)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(isLoading = false, error = e.message)
            }
        }
    }

    // ── Coach ──
    fun onInputChanged(text: String) {
        _uiState.value = _uiState.value.copy(inputText = text)
    }

    fun sendMessage() {
        val text = _uiState.value.inputText
        if (text.isBlank()) return

        _uiState.value = _uiState.value.copy(
            messages = _uiState.value.messages + ChatMessage(content = text, isUser = true),
            inputText = "",
            isLoading = true
        )

        viewModelScope.launch {
            try {
                val response = api.analyzeAI(AIAnalyzeRequest(prompt = text, language = "ar"))
                _uiState.value = _uiState.value.copy(
                    messages = _uiState.value.messages + ChatMessage(
                        content = response.analysis,
                        isUser = false,
                        model = response.model
                    ),
                    isLoading = false
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    messages = _uiState.value.messages + ChatMessage(
                        content = "Error: ${e.message}",
                        isUser = false
                    ),
                    isLoading = false
                )
            }
        }
    }

    // ── Models ──
    fun loadModels() {
        viewModelScope.launch {
            try {
                val response = api.getAIModels()
                _uiState.value = _uiState.value.copy(aiModels = response.models)
            } catch (_: Exception) { }
        }
    }
}
