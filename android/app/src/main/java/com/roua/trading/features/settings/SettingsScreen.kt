package com.roua.trading.features.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.roua.trading.core.network.RouaApiService
import com.roua.trading.core.network.model.AuthMeResponse
import com.roua.trading.design.theme.RouaColors
import dagger.hilt.android.lifecycle.HiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

// ── ViewModel ──

data class SettingsUiState(
    val user: AuthMeResponse? = null,
    val isLoading: Boolean = false,
    val language: String = "ar",
    val biometricEnabled: Boolean = true,
    val pushNotifications: Boolean = true,
    val signalAlerts: Boolean = true,
    val tradeAlerts: Boolean = true,
    val aiAlerts: Boolean = true,
    val scannerAlerts: Boolean = true,
    val riskAlerts: Boolean = true,
    val autoExecute: Boolean = false,
    val confirmOrders: Boolean = true,
    val defaultCredential: String = "",
    val defaultOrderType: String = "market",
    val activeSessions: Int = 1,
    val passkeyEnabled: Boolean = false
)

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val api: RouaApiService
) : ViewModel() {

    private val _uiState = MutableStateFlow(SettingsUiState())
    val uiState: StateFlow<SettingsUiState> = _uiState

    init { loadUser() }

    fun loadUser() {
        viewModelScope.launch {
            try {
                val me = api.getSession()
                _uiState.value = _uiState.value.copy(user = me)
            } catch (_: Exception) { }
        }
    }

    fun setLanguage(lang: String) { _uiState.value = _uiState.value.copy(language = lang) }
    fun setBiometric(enabled: Boolean) { _uiState.value = _uiState.value.copy(biometricEnabled = enabled) }
    fun setPushNotifications(enabled: Boolean) { _uiState.value = _uiState.value.copy(pushNotifications = enabled) }
    fun setSignalAlerts(enabled: Boolean) { _uiState.value = _uiState.value.copy(signalAlerts = enabled) }
    fun setTradeAlerts(enabled: Boolean) { _uiState.value = _uiState.value.copy(tradeAlerts = enabled) }
    fun setAiAlerts(enabled: Boolean) { _uiState.value = _uiState.value.copy(aiAlerts = enabled) }
    fun setScannerAlerts(enabled: Boolean) { _uiState.value = _uiState.value.copy(scannerAlerts = enabled) }
    fun setRiskAlerts(enabled: Boolean) { _uiState.value = _uiState.value.copy(riskAlerts = enabled) }
    fun setAutoExecute(enabled: Boolean) { _uiState.value = _uiState.value.copy(autoExecute = enabled) }
    fun setConfirmOrders(enabled: Boolean) { _uiState.value = _uiState.value.copy(confirmOrders = enabled) }
    fun setDefaultOrderType(type: String) { _uiState.value = _uiState.value.copy(defaultOrderType = type) }
    fun setPasskeyEnabled(enabled: Boolean) { _uiState.value = _uiState.value.copy(passkeyEnabled = enabled) }

    fun signOut() {
        viewModelScope.launch {
            try { api.logout() } catch (_: Exception) { }
        }
    }

    fun saveNotificationPreferences() {
        val state = _uiState.value
        viewModelScope.launch {
            try {
                api.updateNotificationPreferences(
                    com.roua.trading.core.network.model.NotificationPreferences(
                        enabled = state.pushNotifications,
                        pushEnabled = state.pushNotifications,
                        signalAlerts = state.signalAlerts,
                        tradeAlerts = state.tradeAlerts,
                        aiAlerts = state.aiAlerts,
                        riskAlerts = state.riskAlerts,
                        autoExecuteEnabled = state.autoExecute
                    )
                )
            } catch (_: Exception) { }
        }
    }
}

// ── Screen ──

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(viewModel: SettingsViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(RouaColors.Background)
    ) {
        Text(
            "Settings",
            style = MaterialTheme.typography.headlineMedium,
            color = RouaColors.TextPrimary,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(start = 16.dp, end = 16.dp, top = 16.dp, bottom = 8.dp)
        )

        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // ═══ Profile Section ═══
            item {
                SettingsSectionCard {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        // Avatar
                        Box(
                            modifier = Modifier
                                .size(48.dp)
                                .clip(CircleShape)
                                .background(RouaColors.Brand.copy(alpha = 0.2f)),
                            contentAlignment = Alignment.Center
                        ) {
                            val initials = (uiState.user?.user?.displayName?.take(2)
                                ?: uiState.user?.user?.email?.take(2)?.uppercase()
                                ?: "RT")
                            Text(initials, color = RouaColors.BrandLight, fontWeight = FontWeight.Bold)
                        }

                        Spacer(Modifier.width(12.dp))

                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                uiState.user?.user?.displayName ?: "Roua Trader",
                                style = MaterialTheme.typography.labelLarge,
                                color = RouaColors.TextPrimary
                            )
                            Text(
                                uiState.user?.user?.email ?: "",
                                style = MaterialTheme.typography.bodySmall,
                                color = RouaColors.TextTertiary
                            )
                        }

                        // Tier Badge
                        val tier = uiState.user?.user?.tier ?: "FREE"
                        Surface(
                            shape = RoundedCornerShape(6.dp),
                            color = when (tier) {
                                "PRO" -> RouaColors.Gold.copy(alpha = 0.15f)
                                "ELITE" -> RouaColors.Brand.copy(alpha = 0.15f)
                                else -> RouaColors.Cyan.copy(alpha = 0.1f)
                            }
                        ) {
                            Text(
                                tier,
                                style = MaterialTheme.typography.labelSmall,
                                color = when (tier) {
                                    "PRO" -> RouaColors.Gold
                                    "ELITE" -> RouaColors.BrandLight
                                    else -> RouaColors.Cyan
                                },
                                fontWeight = FontWeight.Bold,
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                            )
                        }
                    }
                }
            }

            // ═══ Security ═══
            item {
                SettingsSectionCard {
                    SectionHeader("Security", Icons.Filled.Security)

                    Spacer(Modifier.height(8.dp))

                    SettingsRow(
                        icon = Icons.Filled.Devices,
                        title = "Active Sessions",
                        subtitle = "${uiState.activeSessions} device(s)"
                    )

                    HorizontalDivider(color = RouaColors.Border, modifier = Modifier.padding(vertical = 4.dp))

                    SettingsToggle(
                        icon = Icons.Filled.Fingerprint,
                        title = "Biometric Unlock",
                        checked = uiState.biometricEnabled,
                        onCheckedChange = { viewModel.setBiometric(it) }
                    )

                    HorizontalDivider(color = RouaColors.Border, modifier = Modifier.padding(vertical = 4.dp))

                    SettingsToggle(
                        icon = Icons.Filled.VpnKey,
                        title = "Passkey",
                        checked = uiState.passkeyEnabled,
                        onCheckedChange = { viewModel.setPasskeyEnabled(it) }
                    )
                }
            }

            // ═══ Notifications ═══
            item {
                SettingsSectionCard {
                    SectionHeader("Notifications", Icons.Filled.Notifications)

                    Spacer(Modifier.height(8.dp))

                    SettingsToggle(Icons.Filled.NotificationsActive, "Push Notifications", uiState.pushNotifications) { viewModel.setPushNotifications(it) }
                    HorizontalDivider(color = RouaColors.Border, modifier = Modifier.padding(vertical = 4.dp))
                    SettingsToggle(Icons.Filled.AutoAwesome, "Signal Alerts", uiState.signalAlerts) { viewModel.setSignalAlerts(it) }
                    HorizontalDivider(color = RouaColors.Border, modifier = Modifier.padding(vertical = 4.dp))
                    SettingsToggle(Icons.Filled.ShowChart, "Trade Alerts", uiState.tradeAlerts) { viewModel.setTradeAlerts(it) }
                    HorizontalDivider(color = RouaColors.Border, modifier = Modifier.padding(vertical = 4.dp))
                    SettingsToggle(Icons.Filled.Psychology, "AI Alerts", uiState.aiAlerts) { viewModel.setAiAlerts(it) }
                    HorizontalDivider(color = RouaColors.Border, modifier = Modifier.padding(vertical = 4.dp))
                    SettingsToggle(Icons.Filled.Search, "Scanner Alerts", uiState.scannerAlerts) { viewModel.setScannerAlerts(it) }
                    HorizontalDivider(color = RouaColors.Border, modifier = Modifier.padding(vertical = 4.dp))
                    SettingsToggle(Icons.Filled.Warning, "Risk Alerts", uiState.riskAlerts) { viewModel.setRiskAlerts(it) }
                    HorizontalDivider(color = RouaColors.Border, modifier = Modifier.padding(vertical = 4.dp))
                    SettingsToggle(Icons.Filled.AutoMode, "Auto-Execute", uiState.autoExecute) { viewModel.setAutoExecute(it) }

                    Spacer(Modifier.height(8.dp))

                    Button(
                        onClick = { viewModel.saveNotificationPreferences() },
                        colors = ButtonDefaults.buttonColors(containerColor = RouaColors.Accent),
                        shape = RoundedCornerShape(8.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Save Preferences")
                    }
                }
            }

            // ═══ Language ═══
            item {
                SettingsSectionCard {
                    SectionHeader("Language", Icons.Filled.Language)

                    Spacer(Modifier.height(8.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        listOf("ar" to "العربية", "en" to "English").forEach { (code, label) ->
                            val isSelected = uiState.language == code
                            FilterChip(
                                selected = isSelected,
                                onClick = { viewModel.setLanguage(code) },
                                label = {
                                    Text(
                                        label,
                                        style = MaterialTheme.typography.labelMedium,
                                        fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                                    )
                                },
                                colors = FilterChipDefaults.filterChipColors(
                                    selectedContainerColor = RouaColors.Accent.copy(alpha = 0.2f),
                                    selectedLabelColor = RouaColors.TextPrimary,
                                    containerColor = RouaColors.BackgroundLight,
                                    labelColor = RouaColors.TextSecondary
                                ),
                                shape = RoundedCornerShape(8.dp),
                                modifier = Modifier.weight(1f)
                            )
                        }
                    }
                }
            }

            // ═══ Trading Config ═══
            item {
                SettingsSectionCard {
                    SectionHeader("Trading Configuration", Icons.Filled.Tune)

                    Spacer(Modifier.height(8.dp))

                    SettingsRow(
                        icon = Icons.Filled.AccountBalance,
                        title = "Default Credential",
                        subtitle = if (uiState.defaultCredential.isBlank()) "Not set" else uiState.defaultCredential
                    )

                    HorizontalDivider(color = RouaColors.Border, modifier = Modifier.padding(vertical = 4.dp))

                    // Order Type Selector
                    Text("Order Type", style = MaterialTheme.typography.bodySmall, color = RouaColors.TextSecondary)
                    Spacer(Modifier.height(4.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        listOf("market", "limit").forEach { type ->
                            val isSelected = uiState.defaultOrderType == type
                            FilterChip(
                                selected = isSelected,
                                onClick = { viewModel.setDefaultOrderType(type) },
                                label = { Text(type.replaceFirstChar { it.uppercase() }, style = MaterialTheme.typography.labelSmall) },
                                colors = FilterChipDefaults.filterChipColors(
                                    selectedContainerColor = RouaColors.Cyan.copy(alpha = 0.2f),
                                    selectedLabelColor = RouaColors.Cyan,
                                    containerColor = RouaColors.BackgroundLight,
                                    labelColor = RouaColors.TextSecondary
                                ),
                                shape = RoundedCornerShape(6.dp)
                            )
                        }
                    }

                    HorizontalDivider(color = RouaColors.Border, modifier = Modifier.padding(vertical = 4.dp))

                    SettingsToggle(
                        icon = Icons.Filled.CheckCircle,
                        title = "Confirm Before Trading",
                        checked = uiState.confirmOrders,
                        onCheckedChange = { viewModel.setConfirmOrders(it) }
                    )
                }
            }

            // ═══ About ═══
            item {
                SettingsSectionCard {
                    SectionHeader("About", Icons.Filled.Info)

                    Spacer(Modifier.height(8.dp))

                    SettingsRow(icon = Icons.Filled.NewReleases, title = "Version", subtitle = "1.0.0")
                    HorizontalDivider(color = RouaColors.Border, modifier = Modifier.padding(vertical = 4.dp))
                    SettingsClickableRow(icon = Icons.Filled.Description, title = "Terms of Service")
                    HorizontalDivider(color = RouaColors.Border, modifier = Modifier.padding(vertical = 4.dp))
                    SettingsClickableRow(icon = Icons.Filled.PrivacyTip, title = "Privacy Policy")
                    HorizontalDivider(color = RouaColors.Border, modifier = Modifier.padding(vertical = 4.dp))
                    SettingsClickableRow(icon = Icons.Filled.SupportAgent, title = "Support")
                }
            }

            // ═══ Sign Out ═══
            item {
                Button(
                    onClick = { viewModel.signOut() },
                    colors = ButtonDefaults.buttonColors(containerColor = RouaColors.Loss),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Icon(Icons.Filled.Logout, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(Modifier.width(8.dp))
                    Text("Sign Out", fontWeight = FontWeight.Bold)
                }
            }

            // Bottom spacer
            item {
                Spacer(Modifier.height(24.dp))
            }
        }
    }
}

// ═══════════════════════════════════════════════
// REUSABLE COMPONENTS
// ═══════════════════════════════════════════════

@Composable
fun SettingsSectionCard(content: @Composable () -> Unit) {
    Card(
        colors = CardDefaults.cardColors(containerColor = RouaColors.Card),
        shape = RoundedCornerShape(12.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            content()
        }
    }
}

@Composable
fun SectionHeader(title: String, icon: ImageVector) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, contentDescription = null, tint = RouaColors.Cyan, modifier = Modifier.size(20.dp))
        Spacer(Modifier.width(8.dp))
        Text(title, style = MaterialTheme.typography.labelLarge, color = RouaColors.TextPrimary, fontWeight = FontWeight.Bold)
    }
}

@Composable
fun SettingsToggle(
    icon: ImageVector,
    title: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.weight(1f)) {
            Icon(icon, contentDescription = null, tint = RouaColors.TextTertiary, modifier = Modifier.size(20.dp))
            Spacer(Modifier.width(12.dp))
            Text(title, style = MaterialTheme.typography.bodyMedium, color = RouaColors.TextPrimary)
        }
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange,
            colors = SwitchDefaults.colors(checkedTrackColor = RouaColors.Accent)
        )
    }
}

@Composable
fun SettingsRow(
    icon: ImageVector,
    title: String,
    subtitle: String
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.weight(1f)) {
            Icon(icon, contentDescription = null, tint = RouaColors.TextTertiary, modifier = Modifier.size(20.dp))
            Spacer(Modifier.width(12.dp))
            Column {
                Text(title, style = MaterialTheme.typography.bodyMedium, color = RouaColors.TextPrimary)
                Text(subtitle, style = MaterialTheme.typography.bodySmall, color = RouaColors.TextTertiary)
            }
        }
    }
}

@Composable
fun SettingsClickableRow(
    icon: ImageVector,
    title: String
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { },
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.weight(1f)) {
            Icon(icon, contentDescription = null, tint = RouaColors.TextTertiary, modifier = Modifier.size(20.dp))
            Spacer(Modifier.width(12.dp))
            Text(title, style = MaterialTheme.typography.bodyMedium, color = RouaColors.TextPrimary)
        }
        Icon(Icons.Filled.ChevronRight, contentDescription = null, tint = RouaColors.TextTertiary, modifier = Modifier.size(20.dp))
    }
}
