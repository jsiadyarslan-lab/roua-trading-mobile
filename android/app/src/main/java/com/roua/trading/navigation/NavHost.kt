package com.roua.trading.navigation

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.roua.trading.features.dashboard.DashboardScreen
import com.roua.trading.features.trading.TradingScreen
import com.roua.trading.features.ai.AIChatScreen
import com.roua.trading.features.portfolio.PortfolioScreen
import com.roua.trading.features.settings.SettingsScreen
import com.roua.trading.features.scanner.ScannerScreen
import com.roua.trading.features.agent.AgentScreen
import com.roua.trading.features.notifications.NotificationsScreen

sealed class Screen(val route: String, val title: String, val icon: ImageVector) {
    data object Dashboard : Screen("dashboard", "Dashboard", Icons.Filled.Dashboard)
    data object Trading : Screen("trading", "Trade", Icons.Filled.ShowChart)
    data object AI : Screen("ai", "AI", Icons.Filled.Psychology)
    data object Portfolio : Screen("portfolio", "Portfolio", Icons.Filled.AccountBalanceWallet)
    data object More : Screen("more", "More", Icons.Filled.MoreHoriz)
    
    data object Scanner : Screen("scanner", "Scanner", Icons.Filled.Search)
    data object Settings : Screen("settings", "Settings", Icons.Filled.Settings)
    data object Agent : Screen("agent", "Autonomous Trader", Icons.Filled.SmartToy)
    data object Notifications : Screen("notifications", "Notifications", Icons.Filled.Notifications)
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RouaNavHost() {
    val navController = rememberNavController()
    val bottomNavItems = listOf(Screen.Dashboard, Screen.Trading, Screen.AI, Screen.Portfolio, Screen.More)
    
    Scaffold(
        bottomBar = {
            NavigationBar {
                val navBackStackEntry by navController.currentBackStackEntryAsState()
                val currentDestination = navBackStackEntry?.destination
                
                bottomNavItems.forEach { screen ->
                    NavigationBarItem(
                        icon = { Icon(screen.icon, contentDescription = screen.title) },
                        label = { Text(screen.title) },
                        selected = currentDestination?.hierarchy?.any { it.route == screen.route } == true,
                        onClick = {
                            navController.navigate(screen.route) {
                                popUpTo(navController.graph.findStartDestination().id) {
                                    saveState = true
                                }
                                launchSingleTop = true
                                restoreState = true
                            }
                        }
                    )
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = Screen.Dashboard.route,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(Screen.Dashboard.route) { DashboardScreen(navController) }
            composable(Screen.Trading.route) { TradingScreen() }
            composable(Screen.AI.route) { AIChatScreen() }
            composable(Screen.Portfolio.route) { PortfolioScreen() }
            composable(Screen.More.route) {
                MoreMenuScreen(
                    onNavigate = { route -> navController.navigate(route) }
                )
            }
            composable(Screen.Scanner.route) { ScannerScreen() }
            composable(Screen.Settings.route) { SettingsScreen() }
            composable(Screen.Agent.route) { AgentScreen() }
            composable(Screen.Notifications.route) { NotificationsScreen() }
        }
    }
}

@Composable
fun MoreMenuScreen(onNavigate: (String) -> Unit) {
    androidx.compose.foundation.layout.Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(androidx.compose.ui.unit.dp(16))
    ) {
        androidx.compose.material3.Text(
            "More",
            style = androidx.compose.material3.MaterialTheme.typography.headlineMedium,
            color = androidx.compose.material3.MaterialTheme.colorScheme.onBackground,
            modifier = Modifier.padding(bottom = androidx.compose.ui.unit.dp(16))
        )
        
        MoreMenuItem(icon = Icons.Filled.SmartToy, title = "Autonomous Trader") { onNavigate(Screen.Agent.route) }
        MoreMenuItem(icon = Icons.Filled.Search, title = "Market Scanner") { onNavigate(Screen.Scanner.route) }
        MoreMenuItem(icon = Icons.Filled.Notifications, title = "Notifications") { onNavigate(Screen.Notifications.route) }
        MoreMenuItem(icon = Icons.Filled.Settings, title = "Settings") { onNavigate(Screen.Settings.route) }
    }
}

@Composable
fun MoreMenuItem(icon: ImageVector, title: String, onClick: () -> Unit) {
    androidx.compose.material3.TextButton(onClick = onClick) {
        androidx.compose.foundation.layout.Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
        ) {
            Icon(icon, contentDescription = title, tint = androidx.compose.material3.MaterialTheme.colorScheme.primary)
            androidx.compose.foundation.layout.Spacer(modifier = Modifier.width(androidx.compose.ui.unit.dp(12)))
            Text(title, color = androidx.compose.material3.MaterialTheme.colorScheme.onBackground)
        }
    }
}

private val Modifier.Companion.width dp: androidx.compose.ui.unit.Dp
    get() = TODO("Not needed - using inline dp calls")
