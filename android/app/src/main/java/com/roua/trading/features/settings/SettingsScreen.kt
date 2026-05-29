package com.roua.trading.features.settings

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.roua.trading.design.theme.RouaColors

@Composable
fun SettingsScreen() {
    Column(modifier = Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("Settings", style = MaterialTheme.typography.headlineMedium, color = RouaColors.TextPrimary)
        
        Card(colors = CardDefaults.cardColors(containerColor = RouaColors.SurfaceElevated)) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text("Language", style = MaterialTheme.typography.labelLarge, color = RouaColors.TextSecondary)
                Spacer(Modifier.height(4.dp))
                Text("العربية", style = MaterialTheme.typography.bodyLarge, color = RouaColors.TextPrimary)
            }
        }
        
        Card(colors = CardDefaults.cardColors(containerColor = RouaColors.SurfaceElevated)) {
            var biometricEnabled by androidx.compose.runtime.remember { androidx.compose.runtime.mutableStateOf(true) }
            var pushEnabled by androidx.compose.runtime.remember { androidx.compose.runtime.mutableStateOf(true) }
            
            SwitchRow("Biometric Unlock", biometricEnabled) { biometricEnabled = it }
            SwitchRow("Push Notifications", pushEnabled) { pushEnabled = it }
        }
        
        Spacer(Modifier.height(16.dp))
        
        Button(
            onClick = { /* Sign out */ },
            colors = ButtonDefaults.buttonColors(containerColor = RouaColors.Loss),
            modifier = Modifier.fillMaxWidth()
        ) { Text("Sign Out", color = androidx.compose.ui.graphics.Color.White) }
    }
}

@Composable
fun SwitchRow(title: String, checked: Boolean, onCheckedChange: (Boolean) -> Unit) {
    Row(modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(title, style = MaterialTheme.typography.bodyMedium, color = RouaColors.TextPrimary)
        Switch(checked = checked, onCheckedChange = onCheckedChange, colors = SwitchDefaults.colors(checkedTrackColor = RouaColors.Accent))
    }
}

private operator fun <T> androidx.compose.runtime.MutableState<T>.setValue(nothing: Nothing?, property: androidx.compose.runtime.KMutableProperty0<*>, t: T) {}
private operator fun <T> androidx.compose.runtime.MutableState<T>.getValue(nothing: Nothing?, property: androidx.compose.runtime.KMutableProperty0<*>): T = this.value
