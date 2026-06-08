package com.roua.trading.features.trading

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
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
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.roua.trading.core.network.model.Position
import com.roua.trading.core.network.model.Quote
import com.roua.trading.core.network.model.Trade
import com.roua.trading.design.theme.MonoTypography
import com.roua.trading.design.theme.RouaColors
import com.roua.trading.design.theme.getPnlColor
import com.roua.trading.design.theme.getPnlSign

// ══════════════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ══════════════════════════════════════════════════════════════════════════

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TradingScreen(viewModel: TradingViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsState()

    Box(modifier = Modifier.fillMaxSize().background(RouaColors.Background)) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
        ) {
            // 1. Symbol Header
            SymbolHeader(
                symbol = uiState.symbol,
                quote = uiState.currentQuote,
                onSymbolClick = { viewModel.showSymbolPicker() },
                onRefresh = { viewModel.refresh() }
            )

            // Scrollable content
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .weight(1f),
                contentPadding = PaddingValues(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                // 2. 24h Stats Row
                item {
                    StatsRow(quote = uiState.currentQuote)
                }

                // 3. Chart Area
                item {
                    ChartPlaceholder(
                        selectedTimeframe = uiState.selectedTimeframe,
                        onTimeframeSelect = { viewModel.selectTimeframe(it) }
                    )
                }

                // 5. Position Tabs
                item {
                    PositionTabSelector(
                        selectedTab = uiState.selectedPositionTab,
                        onTabSelect = { viewModel.selectPositionTab(it) }
                    )
                }

                // 6/7. Positions or Trades list
                if (uiState.selectedPositionTab == PositionTab.OPEN) {
                    if (uiState.positions.isEmpty()) {
                        item {
                            EmptyState(
                                icon = Icons.Filled.ShowChart,
                                message = "No open positions"
                            )
                        }
                    } else {
                        items(uiState.positions, key = { it.id }) { position ->
                            PositionCard(position = position)
                        }
                    }
                } else {
                    if (uiState.tradeHistory.isEmpty()) {
                        item {
                            EmptyState(
                                icon = Icons.Filled.History,
                                message = "No trade history"
                            )
                        }
                    } else {
                        items(uiState.tradeHistory, key = { it.id }) { trade ->
                            TradeCard(trade = trade)
                        }
                    }
                }

                // Bottom spacing for FAB overlap
                item { Spacer(Modifier.height(80.dp)) }
            }
        }

        // 8. Floating Action Buttons — Buy / Sell
        FloatingTradeButtons(
            onBuyClick = { viewModel.onBuyClick() },
            onSellClick = { viewModel.onSellClick() }
        )
    }

    // 9. Order Bottom Sheet
    if (uiState.showOrderSheet) {
        OrderBottomSheet(viewModel = viewModel)
    }

    // 10. Symbol Picker
    if (uiState.showSymbolPicker) {
        SymbolPickerDialog(viewModel = viewModel)
    }
}

// ══════════════════════════════════════════════════════════════════════════
// 1. SYMBOL HEADER
// ══════════════════════════════════════════════════════════════════════════

@Composable
fun SymbolHeader(
    symbol: String,
    quote: Quote?,
    onSymbolClick: () -> Unit,
    onRefresh: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(RouaColors.Card)
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        // Left: Symbol + Price
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            // Symbol with dropdown chevron
            Row(
                modifier = Modifier
                    .clip(RoundedCornerShape(8.dp))
                    .background(RouaColors.SurfaceElevated)
                    .clickable { onSymbolClick() }
                    .padding(horizontal = 10.dp, vertical = 6.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Text(
                    text = symbol.substringBefore("/"),
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    color = RouaColors.TextPrimary
                )
                Text(
                    text = "/${symbol.substringAfter("/")}",
                    style = MaterialTheme.typography.labelMedium,
                    color = RouaColors.TextSecondary
                )
                Icon(
                    Icons.Filled.KeyboardArrowDown,
                    contentDescription = "Select symbol",
                    tint = RouaColors.TextSecondary,
                    modifier = Modifier.size(18.dp)
                )
            }
        }

        // Right: Price + Change
        Column(horizontalAlignment = Alignment.End) {
            quote?.let { q ->
                Text(
                    text = formatPrice(q.last ?: 0.0),
                    style = MonoTypography.Large.copy(fontSize = 18.sp),
                    color = RouaColors.TextPrimary
                )
                val changePercent = q.changePercent ?: 0.0
                val isPositive = changePercent >= 0
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    ChangeBadge(
                        isPositive = isPositive,
                        text = "${getPnlSign(changePercent)}${String.format("%.2f", kotlin.math.abs(changePercent))}%"
                    )
                }
            } ?: run {
                Text(
                    "---",
                    style = MonoTypography.Large.copy(fontSize = 18.sp),
                    color = RouaColors.TextTertiary
                )
            }
        }
    }
}

@Composable
fun ChangeBadge(isPositive: Boolean, text: String) {
    val bgColor by animateColorAsState(
        targetValue = if (isPositive) RouaColors.ProfitBackground else RouaColors.LossBackground,
        label = "changeBg"
    )
    val textColor by animateColorAsState(
        targetValue = if (isPositive) RouaColors.Profit else RouaColors.Loss,
        label = "changeText"
    )

    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(6.dp))
            .background(bgColor)
            .padding(horizontal = 8.dp, vertical = 3.dp)
    ) {
        Text(
            text = text,
            style = MonoTypography.Small.copy(fontSize = 11.sp),
            color = textColor,
            fontWeight = FontWeight.SemiBold
        )
    }
}

// ══════════════════════════════════════════════════════════════════════════
// 2. 24H STATS ROW
// ══════════════════════════════════════════════════════════════════════════

@Composable
fun StatsRow(quote: Quote?) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        StatChip(
            label = "24h High",
            value = quote?.let { formatPrice(it.high ?: 0.0) } ?: "---",
            modifier = Modifier.weight(1f)
        )
        StatChip(
            label = "24h Low",
            value = quote?.let { formatPrice(it.low ?: 0.0) } ?: "---",
            modifier = Modifier.weight(1f)
        )
        StatChip(
            label = "Volume",
            value = quote?.let { formatVolume(it.volume ?: 0.0) } ?: "---",
            modifier = Modifier.weight(1f)
        )
        StatChip(
            label = "Change",
            value = quote?.let {
                val pct = it.changePercent ?: 0.0
                "${getPnlSign(pct)}${String.format("%.2f", kotlin.math.abs(pct))}%"
            } ?: "---",
            valueColor = quote?.changePercent?.let { getPnlColor(it) },
            modifier = Modifier.weight(1f)
        )
    }
}

@Composable
fun StatChip(
    label: String,
    value: String,
    modifier: Modifier = Modifier,
    valueColor: Color = RouaColors.TextPrimary
) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(10.dp))
            .background(RouaColors.Card)
            .border(1.dp, RouaColors.Border, RoundedCornerShape(10.dp))
            .padding(horizontal = 10.dp, vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(2.dp)
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = RouaColors.TextTertiary,
            fontSize = 10.sp
        )
        Text(
            text = value,
            style = MonoTypography.Small.copy(fontSize = 11.sp),
            color = valueColor
        )
    }
}

// ══════════════════════════════════════════════════════════════════════════
// 3. CHART AREA + 4. TIMEFRAME SELECTOR
// ══════════════════════════════════════════════════════════════════════════

@Composable
fun ChartPlaceholder(
    selectedTimeframe: String,
    onTimeframeSelect: (String) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(RouaColors.Card)
            .border(1.dp, RouaColors.Border, RoundedCornerShape(12.dp))
    ) {
        // Chart area placeholder
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(200.dp)
                .padding(16.dp),
            contentAlignment = Alignment.Center
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Icon(
                    Icons.Filled.AutoGraph,
                    contentDescription = null,
                    tint = RouaColors.TextTertiary.copy(alpha = 0.5f),
                    modifier = Modifier.size(40.dp)
                )
                Text(
                    "Chart will load here",
                    style = MaterialTheme.typography.bodyMedium,
                    color = RouaColors.TextTertiary,
                    fontWeight = FontWeight.Medium
                )
                Text(
                    "Real-time candlestick data",
                    style = MaterialTheme.typography.labelSmall,
                    color = RouaColors.TextMuted
                )
            }
        }

        // Decorative gradient line
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(1.dp)
                .background(
                    Brush.horizontalGradient(
                        colors = listOf(
                            Color.Transparent,
                            RouaColors.Cyan.copy(alpha = 0.3f),
                            RouaColors.Brand.copy(alpha = 0.3f),
                            Color.Transparent
                        )
                    )
                )
        )

        // 4. Timeframe Selector
        TimeframeSelector(
            selectedTimeframe = selectedTimeframe,
            onTimeframeSelect = onTimeframeSelect
        )
    }
}

@Composable
fun TimeframeSelector(
    selectedTimeframe: String,
    onTimeframeSelect: (String) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 8.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        TIMEFRAMES.forEach { tf ->
            val isSelected = tf == selectedTimeframe
            val bgColor by animateColorAsState(
                targetValue = if (isSelected) RouaColors.Accent.copy(alpha = 0.2f) else Color.Transparent,
                label = "tfBg"
            )
            val textColor by animateColorAsState(
                targetValue = if (isSelected) RouaColors.AccentLight else RouaColors.TextTertiary,
                label = "tfText"
            )
            val borderColor by animateColorAsState(
                targetValue = if (isSelected) RouaColors.BorderAccent else Color.Transparent,
                label = "tfBorder"
            )

            Box(
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(8.dp))
                    .background(bgColor)
                    .border(1.dp, borderColor, RoundedCornerShape(8.dp))
                    .clickable { onTimeframeSelect(tf) }
                    .padding(vertical = 8.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = tf,
                    style = MaterialTheme.typography.labelMedium.copy(
                        fontSize = 12.sp,
                        fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal
                    ),
                    color = textColor
                )
            }
        }
    }
}

// ══════════════════════════════════════════════════════════════════════════
// 5. POSITION TABS
// ══════════════════════════════════════════════════════════════════════════

@Composable
fun PositionTabSelector(
    selectedTab: PositionTab,
    onTabSelect: (PositionTab) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(10.dp))
            .background(RouaColors.Card)
            .border(1.dp, RouaColors.Border, RoundedCornerShape(10.dp))
            .padding(4.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        PositionTab.values().forEach { tab ->
            val isSelected = tab == selectedTab
            val bgColor by animateColorAsState(
                targetValue = if (isSelected) RouaColors.SurfaceElevated else Color.Transparent,
                label = "tabBg"
            )
            val textColor by animateColorAsState(
                targetValue = if (isSelected) RouaColors.TextPrimary else RouaColors.TextSecondary,
                label = "tabText"
            )

            Row(
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(8.dp))
                    .background(bgColor)
                    .clickable { onTabSelect(tab) }
                    .padding(vertical = 10.dp),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = when (tab) {
                        PositionTab.OPEN -> "Open"
                        PositionTab.CLOSED -> "Closed"
                    },
                    style = MaterialTheme.typography.labelLarge.copy(
                        fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Medium
                    ),
                    color = textColor
                )
            }
        }
    }
}

// ══════════════════════════════════════════════════════════════════════════
// 6. POSITION CARD
// ══════════════════════════════════════════════════════════════════════════

@Composable
fun PositionCard(position: Position) {
    val isBuy = position.side.equals("BUY", ignoreCase = true)
    val sideColor = if (isBuy) RouaColors.Profit else RouaColors.Loss
    val pnlColor = position.unrealizedPnl?.let { getPnlColor(it) } ?: RouaColors.TextSecondary

    Card(
        colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
        shape = RoundedCornerShape(12.dp),
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, RouaColors.Border, RoundedCornerShape(12.dp))
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Side indicator bar
            Box(
                modifier = Modifier
                    .width(3.dp)
                    .height(44.dp)
                    .clip(RoundedCornerShape(2.dp))
                    .background(sideColor)
            )

            Spacer(Modifier.width(12.dp))

            // Symbol + Side
            Column(modifier = Modifier.weight(1f)) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Text(
                        text = position.symbol,
                        style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.SemiBold),
                        color = RouaColors.TextPrimary
                    )
                    // Side badge
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(4.dp))
                            .background(sideColor.copy(alpha = 0.15f))
                            .padding(horizontal = 6.dp, vertical = 2.dp)
                    ) {
                        Text(
                            text = position.side.uppercase(),
                            style = MaterialTheme.typography.labelSmall.copy(
                                fontSize = 9.sp,
                                fontWeight = FontWeight.Bold
                            ),
                            color = sideColor
                        )
                    }
                }
                Spacer(Modifier.height(4.dp))
                Row(
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Text(
                        text = "Qty: ${formatQuantity(position.quantity)}",
                        style = MonoTypography.Micro,
                        color = RouaColors.TextTertiary
                    )
                    Text(
                        text = "Entry: ${formatPrice(position.entryPrice)}",
                        style = MonoTypography.Micro,
                        color = RouaColors.TextTertiary
                    )
                }
            }

            // Unrealized PnL
            Column(horizontalAlignment = Alignment.End) {
                position.unrealizedPnl?.let { pnl ->
                    Text(
                        text = "${getPnlSign(pnl)}${String.format("%.2f", kotlin.math.abs(pnl))}",
                        style = MonoTypography.Medium.copy(fontSize = 14.sp),
                        color = pnlColor,
                        fontWeight = FontWeight.Bold
                    )
                }
                position.currentPrice?.let { cur ->
                    Text(
                        text = formatPrice(cur),
                        style = MonoTypography.Micro,
                        color = RouaColors.TextTertiary
                    )
                }
            }
        }
    }
}

// ══════════════════════════════════════════════════════════════════════════
// 7. TRADE CARD (Closed)
// ══════════════════════════════════════════════════════════════════════════

@Composable
fun TradeCard(trade: Trade) {
    val isBuy = trade.side.equals("BUY", ignoreCase = true)
    val sideColor = if (isBuy) RouaColors.Profit else RouaColors.Loss
    val pnlColor = trade.pnl?.let { getPnlColor(it) } ?: RouaColors.TextSecondary

    Card(
        colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
        shape = RoundedCornerShape(12.dp),
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, RouaColors.Border, RoundedCornerShape(12.dp))
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Side indicator
            Box(
                modifier = Modifier
                    .width(3.dp)
                    .height(40.dp)
                    .clip(RoundedCornerShape(2.dp))
                    .background(sideColor.copy(alpha = 0.6f))
            )

            Spacer(Modifier.width(12.dp))

            // Symbol + info
            Column(modifier = Modifier.weight(1f)) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Text(
                        text = trade.symbol,
                        style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.SemiBold),
                        color = RouaColors.TextPrimary
                    )
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(4.dp))
                            .background(sideColor.copy(alpha = 0.15f))
                            .padding(horizontal = 6.dp, vertical = 2.dp)
                    ) {
                        Text(
                            text = trade.side.uppercase(),
                            style = MaterialTheme.typography.labelSmall.copy(
                                fontSize = 9.sp,
                                fontWeight = FontWeight.Bold
                            ),
                            color = sideColor
                        )
                    }
                }
                Spacer(Modifier.height(2.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(
                        text = "${formatQuantity(trade.quantity)} @ ${formatPrice(trade.price)}",
                        style = MonoTypography.Micro,
                        color = RouaColors.TextTertiary
                    )
                }
            }

            // Realized PnL
            Column(horizontalAlignment = Alignment.End) {
                trade.pnl?.let { pnl ->
                    Text(
                        text = "${getPnlSign(pnl)}${String.format("%.2f", kotlin.math.abs(pnl))}",
                        style = MonoTypography.Medium.copy(fontSize = 14.sp),
                        color = pnlColor,
                        fontWeight = FontWeight.Bold
                    )
                } ?: run {
                    Text(
                        text = "---",
                        style = MonoTypography.Medium.copy(fontSize = 14.sp),
                        color = RouaColors.TextTertiary
                    )
                }
                Text(
                    text = trade.type.lowercase().replaceFirstChar { it.uppercase() },
                    style = MaterialTheme.typography.labelSmall,
                    color = RouaColors.TextMuted
                )
            }
        }
    }
}

// ══════════════════════════════════════════════════════════════════════════
// 8. FLOATING TRADE BUTTONS
// ══════════════════════════════════════════════════════════════════════════

@Composable
fun FloatingTradeButtons(
    onBuyClick: () -> Unit,
    onSellClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 16.dp)
            .navigationBarsPadding(),
        contentAlignment = Alignment.BottomCenter
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(14.dp))
                .background(RouaColors.NavGlass)
                .border(1.dp, RouaColors.Border, RoundedCornerShape(14.dp))
                .padding(horizontal = 6.dp, vertical = 6.dp),
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            // Buy button
            Button(
                onClick = onBuyClick,
                modifier = Modifier.weight(1f),
                colors = ButtonDefaults.buttonColors(
                    containerColor = RouaColors.Profit,
                    contentColor = Color.White
                ),
                shape = RoundedCornerShape(10.dp),
                contentPadding = PaddingValues(vertical = 14.dp)
            ) {
                Icon(
                    Icons.Filled.TrendingUp,
                    contentDescription = null,
                    modifier = Modifier.size(18.dp)
                )
                Spacer(Modifier.width(6.dp))
                Text(
                    "Buy",
                    style = MaterialTheme.typography.labelLarge.copy(
                        fontWeight = FontWeight.Bold
                    )
                )
            }

            // Sell button
            Button(
                onClick = onSellClick,
                modifier = Modifier.weight(1f),
                colors = ButtonDefaults.buttonColors(
                    containerColor = RouaColors.Loss,
                    contentColor = Color.White
                ),
                shape = RoundedCornerShape(10.dp),
                contentPadding = PaddingValues(vertical = 14.dp)
            ) {
                Icon(
                    Icons.Filled.TrendingDown,
                    contentDescription = null,
                    modifier = Modifier.size(18.dp)
                )
                Spacer(Modifier.width(6.dp))
                Text(
                    "Sell",
                    style = MaterialTheme.typography.labelLarge.copy(
                        fontWeight = FontWeight.Bold
                    )
                )
            }
        }
    }
}

// ══════════════════════════════════════════════════════════════════════════
// 9. ORDER BOTTOM SHEET
// ══════════════════════════════════════════════════════════════════════════

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun OrderBottomSheet(viewModel: TradingViewModel) {
    val uiState by viewModel.uiState.collectAsState()

    ModalBottomSheet(
        onDismissRequest = { viewModel.hideOrderSheet() },
        containerColor = RouaColors.Card,
        shape = RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp),
        dragHandle = {
            Box(
                modifier = Modifier
                    .padding(vertical = 10.dp)
                    .width(40.dp)
                    .height(4.dp)
                    .clip(RoundedCornerShape(2.dp))
                    .background(RouaColors.TextTertiary.copy(alpha = 0.3f))
            )
        }
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp)
                .padding(bottom = 32.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Header: Symbol + Side Toggle
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    "${uiState.symbol} Order",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    color = RouaColors.TextPrimary
                )
                // Side Toggle
                Row(
                    modifier = Modifier
                        .clip(RoundedCornerShape(8.dp))
                        .background(RouaColors.SurfaceElevated)
                        .border(1.dp, RouaColors.Border, RoundedCornerShape(8.dp))
                ) {
                    OrderSide.values().forEach { side ->
                        val isSelected = side == uiState.orderSide
                        val bgColor by animateColorAsState(
                            targetValue = if (isSelected) {
                                if (side == OrderSide.BUY) RouaColors.Profit.copy(alpha = 0.2f)
                                else RouaColors.Loss.copy(alpha = 0.2f)
                            } else Color.Transparent,
                            label = "sideBg"
                        )
                        val textColor by animateColorAsState(
                            targetValue = if (isSelected) {
                                if (side == OrderSide.BUY) RouaColors.Profit else RouaColors.Loss
                            } else RouaColors.TextSecondary,
                            label = "sideText"
                        )

                        Box(
                            modifier = Modifier
                                .clip(RoundedCornerShape(6.dp))
                                .background(bgColor)
                                .clickable { viewModel.setOrderSide(side) }
                                .padding(horizontal = 16.dp, vertical = 8.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = side.name,
                                style = MaterialTheme.typography.labelLarge.copy(
                                    fontWeight = FontWeight.SemiBold
                                ),
                                color = textColor
                            )
                        }
                    }
                }
            }

            // Order Type Toggle
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(8.dp))
                    .background(RouaColors.SurfaceElevated)
                    .border(1.dp, RouaColors.Border, RoundedCornerShape(8.dp))
                    .padding(3.dp),
                horizontalArrangement = Arrangement.spacedBy(3.dp)
            ) {
                OrderType.values().forEach { type ->
                    val isSelected = type == uiState.orderType
                    val bgColor by animateColorAsState(
                        targetValue = if (isSelected) RouaColors.Accent.copy(alpha = 0.15f) else Color.Transparent,
                        label = "typeBg"
                    )
                    val textColor by animateColorAsState(
                        targetValue = if (isSelected) RouaColors.AccentLight else RouaColors.TextSecondary,
                        label = "typeText"
                    )

                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .clip(RoundedCornerShape(6.dp))
                            .background(bgColor)
                            .clickable { viewModel.setOrderType(type) }
                            .padding(vertical = 10.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = type.name,
                            style = MaterialTheme.typography.labelLarge.copy(
                                fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal
                            ),
                            color = textColor
                        )
                    }
                }
            }

            // Quantity Input with +/- Buttons
            OrderInputRow(label = "Quantity") {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    // Minus button
                    Box(
                        modifier = Modifier
                            .size(36.dp)
                            .clip(RoundedCornerShape(8.dp))
                            .background(RouaColors.SurfaceElevated)
                            .border(1.dp, RouaColors.Border, RoundedCornerShape(8.dp))
                            .clickable { viewModel.decrementQuantity() },
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(Icons.Filled.Remove, contentDescription = "Decrease", tint = RouaColors.TextSecondary, modifier = Modifier.size(16.dp))
                    }

                    // Quantity field
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .clip(RoundedCornerShape(8.dp))
                            .background(RouaColors.SurfaceElevated)
                            .border(1.dp, RouaColors.Border, RoundedCornerShape(8.dp))
                            .padding(horizontal = 12.dp, vertical = 10.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        BasicTextField(
                            value = TextFieldValue(uiState.orderQuantity),
                            onValueChange = { viewModel.onQuantityChange(it.text) },
                            textStyle = MonoTypography.Medium.copy(
                                color = RouaColors.TextPrimary,
                                textAlign = TextAlign.Center
                            ),
                            singleLine = true
                        )
                    }

                    // Plus button
                    Box(
                        modifier = Modifier
                            .size(36.dp)
                            .clip(RoundedCornerShape(8.dp))
                            .background(RouaColors.SurfaceElevated)
                            .border(1.dp, RouaColors.Border, RoundedCornerShape(8.dp))
                            .clickable { viewModel.incrementQuantity() },
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(Icons.Filled.Add, contentDescription = "Increase", tint = RouaColors.TextSecondary, modifier = Modifier.size(16.dp))
                    }
                }
            }

            // Limit Price (only for Limit orders)
            if (uiState.orderType == OrderType.LIMIT) {
                OrderInputRow(label = "Limit Price") {
                    OrderTextField(
                        value = uiState.orderLimitPrice,
                        onValueChange = { viewModel.onLimitPriceChange(it) },
                        placeholder = "0.00"
                    )
                }
            }

            // Stop Loss
            OrderInputRow(label = "Stop Loss") {
                OrderTextField(
                    value = uiState.orderStopLoss,
                    onValueChange = { viewModel.onStopLossChange(it) },
                    placeholder = "0.00 (optional)"
                )
            }

            // Take Profit
            OrderInputRow(label = "Take Profit") {
                OrderTextField(
                    value = uiState.orderTakeProfit,
                    onValueChange = { viewModel.onTakeProfitChange(it) },
                    placeholder = "0.00 (optional)"
                )
            }

            // Order Summary
            val estimatedTotal = viewModel.getEstimatedTotal()
            Card(
                colors = CardDefaults.cardColors(containerColor = RouaColors.SurfaceElevated),
                shape = RoundedCornerShape(10.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 14.dp, vertical = 12.dp),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        "Estimated Total",
                        style = MaterialTheme.typography.labelLarge,
                        color = RouaColors.TextSecondary
                    )
                    Text(
                        if (estimatedTotal > 0) "$${String.format("%.2f", estimatedTotal)}" else "---",
                        style = MonoTypography.Medium.copy(fontSize = 14.sp),
                        color = RouaColors.TextPrimary,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }

            // Error message
            uiState.orderError?.let { error ->
                Text(
                    text = error,
                    style = MaterialTheme.typography.labelMedium,
                    color = RouaColors.Danger
                )
            }

            // Confirm Button
            val confirmColor = when (uiState.orderSide) {
                OrderSide.BUY -> RouaColors.Profit
                OrderSide.SELL -> RouaColors.Loss
            }

            Button(
                onClick = { viewModel.placeOrder() },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp),
                colors = ButtonDefaults.buttonColors(containerColor = confirmColor),
                shape = RoundedCornerShape(12.dp),
                enabled = !uiState.isPlacingOrder
            ) {
                if (uiState.isPlacingOrder) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        color = Color.White,
                        strokeWidth = 2.dp
                    )
                } else {
                    Icon(
                        if (uiState.orderSide == OrderSide.BUY) Icons.Filled.TrendingUp else Icons.Filled.TrendingDown,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(Modifier.width(8.dp))
                    Text(
                        "Confirm ${uiState.orderSide.name} ${uiState.orderType.name}",
                        style = MaterialTheme.typography.labelLarge.copy(
                            fontWeight = FontWeight.Bold
                        )
                    )
                }
            }
        }
    }
}

@Composable
fun OrderInputRow(label: String, content: @Composable () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(
            text = label,
            style = MaterialTheme.typography.labelMedium,
            color = RouaColors.TextSecondary,
            fontWeight = FontWeight.Medium
        )
        content()
    }
}

@Composable
fun OrderTextField(
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String = "0.00"
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp))
            .background(RouaColors.SurfaceElevated)
            .border(1.dp, RouaColors.Border, RoundedCornerShape(8.dp))
            .padding(horizontal = 14.dp, vertical = 12.dp)
    ) {
        if (value.isEmpty()) {
            Text(
                text = placeholder,
                style = MonoTypography.Small,
                color = RouaColors.TextMuted
            )
        }
        BasicTextField(
            value = TextFieldValue(value),
            onValueChange = { onValueChange(it.text) },
            textStyle = MonoTypography.Small.copy(color = RouaColors.TextPrimary),
            singleLine = true
        )
    }
}

// ══════════════════════════════════════════════════════════════════════════
// 10. SYMBOL PICKER DIALOG
// ══════════════════════════════════════════════════════════════════════════

@Composable
fun SymbolPickerDialog(viewModel: TradingViewModel) {
    val uiState by viewModel.uiState.collectAsState()

    val filteredSymbols = remember(uiState.symbolSearchQuery) {
        if (uiState.symbolSearchQuery.isBlank()) {
            POPULAR_SYMBOLS
        } else {
            POPULAR_SYMBOLS.filter {
                it.display.contains(uiState.symbolSearchQuery, ignoreCase = true) ||
                it.name.contains(uiState.symbolSearchQuery, ignoreCase = true) ||
                it.symbol.contains(uiState.symbolSearchQuery, ignoreCase = true)
            }
        }
    }

    AlertDialog(
        onDismissRequest = { viewModel.hideSymbolPicker() },
        containerColor = RouaColors.Card,
        shape = RoundedCornerShape(16.dp),
        title = {
            Text(
                "Select Symbol",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color = RouaColors.TextPrimary
            )
        },
        text = {
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                // Search field
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(10.dp))
                        .background(RouaColors.SurfaceElevated)
                        .border(1.dp, RouaColors.Border, RoundedCornerShape(10.dp))
                        .padding(horizontal = 14.dp, vertical = 12.dp)
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(
                            Icons.Filled.Search,
                            contentDescription = null,
                            tint = RouaColors.TextTertiary,
                            modifier = Modifier.size(18.dp)
                        )
                        Box(modifier = Modifier.weight(1f)) {
                            if (uiState.symbolSearchQuery.isEmpty()) {
                                Text(
                                    "Search symbols...",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = RouaColors.TextMuted
                                )
                            }
                            BasicTextField(
                                value = TextFieldValue(uiState.symbolSearchQuery),
                                onValueChange = { viewModel.onSymbolSearchQueryChange(it.text) },
                                textStyle = MaterialTheme.typography.bodyMedium.copy(
                                    color = RouaColors.TextPrimary
                                ),
                                singleLine = true
                            )
                        }
                    }
                }

                // Popular label
                Text(
                    "Popular",
                    style = MaterialTheme.typography.labelMedium,
                    color = RouaColors.TextTertiary,
                    fontWeight = FontWeight.SemiBold
                )

                // Symbol grid
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    filteredSymbols.chunked(2).forEach { row ->
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            row.forEach { item ->
                                val isSelected = item.symbol == uiState.symbol
                                val bgColor by animateColorAsState(
                                    targetValue = if (isSelected) RouaColors.Accent.copy(alpha = 0.15f) else RouaColors.SurfaceElevated,
                                    label = "symBg"
                                )
                                val borderColor by animateColorAsState(
                                    targetValue = if (isSelected) RouaColors.BorderAccent else RouaColors.Border,
                                    label = "symBorder"
                                )

                                Column(
                                    modifier = Modifier
                                        .weight(1f)
                                        .clip(RoundedCornerShape(10.dp))
                                        .background(bgColor)
                                        .border(1.dp, borderColor, RoundedCornerShape(10.dp))
                                        .clickable { viewModel.selectSymbol(item.symbol) }
                                        .padding(horizontal = 12.dp, vertical = 10.dp),
                                    horizontalAlignment = Alignment.Start
                                ) {
                                    Text(
                                        text = item.display,
                                        style = MaterialTheme.typography.labelLarge.copy(
                                            fontWeight = FontWeight.Bold
                                        ),
                                        color = if (isSelected) RouaColors.AccentLight else RouaColors.TextPrimary
                                    )
                                    Text(
                                        text = item.name,
                                        style = MaterialTheme.typography.labelSmall,
                                        color = RouaColors.TextTertiary,
                                        fontSize = 10.sp
                                    )
                                }
                            }
                            // Fill remaining space if odd number
                            if (row.size < 2) {
                                Spacer(Modifier.weight(1f))
                            }
                        }
                    }

                    if (filteredSymbols.isEmpty()) {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 20.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                "No symbols found",
                                style = MaterialTheme.typography.bodyMedium,
                                color = RouaColors.TextTertiary
                            )
                        }
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = { viewModel.hideSymbolPicker() }) {
                Text("Cancel", color = RouaColors.TextSecondary)
            }
        }
    )
}

// ══════════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ══════════════════════════════════════════════════════════════════════════

@Composable
fun EmptyState(icon: ImageVector, message: String) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 32.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Icon(
                icon,
                contentDescription = null,
                tint = RouaColors.TextTertiary.copy(alpha = 0.4f),
                modifier = Modifier.size(36.dp)
            )
            Text(
                message,
                style = MaterialTheme.typography.bodyMedium,
                color = RouaColors.TextTertiary
            )
        }
    }
}

// ══════════════════════════════════════════════════════════════════════════
// FORMATTING HELPERS
// ══════════════════════════════════════════════════════════════════════════

fun formatPrice(price: Double): String {
    return when {
        price >= 10000.0 -> String.format("$%,.0f", price)
        price >= 100.0 -> String.format("$%,.2f", price)
        price >= 1.0 -> String.format("$%.4f", price)
        else -> String.format("$%.6f", price)
    }
}

fun formatVolume(volume: Double): String {
    return when {
        volume >= 1_000_000_000 -> String.format("%.1fB", volume / 1_000_000_000)
        volume >= 1_000_000 -> String.format("%.1fM", volume / 1_000_000)
        volume >= 1_000 -> String.format("%.1fK", volume / 1_000)
        else -> String.format("%.0f", volume)
    }
}

fun formatQuantity(qty: Double): String {
    return when {
        qty >= 100.0 -> String.format("%.1f", qty)
        qty >= 1.0 -> String.format("%.2f", qty)
        qty >= 0.01 -> String.format("%.4f", qty)
        else -> String.format("%.6f", qty)
    }
}
