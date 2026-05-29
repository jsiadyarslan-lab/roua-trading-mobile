package com.roua.trading.features.scanner

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.roua.trading.core.network.model.ScanResult
import com.roua.trading.design.theme.RouaColors

@Composable
fun ScannerScreen(viewModel: ScannerViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsState()
    
    Column(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        Text("Market Scanner", style = MaterialTheme.typography.headlineMedium, color = RouaColors.TextPrimary)
        Spacer(Modifier.height(16.dp))
        
        // Category chips
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            listOf("ALL", "CRYPTO", "FOREX", "STOCK").forEach { cat ->
                FilterChip(
                    selected = uiState.selectedCategory == cat,
                    onClick = { viewModel.selectCategory(cat) },
                    label = { Text(cat) }
                )
            }
        }
        
        Spacer(Modifier.height(16.dp))
        
        LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            items(uiState.results) { result ->
                ScanResultCard(result)
            }
        }
    }
}

@Composable
fun ScanResultCard(result: ScanResult) {
    Card(
        colors = CardDefaults.cardColors(containerColor = RouaColors.SurfaceElevated),
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(12.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column {
                Text(result.symbol, style = MaterialTheme.typography.labelLarge, color = RouaColors.TextPrimary)
                result.name?.let { Text(it, style = MaterialTheme.typography.bodySmall, color = RouaColors.TextTertiary) }
            }
            Column(horizontalAlignment = androidx.compose.ui.Alignment.End) {
                Text(String.format("%.2f", result.price), style = MaterialTheme.typography.labelLarge,
                    fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace, color = RouaColors.TextPrimary)
                Text(String.format("%+.2f%%", result.changePercent),
                    color = if (result.changePercent >= 0) RouaColors.Profit else RouaColors.Loss,
                    fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace)
            }
        }
    }
}
