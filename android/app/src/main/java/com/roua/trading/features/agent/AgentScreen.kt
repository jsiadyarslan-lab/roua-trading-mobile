package com.roua.trading.features.agent

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.roua.trading.core.network.model.AgentPerformance
import com.roua.trading.core.network.model.AgentSettings
import com.roua.trading.core.network.model.AgentStatusResponse
import com.roua.trading.core.network.model.StartAgentRequest
import com.roua.trading.core.network.RouaApiService
import com.roua.trading.design.theme.MonoTypography
import com.roua.trading.design.theme.RouaColors
import dagger.hilt.android.lifecycle.HiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

// ── ViewModel ──

data class AgentUiState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val agentStatus: AgentStatusResponse? = null,
    val agentPerformance: AgentPerformance? = null,
    val agentSettings: AgentSettings? = null,
    val selectedStrategy: String = "conservative",
    val riskPerTrade: Float = 2f,
    val maxPositionSize: Float = 10f,
    val maxDailyLoss: Float = 5f,
    val maxOpenPositions: Int = 3,
    val dailyPnlHistory: List<Double> = emptyList()
)

@HiltViewModel
class AgentViewModel @Inject constructor(
    private val api: RouaApiService
) : ViewModel() {

    private val _uiState = MutableStateFlow(AgentUiState())
    val uiState: StateFlow<AgentUiState> = _uiState

    init { loadData() }

    fun loadData() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)
            try {
                val status = try { api.getAgentStatus() } catch (_: Exception) { null }
                val perf = try { api.getAgentPerformance() } catch (_: Exception) { null }
                val settings = try { api.getAgentSettings() } catch (_: Exception) { null }

                _uiState.value = _uiState.value.copy(
                    agentStatus = status,
                    agentPerformance = perf,
                    agentSettings = settings,
                    selectedStrategy = settings?.defaultStrategy ?: "conservative",
                    riskPerTrade = (settings?.riskPerTradePercent ?: 2.0).toFloat(),
                    maxPositionSize = (settings?.maxPositionSizePercent ?: 10.0).toFloat(),
                    maxDailyLoss = (settings?.maxDailyLossPercent ?: 5.0).toFloat(),
                    maxOpenPositions = settings?.maxOpenPositions ?: 3,
                    isLoading = false
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(isLoading = false, error = e.message)
            }
        }
    }

    fun selectStrategy(strategy: String) {
        _uiState.value = _uiState.value.copy(selectedStrategy = strategy)
    }

    fun setRiskPerTrade(value: Float) { _uiState.value = _uiState.value.copy(riskPerTrade = value) }
    fun setMaxPositionSize(value: Float) { _uiState.value = _uiState.value.copy(maxPositionSize = value) }
    fun setMaxDailyLoss(value: Float) { _uiState.value = _uiState.value.copy(maxDailyLoss = value) }

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
                api.changeStrategy(com.roua.trading.core.network.model.ChangeStrategyRequest(_uiState.value.selectedStrategy))
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

// ── Screen ──

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AgentScreen(viewModel: AgentViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(RouaColors.Background)
    ) {
        // Header
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(start = 16.dp, end = 16.dp, top = 16.dp, bottom = 8.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                "Autonomous Trader",
                style = MaterialTheme.typography.headlineMedium,
                color = RouaColors.TextPrimary,
                fontWeight = FontWeight.Bold
            )
            if (uiState.isLoading) {
                CircularProgressIndicator(
                    modifier = Modifier.size(20.dp),
                    strokeWidth = 2.dp,
                    color = RouaColors.Accent
                )
            }
        }

        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // ── Status Hero Card ──
            item {
                val isRunning = uiState.agentStatus?.isRunning == true
                Card(
                    colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .border(
                            width = if (isRunning) 1.5.dp else 1.dp,
                            color = if (isRunning) RouaColors.Profit.copy(alpha = 0.4f) else RouaColors.Border,
                            shape = RoundedCornerShape(12.dp)
                        )
                ) {
                    Column(
                        modifier = Modifier.padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        // Animated Status Indicator
                        Box(
                            modifier = Modifier
                                .size(80.dp)
                                .clip(CircleShape)
                                .background(
                                    if (isRunning) RouaColors.ProfitBackground
                                    else RouaColors.CardHover
                                ),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                if (isRunning) Icons.Filled.SmartToy else Icons.Filled.SmartToy,
                                contentDescription = null,
                                tint = if (isRunning) RouaColors.Success else RouaColors.TextTertiary,
                                modifier = Modifier.size(44.dp)
                            )
                        }

                        Spacer(Modifier.height(16.dp))

                        Text(
                            if (isRunning) "Agent Running" else "Agent Stopped",
                            style = MaterialTheme.typography.headlineSmall,
                            color = if (isRunning) RouaColors.Success else RouaColors.TextSecondary,
                            fontWeight = FontWeight.Bold
                        )

                        if (uiState.agentStatus?.strategy != null) {
                            Spacer(Modifier.height(6.dp))
                            Surface(
                                shape = RoundedCornerShape(6.dp),
                                color = RouaColors.Brand.copy(alpha = 0.15f)
                            ) {
                                Text(
                                    "Strategy: ${uiState.agentStatus.strategy!!.replaceFirstChar { it.uppercase() }}",
                                    style = MaterialTheme.typography.labelMedium,
                                    color = RouaColors.BrandLight,
                                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp)
                                )
                            }
                        }

                        Spacer(Modifier.height(8.dp))

                        // Quick Stats
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceEvenly
                        ) {
                            AgentStat("Positions", "${uiState.agentStatus?.activePositions ?: 0}")
                            AgentStat(
                                "Daily P&L",
                                String.format("$%.2f", uiState.agentStatus?.dailyPnl ?: 0.0),
                                color = if ((uiState.agentStatus?.dailyPnl ?: 0.0) >= 0) RouaColors.Profit else RouaColors.Loss
                            )
                        }

                        Spacer(Modifier.height(20.dp))

                        // Control Buttons
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            Button(
                                onClick = { viewModel.startAgent() },
                                colors = ButtonDefaults.buttonColors(containerColor = RouaColors.Profit),
                                shape = RoundedCornerShape(10.dp),
                                modifier = Modifier.weight(1f),
                                enabled = !isRunning && !uiState.isLoading
                            ) {
                                Icon(Icons.Filled.PlayArrow, contentDescription = null, modifier = Modifier.size(20.dp))
                                Spacer(Modifier.width(6.dp))
                                Text("Start Agent")
                            }

                            Button(
                                onClick = { viewModel.stopAgent() },
                                colors = ButtonDefaults.buttonColors(containerColor = RouaColors.Loss),
                                shape = RoundedCornerShape(10.dp),
                                modifier = Modifier.weight(1f),
                                enabled = isRunning && !uiState.isLoading
                            ) {
                                Icon(Icons.Filled.Stop, contentDescription = null, modifier = Modifier.size(20.dp))
                                Spacer(Modifier.width(6.dp))
                                Text("Stop Agent")
                            }
                        }
                    }
                }
            }

            // ── Strategy Selector ──
            item {
                Card(
                    colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Filled.TipsAndUpdates, contentDescription = null, tint = RouaColors.Gold, modifier = Modifier.size(18.dp))
                            Spacer(Modifier.width(8.dp))
                            Text("Strategy", style = MaterialTheme.typography.labelLarge, color = RouaColors.TextPrimary)
                        }

                        Spacer(Modifier.height(12.dp))

                        // Strategy Cards
                        listOf(
                            Triple("conservative", "Low risk, steady returns", RouaColors.Profit),
                            Triple("moderate", "Balanced risk/reward", RouaColors.Cyan),
                            Triple("aggressive", "High risk, high reward", RouaColors.Danger)
                        ).forEach { (strategy, desc, color) ->
                            val isSelected = uiState.selectedStrategy == strategy
                            Surface(
                                shape = RoundedCornerShape(10.dp),
                                color = if (isSelected) color.copy(alpha = 0.1f) else RouaColors.BackgroundLight,
                                border = if (isSelected) {
                                    ButtonDefaults.outlinedButtonBorder(enabled = true).copy(
                                        brush = Brush.linearGradient(colors = listOf(color.copy(alpha = 0.4f), color.copy(alpha = 0.4f)))
                                    )
                                } else null,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 4.dp)
                                    .clickable { viewModel.selectStrategy(strategy) }
                            ) {
                                Row(
                                    modifier = Modifier.padding(12.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    RadioButton(
                                        selected = isSelected,
                                        onClick = { viewModel.selectStrategy(strategy) },
                                        colors = RadioButtonDefaults.colors(
                                            selectedColor = color,
                                            unselectedColor = RouaColors.TextTertiary
                                        )
                                    )
                                    Spacer(Modifier.width(8.dp))
                                    Column {
                                        Text(
                                            strategy.replaceFirstChar { it.uppercase() },
                                            style = MaterialTheme.typography.labelLarge,
                                            color = if (isSelected) color else RouaColors.TextPrimary,
                                            fontWeight = FontWeight.Bold
                                        )
                                        Text(desc, style = MaterialTheme.typography.bodySmall, color = RouaColors.TextTertiary)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Risk Parameters ──
            item {
                Card(
                    colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Filled.Shield, contentDescription = null, tint = RouaColors.Warning, modifier = Modifier.size(18.dp))
                            Spacer(Modifier.width(8.dp))
                            Text("Risk Parameters", style = MaterialTheme.typography.labelLarge, color = RouaColors.TextPrimary)
                        }

                        Spacer(Modifier.height(14.dp))

                        AgentRiskSlider(
                            label = "Risk Per Trade",
                            value = uiState.riskPerTrade,
                            range = 0.5f..10f,
                            steps = 18,
                            unit = "%",
                            onValueChange = { viewModel.setRiskPerTrade(it) }
                        )

                        Spacer(Modifier.height(12.dp))

                        AgentRiskSlider(
                            label = "Max Position Size",
                            value = uiState.maxPositionSize,
                            range = 1f..50f,
                            steps = 48,
                            unit = "%",
                            onValueChange = { viewModel.setMaxPositionSize(it) }
                        )

                        Spacer(Modifier.height(12.dp))

                        AgentRiskSlider(
                            label = "Max Daily Loss",
                            value = uiState.maxDailyLoss,
                            range = 1f..20f,
                            steps = 38,
                            unit = "%",
                            onValueChange = { viewModel.setMaxDailyLoss(it) }
                        )

                        Spacer(Modifier.height(14.dp))

                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            Button(
                                onClick = { viewModel.changeStrategy() },
                                colors = ButtonDefaults.buttonColors(containerColor = RouaColors.Brand),
                                shape = RoundedCornerShape(10.dp),
                                modifier = Modifier.weight(1f)
                            ) {
                                Text("Apply Strategy")
                            }
                            Button(
                                onClick = { viewModel.updateSettings() },
                                colors = ButtonDefaults.buttonColors(containerColor = RouaColors.Accent),
                                shape = RoundedCornerShape(10.dp),
                                modifier = Modifier.weight(1f)
                            ) {
                                Text("Save Settings")
                            }
                        }
                    }
                }
            }

            // ── Performance Metrics ──
            item {
                val perf = uiState.agentPerformance
                Card(
                    colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Filled.BarChart, contentDescription = null, tint = RouaColors.Cyan, modifier = Modifier.size(18.dp))
                            Spacer(Modifier.width(8.dp))
                            Text("Performance Metrics", style = MaterialTheme.typography.labelLarge, color = RouaColors.TextPrimary)
                        }

                        Spacer(Modifier.height(14.dp))

                        // Top Row - Key Metrics
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            AgentPerfItem("Total P&L", String.format("$%,.2f", perf?.totalPnl ?: 0.0),
                                color = if ((perf?.totalPnl ?: 0.0) >= 0) RouaColors.Profit else RouaColors.Loss)
                            AgentPerfItem("Win Rate", String.format("%.1f%%", (perf?.winRate ?: 0.0) * 100),
                                color = if ((perf?.winRate ?: 0.0) >= 0.5) RouaColors.Profit else RouaColors.Loss)
                            AgentPerfItem("Total Trades", "${perf?.totalTrades ?: 0}", color = RouaColors.Cyan)
                        }

                        Spacer(Modifier.height(12.dp))
                        HorizontalDivider(color = RouaColors.Border)
                        Spacer(Modifier.height(12.dp))

                        // Bottom Row - Advanced Metrics
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            AgentPerfItem("Sharpe Ratio", String.format("%.2f", perf?.sharpeRatio ?: 0.0), color = RouaColors.Cyan)
                            AgentPerfItem("Max Drawdown", String.format("%.1f%%", perf?.maxDrawdown ?: 0.0), color = RouaColors.Warning)
                            AgentPerfItem("Daily P&L", String.format("$%,.2f", perf?.dailyPnl ?: 0.0),
                                color = if ((perf?.dailyPnl ?: 0.0) >= 0) RouaColors.Profit else RouaColors.Loss)
                        }

                        Spacer(Modifier.height(12.dp))
                        HorizontalDivider(color = RouaColors.Border)
                        Spacer(Modifier.height(12.dp))

                        // Active Positions
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            AgentPerfItem("Active Positions", "${perf?.activePositions ?: 0}", color = RouaColors.BrandLight)
                            AgentPerfItem("Current Strategy", uiState.agentStatus?.strategy?.replaceFirstChar { it.uppercase() } ?: "None", color = RouaColors.Gold)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun AgentStat(label: String, value: String, color: Color = RouaColors.TextPrimary) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(value, style = MonoTypography.Small, color = color, fontWeight = FontWeight.Bold)
        Spacer(Modifier.height(2.dp))
        Text(label, style = MaterialTheme.typography.labelSmall, color = RouaColors.TextTertiary)
    }
}

@Composable
private fun AgentRiskSlider(
    label: String,
    value: Float,
    range: ClosedFloatingPointRange<Float>,
    steps: Int,
    unit: String,
    onValueChange: (Float) -> Unit
) {
    Column {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(label, style = MaterialTheme.typography.bodySmall, color = RouaColors.TextPrimary)
            Text(
                String.format("%.1f%s", value, unit),
                style = MonoTypography.Micro,
                color = RouaColors.Cyan
            )
        }
        Slider(
            value = value,
            onValueChange = onValueChange,
            valueRange = range,
            steps = steps,
            colors = SliderDefaults.colors(
                thumbColor = RouaColors.Accent,
                activeTrackColor = RouaColors.Accent,
                inactiveTrackColor = RouaColors.BackgroundLight
            )
        )
    }
}

@Composable
private fun AgentPerfItem(label: String, value: String, color: Color = RouaColors.TextPrimary) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.weight(1f)) {
        Text(value, style = MonoTypography.Small, color = color, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center)
        Spacer(Modifier.height(2.dp))
        Text(label, style = MaterialTheme.typography.labelSmall, color = RouaColors.TextTertiary, textAlign = TextAlign.Center)
    }
}
