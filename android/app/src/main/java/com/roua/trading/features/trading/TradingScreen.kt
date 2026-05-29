package com.roua.trading.features.trading

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.roua.trading.design.theme.RouaColors

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TradingScreen(viewModel: TradingViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsState()
    
    Column(modifier = Modifier.fillMaxSize()) {
        // Symbol Header
        Row(
            modifier = Modifier.fillMaxWidth().padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column {
                Text("BTC/USDT", style = MaterialTheme.typography.headlineMedium, color = RouaColors.TextPrimary)
                uiState.currentQuote?.let { quote ->
                    Text(
                        String.format("$%.2f", quote.last ?: 0.0),
                        style = androidx.compose.ui.text.TextStyle(
                            fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace,
                            fontSize = 20.sp
                        ),
                        color = RouaColors.TextPrimary
                    )
                }
            }
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Button(
                    onClick = { viewModel.onBuyClick() },
                    colors = ButtonDefaults.buttonColors(containerColor = RouaColors.Profit)
                ) { Text("Buy", color = androidx.compose.ui.graphics.Color.White) }
                Button(
                    onClick = { viewModel.onSellClick() },
                    colors = ButtonDefaults.buttonColors(containerColor = RouaColors.Loss)
                ) { Text("Sell", color = androidx.compose.ui.graphics.Color.White) }
            }
        }
        
        // Quick Stats
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            uiState.currentQuote?.let { q ->
                StatChip("H", String.format("%.2f", q.high ?: 0.0))
                StatChip("L", String.format("%.2f", q.low ?: 0.0))
                StatChip("Vol", formatVolume(q.volume ?: 0.0))
            }
        }
        
        Spacer(Modifier.height(16.dp))
        
        // Positions
        Text("Open Positions", style = MaterialTheme.typography.titleMedium, color = RouaColors.TextPrimary, modifier = Modifier.padding(horizontal = 16.dp))
        
        Column(modifier = Modifier.verticalScroll(rememberScrollState()).padding(16.dp)) {
            uiState.positions.forEach { pos ->
                Card(
                    colors = CardDefaults.cardColors(containerColor = RouaColors.SurfaceElevated),
                    modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth().padding(12.dp),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(pos.symbol, color = RouaColors.TextPrimary)
                        Text(pos.side, color = if (pos.side == "BUY") RouaColors.Profit else RouaColors.Loss)
                        pos.unrealizedPnl?.let {
                            Text(String.format("%+.2f", it), color = if (it >= 0) RouaColors.Profit else RouaColors.Loss)
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun StatChip(label: String, value: String) {
    Card(colors = CardDefaults.cardColors(containerColor = RouaColors.SurfaceElevated)) {
        Column(modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)) {
            Text(label, style = MaterialTheme.typography.labelSmall, color = RouaColors.TextTertiary)
            Text(value, style = MaterialTheme.typography.labelMedium, color = RouaColors.TextPrimary,
                fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace)
        }
    }
}

private fun formatVolume(volume: Double): String {
    return when {
        volume >= 1_000_000 -> String.format("%.1fM", volume / 1_000_000)
        volume >= 1_000 -> String.format("%.1fK", volume / 1_000)
        else -> String.format("%.0f", volume)
    }
}

private val Int.sp get() = androidx.compose.ui.unit.sp
