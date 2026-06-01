package com.roua.trading.features.dashboard

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.roua.trading.core.network.model.Position
import com.roua.trading.core.network.model.PortfolioSummary
import com.roua.trading.core.network.model.Quote
import com.roua.trading.design.theme.MonoTypography
import com.roua.trading.design.theme.RouaColors

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen(navController: NavController, viewModel: DashboardViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsState()
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Roua Trading") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = RouaColors.Background
                )
            )
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Portfolio Summary
            item {
                PortfolioSummaryCard(summary = uiState.portfolioSummary)
            }
            
            // Quick Stats
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    StatCard(
                        title = "Daily P&L",
                        value = uiState.portfolioSummary?.let { String.format("$%.2f", it.dailyPnl) } ?: "---",
                        modifier = Modifier.weight(1f),
                        isPositive = (uiState.portfolioSummary?.dailyPnl ?: 0.0) >= 0
                    )
                    StatCard(
                        title = "Positions",
                        value = "${uiState.positions.size}",
                        modifier = Modifier.weight(1f)
                    )
                    StatCard(
                        title = "Total P&L",
                        value = uiState.portfolioSummary?.let { String.format("$%.2f", it.totalPnl) } ?: "---",
                        modifier = Modifier.weight(1f),
                        isPositive = (uiState.portfolioSummary?.totalPnl ?: 0.0) >= 0
                    )
                }
            }
            
            // Active Positions
            item {
                Text("Active Positions", style = MaterialTheme.typography.titleMedium, color = RouaColors.TextPrimary)
            }
            
            items(uiState.positions) { position ->
                PositionCard(position = position)
            }
        }
    }
}

@Composable
fun PortfolioSummaryCard(summary: PortfolioSummary?) {
    Card(
        colors = CardDefaults.cardColors(containerColor = RouaColors.SurfaceElevated),
        shape = androidx.compose.foundation.shape.RoundedCornerShape(16.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text("Portfolio Value", style = MaterialTheme.typography.labelSmall, color = RouaColors.TextTertiary)
            Spacer(Modifier.height(4.dp))
            Text(
                summary?.let { String.format("$%,.2f", it.totalValue) } ?: "Loading...",
                style = MonoTypography.Large,
                color = RouaColors.TextPrimary
            )
        }
    }
}

@Composable
fun StatCard(title: String, value: String, modifier: Modifier = Modifier, isPositive: Boolean? = null) {
    Card(
        colors = CardDefaults.cardColors(containerColor = RouaColors.SurfaceElevated),
        shape = androidx.compose.foundation.shape.RoundedCornerShape(10.dp),
        modifier = modifier
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Text(title, style = MaterialTheme.typography.labelSmall, color = RouaColors.TextTertiary)
            Spacer(Modifier.height(2.dp))
            Text(
                value,
                style = MonoTypography.Small,
                color = when (isPositive) {
                    true -> RouaColors.Profit
                    false -> RouaColors.Loss
                    null -> RouaColors.TextPrimary
                }
            )
        }
    }
}

@Composable
fun PositionCard(position: Position) {
    Card(
        colors = CardDefaults.cardColors(containerColor = RouaColors.SurfaceElevated),
        shape = androidx.compose.foundation.shape.RoundedCornerShape(12.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Spacer(Modifier.width(4.dp))
                    Text(position.symbol, style = MaterialTheme.typography.labelLarge, color = RouaColors.TextPrimary)
                    Spacer(Modifier.width(6.dp))
                    Text(position.side, style = MaterialTheme.typography.labelSmall,
                        color = if (position.side == "BUY") RouaColors.Profit else RouaColors.Loss)
                }
                Text("Qty: ${String.format("%.4f", position.quantity)}", style = MonoTypography.Micro, color = RouaColors.TextTertiary)
            }
            Column(horizontalAlignment = Alignment.End) {
                position.unrealizedPnl?.let { pnl ->
                    Text(String.format("%+.2f", pnl), style = MonoTypography.Medium,
                        color = if (pnl >= 0) RouaColors.Profit else RouaColors.Loss)
                }
                Text("Entry: ${String.format("%.2f", position.entryPrice)}", style = MonoTypography.Micro, color = RouaColors.TextTertiary)
            }
        }
    }
}
