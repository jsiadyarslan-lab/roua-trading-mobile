package com.roua.trading.features.ai

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.roua.trading.core.network.model.AIModelStatus
import com.roua.trading.core.network.model.Signal
import com.roua.trading.core.network.model.TradingBrief
import com.roua.trading.design.theme.MonoTypography
import com.roua.trading.design.theme.RouaColors

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AIChatScreen(viewModel: AIViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(RouaColors.Background)
    ) {
        // ── Header ──
        Text(
            "AI Hub",
            style = MaterialTheme.typography.headlineMedium,
            color = RouaColors.TextPrimary,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(start = 16.dp, end = 16.dp, top = 16.dp, bottom = 8.dp)
        )

        // ── Tab Pill Selector ──
        AITabSelector(
            selectedTab = uiState.selectedTab,
            onTabSelected = { viewModel.selectTab(it) }
        )

        Spacer(Modifier.height(12.dp))

        // ── Tab Content ──
        when (uiState.selectedTab) {
            AITab.COUNCIL -> CouncilTab(uiState, viewModel)
            AITab.EXECUTOR -> ExecutorTab(uiState, viewModel)
            AITab.SIGNALS -> SignalsTab(uiState, viewModel)
            AITab.COACH -> CoachTab(uiState, viewModel)
            AITab.MODELS -> ModelsTab(uiState, viewModel)
        }
    }
}

// ═══════════════════════════════════════════════
// TAB SELECTOR
// ═══════════════════════════════════════════════

@Composable
fun AITabSelector(
    selectedTab: AITab,
    onTabSelected: (AITab) -> Unit
) {
    ScrollableTabRow(
        selectedTabIndex = selectedTab.ordinal,
        containerColor = Color.Transparent,
        contentColor = RouaColors.TextPrimary,
        edgePadding = 16.dp,
        divider = {},
        indicator = { }
    ) {
        AITab.entries.forEach { tab ->
            val isSelected = tab == selectedTab
            Tab(
                selected = isSelected,
                onClick = { onTabSelected(tab) },
                text = {
                    Text(
                        tab.label,
                        fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                        color = if (isSelected) RouaColors.TextPrimary else RouaColors.TextSecondary
                    )
                },
                selectedContentColor = RouaColors.Accent,
                unselectedContentColor = RouaColors.TextSecondary,
                modifier = Modifier
                    .padding(horizontal = 4.dp, vertical = 4.dp)
                    .clip(RoundedCornerShape(20.dp))
                    .background(
                        if (isSelected) RouaColors.Accent.copy(alpha = 0.15f)
                        else Color.Transparent
                    )
                    .border(
                        width = if (isSelected) 1.dp else 0.dp,
                        color = if (isSelected) RouaColors.Accent.copy(alpha = 0.4f) else Color.Transparent,
                        shape = RoundedCornerShape(20.dp)
                    )
                    .padding(horizontal = 12.dp, vertical = 6.dp)
            )
        }
    }
}

// ═══════════════════════════════════════════════
// COUNCIL TAB
// ═══════════════════════════════════════════════

@Composable
fun CouncilTab(uiState: AIUiState, viewModel: AIViewModel) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Session Status Card
        item {
            Card(
                colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                Icons.Filled.Groups,
                                contentDescription = null,
                                tint = RouaColors.Brand,
                                modifier = Modifier.size(20.dp)
                            )
                            Spacer(Modifier.width(8.dp))
                            Text("Council Session", style = MaterialTheme.typography.labelLarge, color = RouaColors.TextPrimary)
                        }
                        StatusDot(
                            color = when (uiState.councilSessionStatus) {
                                "running" -> RouaColors.Success
                                "completed" -> RouaColors.Cyan
                                else -> RouaColors.TextTertiary
                            },
                            label = uiState.councilSessionStatus.replaceFirstChar { it.uppercase() }
                        )
                    }

                    if (uiState.councilSessionId != null) {
                        Spacer(Modifier.height(4.dp))
                        Text(
                            "Session: ${uiState.councilSessionId.take(8)}",
                            style = MonoTypography.Micro,
                            color = RouaColors.TextTertiary
                        )
                    }

                    Spacer(Modifier.height(12.dp))

                    Button(
                        onClick = { viewModel.triggerCouncil() },
                        colors = ButtonDefaults.buttonColors(containerColor = RouaColors.Brand),
                        shape = RoundedCornerShape(10.dp),
                        modifier = Modifier.fillMaxWidth(),
                        enabled = !uiState.isLoading
                    ) {
                        Icon(Icons.Filled.PlayArrow, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(6.dp))
                        Text("Trigger Council Session")
                    }
                }
            }
        }

        // Active Briefs Header
        item {
            Text(
                "Active Briefs",
                style = MaterialTheme.typography.labelLarge,
                color = RouaColors.TextSecondary
            )
        }

        // Briefs List
        items(uiState.activeBriefs) { brief ->
            BriefCard(brief)
        }

        if (uiState.activeBriefs.isEmpty() && !uiState.isLoading) {
            item {
                Card(
                    colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        "No active briefs. Trigger a council session to generate analysis.",
                        style = MaterialTheme.typography.bodySmall,
                        color = RouaColors.TextTertiary,
                        modifier = Modifier.padding(16.dp),
                        textAlign = TextAlign.Center
                    )
                }
            }
        }
    }
}

@Composable
fun BriefCard(brief: TradingBrief) {
    Card(
        colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
        shape = RoundedCornerShape(12.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(brief.pair, style = MaterialTheme.typography.labelLarge, color = RouaColors.TextPrimary)
                DirectionBadge(brief.direction)
            }

            Spacer(Modifier.height(10.dp))

            // Confidence Bar
            val confidence = (brief.confidence ?: 0.0).coerceIn(0.0, 100.0)
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("Confidence", style = MaterialTheme.typography.labelSmall, color = RouaColors.TextTertiary)
                Spacer(Modifier.weight(1f))
                Text(String.format("%.0f%%", confidence), style = MonoTypography.Micro, color = RouaColors.Cyan)
            }
            Spacer(Modifier.height(4.dp))
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(6.dp)
                    .clip(RoundedCornerShape(3.dp))
                    .background(RouaColors.BackgroundLight)
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxHeight()
                        .fillMaxWidth((confidence / 100f).toFloat())
                        .clip(RoundedCornerShape(3.dp))
                        .background(
                            when {
                                confidence >= 70 -> RouaColors.Profit
                                confidence >= 40 -> RouaColors.Warning
                                else -> RouaColors.Loss
                            }
                        )
                )
            }

            // Entry/SL/TP Row
            if (brief.entryPrice != null || brief.stopLoss != null || brief.takeProfit != null) {
                Spacer(Modifier.height(8.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    brief.entryPrice?.let {
                        LabelValue("Entry", String.format("%.2f", it))
                    }
                    brief.stopLoss?.let {
                        LabelValue("SL", String.format("%.2f", it), color = RouaColors.Loss)
                    }
                    brief.takeProfit?.let {
                        LabelValue("TP", String.format("%.2f", it), color = RouaColors.Profit)
                    }
                }
            }

            if (!brief.timeframe.isNullOrBlank()) {
                Spacer(Modifier.height(6.dp))
                Text(
                    "Timeframe: ${brief.timeframe}",
                    style = MaterialTheme.typography.labelSmall,
                    color = RouaColors.TextTertiary
                )
            }
        }
    }
}

@Composable
fun DirectionBadge(direction: String?) {
    val bgColor = when (direction?.lowercase()) {
        "long", "buy" -> RouaColors.ProfitBackground
        "short", "sell" -> RouaColors.LossBackground
        else -> RouaColors.InfoBackground
    }
    val textColor = when (direction?.lowercase()) {
        "long", "buy" -> RouaColors.Profit
        "short", "sell" -> RouaColors.Loss
        else -> RouaColors.Cyan
    }
    val icon = when (direction?.lowercase()) {
        "long", "buy" -> Icons.Filled.ArrowUpward
        "short", "sell" -> Icons.Filled.ArrowDownward
        else -> Icons.Filled.Remove
    }

    Surface(
        shape = RoundedCornerShape(6.dp),
        color = bgColor
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(icon, contentDescription = null, tint = textColor, modifier = Modifier.size(12.dp))
            Spacer(Modifier.width(4.dp))
            Text(
                direction?.uppercase() ?: "NEUTRAL",
                style = MaterialTheme.typography.labelSmall,
                color = textColor,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

@Composable
fun LabelValue(label: String, value: String, color: Color = RouaColors.TextSecondary) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(label, style = MaterialTheme.typography.labelSmall, color = RouaColors.TextTertiary)
        Text(value, style = MonoTypography.Micro, color = color)
    }
}

@Composable
fun StatusDot(color: Color, label: String) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(
            modifier = Modifier
                .size(8.dp)
                .clip(CircleShape)
                .background(color)
        )
        Spacer(Modifier.width(6.dp))
        Text(label, style = MaterialTheme.typography.labelSmall, color = color)
    }
}

// ═══════════════════════════════════════════════
// EXECUTOR TAB
// ═══════════════════════════════════════════════

@Composable
fun ExecutorTab(uiState: AIUiState, viewModel: AIViewModel) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Status Hero Card
        item {
            Card(
                colors = CardDefaults.cardColors(
                    containerColor = if (uiState.executorEnabled) RouaColors.Card else RouaColors.Card
                ),
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .border(
                        width = 1.dp,
                        color = if (uiState.executorEnabled) RouaColors.Profit.copy(alpha = 0.3f) else RouaColors.Border,
                        shape = RoundedCornerShape(12.dp)
                    )
            ) {
                Column(
                    modifier = Modifier.padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    // Status Icon
                    Box(
                        modifier = Modifier
                            .size(64.dp)
                            .clip(CircleShape)
                            .background(
                                if (uiState.executorEnabled) RouaColors.ProfitBackground
                                else RouaColors.LossBackground.copy(alpha = 0.3f)
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            if (uiState.executorEnabled) Icons.Filled.PlayCircleFilled
                            else Icons.Filled.PauseCircle,
                            contentDescription = null,
                            tint = if (uiState.executorEnabled) RouaColors.Profit else RouaColors.TextTertiary,
                            modifier = Modifier.size(36.dp)
                        )
                    }

                    Spacer(Modifier.height(12.dp))

                    Text(
                        if (uiState.executorEnabled) "Executor Active" else "Executor Inactive",
                        style = MaterialTheme.typography.headlineSmall,
                        color = if (uiState.executorEnabled) RouaColors.Profit else RouaColors.TextSecondary,
                        fontWeight = FontWeight.Bold
                    )

                    Spacer(Modifier.height(16.dp))

                    // Stats Row
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        StatItem("Positions", "${uiState.executorStatus?.activePositions ?: 0}")
                        StatItem(
                            "P&L",
                            String.format("$%.2f", uiState.executorStatus?.dailyPnl ?: 0.0),
                            color = if ((uiState.executorStatus?.dailyPnl ?: 0.0) >= 0) RouaColors.Profit else RouaColors.Loss
                        )
                        StatItem("Win Rate", String.format("%.0f%%", 0.0))
                    }

                    Spacer(Modifier.height(20.dp))

                    // Toggle + Emergency Stop
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        // Enable/Disable Toggle
                        Button(
                            onClick = { viewModel.toggleExecutor(!uiState.executorEnabled) },
                            colors = ButtonDefaults.buttonColors(
                                containerColor = if (uiState.executorEnabled) RouaColors.Loss else RouaColors.Profit
                            ),
                            shape = RoundedCornerShape(10.dp),
                            modifier = Modifier.weight(1f)
                        ) {
                            Text(if (uiState.executorEnabled) "Disable" else "Enable")
                        }

                        // Emergency Stop
                        OutlinedButton(
                            onClick = { viewModel.emergencyStop() },
                            shape = RoundedCornerShape(10.dp),
                            border = ButtonDefaults.outlinedButtonBorder(enabled = true).copy(
                                brush = Brush.linearGradient(
                                    colors = listOf(RouaColors.Danger, RouaColors.Loss)
                                )
                            ),
                            colors = ButtonDefaults.outlinedButtonColors(contentColor = RouaColors.Danger),
                            modifier = Modifier.weight(1f)
                        ) {
                            Icon(Icons.Filled.Emergency, contentDescription = null, modifier = Modifier.size(16.dp))
                            Spacer(Modifier.width(4.dp))
                            Text("E-Stop")
                        }
                    }
                }
            }
        }

        // Exposure Summary
        item {
            Card(
                colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.PieChart, contentDescription = null, tint = RouaColors.Cyan, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(8.dp))
                        Text("Exposure Summary", style = MaterialTheme.typography.labelLarge, color = RouaColors.TextPrimary)
                    }

                    Spacer(Modifier.height(12.dp))

                    val exposure = uiState.exposure
                    if (exposure != null) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            LabelValue("Total", String.format("$%,.0f", exposure.totalExposure ?: 0.0), color = RouaColors.TextPrimary)
                            LabelValue("Max", String.format("$%,.0f", exposure.maxExposure ?: 0.0), color = RouaColors.Warning)
                        }

                        Spacer(Modifier.height(8.dp))

                        val bySide = exposure.bySide ?: emptyMap()
                        if (bySide.isNotEmpty()) {
                            Text("By Side", style = MaterialTheme.typography.labelSmall, color = RouaColors.TextTertiary)
                            Spacer(Modifier.height(4.dp))
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                bySide.forEach { (side, value) ->
                                    val clr = when (side.lowercase()) {
                                        "long", "buy" -> RouaColors.Profit
                                        "short", "sell" -> RouaColors.Loss
                                        else -> RouaColors.Cyan
                                    }
                                    LabelValue(side.uppercase(), String.format("$%,.0f", value), color = clr)
                                }
                            }
                        }
                    } else {
                        Text(
                            "No exposure data available",
                            style = MaterialTheme.typography.bodySmall,
                            color = RouaColors.TextTertiary
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun StatItem(label: String, value: String, color: Color = RouaColors.TextPrimary) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(value, style = MonoTypography.Small, color = color, fontWeight = FontWeight.Bold)
        Spacer(Modifier.height(2.dp))
        Text(label, style = MaterialTheme.typography.labelSmall, color = RouaColors.TextTertiary)
    }
}

// ═══════════════════════════════════════════════
// SIGNALS TAB
// ═══════════════════════════════════════════════

@Composable
fun SignalsTab(uiState: AIUiState, viewModel: AIViewModel) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Generate Signal Button
        item {
            Button(
                onClick = { viewModel.generateSignal() },
                colors = ButtonDefaults.buttonColors(containerColor = RouaColors.Accent),
                shape = RoundedCornerShape(10.dp),
                modifier = Modifier.fillMaxWidth(),
                enabled = !uiState.isLoading
            ) {
                Icon(Icons.Filled.AutoAwesome, contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(6.dp))
                Text("Generate Signal")
            }
        }

        // Active Signals Header
        item {
            Text(
                "Active Signals",
                style = MaterialTheme.typography.labelLarge,
                color = RouaColors.TextSecondary
            )
        }

        // Active Signals
        items(uiState.activeSignals) { signal ->
            SignalCard(signal)
        }

        if (uiState.activeSignals.isEmpty()) {
            item {
                Card(
                    colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        "No active signals. Generate one to get started.",
                        style = MaterialTheme.typography.bodySmall,
                        color = RouaColors.TextTertiary,
                        modifier = Modifier.padding(16.dp),
                        textAlign = TextAlign.Center
                    )
                }
            }
        }

        // Signal History Header
        if (uiState.signalHistory.isNotEmpty()) {
            item {
                Spacer(Modifier.height(4.dp))
                Text(
                    "Signal History",
                    style = MaterialTheme.typography.labelLarge,
                    color = RouaColors.TextSecondary
                )
            }

            items(uiState.signalHistory) { signal ->
                SignalCard(signal, isHistory = true)
            }
        }
    }
}

@Composable
fun SignalCard(signal: Signal, isHistory: Boolean = false) {
    Card(
        colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
        shape = RoundedCornerShape(12.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.Top
        ) {
            // Confidence Ring
            Box(
                modifier = Modifier.size(48.dp),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(
                    progress = { (signal.confidence / 100f).toFloat() },
                    modifier = Modifier.size(48.dp),
                    color = when {
                        signal.confidence >= 70 -> RouaColors.Profit
                        signal.confidence >= 40 -> RouaColors.Warning
                        else -> RouaColors.Loss
                    },
                    strokeWidth = 3.dp,
                    trackColor = RouaColors.BackgroundLight,
                    strokeCap = StrokeCap.Round
                )
                Text(
                    String.format("%.0f", signal.confidence),
                    style = MonoTypography.Micro,
                    color = RouaColors.TextPrimary,
                    fontWeight = FontWeight.Bold
                )
            }

            Spacer(Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(signal.pair, style = MaterialTheme.typography.labelLarge, color = RouaColors.TextPrimary)
                    DirectionBadge(signal.action)
                }

                Spacer(Modifier.height(8.dp))

                // Entry / SL / TP
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    signal.entryPrice?.let { LabelValue("Entry", String.format("%.2f", it)) }
                    signal.stopLoss?.let { LabelValue("SL", String.format("%.2f", it), color = RouaColors.Loss) }
                    signal.takeProfit?.let { LabelValue("TP", String.format("%.2f", it), color = RouaColors.Profit) }
                }

                // R:R Ratio
                if (signal.entryPrice != null && signal.stopLoss != null && signal.takeProfit != null) {
                    val risk = kotlin.math.abs(signal.entryPrice!! - signal.stopLoss!!)
                    val reward = kotlin.math.abs(signal.takeProfit!! - signal.entryPrice!!)
                    if (risk > 0) {
                        Spacer(Modifier.height(4.dp))
                        Text(
                            "R:R = 1:${String.format("%.1f", reward / risk)}",
                            style = MonoTypography.Micro,
                            color = RouaColors.Cyan
                        )
                    }
                }

                if (isHistory) {
                    Spacer(Modifier.height(4.dp))
                    Surface(
                        shape = RoundedCornerShape(4.dp),
                        color = when (signal.status?.lowercase()) {
                            "hit_tp", "closed_profit" -> RouaColors.ProfitBackground
                            "hit_sl", "closed_loss" -> RouaColors.LossBackground
                            else -> RouaColors.InfoBackground
                        }
                    ) {
                        Text(
                            signal.status?.replace("_", " ")?.replaceFirstChar { it.uppercase() } ?: "",
                            style = MaterialTheme.typography.labelSmall,
                            color = when (signal.status?.lowercase()) {
                                "hit_tp", "closed_profit" -> RouaColors.Profit
                                "hit_sl", "closed_loss" -> RouaColors.Loss
                                else -> RouaColors.Cyan
                            },
                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                        )
                    }
                }
            }
        }
    }
}

// ═══════════════════════════════════════════════
// COACH TAB
// ═══════════════════════════════════════════════

@Composable
fun CoachTab(uiState: AIUiState, viewModel: AIViewModel) {
    Column(modifier = Modifier.fillMaxSize()) {
        // Messages
        LazyColumn(
            modifier = Modifier
                .weight(1f)
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
            reverseLayout = true
        ) {
            // Quick Action Buttons
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    QuickActionButton("Market Analysis", Icons.Filled.Analytics) {
                        viewModel.onInputChanged("Give me a market analysis for BTC/USD")
                        viewModel.sendMessage()
                    }
                    QuickActionButton("Risk Advice", Icons.Filled.Shield) {
                        viewModel.onInputChanged("Assess my current risk exposure")
                        viewModel.sendMessage()
                    }
                    QuickActionButton("Strategy", Icons.Filled.TipsAndUpdates) {
                        viewModel.onInputChanged("Suggest a trading strategy for current market conditions")
                        viewModel.sendMessage()
                    }
                }
            }

            items(uiState.messages.reversed()) { message ->
                if (message.isUser) {
                    UserMessageBubble(message)
                } else {
                    AIMessageBubble(message)
                }
            }

            if (uiState.messages.isEmpty()) {
                item {
                    Card(
                        colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(
                            modifier = Modifier.padding(24.dp),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Icon(
                                Icons.Filled.Psychology,
                                contentDescription = null,
                                tint = RouaColors.Brand,
                                modifier = Modifier.size(40.dp)
                            )
                            Spacer(Modifier.height(12.dp))
                            Text(
                                "AI Trading Coach",
                                style = MaterialTheme.typography.labelLarge,
                                color = RouaColors.TextPrimary
                            )
                            Spacer(Modifier.height(4.dp))
                            Text(
                                "Ask anything about markets, risk, or strategy",
                                style = MaterialTheme.typography.bodySmall,
                                color = RouaColors.TextTertiary,
                                textAlign = TextAlign.Center
                            )
                        }
                    }
                }
            }

            if (uiState.isLoading) {
                item {
                    Row(
                        modifier = Modifier.padding(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(16.dp),
                            strokeWidth = 2.dp,
                            color = RouaColors.Brand
                        )
                        Spacer(Modifier.width(8.dp))
                        Text("AI is thinking...", style = MaterialTheme.typography.bodySmall, color = RouaColors.TextTertiary)
                    }
                }
            }
        }

        // Input Bar
        Surface(
            color = RouaColors.Card,
            shadowElevation = 8.dp
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(12.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                OutlinedTextField(
                    value = uiState.inputText,
                    onValueChange = { viewModel.onInputChanged(it) },
                    placeholder = {
                        Text("Ask AI about markets...", color = RouaColors.TextTertiary)
                    },
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(10.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedContainerColor = RouaColors.BackgroundLight,
                        unfocusedContainerColor = RouaColors.BackgroundLight,
                        focusedBorderColor = RouaColors.Accent.copy(alpha = 0.5f),
                        unfocusedBorderColor = RouaColors.Border,
                        focusedTextColor = RouaColors.TextPrimary,
                        unfocusedTextColor = RouaColors.TextPrimary
                    ),
                    maxLines = 3
                )
                FilledIconButton(
                    onClick = { viewModel.sendMessage() },
                    enabled = uiState.inputText.isNotBlank() && !uiState.isLoading,
                    colors = IconButtonDefaults.filledIconButtonColors(
                        containerColor = RouaColors.Accent,
                        disabledContainerColor = RouaColors.Accent.copy(alpha = 0.3f)
                    ),
                    shape = RoundedCornerShape(10.dp)
                ) {
                    Icon(Icons.Filled.Send, contentDescription = "Send")
                }
            }
        }
    }
}

@Composable
fun QuickActionButton(label: String, icon: ImageVector, onClick: () -> Unit) {
    OutlinedButton(
        onClick = onClick,
        shape = RoundedCornerShape(8.dp),
        colors = ButtonDefaults.outlinedButtonColors(
            contentColor = RouaColors.TextSecondary
        ),
        border = ButtonDefaults.outlinedButtonBorder(enabled = true).copy(
            brush = Brush.linearGradient(colors = listOf(RouaColors.Border2, RouaColors.Border2))
        ),
        contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp)
    ) {
        Icon(icon, contentDescription = null, modifier = Modifier.size(14.dp))
        Spacer(Modifier.width(4.dp))
        Text(label, style = MaterialTheme.typography.labelSmall)
    }
}

@Composable
fun UserMessageBubble(message: ChatMessage) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.End
    ) {
        Surface(
            shape = RoundedCornerShape(topStart = 12.dp, topEnd = 12.dp, bottomStart = 12.dp, bottomEnd = 4.dp),
            color = RouaColors.Accent.copy(alpha = 0.2f),
            modifier = Modifier.widthIn(max = 280.dp)
        ) {
            Column(modifier = Modifier.padding(12.dp)) {
                Text(message.content, style = MaterialTheme.typography.bodyMedium, color = RouaColors.TextPrimary)
            }
        }
    }
}

@Composable
fun AIMessageBubble(message: ChatMessage) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.Start
    ) {
        Surface(
            shape = RoundedCornerShape(topStart = 12.dp, topEnd = 12.dp, bottomStart = 4.dp, bottomEnd = 12.dp),
            color = RouaColors.Card,
            modifier = Modifier.widthIn(max = 300.dp)
        ) {
            Column(modifier = Modifier.padding(12.dp)) {
                if (message.model != null) {
                    Surface(
                        shape = RoundedCornerShape(4.dp),
                        color = RouaColors.Brand.copy(alpha = 0.15f)
                    ) {
                        Text(
                            message.model,
                            style = MaterialTheme.typography.labelSmall,
                            color = RouaColors.BrandLight,
                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                        )
                    }
                    Spacer(Modifier.height(6.dp))
                }
                Text(message.content, style = MaterialTheme.typography.bodyMedium, color = RouaColors.TextPrimary)
            }
        }
    }
}

// ═══════════════════════════════════════════════
// MODELS TAB
// ═══════════════════════════════════════════════

@Composable
fun ModelsTab(uiState: AIUiState, viewModel: AIViewModel) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Overall Availability Ring
        item {
            Card(
                colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text("Model Availability", style = MaterialTheme.typography.labelLarge, color = RouaColors.TextSecondary)
                    Spacer(Modifier.height(16.dp))

                    val total = uiState.aiModels.size
                    val available = uiState.aiModels.count { it.isAvailable }
                    val ratio = if (total > 0) available.toFloat() / total else 0f

                    Box(
                        modifier = Modifier.size(100.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator(
                            progress = { ratio },
                            modifier = Modifier.size(100.dp),
                            color = if (ratio >= 0.8f) RouaColors.Profit else if (ratio >= 0.5f) RouaColors.Warning else RouaColors.Loss,
                            strokeWidth = 6.dp,
                            trackColor = RouaColors.BackgroundLight,
                            strokeCap = StrokeCap.Round
                        )
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                "$available/$total",
                                style = MonoTypography.Medium,
                                color = RouaColors.TextPrimary,
                                fontWeight = FontWeight.Bold
                            )
                            Text("Online", style = MaterialTheme.typography.labelSmall, color = RouaColors.TextTertiary)
                        }
                    }
                }
            }
        }

        // Model Cards Grid Header
        item {
            Text("Models", style = MaterialTheme.typography.labelLarge, color = RouaColors.TextSecondary)
        }

        // Model Cards
        items(uiState.aiModels.chunked(2)) { rowModels ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                rowModels.forEach { model ->
                    ModelCard(model, modifier = Modifier.weight(1f))
                }
                if (rowModels.size < 2) {
                    Spacer(Modifier.weight(1f))
                }
            }
        }

        if (uiState.aiModels.isEmpty()) {
            item {
                Card(
                    colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        "No model data available. Pull to refresh.",
                        style = MaterialTheme.typography.bodySmall,
                        color = RouaColors.TextTertiary,
                        modifier = Modifier.padding(16.dp),
                        textAlign = TextAlign.Center
                    )
                }
            }
        }
    }
}

@Composable
fun ModelCard(model: AIModelStatus, modifier: Modifier = Modifier) {
    Card(
        colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
        shape = RoundedCornerShape(12.dp),
        modifier = modifier
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    model.name.take(16),
                    style = MaterialTheme.typography.labelLarge,
                    color = RouaColors.TextPrimary,
                    maxLines = 1
                )
                Box(
                    modifier = Modifier
                        .size(8.dp)
                        .clip(CircleShape)
                        .background(if (model.isAvailable) RouaColors.Profit else RouaColors.Loss)
                )
            }

            Spacer(Modifier.height(4.dp))

            Surface(
                shape = RoundedCornerShape(4.dp),
                color = RouaColors.Brand.copy(alpha = 0.1f)
            ) {
                Text(
                    model.provider,
                    style = MaterialTheme.typography.labelSmall,
                    color = RouaColors.BrandLight,
                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                )
            }

            Spacer(Modifier.height(6.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    if (model.isAvailable) "Online" else "Offline",
                    style = MaterialTheme.typography.labelSmall,
                    color = if (model.isAvailable) RouaColors.Profit else RouaColors.Loss
                )
                model.latency?.let { latency ->
                    Text(
                        String.format("%.0fms", latency),
                        style = MonoTypography.Micro,
                        color = if (latency < 2000) RouaColors.TextTertiary else RouaColors.Warning
                    )
                }
            }
        }
    }
}
