package com.roua.trading.features.notifications

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.roua.trading.design.theme.RouaColors

@Composable
fun NotificationsScreen() {
    LazyColumn(modifier = Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        item {
            Text("Notifications", style = MaterialTheme.typography.headlineMedium, color = RouaColors.TextPrimary)
        }
        item {
            Card(colors = CardDefaults.cardColors(containerColor = RouaColors.SurfaceElevated)) {
                Text("No notifications yet", modifier = Modifier.padding(24.dp), color = RouaColors.TextTertiary)
            }
        }
    }
}
