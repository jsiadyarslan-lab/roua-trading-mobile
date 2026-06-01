package com.roua.trading.features.agent

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.roua.trading.design.theme.RouaColors

@Composable
fun AgentScreen() {
    Column(modifier = Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("Autonomous Trader", style = MaterialTheme.typography.headlineMedium, color = RouaColors.TextPrimary)
        
        Card(colors = CardDefaults.cardColors(containerColor = RouaColors.SurfaceElevated)) {
            Column(modifier = Modifier.padding(16.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                Text("Agent Status", style = MaterialTheme.typography.labelLarge, color = RouaColors.TextSecondary)
                Spacer(Modifier.height(8.dp))
                Text("Stopped", style = MaterialTheme.typography.headlineSmall, color = RouaColors.TextTertiary)
                Spacer(Modifier.height(16.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    Button(onClick = { }, colors = ButtonDefaults.buttonColors(containerColor = RouaColors.Profit)) { Text("Start") }
                    Button(onClick = { }, colors = ButtonDefaults.buttonColors(containerColor = RouaColors.Loss)) { Text("Stop") }
                }
            }
        }
    }
}
