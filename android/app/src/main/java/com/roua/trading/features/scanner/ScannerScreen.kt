package com.roua.trading.features.scanner

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.roua.trading.core.network.model.HeatmapItem
import com.roua.trading.core.network.model.NewsArticle
import com.roua.trading.core.network.model.ScanResult
import com.roua.trading.design.theme.MonoTypography
import com.roua.trading.design.theme.RouaColors

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ScannerScreen(viewModel: ScannerViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(RouaColors.Background)
    ) {
        // Header
        Text(
            "Market Scanner",
            style = MaterialTheme.typography.headlineMedium,
            color = RouaColors.TextPrimary,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(start = 16.dp, end = 16.dp, top = 16.dp, bottom = 8.dp)
        )

        // Tab Selector
        ScannerTabSelector(
            selectedTab = uiState.selectedTab,
            onTabSelected = { viewModel.selectTab(it) }
        )

        Spacer(Modifier.height(12.dp))

        // Tab Content
        when (uiState.selectedTab) {
            ScannerTab.SCANNER -> ScannerTabContent(uiState, viewModel)
            ScannerTab.HEATMAP -> HeatmapTabContent(uiState, viewModel)
            ScannerTab.NEWS -> NewsTabContent(uiState, viewModel)
        }
    }
}

// ═══════════════════════════════════════════════
// TAB SELECTOR
// ═══════════════════════════════════════════════

@Composable
fun ScannerTabSelector(
    selectedTab: ScannerTab,
    onTabSelected: (ScannerTab) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        ScannerTab.entries.forEach { tab ->
            val isSelected = tab == selectedTab
            Surface(
                shape = RoundedCornerShape(20.dp),
                color = if (isSelected) RouaColors.Accent.copy(alpha = 0.15f) else Color.Transparent,
                border = if (isSelected) {
                    ButtonDefaults.outlinedButtonBorder(enabled = true).copy(
                        brush = androidx.compose.ui.graphics.Brush.linearGradient(
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
// SCANNER TAB
// ═══════════════════════════════════════════════

@Composable
fun ScannerTabContent(uiState: ScannerUiState, viewModel: ScannerViewModel) {
    Column(modifier = Modifier.fillMaxSize()) {
        // Timeframe Selector
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 4.dp),
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            listOf("5m", "15m", "1h", "4h", "1d").forEach { tf ->
                val isSelected = uiState.selectedTimeframe == tf
                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = if (isSelected) RouaColors.Cyan.copy(alpha = 0.15f) else RouaColors.Card,
                    modifier = Modifier.clickable { viewModel.selectTimeframe(tf) }
                ) {
                    Text(
                        tf,
                        style = MaterialTheme.typography.labelSmall,
                        color = if (isSelected) RouaColors.Cyan else RouaColors.TextTertiary,
                        fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp)
                    )
                }
            }
        }

        Spacer(Modifier.height(6.dp))

        // Category Filter Chips
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            listOf("ALL", "CRYPTO", "FOREX", "STOCK").forEach { cat ->
                val isSelected = uiState.selectedCategory == cat
                FilterChip(
                    selected = isSelected,
                    onClick = { viewModel.selectCategory(cat) },
                    label = {
                        Text(
                            cat,
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                        )
                    },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = RouaColors.Accent.copy(alpha = 0.2f),
                        selectedLabelColor = RouaColors.TextPrimary,
                        containerColor = RouaColors.Card,
                        labelColor = RouaColors.TextSecondary
                    ),
                    border = FilterChipDefaults.filterChipBorder(
                        borderColor = RouaColors.Border,
                        selectedBorderColor = RouaColors.Accent.copy(alpha = 0.4f),
                        enabled = true,
                        selected = isSelected
                    ),
                    shape = RoundedCornerShape(8.dp)
                )
            }
        }

        Spacer(Modifier.height(8.dp))

        // Results List
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(uiState.results) { result ->
                ScanResultCard(result)
            }

            if (uiState.results.isEmpty() && !uiState.isLoading) {
                item {
                    Card(
                        colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text(
                            "No scan results. Try adjusting filters.",
                            style = MaterialTheme.typography.bodySmall,
                            color = RouaColors.TextTertiary,
                            modifier = Modifier.padding(20.dp),
                            textAlign = TextAlign.Center
                        )
                    }
                }
            }

            if (uiState.isLoading) {
                item {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(20.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(24.dp),
                            strokeWidth = 2.dp,
                            color = RouaColors.Accent
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun ScanResultCard(result: ScanResult) {
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
                Column {
                    Text(result.symbol, style = MaterialTheme.typography.labelLarge, color = RouaColors.TextPrimary)
                    result.name?.let {
                        Text(
                            it,
                            style = MaterialTheme.typography.bodySmall,
                            color = RouaColors.TextTertiary,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                }
                Column(horizontalAlignment = Alignment.End) {
                    Text(
                        String.format("%.2f", result.price),
                        style = MonoTypography.Small,
                        color = RouaColors.TextPrimary
                    )
                    Text(
                        String.format("%+.2f%%", result.changePercent),
                        style = MonoTypography.Micro,
                        color = if (result.changePercent >= 0) RouaColors.Profit else RouaColors.Loss
                    )
                }
            }

            // Signal Strength Bar
            val strength = result.strength?.toFloat() ?: 0f
            if (strength > 0f) {
                Spacer(Modifier.height(8.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    val signalColor = when {
                        strength >= 70f -> RouaColors.Profit
                        strength >= 40f -> RouaColors.Warning
                        else -> RouaColors.Loss
                    }
                    val signalLabel = result.signal ?: "NEUTRAL"

                    Surface(
                        shape = RoundedCornerShape(4.dp),
                        color = signalColor.copy(alpha = 0.15f)
                    ) {
                        Text(
                            signalLabel.uppercase(),
                            style = MaterialTheme.typography.labelSmall,
                            color = signalColor,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                        )
                    }
                    Spacer(Modifier.weight(1f))
                    Text(
                        String.format("%.0f%%", strength),
                        style = MonoTypography.Micro,
                        color = signalColor
                    )
                }
                Spacer(Modifier.height(4.dp))
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(4.dp)
                        .clip(RoundedCornerShape(2.dp))
                        .background(RouaColors.BackgroundLight)
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxHeight()
                            .fillMaxWidth((strength / 100f).coerceIn(0f, 1f))
                            .clip(RoundedCornerShape(2.dp))
                            .background(signalColor)
                    )
                }
            }
        }
    }
}

// ═══════════════════════════════════════════════
// HEATMAP TAB
// ═══════════════════════════════════════════════

@Composable
fun HeatmapTabContent(uiState: ScannerUiState, viewModel: ScannerViewModel) {
    Column(modifier = Modifier.fillMaxSize()) {
        // Category Filter
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 4.dp),
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            listOf("ALL", "CRYPTO", "FOREX", "STOCK").forEach { cat ->
                val isSelected = uiState.heatmapCategory == cat
                FilterChip(
                    selected = isSelected,
                    onClick = { viewModel.setHeatmapCategory(cat) },
                    label = { Text(cat, style = MaterialTheme.typography.labelSmall) },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = RouaColors.Accent.copy(alpha = 0.2f),
                        selectedLabelColor = RouaColors.TextPrimary,
                        containerColor = RouaColors.Card,
                        labelColor = RouaColors.TextSecondary
                    ),
                    shape = RoundedCornerShape(8.dp)
                )
            }
        }

        Spacer(Modifier.height(8.dp))

        // Heatmap Grid
        if (uiState.heatmapItems.isNotEmpty()) {
            val maxVolume = uiState.heatmapItems.maxOfOrNull { it.volume ?: 0.0 } ?: 1.0

            LazyVerticalGrid(
                columns = GridCells.Fixed(3),
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(4.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                items(uiState.heatmapItems) { item ->
                    HeatmapCell(item, maxVolume)
                }
            }
        } else {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    "No heatmap data available",
                    style = MaterialTheme.typography.bodySmall,
                    color = RouaColors.TextTertiary
                )
            }
        }
    }
}

@Composable
fun HeatmapCell(item: HeatmapItem, maxVolume: Double) {
    val volumeRatio = ((item.volume ?: 0.0) / maxVolume).coerceIn(0.2, 1.0)
    val cellHeight = (40 + (volumeRatio * 40)).dp

    val bgColor = when {
        item.change >= 5 -> RouaColors.Profit.copy(alpha = 0.6f)
        item.change >= 2 -> RouaColors.Profit.copy(alpha = 0.35f)
        item.change >= 0 -> RouaColors.Profit.copy(alpha = 0.15f)
        item.change > -2 -> RouaColors.Loss.copy(alpha = 0.15f)
        item.change > -5 -> RouaColors.Loss.copy(alpha = 0.35f)
        else -> RouaColors.Loss.copy(alpha = 0.6f)
    }

    Surface(
        shape = RoundedCornerShape(6.dp),
        color = bgColor,
        modifier = Modifier.height(cellHeight)
    ) {
        Column(
            modifier = Modifier.padding(4.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                item.symbol,
                style = MaterialTheme.typography.labelSmall,
                color = RouaColors.TextPrimary,
                fontWeight = FontWeight.Bold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Text(
                String.format("%+.1f%%", item.change),
                style = MonoTypography.Micro,
                color = RouaColors.TextPrimary
            )
        }
    }
}

// ═══════════════════════════════════════════════
// NEWS TAB
// ═══════════════════════════════════════════════

@Composable
fun NewsTabContent(uiState: ScannerUiState, viewModel: ScannerViewModel) {
    val filteredNews = viewModel.filteredNews()

    Column(modifier = Modifier.fillMaxSize()) {
        // Sentiment Filter
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 4.dp),
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            SentimentFilter.entries.forEach { filter ->
                val isSelected = uiState.sentimentFilter == filter
                val chipColor = when (filter) {
                    SentimentFilter.ALL -> RouaColors.Cyan
                    SentimentFilter.POSITIVE -> RouaColors.Profit
                    SentimentFilter.NEGATIVE -> RouaColors.Loss
                    SentimentFilter.NEUTRAL -> RouaColors.TextSecondary
                }
                FilterChip(
                    selected = isSelected,
                    onClick = { viewModel.setSentimentFilter(filter) },
                    label = {
                        Text(
                            filter.label,
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                        )
                    },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = chipColor.copy(alpha = 0.2f),
                        selectedLabelColor = chipColor,
                        containerColor = RouaColors.Card,
                        labelColor = RouaColors.TextSecondary
                    ),
                    shape = RoundedCornerShape(8.dp)
                )
            }
        }

        Spacer(Modifier.height(8.dp))

        // News List
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(filteredNews) { article ->
                NewsCard(article)
            }

            if (filteredNews.isEmpty()) {
                item {
                    Card(
                        colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text(
                            "No news articles matching filter.",
                            style = MaterialTheme.typography.bodySmall,
                            color = RouaColors.TextTertiary,
                            modifier = Modifier.padding(20.dp),
                            textAlign = TextAlign.Center
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun NewsCard(article: NewsArticle) {
    Card(
        colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
        shape = RoundedCornerShape(12.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                // Sentiment Badge
                val sentimentColor = when (article.sentiment?.lowercase()) {
                    "positive" -> RouaColors.Profit
                    "negative" -> RouaColors.Loss
                    "neutral" -> RouaColors.TextSecondary
                    else -> RouaColors.Cyan
                }
                val sentimentIcon = when (article.sentiment?.lowercase()) {
                    "positive" -> Icons.Filled.ThumbUp
                    "negative" -> Icons.Filled.ThumbDown
                    "neutral" -> Icons.Filled.Remove
                    else -> Icons.Filled.Article
                }

                Surface(
                    shape = RoundedCornerShape(4.dp),
                    color = sentimentColor.copy(alpha = 0.15f)
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 3.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            sentimentIcon,
                            contentDescription = null,
                            tint = sentimentColor,
                            modifier = Modifier.size(12.dp)
                        )
                        Spacer(Modifier.width(3.dp))
                        Text(
                            article.sentiment?.replaceFirstChar { it.uppercase() } ?: "News",
                            style = MaterialTheme.typography.labelSmall,
                            color = sentimentColor,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }

                article.source?.let {
                    Text(
                        it,
                        style = MaterialTheme.typography.labelSmall,
                        color = RouaColors.TextTertiary
                    )
                }
            }

            Spacer(Modifier.height(8.dp))

            Text(
                article.title,
                style = MaterialTheme.typography.bodyMedium,
                color = RouaColors.TextPrimary,
                maxLines = 3,
                overflow = TextOverflow.Ellipsis
            )

            article.summary?.let { summary ->
                Spacer(Modifier.height(4.dp))
                Text(
                    summary,
                    style = MaterialTheme.typography.bodySmall,
                    color = RouaColors.TextTertiary,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
            }

            // Symbol Tag
            if (!article.symbol.isNullOrBlank()) {
                Spacer(Modifier.height(6.dp))
                Surface(
                    shape = RoundedCornerShape(4.dp),
                    color = RouaColors.InfoBackground
                ) {
                    Text(
                        article.symbol,
                        style = MonoTypography.Micro,
                        color = RouaColors.Cyan,
                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                    )
                }
            }
        }
    }
}
