package com.roua.trading.features.dashboard

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Psychology
import androidx.compose.material.icons.filled.Science
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.ShowChart
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.material3.pulltorefresh.rememberPullToRefreshState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.roua.trading.core.network.model.ExecutorStatus
import com.roua.trading.core.network.model.NewsArticle
import com.roua.trading.core.network.model.PortfolioSummary
import com.roua.trading.core.network.model.Position
import com.roua.trading.core.network.model.ScanResult
import com.roua.trading.core.network.model.Signal
import com.roua.trading.design.theme.MonoTypography
import com.roua.trading.design.theme.RouaColors
import com.roua.trading.navigation.Screen

// ──────────────────────────────────────────────────────────────────────
// Main Dashboard Screen
// ──────────────────────────────────────────────────────────────────────

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen(
    navController: NavController,
    viewModel: DashboardViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val pullToRefreshState = rememberPullToRefreshState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        "Roua Trading",
                        fontWeight = FontWeight.Bold,
                        color = RouaColors.TextPrimary
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = RouaColors.Background
                )
            )
        },
        containerColor = RouaColors.Background
    ) { padding ->
        PullToRefreshBox(
            isRefreshing = uiState.isRefreshing,
            onRefresh = { viewModel.refresh() },
            state = pullToRefreshState,
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            if (uiState.isLoading) {
                ShimmerDashboard()
            } else {
                DashboardContent(
                    uiState = uiState,
                    onNavigate = { route -> navController.navigate(route) }
                )
            }
        }
    }
}

// ──────────────────────────────────────────────────────────────────────
// Dashboard Content — LazyColumn with all sections
// ──────────────────────────────────────────────────────────────────────

@Composable
private fun DashboardContent(
    uiState: DashboardUiState,
    onNavigate: (String) -> Unit
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(0.dp)
    ) {
        // 1. Ticker Bar
        item {
            TickerBar(scannerResults = uiState.scannerResults)
        }

        item { Spacer(Modifier.height(12.dp)) }

        // 2. Portfolio Summary Card
        item {
            PortfolioSummaryCard(summary = uiState.portfolioSummary)
        }

        item { Spacer(Modifier.height(12.dp)) }

        // 3. Market Movers
        item {
            SectionHeader(title = "Market Movers")
        }
        item {
            MarketMoversRow(scannerResults = uiState.scannerResults)
        }

        item { Spacer(Modifier.height(16.dp)) }

        // 4. AI Signals
        if (uiState.signals.isNotEmpty()) {
            item {
                SectionHeader(title = "AI Signals")
            }
            item {
                AISignalsRow(signals = uiState.signals)
            }
            item { Spacer(Modifier.height(16.dp)) }
        }

        // 5. Quick Actions Grid
        item {
            SectionHeader(title = "Quick Actions")
        }
        item {
            QuickActionsGrid(onNavigate = onNavigate)
        }

        item { Spacer(Modifier.height(16.dp)) }

        // 6. Smart Executor Status
        item {
            SmartExecutorCard(executorStatus = uiState.executorStatus)
        }

        item { Spacer(Modifier.height(16.dp)) }

        // 7. Recent News
        if (uiState.news.isNotEmpty()) {
            item {
                SectionHeader(title = "Recent News")
            }
            items(uiState.news, key = { it.id }) { article ->
                NewsItemCard(article = article)
                Spacer(Modifier.height(8.dp))
            }
            item { Spacer(Modifier.height(8.dp)) }
        }

        // 8. Active Positions
        item {
            SectionHeader(title = "Active Positions")
        }
        if (uiState.positions.isEmpty()) {
            item {
                EmptyPositionsPlaceholder()
            }
        } else {
            items(uiState.positions, key = { it.id }) { position ->
                PositionCard(position = position)
                Spacer(Modifier.height(8.dp))
            }
        }

        // Bottom spacing
        item {
            Spacer(Modifier.height(24.dp))
        }
    }
}

// ──────────────────────────────────────────────────────────────────────
// 1. Ticker Bar — horizontal scrolling market ticker strip
// ──────────────────────────────────────────────────────────────────────

@Composable
private fun TickerBar(scannerResults: List<ScanResult>) {
    val tickerItems = if (scannerResults.isNotEmpty()) {
        scannerResults.take(20)
    } else {
        fallbackTickers
    }

    Surface(
        color = RouaColors.BackgroundLight,
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .horizontalScroll(rememberScrollState())
                .padding(vertical = 10.dp, horizontal = 12.dp),
            horizontalArrangement = Arrangement.spacedBy(20.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            tickerItems.forEach { item ->
                TickerChip(
                    symbol = item.symbol,
                    price = item.price,
                    changePercent = item.changePercent
                )
            }
        }
    }
}

@Composable
private fun TickerChip(symbol: String, price: Double, changePercent: Double) {
    val isPositive = changePercent >= 0
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Text(
            text = symbol,
            style = MaterialTheme.typography.labelMedium,
            fontWeight = FontWeight.SemiBold,
            color = RouaColors.TextPrimary,
            maxLines = 1
        )
        Text(
            text = String.format("%.2f", price),
            style = MonoTypography.Micro,
            color = RouaColors.TextSecondary,
            maxLines = 1
        )
        Text(
            text = String.format("%+.2f%%", changePercent),
            style = MonoTypography.Micro,
            fontWeight = FontWeight.SemiBold,
            color = if (isPositive) RouaColors.Profit else RouaColors.Loss,
            maxLines = 1
        )
    }
}

private val fallbackTickers = listOf(
    ScanResult(symbol = "BTC/USD", price = 67432.50, changePercent = 2.34),
    ScanResult(symbol = "ETH/USD", price = 3521.80, changePercent = -1.12),
    ScanResult(symbol = "SOL/USD", price = 178.45, changePercent = 5.67),
    ScanResult(symbol = "XRP/USD", price = 0.62, changePercent = -0.89),
    ScanResult(symbol = "ADA/USD", price = 0.48, changePercent = 1.23),
    ScanResult(symbol = "DOGE/USD", price = 0.165, changePercent = 3.45),
    ScanResult(symbol = "AAPL", price = 189.72, changePercent = 0.56),
    ScanResult(symbol = "TSLA", price = 248.30, changePercent = -2.10)
)

// ──────────────────────────────────────────────────────────────────────
// 2. Portfolio Summary Card
// ──────────────────────────────────────────────────────────────────────

@Composable
private fun PortfolioSummaryCard(summary: PortfolioSummary?) {
    Card(
        colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
        shape = RoundedCornerShape(12.dp),
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .border(1.dp, RouaColors.Border, RoundedCornerShape(12.dp))
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(
                    Brush.linearGradient(
                        colors = listOf(
                            RouaColors.Card,
                            RouaColors.CardHover.copy(alpha = 0.6f)
                        ),
                        start = Offset.Zero,
                        end = Offset(1000f, 1000f)
                    )
                )
                .padding(20.dp)
        ) {
            Column {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Portfolio Value",
                        style = MaterialTheme.typography.labelMedium,
                        color = RouaColors.TextSecondary
                    )
                    val dailyPnl = summary?.dailyPnl ?: 0.0
                    val dailyPositive = dailyPnl >= 0
                    Surface(
                        color = if (dailyPositive) RouaColors.ProfitBackground else RouaColors.LossBackground,
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Text(
                            text = String.format("%s$%.2f", if (dailyPositive) "+" else "", dailyPnl),
                            style = MonoTypography.Small.copy(fontWeight = FontWeight.SemiBold),
                            color = if (dailyPositive) RouaColors.Profit else RouaColors.Loss,
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp)
                        )
                    }
                }

                Spacer(Modifier.height(8.dp))

                Text(
                    text = summary?.let { String.format("$%,.2f", it.totalValue) } ?: "---",
                    style = TextStyle(
                        fontFamily = FontFamily.Monospace,
                        fontWeight = FontWeight.Bold,
                        fontSize = 28.sp,
                        lineHeight = 36.sp
                    ),
                    color = RouaColors.TextPrimary
                )

                Spacer(Modifier.height(12.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(24.dp)
                ) {
                    Column {
                        Text(
                            text = "Total P&L",
                            style = MaterialTheme.typography.labelSmall,
                            color = RouaColors.TextSecondary
                        )
                        Spacer(Modifier.height(2.dp))
                        val totalPnl = summary?.totalPnl ?: 0.0
                        Text(
                            text = String.format("%s$%.2f", if (totalPnl >= 0) "+" else "", totalPnl),
                            style = MonoTypography.Small.copy(fontWeight = FontWeight.SemiBold),
                            color = if (totalPnl >= 0) RouaColors.Profit else RouaColors.Loss
                        )
                    }
                    Column {
                        Text(
                            text = "Positions",
                            style = MaterialTheme.typography.labelSmall,
                            color = RouaColors.TextSecondary
                        )
                        Spacer(Modifier.height(2.dp))
                        Text(
                            text = "${summary?.positions?.size ?: 0}",
                            style = MonoTypography.Small.copy(fontWeight = FontWeight.SemiBold),
                            color = RouaColors.TextPrimary
                        )
                    }
                    Column {
                        Text(
                            text = "Unrealized",
                            style = MaterialTheme.typography.labelSmall,
                            color = RouaColors.TextSecondary
                        )
                        Spacer(Modifier.height(2.dp))
                        val unrealized = summary?.unrealizedPnl ?: 0.0
                        Text(
                            text = String.format("%s$%.2f", if (unrealized >= 0) "+" else "", unrealized),
                            style = MonoTypography.Small.copy(fontWeight = FontWeight.SemiBold),
                            color = if (unrealized >= 0) RouaColors.Profit else RouaColors.Loss
                        )
                    }
                }
            }
        }
    }
}

// ──────────────────────────────────────────────────────────────────────
// 3. Market Movers — horizontal scroll of gainers/losers
// ──────────────────────────────────────────────────────────────────────

@Composable
private fun MarketMoversRow(scannerResults: List<ScanResult>) {
    val movers = if (scannerResults.isNotEmpty()) {
        scannerResults.sortedByDescending { it.changePercent }.take(10)
    } else {
        emptyList()
    }

    Row(
        modifier = Modifier
            .horizontalScroll(rememberScrollState())
            .padding(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        movers.forEach { result ->
            MarketMoverMiniCard(result)
        }
    }
}

@Composable
private fun MarketMoverMiniCard(result: ScanResult) {
    val isPositive = result.changePercent >= 0
    val accentColor = if (isPositive) RouaColors.Profit else RouaColors.Loss
    val accentBg = if (isPositive) RouaColors.ProfitBackground else RouaColors.LossBackground

    Card(
        colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
        shape = RoundedCornerShape(12.dp),
        modifier = Modifier
            .width(130.dp)
            .border(1.dp, RouaColors.Border, RoundedCornerShape(12.dp))
    ) {
        Column(
            modifier = Modifier.padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Text(
                text = result.symbol,
                style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.SemiBold),
                color = RouaColors.TextPrimary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Text(
                text = String.format("%.2f", result.price),
                style = MonoTypography.Small,
                color = RouaColors.TextPrimary
            )
            Surface(
                color = accentBg,
                shape = RoundedCornerShape(6.dp)
            ) {
                Text(
                    text = String.format("%+.2f%%", result.changePercent),
                    style = MonoTypography.Micro.copy(fontWeight = FontWeight.SemiBold),
                    color = accentColor,
                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                )
            }
        }
    }
}

// ──────────────────────────────────────────────────────────────────────
// 4. AI Signals — horizontal scroll of active signals with confidence
// ──────────────────────────────────────────────────────────────────────

@Composable
private fun AISignalsRow(signals: List<Signal>) {
    Row(
        modifier = Modifier
            .horizontalScroll(rememberScrollState())
            .padding(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        signals.forEach { signal ->
            AISignalCard(signal)
        }
    }
}

@Composable
private fun AISignalCard(signal: Signal) {
    val isBuy = signal.action.equals("BUY", ignoreCase = true)
    val accentColor = if (isBuy) RouaColors.Profit else RouaColors.Loss
    val accentBg = if (isBuy) RouaColors.ProfitBackground else RouaColors.LossBackground

    Card(
        colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
        shape = RoundedCornerShape(12.dp),
        modifier = Modifier
            .width(200.dp)
            .border(1.dp, RouaColors.Border, RoundedCornerShape(12.dp))
    ) {
        Column(
            modifier = Modifier.padding(14.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = signal.pair,
                    style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.SemiBold),
                    color = RouaColors.TextPrimary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Surface(
                    color = accentBg,
                    shape = RoundedCornerShape(6.dp)
                ) {
                    Text(
                        text = signal.action.uppercase(),
                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                        color = accentColor,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                    )
                }
            }

            // Confidence bar
            Column {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "Confidence",
                        style = MaterialTheme.typography.labelSmall,
                        color = RouaColors.TextSecondary
                    )
                    Text(
                        text = String.format("%.0f%%", signal.confidence * 100),
                        style = MonoTypography.Micro.copy(fontWeight = FontWeight.SemiBold),
                        color = RouaColors.Cyan
                    )
                }
                Spacer(Modifier.height(4.dp))
                LinearProgressIndicator(
                    progress = { signal.confidence.toFloat().coerceIn(0f, 1f) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(4.dp)
                        .clip(RoundedCornerShape(2.dp)),
                    color = RouaColors.Cyan,
                    trackColor = RouaColors.CardHover,
                    strokeCap = StrokeCap.Round
                )
            }

            // Entry price
            signal.entryPrice?.let { entry ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "Entry",
                        style = MaterialTheme.typography.labelSmall,
                        color = RouaColors.TextSecondary
                    )
                    Text(
                        text = String.format("%.2f", entry),
                        style = MonoTypography.Micro,
                        color = RouaColors.TextPrimary
                    )
                }
            }
        }
    }
}

// ──────────────────────────────────────────────────────────────────────
// 5. Quick Actions Grid — 2x2
// ──────────────────────────────────────────────────────────────────────

@Composable
private fun QuickActionsGrid(onNavigate: (String) -> Unit) {
    Column(
        modifier = Modifier.padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            QuickActionCard(
                title = "New Trade",
                icon = Icons.Filled.ShowChart,
                accentColor = RouaColors.Accent,
                bgColor = RouaColors.Accent.copy(alpha = 0.12f),
                modifier = Modifier.weight(1f),
                onClick = { onNavigate(Screen.Trading.route) }
            )
            QuickActionCard(
                title = "Scanner",
                icon = Icons.Filled.Search,
                accentColor = RouaColors.Cyan,
                bgColor = RouaColors.Cyan.copy(alpha = 0.12f),
                modifier = Modifier.weight(1f),
                onClick = { onNavigate(Screen.Scanner.route) }
            )
        }
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            QuickActionCard(
                title = "AI Council",
                icon = Icons.Filled.Psychology,
                accentColor = RouaColors.Brand,
                bgColor = RouaColors.Brand.copy(alpha = 0.12f),
                modifier = Modifier.weight(1f),
                onClick = { onNavigate(Screen.AI.route) }
            )
            QuickActionCard(
                title = "Neural Lab",
                icon = Icons.Filled.Science,
                accentColor = RouaColors.Gold,
                bgColor = RouaColors.Gold.copy(alpha = 0.12f),
                modifier = Modifier.weight(1f),
                onClick = { onNavigate(Screen.Agent.route) }
            )
        }
    }
}

@Composable
private fun QuickActionCard(
    title: String,
    icon: ImageVector,
    accentColor: Color,
    bgColor: Color,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    Card(
        onClick = onClick,
        colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
        shape = RoundedCornerShape(12.dp),
        modifier = modifier.border(1.dp, RouaColors.Border, RoundedCornerShape(12.dp))
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Surface(
                color = bgColor,
                shape = RoundedCornerShape(10.dp),
                modifier = Modifier.size(44.dp)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        imageVector = icon,
                        contentDescription = title,
                        tint = accentColor,
                        modifier = Modifier.size(22.dp)
                    )
                }
            }
            Spacer(Modifier.height(8.dp))
            Text(
                text = title,
                style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.SemiBold),
                color = RouaColors.TextPrimary
            )
        }
    }
}

// ──────────────────────────────────────────────────────────────────────
// 6. Smart Executor Status
// ──────────────────────────────────────────────────────────────────────

@Composable
private fun SmartExecutorCard(executorStatus: ExecutorStatus?) {
    val isRunning = executorStatus?.isRunning ?: false
    val statusColor = if (isRunning) RouaColors.Success else RouaColors.TextSecondary
    val statusBg = if (isRunning) RouaColors.Success.copy(alpha = 0.12f) else RouaColors.CardHover

    Card(
        colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
        shape = RoundedCornerShape(12.dp),
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .border(1.dp, RouaColors.Border, RoundedCornerShape(12.dp))
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Surface(
                    color = statusBg,
                    shape = RoundedCornerShape(10.dp),
                    modifier = Modifier.size(40.dp)
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(
                            imageVector = if (isRunning) Icons.Filled.PlayArrow else Icons.Filled.Stop,
                            contentDescription = "Executor Status",
                            tint = statusColor,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
                Column {
                    Text(
                        text = "Smart Executor",
                        style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.SemiBold),
                        color = RouaColors.TextPrimary
                    )
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(6.dp)
                                .background(statusColor, CircleShape)
                        )
                        Text(
                            text = if (isRunning) "Running" else "Stopped",
                            style = MaterialTheme.typography.labelSmall,
                            color = statusColor
                        )
                    }
                }
            }

            Row(
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                executorStatus?.activePositions?.let { count ->
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            text = "$count",
                            style = MonoTypography.Small.copy(fontWeight = FontWeight.SemiBold),
                            color = RouaColors.TextPrimary
                        )
                        Text(
                            text = "Positions",
                            style = MaterialTheme.typography.labelSmall,
                            color = RouaColors.TextSecondary
                        )
                    }
                }
                executorStatus?.dailyPnl?.let { pnl ->
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            text = String.format("%s$%.2f", if (pnl >= 0) "+" else "", pnl),
                            style = MonoTypography.Small.copy(fontWeight = FontWeight.SemiBold),
                            color = if (pnl >= 0) RouaColors.Profit else RouaColors.Loss
                        )
                        Text(
                            text = "Daily P&L",
                            style = MaterialTheme.typography.labelSmall,
                            color = RouaColors.TextSecondary
                        )
                    }
                }
            }
        }
    }
}

// ──────────────────────────────────────────────────────────────────────
// 7. Recent News — news items with sentiment badges
// ──────────────────────────────────────────────────────────────────────

@Composable
private fun NewsItemCard(article: NewsArticle) {
    Card(
        colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
        shape = RoundedCornerShape(12.dp),
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .border(1.dp, RouaColors.Border, RoundedCornerShape(12.dp))
    ) {
        Column(
            modifier = Modifier.padding(14.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    article.source?.let { src ->
                        Text(
                            text = src,
                            style = MaterialTheme.typography.labelSmall,
                            color = RouaColors.TextSecondary
                        )
                    }
                    article.sentiment?.let { sentiment ->
                        val (sentColor, sentBg) = when (sentiment.lowercase()) {
                            "positive", "bullish" -> RouaColors.Profit to RouaColors.ProfitBackground
                            "negative", "bearish" -> RouaColors.Loss to RouaColors.LossBackground
                            else -> RouaColors.Cyan to RouaColors.InfoBackground
                        }
                        Surface(
                            color = sentBg,
                            shape = RoundedCornerShape(4.dp)
                        ) {
                            Text(
                                text = sentiment.replaceFirstChar { it.uppercase() },
                                style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.SemiBold),
                                color = sentColor,
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                            )
                        }
                    }
                }
                article.symbol?.let { sym ->
                    Surface(
                        color = RouaColors.Glass,
                        shape = RoundedCornerShape(4.dp)
                    ) {
                        Text(
                            text = sym,
                            style = MaterialTheme.typography.labelSmall,
                            color = RouaColors.TextSecondary,
                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                        )
                    }
                }
            }

            Text(
                text = article.title,
                style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Medium),
                color = RouaColors.TextPrimary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )

            article.summary?.let { summary ->
                Text(
                    text = summary,
                    style = MaterialTheme.typography.bodySmall,
                    color = RouaColors.TextSecondary,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }
    }
}

// ──────────────────────────────────────────────────────────────────────
// 8. Active Positions — list with PnL coloring
// ──────────────────────────────────────────────────────────────────────

@Composable
private fun PositionCard(position: Position) {
    val isBuy = position.side.equals("BUY", ignoreCase = true)
    val sideColor = if (isBuy) RouaColors.Profit else RouaColors.Loss
    val sideBg = if (isBuy) RouaColors.ProfitBackground else RouaColors.LossBackground

    Card(
        colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
        shape = RoundedCornerShape(12.dp),
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .border(1.dp, RouaColors.Border, RoundedCornerShape(12.dp))
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = position.symbol,
                        style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.SemiBold),
                        color = RouaColors.TextPrimary
                    )
                    Surface(
                        color = sideBg,
                        shape = RoundedCornerShape(4.dp)
                    ) {
                        Text(
                            text = position.side.uppercase(),
                            style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                            color = sideColor,
                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                        )
                    }
                    position.source?.let { src ->
                        Surface(
                            color = RouaColors.Glass,
                            shape = RoundedCornerShape(4.dp)
                        ) {
                            Text(
                                text = src,
                                style = MaterialTheme.typography.labelSmall,
                                color = RouaColors.TextSecondary,
                                modifier = Modifier.padding(horizontal = 5.dp, vertical = 2.dp)
                            )
                        }
                    }
                }
                Text(
                    text = "Qty: ${String.format("%.4f", position.quantity)}",
                    style = MonoTypography.Micro,
                    color = RouaColors.TextSecondary
                )
            }

            Column(
                horizontalAlignment = Alignment.End,
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                position.unrealizedPnl?.let { pnl ->
                    val pnlColor = when {
                        pnl > 0 -> RouaColors.Profit
                        pnl < 0 -> RouaColors.Loss
                        else -> RouaColors.TextSecondary
                    }
                    Text(
                        text = String.format("%s$%.2f", if (pnl >= 0) "+" else "", pnl),
                        style = MonoTypography.Small.copy(fontWeight = FontWeight.SemiBold),
                        color = pnlColor
                    )
                }
                Row(
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Column(horizontalAlignment = Alignment.End) {
                        Text(
                            text = "Entry",
                            style = MaterialTheme.typography.labelSmall,
                            color = RouaColors.TextSecondary
                        )
                        Text(
                            text = String.format("%.2f", position.entryPrice),
                            style = MonoTypography.Micro,
                            color = RouaColors.TextPrimary
                        )
                    }
                    position.currentPrice?.let { current ->
                        Column(horizontalAlignment = Alignment.End) {
                            Text(
                                text = "Now",
                                style = MaterialTheme.typography.labelSmall,
                                color = RouaColors.TextSecondary
                            )
                            Text(
                                text = String.format("%.2f", current),
                                style = MonoTypography.Micro,
                                color = RouaColors.TextPrimary
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun EmptyPositionsPlaceholder() {
    Card(
        colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
        shape = RoundedCornerShape(12.dp),
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .border(1.dp, RouaColors.Border, RoundedCornerShape(12.dp))
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = Icons.Filled.BarChart,
                contentDescription = "No positions",
                tint = RouaColors.TextMuted,
                modifier = Modifier.size(32.dp)
            )
            Spacer(Modifier.height(8.dp))
            Text(
                text = "No active positions",
                style = MaterialTheme.typography.bodyMedium,
                color = RouaColors.TextSecondary
            )
            Text(
                text = "Open a trade to get started",
                style = MaterialTheme.typography.bodySmall,
                color = RouaColors.TextMuted
            )
        }
    }
}

// ──────────────────────────────────────────────────────────────────────
// Shared UI components
// ──────────────────────────────────────────────────────────────────────

@Composable
private fun SectionHeader(title: String) {
    Text(
        text = title,
        style = MaterialTheme.typography.labelLarge.copy(
            fontWeight = FontWeight.SemiBold,
            fontSize = 13.sp
        ),
        color = RouaColors.TextSecondary,
        modifier = Modifier.padding(horizontal = 16.dp, vertical = 6.dp)
    )
}

// ──────────────────────────────────────────────────────────────────────
// Shimmer Loading State
// ──────────────────────────────────────────────────────────────────────

@Composable
private fun ShimmerDashboard() {
    val infiniteTransition = rememberInfiniteTransition(label = "shimmer")
    val shimmerAlpha by infiniteTransition.animateFloat(
        initialValue = 0.15f,
        targetValue = 0.35f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 800, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "shimmerAlpha"
    )
    val shimmerColor = RouaColors.TextPrimary.copy(alpha = shimmerAlpha)

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(0.dp)
    ) {
        // Ticker bar shimmer
        item {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(RouaColors.BackgroundLight)
                    .padding(vertical = 10.dp, horizontal = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(20.dp)
            ) {
                repeat(6) {
                    Box(
                        modifier = Modifier
                            .height(14.dp)
                            .width(80.dp)
                            .background(shimmerColor, RoundedCornerShape(4.dp))
                    )
                }
            }
        }

        item { Spacer(Modifier.height(12.dp)) }

        // Portfolio card shimmer
        item {
            Card(
                colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
            ) {
                Column(
                    modifier = Modifier.padding(20.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .height(12.dp)
                            .fillMaxWidth(0.35f)
                            .background(shimmerColor, RoundedCornerShape(4.dp))
                    )
                    Box(
                        modifier = Modifier
                            .height(32.dp)
                            .fillMaxWidth(0.6f)
                            .background(shimmerColor, RoundedCornerShape(4.dp))
                    )
                    Row(horizontalArrangement = Arrangement.spacedBy(24.dp)) {
                        repeat(3) {
                            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                                Box(
                                    modifier = Modifier
                                        .height(10.dp)
                                        .width(50.dp)
                                        .background(shimmerColor, RoundedCornerShape(4.dp))
                                )
                                Box(
                                    modifier = Modifier
                                        .height(14.dp)
                                        .width(60.dp)
                                        .background(shimmerColor, RoundedCornerShape(4.dp))
                                )
                            }
                        }
                    }
                }
            }
        }

        item { Spacer(Modifier.height(16.dp)) }

        // Market movers shimmer
        item {
            Box(
                modifier = Modifier
                    .padding(horizontal = 16.dp)
            ) {
                Box(
                    modifier = Modifier
                        .height(12.dp)
                        .width(100.dp)
                        .background(shimmerColor, RoundedCornerShape(4.dp))
                )
            }
        }
        item { Spacer(Modifier.height(6.dp)) }
        item {
            Row(
                modifier = Modifier.padding(horizontal = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                repeat(4) {
                    Card(
                        colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.width(130.dp)
                    ) {
                        Column(
                            modifier = Modifier.padding(12.dp),
                            verticalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Box(
                                modifier = Modifier
                                    .height(14.dp)
                                    .fillMaxWidth(0.6f)
                                    .background(shimmerColor, RoundedCornerShape(4.dp))
                            )
                            Box(
                                modifier = Modifier
                                    .height(12.dp)
                                    .fillMaxWidth(0.8f)
                                    .background(shimmerColor, RoundedCornerShape(4.dp))
                            )
                            Box(
                                modifier = Modifier
                                    .height(18.dp)
                                    .fillMaxWidth(0.5f)
                                    .background(shimmerColor, RoundedCornerShape(6.dp))
                            )
                        }
                    }
                }
            }
        }

        item { Spacer(Modifier.height(16.dp)) }

        // Quick actions shimmer
        item {
            Box(
                modifier = Modifier
                    .padding(horizontal = 16.dp)
            ) {
                Box(
                    modifier = Modifier
                        .height(12.dp)
                        .width(90.dp)
                        .background(shimmerColor, RoundedCornerShape(4.dp))
                )
            }
        }
        item { Spacer(Modifier.height(6.dp)) }
        item {
            Column(
                modifier = Modifier.padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    repeat(2) {
                        Card(
                            colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
                            shape = RoundedCornerShape(12.dp),
                            modifier = Modifier.weight(1f)
                        ) {
                            Column(
                                modifier = Modifier.padding(16.dp),
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                Box(
                                    modifier = Modifier
                                        .size(44.dp)
                                        .background(shimmerColor, RoundedCornerShape(10.dp))
                                )
                                Spacer(Modifier.height(8.dp))
                                Box(
                                    modifier = Modifier
                                        .height(12.dp)
                                        .width(60.dp)
                                        .background(shimmerColor, RoundedCornerShape(4.dp))
                                )
                            }
                        }
                    }
                }
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    repeat(2) {
                        Card(
                            colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
                            shape = RoundedCornerShape(12.dp),
                            modifier = Modifier.weight(1f)
                        ) {
                            Column(
                                modifier = Modifier.padding(16.dp),
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                Box(
                                    modifier = Modifier
                                        .size(44.dp)
                                        .background(shimmerColor, RoundedCornerShape(10.dp))
                                )
                                Spacer(Modifier.height(8.dp))
                                Box(
                                    modifier = Modifier
                                        .height(12.dp)
                                        .width(60.dp)
                                        .background(shimmerColor, RoundedCornerShape(4.dp))
                                )
                            }
                        }
                    }
                }
            }
        }

        item { Spacer(Modifier.height(16.dp)) }

        // Positions shimmer
        item {
            Box(
                modifier = Modifier
                    .padding(horizontal = 16.dp)
            ) {
                Box(
                    modifier = Modifier
                        .height(12.dp)
                        .width(110.dp)
                        .background(shimmerColor, RoundedCornerShape(4.dp))
                )
            }
        }
        item { Spacer(Modifier.height(6.dp)) }
        repeat(3) {
            item {
                Card(
                    colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(14.dp),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            Box(
                                modifier = Modifier
                                    .height(14.dp)
                                    .width(80.dp)
                                    .background(shimmerColor, RoundedCornerShape(4.dp))
                            )
                            Box(
                                modifier = Modifier
                                    .height(10.dp)
                                    .width(60.dp)
                                    .background(shimmerColor, RoundedCornerShape(4.dp))
                            )
                        }
                        Column(
                            horizontalAlignment = Alignment.End,
                            verticalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            Box(
                                modifier = Modifier
                                    .height(14.dp)
                                    .width(70.dp)
                                    .background(shimmerColor, RoundedCornerShape(4.dp))
                            )
                            Box(
                                modifier = Modifier
                                    .height(10.dp)
                                    .width(50.dp)
                                    .background(shimmerColor, RoundedCornerShape(4.dp))
                            )
                        }
                    }
                }
                Spacer(Modifier.height(8.dp))
            }
        }
    }
}
