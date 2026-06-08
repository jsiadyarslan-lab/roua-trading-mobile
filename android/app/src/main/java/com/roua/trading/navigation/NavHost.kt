package com.roua.trading.navigation

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountBalanceWallet
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Psychology
import androidx.compose.material.icons.filled.ShowChart
import androidx.compose.material.icons.filled.TrendingUp
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.roua.trading.core.auth.SessionManager
import com.roua.trading.features.agent.AgentScreen
import com.roua.trading.features.dashboard.DashboardScreen
import com.roua.trading.features.notifications.NotificationsScreen
import com.roua.trading.features.portfolio.PortfolioScreen
import com.roua.trading.features.scanner.ScannerScreen
import com.roua.trading.features.settings.SettingsScreen
import com.roua.trading.features.trading.TradingScreen
import com.roua.trading.features.ai.AIChatScreen
import com.roua.trading.features.auth.AuthScreen
import com.roua.trading.design.theme.RouaColors
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

// ──────────────────────────────────────────────────────────────────────
// Route definitions
// ──────────────────────────────────────────────────────────────────────

sealed class Screen(val route: String) {
    // ── Bottom-nav tabs ──
    data object Home : Screen("home")
    data object Markets : Screen("markets")
    data object Trade : Screen("trade")
    data object AI : Screen("ai")
    data object Portfolio : Screen("portfolio")

    // ── Secondary screens (reachable from tabs / menus) ──
    data object Scanner : Screen("scanner")
    data object Heatmap : Screen("heatmap")
    data object News : Screen("news")
    data object Agent : Screen("agent")
    data object Credentials : Screen("credentials")
    data object Settings : Screen("settings")
    data object Notifications : Screen("notifications")
    data object Auth : Screen("auth")
}

// ──────────────────────────────────────────────────────────────────────
// Bottom-nav item descriptor
// ──────────────────────────────────────────────────────────────────────

data class BottomNavItem(
    val screen: Screen,
    val icon: ImageVector,
    val label: String,
    val isCenter: Boolean = false,
    val badgeCount: Int = 0,
)

private val bottomNavItems = listOf(
    BottomNavItem(Screen.Home, Icons.Filled.Home, "Home"),
    BottomNavItem(Screen.Markets, Icons.Filled.TrendingUp, "Markets"),
    BottomNavItem(Screen.Trade, Icons.Filled.ShowChart, "Trade", isCenter = true),
    BottomNavItem(Screen.AI, Icons.Filled.Psychology, "AI"),
    BottomNavItem(Screen.Portfolio, Icons.Filled.AccountBalanceWallet, "Portfolio"),
)

// ──────────────────────────────────────────────────────────────────────
// Auth-state ViewModel
// ──────────────────────────────────────────────────────────────────────

@HiltViewModel
class MainNavViewModel @Inject constructor(
    private val sessionManager: SessionManager,
) : ViewModel() {

    val isLoggedIn: Boolean
        get() = sessionManager.isLoggedIn()

    fun onLoginSuccess(token: String, refreshToken: String? = null) {
        sessionManager.saveSession(
            token = token,
            refreshToken = refreshToken,
        )
    }

    fun onLogout() {
        sessionManager.clearSession()
    }
}

// ──────────────────────────────────────────────────────────────────────
// Top-level navigation host
// ──────────────────────────────────────────────────────────────────────

@Composable
fun RouaNavHost(
    viewModel: MainNavViewModel = hiltViewModel(),
) {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route

    // Auth gate — mutable state so recomposition triggers when auth changes
    var isAuthenticated by remember { mutableStateOf(viewModel.isLoggedIn) }

    // Notification badge count — can be driven by a repository / ViewModel later
    var notificationBadgeCount by remember { mutableStateOf(0) }

    // Determine whether the bottom bar should be visible
    val showBottomBar by remember(currentRoute) {
        derivedStateOf {
            currentRoute in listOf(
                Screen.Home.route,
                Screen.Markets.route,
                Screen.Trade.route,
                Screen.AI.route,
                Screen.Portfolio.route,
            )
        }
    }

    if (!isAuthenticated) {
        AuthScreen(
            onAuthSuccess = { token, refreshToken ->
                viewModel.onLoginSuccess(token, refreshToken)
                isAuthenticated = true
            },
        )
        return
    }

    Scaffold(
        containerColor = RouaColors.Background,
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        bottomBar = {
            AnimatedVisibility(
                visible = showBottomBar,
                enter = slideInVertically(initialOffsetY = { it }) + fadeIn(),
                exit = slideOutVertically(targetOffsetY = { it }) + fadeOut(),
            ) {
                RouaGlassBottomBar(
                    items = bottomNavItems.map { item ->
                        if (item.screen == Screen.Portfolio) {
                            item.copy(badgeCount = notificationBadgeCount)
                        } else item
                    },
                    currentRoute = currentRoute,
                    onItemSelected = { screen ->
                        navController.navigate(screen.route) {
                            popUpTo(navController.graph.findStartDestination().id) {
                                saveState = true
                            }
                            launchSingleTop = true
                            restoreState = true
                        }
                    },
                )
            }
        },
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = Screen.Home.route,
            modifier = Modifier.padding(innerPadding),
        ) {
            // ── Bottom-nav tab screens ──
            composable(Screen.Home.route) {
                DashboardScreen(navController = navController)
            }
            composable(Screen.Markets.route) {
                MarketsScreen(navController = navController)
            }
            composable(Screen.Trade.route) {
                TradingScreen()
            }
            composable(Screen.AI.route) {
                AIChatScreen()
            }
            composable(Screen.Portfolio.route) {
                PortfolioScreen()
            }

            // ── Secondary screens ──
            composable(Screen.Scanner.route) {
                ScannerScreen()
            }
            composable(Screen.Heatmap.route) {
                HeatmapScreen()
            }
            composable(Screen.News.route) {
                NewsScreen()
            }
            composable(Screen.Agent.route) {
                AgentScreen()
            }
            composable(Screen.Credentials.route) {
                CredentialsScreen()
            }
            composable(Screen.Settings.route) {
                SettingsScreen()
            }
            composable(Screen.Notifications.route) {
                NotificationsScreen()
            }
        }
    }
}

// ──────────────────────────────────────────────────────────────────────
// Glass-morphism bottom navigation bar
// ──────────────────────────────────────────────────────────────────────

@Composable
fun RouaGlassBottomBar(
    items: List<BottomNavItem>,
    currentRoute: String?,
    onItemSelected: (Screen) -> Unit,
    modifier: Modifier = Modifier,
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .windowInsetsPadding(WindowInsets.navigationBars)
            .background(
                color = RouaColors.NavGlass, // rgba(11,14,20,0.85)
            )
            .drawBehind {
                // Top border — subtle separator
                drawLine(
                    color = RouaColors.Border2,
                    start = Offset(0f, 0f),
                    end = Offset(size.width, 0f),
                    strokeWidth = 1.dp.toPx(),
                )
            },
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(64.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            items.forEach { item ->
                val selected = currentRoute == item.screen.route
                if (item.isCenter) {
                    CenterTradeButton(
                        selected = selected,
                        onClick = { onItemSelected(item.screen) },
                    )
                } else {
                    NavItem(
                        icon = item.icon,
                        label = item.label,
                        selected = selected,
                        badgeCount = item.badgeCount,
                        onClick = { onItemSelected(item.screen) },
                    )
                }
            }
        }
    }
}

// ──────────────────────────────────────────────────────────────────────
// Standard nav item with dot indicator + optional badge
// ──────────────────────────────────────────────────────────────────────

@Composable
private fun NavItem(
    icon: ImageVector,
    label: String,
    selected: Boolean,
    badgeCount: Int,
    onClick: () -> Unit,
) {
    val tintColor = if (selected) RouaColors.Accent else RouaColors.TextSecondary

    Column(
        modifier = Modifier
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                onClick = onClick,
            )
            .padding(horizontal = 12.dp, vertical = 4.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        BadgedBox(
            badge = {
                if (badgeCount > 0) {
                    Badge(
                        containerColor = RouaColors.Danger,
                        contentColor = Color.White,
                    ) {
                        Text(
                            text = if (badgeCount > 99) "99+" else "$badgeCount",
                            fontSize = 9.sp,
                            fontWeight = FontWeight.Bold,
                        )
                    }
                }
            },
        ) {
            Icon(
                imageVector = icon,
                contentDescription = label,
                tint = tintColor,
                modifier = Modifier.size(24.dp),
            )
        }

        Spacer(Modifier.height(2.dp))

        Text(
            text = label,
            color = tintColor,
            fontSize = 10.sp,
            fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal,
            textAlign = TextAlign.Center,
        )

        // Dot indicator
        AnimatedVisibility(visible = selected) {
            Box(
                modifier = Modifier
                    .padding(top = 2.dp)
                    .size(4.dp)
                    .background(RouaColors.Accent, CircleShape),
            )
        }
    }
}

// ──────────────────────────────────────────────────────────────────────
// Prominent center "Trade" button with accent glow
// ──────────────────────────────────────────────────────────────────────

@Composable
private fun CenterTradeButton(
    selected: Boolean,
    onClick: () -> Unit,
) {
    val accentGlow = RouaColors.Accent.copy(alpha = 0.35f)

    Box(
        modifier = Modifier
            .size(56.dp)
            .drawBehind {
                // Outer glow
                if (selected) {
                    drawCircle(
                        color = accentGlow,
                        radius = size.minDimension / 2f + 6.dp.toPx(),
                        alpha = 0.5f,
                    )
                }
            }
            .shadow(
                elevation = if (selected) 8.dp else 2.dp,
                shape = CircleShape,
                ambientColor = if (selected) RouaColors.Accent else Color.Transparent,
                spotColor = if (selected) RouaColors.Accent else Color.Transparent,
            )
            .background(
                brush = Brush.verticalGradient(
                    colors = if (selected) {
                        listOf(RouaColors.Accent, RouaColors.AccentDark)
                    } else {
                        listOf(RouaColors.SurfaceElevated, RouaColors.Card)
                    },
                ),
                shape = CircleShape,
            )
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                onClick = onClick,
            ),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            imageVector = Icons.Filled.ShowChart,
            contentDescription = "Trade",
            tint = if (selected) Color.White else RouaColors.TextSecondary,
            modifier = Modifier.size(26.dp),
        )
    }
}

// ──────────────────────────────────────────────────────────────────────
// Markets screen — tab container for Scanner / Heatmap / News
// ──────────────────────────────────────────────────────────────────────

@Composable
fun MarketsScreen(navController: NavHostController) {
    var selectedTab by remember { mutableStateOf(0) }
    val tabs = listOf("Scanner", "Heatmap", "News")

    Column(modifier = Modifier.fillMaxSize()) {
        // Title
        Text(
            text = "الأسواق", // "Markets" in Arabic
            style = MaterialTheme.typography.headlineMedium,
            color = RouaColors.TextPrimary,
            modifier = Modifier.padding(start = 16.dp, top = 16.dp, end = 16.dp, bottom = 8.dp),
        )

        // Tab row
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            tabs.forEachIndexed { index, title ->
                val isSelected = selectedTab == index
                Surface(
                    modifier = Modifier
                        .weight(1f)
                        .clickable(
                            interactionSource = remember { MutableInteractionSource() },
                            indication = null,
                            onClick = { selectedTab = index },
                        ),
                    shape = RoundedCornerShape(8.dp),
                    color = if (isSelected) RouaColors.Accent.copy(alpha = 0.15f) else Color.Transparent,
                ) {
                    Box(
                        modifier = Modifier.padding(vertical = 10.dp),
                        contentAlignment = Alignment.Center,
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                text = title,
                                color = if (isSelected) RouaColors.Accent else RouaColors.TextSecondary,
                                fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                                fontSize = 13.sp,
                            )
                            Spacer(Modifier.height(4.dp))
                            Box(
                                modifier = Modifier
                                    .height(2.dp)
                                    .width(if (isSelected) 24.dp else 0.dp)
                                    .background(RouaColors.Accent, RoundedCornerShape(1.dp)),
                            )
                        }
                    }
                }
            }
        }

        Spacer(Modifier.height(8.dp))

        // Tab content
        when (selectedTab) {
            0 -> ScannerScreen()
            1 -> HeatmapScreen()
            2 -> NewsScreen()
        }
    }
}

// ──────────────────────────────────────────────────────────────────────
// Placeholder screens for new sub-features
// ──────────────────────────────────────────────────────────────────────

@Composable
fun HeatmapScreen() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
    ) {
        Text(
            text = "خريطة الحرارة", // "Heatmap" in Arabic
            style = MaterialTheme.typography.headlineMedium,
            color = RouaColors.TextPrimary,
        )
        Spacer(Modifier.height(16.dp))

        // Heatmap grid — simplified visual representation
        val symbols = listOf(
            "BTC" to 3.2f, "ETH" to -1.5f, "BNB" to 0.8f, "SOL" to 5.1f,
            "XRP" to -0.3f, "ADA" to 2.1f, "DOGE" to -2.8f, "AVAX" to 4.0f,
            "DOT" to -1.1f, "MATIC" to 1.7f, "LINK" to -0.6f, "UNI" to 3.5f,
        )

        // 4x3 grid
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            symbols.chunked(4).forEach { row ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                ) {
                    row.forEach { (symbol, change) ->
                        val isPositive = change >= 0
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .height(64.dp)
                                .background(
                                    color = if (isPositive) {
                                        RouaColors.Profit.copy(alpha = (0.15f + change.coerceIn(0f, 5f) / 5f * 0.6f))
                                    } else {
                                        RouaColors.Loss.copy(alpha = (0.15f + change.coerceIn(-5f, 0f).unaryMinus() / 5f * 0.6f))
                                    },
                                    shape = RoundedCornerShape(6.dp),
                                ),
                            contentAlignment = Alignment.Center,
                        ) {
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Text(
                                    text = symbol,
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = RouaColors.TextPrimary,
                                )
                                Text(
                                    text = String.format("%+.1f%%", change),
                                    fontSize = 10.sp,
                                    color = if (isPositive) RouaColors.Profit else RouaColors.Loss,
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun NewsScreen() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
    ) {
        Text(
            text = "الأخبار", // "News" in Arabic
            style = MaterialTheme.typography.headlineMedium,
            color = RouaColors.TextPrimary,
        )
        Spacer(Modifier.height(16.dp))

        // Placeholder news items
        val newsItems = listOf(
            "Bitcoin Breaks Key Resistance Level" to "2 hours ago",
            "Ethereum 2.0 Staking Reaches New ATH" to "5 hours ago",
            "Federal Reserve Signals Rate Pause" to "8 hours ago",
            "Solana DeFi TVL Surges 40%" to "12 hours ago",
        )

        newsItems.forEach { (headline, time) ->
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 8.dp),
                shape = RoundedCornerShape(10.dp),
                color = RouaColors.SurfaceElevated,
            ) {
                Column(modifier = Modifier.padding(14.dp)) {
                    Text(
                        text = headline,
                        style = MaterialTheme.typography.bodyLarge,
                        color = RouaColors.TextPrimary,
                    )
                    Spacer(Modifier.height(4.dp))
                    Text(
                        text = time,
                        style = MaterialTheme.typography.labelSmall,
                        color = RouaColors.TextTertiary,
                    )
                }
            }
        }
    }
}

@Composable
fun CredentialsScreen() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(
            text = "بيانات الربط", // "Credentials" in Arabic
            style = MaterialTheme.typography.headlineMedium,
            color = RouaColors.TextPrimary,
        )

        Surface(
            shape = RoundedCornerShape(12.dp),
            color = RouaColors.SurfaceElevated,
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Text(
                    text = "No exchange accounts linked",
                    color = RouaColors.TextTertiary,
                    style = MaterialTheme.typography.bodyMedium,
                )
                Spacer(Modifier.height(12.dp))
                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = RouaColors.Accent,
                    modifier = Modifier.clickable { /* Link exchange */ },
                ) {
                    Text(
                        text = "ربط حساب бирجة", // "Link Exchange Account" in Arabic
                        color = Color.White,
                        modifier = Modifier.padding(horizontal = 20.dp, vertical = 10.dp),
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 14.sp,
                    )
                }
            }
        }
    }
}
