package com.roua.trading.features.portfolio

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
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
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.roua.trading.core.network.model.CurrencyBalance
import com.roua.trading.core.network.model.ExchangeBalance
import com.roua.trading.core.network.model.ExchangeCredential
import com.roua.trading.design.theme.MonoTypography
import com.roua.trading.design.theme.RouaColors
import kotlin.math.abs

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PortfolioScreen(viewModel: PortfolioViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(RouaColors.Background)
    ) {
        // Header
        Text(
            "Portfolio",
            style = MaterialTheme.typography.headlineMedium,
            color = RouaColors.TextPrimary,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(start = 16.dp, end = 16.dp, top = 16.dp, bottom = 8.dp)
        )

        // Tab Selector
        PortfolioTabSelector(
            selectedTab = uiState.selectedTab,
            onTabSelected = { viewModel.selectTab(it) }
        )

        Spacer(Modifier.height(12.dp))

        // Tab Content
        when (uiState.selectedTab) {
            PortfolioTab.BALANCES -> BalancesTab(uiState)
            PortfolioTab.CREDENTIALS -> CredentialsTab(uiState, viewModel)
            PortfolioTab.AGENT -> AgentTab(uiState, viewModel)
        }
    }
}

// ═══════════════════════════════════════════════
// TAB SELECTOR
// ═══════════════════════════════════════════════

@Composable
fun PortfolioTabSelector(
    selectedTab: PortfolioTab,
    onTabSelected: (PortfolioTab) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        PortfolioTab.entries.forEach { tab ->
            val isSelected = tab == selectedTab
            Surface(
                shape = RoundedCornerShape(20.dp),
                color = if (isSelected) RouaColors.Accent.copy(alpha = 0.15f) else Color.Transparent,
                border = if (isSelected) {
                    ButtonDefaults.outlinedButtonBorder(enabled = true).copy(
                        brush = Brush.linearGradient(
                            colors = listOf(RouaColors.Accent.copy(alpha = 0.4f), RouaColors.Accent.copy(alpha = 0.4f))
                        )
                    )
                } else null,
                modifier = Modifier.clickable { onTabSelected(tab) }
            ) {
                Text(
                    tab.label,
                    style = MaterialTheme.typography.labelMedium,
                    color = if (isSelected) RouaColors.TextPrimary else RouaColors.TextSecondary,
                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                )
            }
        }
    }
}

// ═══════════════════════════════════════════════
// BALANCES TAB
// ═══════════════════════════════════════════════

@Composable
fun BalancesTab(uiState: PortfolioUiState) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Total Balance Card
        item {
            Card(
                colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .border(
                        width = 1.dp,
                        color = RouaColors.Accent.copy(alpha = 0.2f),
                        shape = RoundedCornerShape(12.dp)
                    )
            ) {
                Column(
                    modifier = Modifier.padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text("Total Balance", style = MaterialTheme.typography.labelMedium, color = RouaColors.TextTertiary)
                    Spacer(Modifier.height(4.dp))
                    Text(
                        String.format("$%,.2f", uiState.totalValue),
                        style = MonoTypography.Large,
                        color = RouaColors.TextPrimary
                    )
                    Spacer(Modifier.height(8.dp))

                    // Daily P&L
                    val pnlColor = when {
                        uiState.dailyPnl > 0 -> RouaColors.Profit
                        uiState.dailyPnl < 0 -> RouaColors.Loss
                        else -> RouaColors.TextSecondary
                    }
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            if (uiState.dailyPnl >= 0) Icons.Filled.TrendingUp else Icons.Filled.TrendingDown,
                            contentDescription = null,
                            tint = pnlColor,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(Modifier.width(4.dp))
                        Text(
                            String.format("%s$%,.2f today", if (uiState.dailyPnl >= 0) "+" else "", uiState.dailyPnl),
                            style = MonoTypography.Small,
                            color = pnlColor
                        )
                    }
                }
            }
        }

        // Metrics Grid
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                MetricCard("Exposure", String.format("$%,.0f", uiState.exposure), Modifier.weight(1f), RouaColors.Cyan)
                MetricCard("Margin", String.format("%.0f", uiState.margin), Modifier.weight(1f), RouaColors.Gold)
                MetricCard("Drawdown", String.format("%.1f%%", uiState.drawdown), Modifier.weight(1f), RouaColors.Warning)
            }
        }

        // Exchange Balances
        item {
            Text("Exchange Balances", style = MaterialTheme.typography.labelLarge, color = RouaColors.TextSecondary)
        }

        items(uiState.balances) { balance ->
            ExchangeBalanceCard(balance)
        }

        if (uiState.balances.isEmpty()) {
            item {
                Card(
                    colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        "No exchange balances. Add credentials to get started.",
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
fun MetricCard(label: String, value: String, modifier: Modifier = Modifier, accentColor: Color = RouaColors.Cyan) {
    Card(
        colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
        shape = RoundedCornerShape(12.dp),
        modifier = modifier
    ) {
        Column(
            modifier = Modifier.padding(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(label, style = MaterialTheme.typography.labelSmall, color = RouaColors.TextTertiary)
            Spacer(Modifier.height(4.dp))
            Text(value, style = MonoTypography.Small, color = accentColor, fontWeight = FontWeight.Bold)
        }
    }
}

@Composable
fun ExchangeBalanceCard(balance: ExchangeBalance) {
    Card(
        colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
        shape = RoundedCornerShape(12.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Filled.AccountBalance,
                        contentDescription = null,
                        tint = RouaColors.Cyan,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(Modifier.width(8.dp))
                    Text(balance.exchange.uppercase(), style = MaterialTheme.typography.labelLarge, color = RouaColors.TextPrimary)
                }
                balance.totalValue?.let {
                    Text(String.format("$%,.2f", it), style = MonoTypography.Small, color = RouaColors.TextPrimary)
                }
            }

            // Currency breakdown
            val currencies = balance.currencies?.filter { it.total > 0 }?.take(5) ?: emptyList()
            if (currencies.isNotEmpty()) {
                Spacer(Modifier.height(8.dp))
                currencies.forEach { curr ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 2.dp),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(curr.currency, style = MaterialTheme.typography.bodySmall, color = RouaColors.TextSecondary)
                        Text(
                            String.format("%.4f", curr.total),
                            style = MonoTypography.Micro,
                            color = RouaColors.TextPrimary
                        )
                        curr.usdValue?.let { usd ->
                            Text(
                                String.format("$%,.2f", usd),
                                style = MonoTypography.Micro,
                                color = RouaColors.TextTertiary
                            )
                        }
                    }
                }
            }
        }
    }
}

// ═══════════════════════════════════════════════
// CREDENTIALS TAB
// ═══════════════════════════════════════════════

@Composable
fun CredentialsTab(uiState: PortfolioUiState, viewModel: PortfolioViewModel) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        // Add Credential Button
        item {
            Button(
                onClick = { viewModel.toggleAddForm() },
                colors = ButtonDefaults.buttonColors(containerColor = RouaColors.Accent),
                shape = RoundedCornerShape(10.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Icon(
                    if (uiState.showAddForm) Icons.Filled.Close else Icons.Filled.Add,
                    contentDescription = null,
                    modifier = Modifier.size(18.dp)
                )
                Spacer(Modifier.width(6.dp))
                Text(if (uiState.showAddForm) "Cancel" else "Add Exchange Account")
            }
        }

        // Add Credential Form
        if (uiState.showAddForm) {
            item {
                Card(
                    colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text("New Exchange Account", style = MaterialTheme.typography.labelLarge, color = RouaColors.TextPrimary)
                        Spacer(Modifier.height(12.dp))

                        // Exchange Selector
                        Text("Exchange", style = MaterialTheme.typography.labelSmall, color = RouaColors.TextTertiary)
                        Spacer(Modifier.height(4.dp))
                        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            listOf("binance", "okx", "bybit").forEach { exchange ->
                                val isSelected = uiState.newExchange == exchange
                                FilterChip(
                                    selected = isSelected,
                                    onClick = { viewModel.setNewExchange(exchange) },
                                    label = { Text(exchange.uppercase(), style = MaterialTheme.typography.labelSmall) },
                                    colors = FilterChipDefaults.filterChipColors(
                                        selectedContainerColor = RouaColors.Accent.copy(alpha = 0.2f),
                                        selectedLabelColor = RouaColors.TextPrimary,
                                        containerColor = RouaColors.BackgroundLight,
                                        labelColor = RouaColors.TextSecondary
                                    ),
                                    shape = RoundedCornerShape(6.dp)
                                )
                            }
                        }

                        Spacer(Modifier.height(10.dp))

                        // Label
                        OutlinedTextField(
                            value = uiState.newLabel,
                            onValueChange = { viewModel.setNewLabel(it) },
                            label = { Text("Label") },
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(8.dp),
                            colors = TextFieldDefaults.outlinedTextFieldColors(
                                focusedBorderColor = RouaColors.Accent.copy(alpha = 0.5f),
                                unfocusedBorderColor = RouaColors.Border,
                                focusedTextColor = RouaColors.TextPrimary,
                                unfocusedTextColor = RouaColors.TextPrimary,
                                focusedLabelColor = RouaColors.TextSecondary,
                                unfocusedLabelColor = RouaColors.TextTertiary,
                                containerColor = RouaColors.BackgroundLight
                            ),
                            singleLine = true
                        )

                        Spacer(Modifier.height(8.dp))

                        // API Key
                        OutlinedTextField(
                            value = uiState.newApiKey,
                            onValueChange = { viewModel.setNewApiKey(it) },
                            label = { Text("API Key") },
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(8.dp),
                            colors = TextFieldDefaults.outlinedTextFieldColors(
                                focusedBorderColor = RouaColors.Accent.copy(alpha = 0.5f),
                                unfocusedBorderColor = RouaColors.Border,
                                focusedTextColor = RouaColors.TextPrimary,
                                unfocusedTextColor = RouaColors.TextPrimary,
                                focusedLabelColor = RouaColors.TextSecondary,
                                unfocusedLabelColor = RouaColors.TextTertiary,
                                containerColor = RouaColors.BackgroundLight
                            ),
                            singleLine = true
                        )

                        Spacer(Modifier.height(8.dp))

                        // API Secret
                        OutlinedTextField(
                            value = uiState.newApiSecret,
                            onValueChange = { viewModel.setNewApiSecret(it) },
                            label = { Text("API Secret") },
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(8.dp),
                            colors = TextFieldDefaults.outlinedTextFieldColors(
                                focusedBorderColor = RouaColors.Accent.copy(alpha = 0.5f),
                                unfocusedBorderColor = RouaColors.Border,
                                focusedTextColor = RouaColors.TextPrimary,
                                unfocusedTextColor = RouaColors.TextPrimary,
                                focusedLabelColor = RouaColors.TextSecondary,
                                unfocusedLabelColor = RouaColors.TextTertiary,
                                containerColor = RouaColors.BackgroundLight
                            ),
                            singleLine = true
                        )

                        Spacer(Modifier.height(8.dp))

                        // Passphrase (optional)
                        OutlinedTextField(
                            value = uiState.newPassphrase,
                            onValueChange = { viewModel.setNewPassphrase(it) },
                            label = { Text("Passphrase (optional)") },
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(8.dp),
                            colors = TextFieldDefaults.outlinedTextFieldColors(
                                focusedBorderColor = RouaColors.Accent.copy(alpha = 0.5f),
                                unfocusedBorderColor = RouaColors.Border,
                                focusedTextColor = RouaColors.TextPrimary,
                                unfocusedTextColor = RouaColors.TextPrimary,
                                focusedLabelColor = RouaColors.TextSecondary,
                                unfocusedLabelColor = RouaColors.TextTertiary,
                                containerColor = RouaColors.BackgroundLight
                            ),
                            singleLine = true
                        )

                        Spacer(Modifier.height(8.dp))

                        // Testnet Toggle
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text("Testnet", style = MaterialTheme.typography.bodyMedium, color = RouaColors.TextPrimary)
                            Switch(
                                checked = uiState.newTestnet,
                                onCheckedChange = { viewModel.setNewTestnet(it) },
                                colors = SwitchDefaults.colors(checkedTrackColor = RouaColors.Accent)
                            )
                        }

                        Spacer(Modifier.height(12.dp))

                        // Submit
                        Button(
                            onClick = { viewModel.addCredential() },
                            colors = ButtonDefaults.buttonColors(containerColor = RouaColors.Accent),
                            shape = RoundedCornerShape(10.dp),
                            modifier = Modifier.fillMaxWidth(),
                            enabled = uiState.newApiKey.isNotBlank() && uiState.newApiSecret.isNotBlank()
                        ) {
                            Text("Add Account")
                        }
                    }
                }
            }
        }

        // Credentials List
        items(uiState.credentials, key = { it.id }) { credential ->
            CredentialCard(
                credential = credential,
                onDelete = { viewModel.deleteCredential(credential.id) }
            )
        }

        if (uiState.credentials.isEmpty() && !uiState.showAddForm) {
            item {
                Card(
                    colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        "No exchange accounts connected. Add one to start trading.",
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
fun CredentialCard(credential: ExchangeCredential, onDelete: () -> Unit) {
    Card(
        colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
        shape = RoundedCornerShape(12.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(credential.label, style = MaterialTheme.typography.labelLarge, color = RouaColors.TextPrimary)
                    if (credential.testnet) {
                        Spacer(Modifier.width(6.dp))
                        Surface(
                            shape = RoundedCornerShape(4.dp),
                            color = RouaColors.WarningBackground
                        ) {
                            Text(
                                "TESTNET",
                                style = MaterialTheme.typography.labelSmall,
                                color = RouaColors.Warning,
                                fontWeight = FontWeight.Bold,
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                            )
                        }
                    }
                }
                Spacer(Modifier.height(2.dp))
                Text(
                    credential.exchange.uppercase(),
                    style = MaterialTheme.typography.labelSmall,
                    color = RouaColors.TextTertiary
                )
            }

            IconButton(onClick = onDelete) {
                Icon(
                    Icons.Filled.DeleteOutline,
                    contentDescription = "Delete",
                    tint = RouaColors.TextTertiary,
                    modifier = Modifier.size(20.dp)
                )
            }
        }
    }
}

// ═══════════════════════════════════════════════
// AGENT TAB
// ═══════════════════════════════════════════════

@Composable
fun AgentTab(uiState: PortfolioUiState, viewModel: PortfolioViewModel) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Status Card
        item {
            val isRunning = uiState.agentStatus?.isRunning == true
            Card(
                colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .border(
                        width = 1.dp,
                        color = if (isRunning) RouaColors.Profit.copy(alpha = 0.3f) else RouaColors.Border,
                        shape = RoundedCornerShape(12.dp)
                    )
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Box(
                            modifier = Modifier
                                .size(10.dp)
                                .clip(CircleShape)
                                .background(if (isRunning) RouaColors.Success else RouaColors.TextTertiary)
                        )
                        Spacer(Modifier.width(8.dp))
                        Text(
                            if (isRunning) "Agent Active" else "Agent Stopped",
                            style = MaterialTheme.typography.labelLarge,
                            color = if (isRunning) RouaColors.Profit else RouaColors.TextSecondary
                        )
                    }

                    if (uiState.agentStatus?.strategy != null) {
                        Spacer(Modifier.height(4.dp))
                        Surface(
                            shape = RoundedCornerShape(4.dp),
                            color = RouaColors.Brand.copy(alpha = 0.15f)
                        ) {
                            Text(
                                uiState.agentStatus.strategy!!.replaceFirstChar { it.uppercase() },
                                style = MaterialTheme.typography.labelSmall,
                                color = RouaColors.BrandLight,
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                            )
                        }
                    }

                    Spacer(Modifier.height(14.dp))

                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Button(
                            onClick = { viewModel.startAgent() },
                            colors = ButtonDefaults.buttonColors(containerColor = RouaColors.Profit),
                            shape = RoundedCornerShape(10.dp),
                            enabled = !isRunning
                        ) {
                            Icon(Icons.Filled.PlayArrow, contentDescription = null, modifier = Modifier.size(18.dp))
                            Spacer(Modifier.width(4.dp))
                            Text("Start")
                        }
                        Button(
                            onClick = { viewModel.stopAgent() },
                            colors = ButtonDefaults.buttonColors(containerColor = RouaColors.Loss),
                            shape = RoundedCornerShape(10.dp),
                            enabled = isRunning
                        ) {
                            Icon(Icons.Filled.Stop, contentDescription = null, modifier = Modifier.size(18.dp))
                            Spacer(Modifier.width(4.dp))
                            Text("Stop")
                        }
                    }
                }
            }
        }

        // Strategy Selector
        item {
            Card(
                colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("Strategy", style = MaterialTheme.typography.labelLarge, color = RouaColors.TextSecondary)
                    Spacer(Modifier.height(8.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        listOf("conservative", "moderate", "aggressive").forEach { strategy ->
                            val isSelected = uiState.selectedStrategy == strategy
                            FilterChip(
                                selected = isSelected,
                                onClick = { viewModel.selectStrategy(strategy) },
                                label = {
                                    Text(
                                        strategy.replaceFirstChar { it.uppercase() },
                                        style = MaterialTheme.typography.labelSmall
                                    )
                                },
                                colors = FilterChipDefaults.filterChipColors(
                                    selectedContainerColor = RouaColors.Brand.copy(alpha = 0.2f),
                                    selectedLabelColor = RouaColors.BrandLight,
                                    containerColor = RouaColors.BackgroundLight,
                                    labelColor = RouaColors.TextSecondary
                                ),
                                shape = RoundedCornerShape(6.dp)
                            )
                        }
                    }
                }
            }
        }

        // Risk Parameters
        item {
            Card(
                colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("Risk Parameters", style = MaterialTheme.typography.labelLarge, color = RouaColors.TextSecondary)
                    Spacer(Modifier.height(12.dp))

                    // Risk Per Trade
                    RiskSlider(
                        label = "Risk Per Trade",
                        value = uiState.riskPerTrade,
                        range = 0.5f..10f,
                        steps = 18,
                        unit = "%",
                        onValueChange = { viewModel.setRiskPerTrade(it) }
                    )

                    Spacer(Modifier.height(12.dp))

                    // Max Position Size
                    RiskSlider(
                        label = "Max Position Size",
                        value = uiState.maxPositionSize,
                        range = 1f..50f,
                        steps = 48,
                        unit = "%",
                        onValueChange = { viewModel.setMaxPositionSize(it) }
                    )

                    Spacer(Modifier.height(12.dp))

                    // Max Daily Loss
                    RiskSlider(
                        label = "Max Daily Loss",
                        value = uiState.maxDailyLoss,
                        range = 1f..20f,
                        steps = 38,
                        unit = "%",
                        onValueChange = { viewModel.setMaxDailyLoss(it) }
                    )

                    Spacer(Modifier.height(12.dp))

                    // Apply Button
                    Button(
                        onClick = { viewModel.updateSettings() },
                        colors = ButtonDefaults.buttonColors(containerColor = RouaColors.Accent),
                        shape = RoundedCornerShape(8.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Apply Settings")
                    }
                }
            }
        }

        // Performance Metrics
        item {
            val perf = uiState.agentPerformance
            Card(
                colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("Performance", style = MaterialTheme.typography.labelLarge, color = RouaColors.TextSecondary)
                    Spacer(Modifier.height(12.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        PerfItem("Total P&L", String.format("$%,.2f", perf?.totalPnl ?: 0.0),
                            color = if ((perf?.totalPnl ?: 0.0) >= 0) RouaColors.Profit else RouaColors.Loss)
                        PerfItem("Win Rate", String.format("%.1f%%", (perf?.winRate ?: 0.0) * 100))
                        PerfItem("Trades", "${perf?.totalTrades ?: 0}")
                    }

                    Spacer(Modifier.height(10.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        PerfItem("Sharpe", String.format("%.2f", perf?.sharpeRatio ?: 0.0), color = RouaColors.Cyan)
                        PerfItem("Drawdown", String.format("%.1f%%", perf?.maxDrawdown ?: 0.0), color = RouaColors.Warning)
                        PerfItem("Daily", String.format("$%,.2f", perf?.dailyPnl ?: 0.0),
                            color = if ((perf?.dailyPnl ?: 0.0) >= 0) RouaColors.Profit else RouaColors.Loss)
                    }
                }
            }
        }
    }
}

@Composable
fun RiskSlider(
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
fun PerfItem(label: String, value: String, color: Color = RouaColors.TextPrimary) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(value, style = MonoTypography.Small, color = color, fontWeight = FontWeight.Bold)
        Spacer(Modifier.height(2.dp))
        Text(label, style = MaterialTheme.typography.labelSmall, color = RouaColors.TextTertiary)
    }
}
