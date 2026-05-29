package com.roua.trading.features.portfolio

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.roua.trading.core.network.model.ExchangeCredential
import com.roua.trading.design.theme.MonoTypography
import com.roua.trading.design.theme.RouaColors

@Composable
fun PortfolioScreen(viewModel: PortfolioViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsState()
    
    LazyColumn(modifier = Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        item {
            Card(colors = CardDefaults.cardColors(containerColor = RouaColors.SurfaceElevated), shape = androidx.compose.foundation.shape.RoundedCornerShape(16.dp)) {
                Column(modifier = Modifier.padding(16.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                    Text("Total Portfolio Value", style = MaterialTheme.typography.labelSmall, color = RouaColors.TextTertiary)
                    Spacer(Modifier.height(4.dp))
                    Text(String.format("$%,.2f", uiState.totalValue), style = MonoTypography.Large, color = RouaColors.TextPrimary)
                }
            }
        }
        
        item { Text("Exchange Accounts", style = MaterialTheme.typography.titleMedium, color = RouaColors.TextPrimary) }
        
        items(uiState.credentials) { cred ->
            Card(colors = CardDefaults.cardColors(containerColor = RouaColors.SurfaceElevated)) {
                Row(modifier = Modifier.fillMaxWidth().padding(12.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                    Column {
                        Text(cred.label, style = MaterialTheme.typography.labelLarge, color = RouaColors.TextPrimary)
                        Text(cred.exchange.uppercase(), style = MaterialTheme.typography.labelSmall, color = RouaColors.TextTertiary)
                    }
                    if (cred.testnet) {
                        Text("TESTNET", style = MaterialTheme.typography.labelSmall, color = RouaColors.Warning)
                    }
                }
            }
        }
    }
}
