package com.roua.trading.features.notifications

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
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
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.roua.trading.core.network.RouaApiService
import com.roua.trading.core.network.model.UserNotification
import com.roua.trading.core.network.model.UnreadCountResponse
import com.roua.trading.design.theme.RouaColors
import dagger.hilt.android.lifecycle.HiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import javax.inject.Inject

// ── ViewModel ──

data class NotificationsUiState(
    val notifications: List<UserNotification> = emptyList(),
    val unreadCount: Int = 0,
    val isLoading: Boolean = false,
    val error: String? = null,
    val deletedIds: Set<String> = emptySet(),
    val readIds: Set<String> = emptySet()
)

@HiltViewModel
class NotificationsViewModel @Inject constructor(
    private val api: RouaApiService
) : ViewModel() {

    private val _uiState = MutableStateFlow(NotificationsUiState())
    val uiState: StateFlow<NotificationsUiState> = _uiState

    init { loadNotifications() }

    fun loadNotifications() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)
            try {
                val notifications = api.getNotifications(limit = 50)
                val unread = try { api.getUnreadCount().count } catch (_: Exception) { 0 }
                _uiState.value = _uiState.value.copy(
                    notifications = notifications,
                    unreadCount = unread,
                    isLoading = false
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(isLoading = false, error = e.message)
            }
        }
    }

    fun markAsRead(id: String) {
        val currentRead = _uiState.value.readIds
        if (id in currentRead) return

        _uiState.value = _uiState.value.copy(
            readIds = currentRead + id,
            unreadCount = maxOf(0, _uiState.value.unreadCount - 1)
        )

        viewModelScope.launch {
            try { api.markAsRead(com.roua.trading.core.network.model.MarkReadRequest(ids = listOf(id))) } catch (_: Exception) { }
        }
    }

    fun markAllAsRead() {
        val unreadIds = _uiState.value.notifications
            .filter { !it.isRead && it.id !in _uiState.value.readIds }
            .map { it.id }

        _uiState.value = _uiState.value.copy(
            readIds = _uiState.value.readIds + unreadIds.toSet(),
            unreadCount = 0
        )

        viewModelScope.launch {
            try { api.markAllRead() } catch (_: Exception) { }
        }
    }

    fun deleteNotification(id: String) {
        _uiState.value = _uiState.value.copy(
            deletedIds = _uiState.value.deletedIds + id
        )
    }

    fun visibleNotifications(): List<UserNotification> {
        return _uiState.value.notifications.filter { it.id !in _uiState.value.deletedIds }
    }

    fun isRead(notification: UserNotification): Boolean {
        return notification.isRead || notification.id in _uiState.value.readIds
    }
}

// ── Date Grouping ──

enum class DateGroup(val label: String) {
    TODAY("Today"),
    YESTERDAY("Yesterday"),
    EARLIER("Earlier")
}

fun getDateGroup(dateStr: String): DateGroup {
    return try {
        val notificationDate = LocalDateTime.parse(dateStr.replace("Z", "")).toLocalDate()
        val today = LocalDate.now()
        when {
            notificationDate == today -> DateGroup.TODAY
            notificationDate == today.minusDays(1) -> DateGroup.YESTERDAY
            else -> DateGroup.EARLIER
        }
    } catch (_: Exception) {
        DateGroup.EARLIER
    }
}

fun formatTime(dateStr: String): String {
    return try {
        val dt = LocalDateTime.parse(dateStr.replace("Z", ""))
        dt.format(DateTimeFormatter.ofPattern("HH:mm"))
    } catch (_: Exception) {
        ""
    }
}

// ── Notification Type Colors/Icons ──

enum class NotificationType(val color: Color, val icon: ImageVector) {
    TRADE(RouaColors.Profit, Icons.Filled.ShowChart),
    SIGNAL(RouaColors.Cyan, Icons.Filled.AutoAwesome),
    AI(RouaColors.Brand, Icons.Filled.Psychology),
    RISK(RouaColors.Warning, Icons.Filled.Warning),
    SYSTEM(RouaColors.TextSecondary, Icons.Filled.Settings),
    NEWS(RouaColors.Gold, Icons.Filled.Article)
}

fun getNotificationType(type: String): NotificationType {
    return when (type.lowercase()) {
        "trade", "order", "position" -> NotificationType.TRADE
        "signal" -> NotificationType.SIGNAL
        "ai", "council", "executor" -> NotificationType.AI
        "risk", "alert" -> NotificationType.RISK
        "news" -> NotificationType.NEWS
        else -> NotificationType.SYSTEM
    }
}

// ── Screen ──

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NotificationsScreen(viewModel: NotificationsViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsState()
    val visibleNotifications = viewModel.visibleNotifications()

    // Group by date
    val grouped = visibleNotifications.groupBy { getDateGroup(it.createdAt) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(RouaColors.Background)
    ) {
        // Header with Mark All Read
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(start = 16.dp, end = 16.dp, top = 16.dp, bottom = 8.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    "Notifications",
                    style = MaterialTheme.typography.headlineMedium,
                    color = RouaColors.TextPrimary,
                    fontWeight = FontWeight.Bold
                )
                if (uiState.unreadCount > 0) {
                    Spacer(Modifier.width(8.dp))
                    Surface(
                        shape = RoundedCornerShape(10.dp),
                        color = RouaColors.Danger
                    ) {
                        Text(
                            "${uiState.unreadCount}",
                            style = MaterialTheme.typography.labelSmall,
                            color = Color.White,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp)
                        )
                    }
                }
            }

            if (uiState.unreadCount > 0) {
                TextButton(onClick = { viewModel.markAllAsRead() }) {
                    Text(
                        "Mark All Read",
                        style = MaterialTheme.typography.labelMedium,
                        color = RouaColors.Cyan
                    )
                }
            }
        }

        if (uiState.isLoading) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(32.dp),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(color = RouaColors.Accent)
            }
        } else if (visibleNotifications.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(32.dp),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(
                        Icons.Filled.NotificationsOff,
                        contentDescription = null,
                        tint = RouaColors.TextTertiary,
                        modifier = Modifier.size(48.dp)
                    )
                    Spacer(Modifier.height(12.dp))
                    Text(
                        "No notifications",
                        style = MaterialTheme.typography.bodyMedium,
                        color = RouaColors.TextTertiary
                    )
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                DateGroup.entries.forEach { group ->
                    val groupNotifications = grouped[group] ?: return@forEach

                    item {
                        Spacer(Modifier.height(8.dp))
                        Text(
                            group.label,
                            style = MaterialTheme.typography.labelLarge,
                            color = RouaColors.TextSecondary,
                            fontWeight = FontWeight.Bold
                        )
                        Spacer(Modifier.height(4.dp))
                    }

                    items(groupNotifications, key = { it.id }) { notification ->
                        val isRead = viewModel.isRead(notification)
                        val swipeOffset = remember { mutableFloatStateOf(0f) }

                        NotificationCard(
                            notification = notification,
                            isRead = isRead,
                            onMarkRead = { viewModel.markAsRead(notification.id) },
                            onDelete = { viewModel.deleteNotification(notification.id) }
                        )
                    }
                }

                // Bottom spacer
                item { Spacer(Modifier.height(24.dp)) }
            }
        }
    }
}

@Composable
fun NotificationCard(
    notification: UserNotification,
    isRead: Boolean,
    onMarkRead: () -> Unit,
    onDelete: () -> Unit
) {
    val notifType = getNotificationType(notification.type)
    val bgColor by animateColorAsState(
        targetValue = if (isRead) RouaColors.Card else RouaColors.CardHover,
        label = "bgColor"
    )
    val swipeOffset = remember { mutableFloatStateOf(0f) }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(RouaColors.Loss.copy(alpha = 0.1f))
    ) {
        // Delete action (revealed on swipe)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    Icons.Filled.Delete,
                    contentDescription = "Delete",
                    tint = RouaColors.Loss,
                    modifier = Modifier.size(16.dp)
                )
                Spacer(Modifier.width(4.dp))
                Text("Delete", style = MaterialTheme.typography.labelSmall, color = RouaColors.Loss)
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    Icons.Filled.Done,
                    contentDescription = "Mark Read",
                    tint = RouaColors.Profit,
                    modifier = Modifier.size(16.dp)
                )
                Spacer(Modifier.width(4.dp))
                Text("Read", style = MaterialTheme.typography.labelSmall, color = RouaColors.Profit)
            }
        }

        // Main content card
        Card(
            colors = CardDefaults.cardColors(containerColor = bgColor),
            shape = RoundedCornerShape(12.dp),
            modifier = Modifier
                .fillMaxWidth()
                .offset(x = swipeOffset.floatValue.dp)
                .pointerInput(Unit) {
                    detectHorizontalDragGestures(
                        onDragEnd = {
                            when {
                                swipeOffset.floatValue < -150f -> onDelete()
                                swipeOffset.floatValue > 100f -> onMarkRead()
                            }
                            swipeOffset.floatValue = 0f
                        },
                        onHorizontalDrag = { _, dragAmount ->
                            swipeOffset.floatValue = (swipeOffset.floatValue + dragAmount / 3f)
                                .coerceIn(-200f, 150f)
                        }
                    )
                }
                .clickable {
                    if (!isRead) onMarkRead()
                }
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(14.dp),
                verticalAlignment = Alignment.Top
            ) {
                // Type Icon
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .clip(CircleShape)
                        .background(notifType.color.copy(alpha = 0.15f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        notifType.icon,
                        contentDescription = null,
                        tint = notifType.color,
                        modifier = Modifier.size(20.dp)
                    )
                }

                Spacer(Modifier.width(12.dp))

                Column(modifier = Modifier.weight(1f)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            notification.title,
                            style = MaterialTheme.typography.labelLarge,
                            color = if (isRead) RouaColors.TextSecondary else RouaColors.TextPrimary,
                            fontWeight = if (isRead) FontWeight.Normal else FontWeight.Bold,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                            modifier = Modifier.weight(1f)
                        )

                        // Unread indicator
                        if (!isRead) {
                            Spacer(Modifier.width(6.dp))
                            Box(
                                modifier = Modifier
                                    .size(8.dp)
                                    .clip(CircleShape)
                                    .background(RouaColors.Cyan)
                            )
                        }
                    }

                    notification.body?.let { body ->
                        Spacer(Modifier.height(3.dp))
                        Text(
                            body,
                            style = MaterialTheme.typography.bodySmall,
                            color = if (isRead) RouaColors.TextTertiary else RouaColors.TextSecondary,
                            maxLines = 2,
                            overflow = TextOverflow.Ellipsis
                        )
                    }

                    // Meta row
                    Spacer(Modifier.height(6.dp))
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        // Type badge
                        Surface(
                            shape = RoundedCornerShape(4.dp),
                            color = notifType.color.copy(alpha = 0.1f)
                        ) {
                            Text(
                                notification.type.uppercase(),
                                style = MaterialTheme.typography.labelSmall,
                                color = notifType.color,
                                fontWeight = FontWeight.Bold,
                                modifier = Modifier.padding(horizontal = 5.dp, vertical = 2.dp)
                            )
                        }

                        // Time
                        Text(
                            formatTime(notification.createdAt),
                            style = MaterialTheme.typography.labelSmall,
                            color = RouaColors.TextTertiary
                        )

                        // Pair tag
                        if (!notification.pair.isNullOrBlank()) {
                            Surface(
                                shape = RoundedCornerShape(4.dp),
                                color = RouaColors.InfoBackground
                            ) {
                                Text(
                                    notification.pair,
                                    style = MaterialTheme.typography.labelSmall,
                                    color = RouaColors.Cyan,
                                    modifier = Modifier.padding(horizontal = 5.dp, vertical = 2.dp)
                                )
                            }
                        }

                        // Priority badge
                        if (!notification.priority.isNullOrBlank() && notification.priority != "normal") {
                            val prioColor = when (notification.priority.lowercase()) {
                                "high", "urgent" -> RouaColors.Danger
                                "medium" -> RouaColors.Warning
                                else -> RouaColors.TextTertiary
                            }
                            Surface(
                                shape = RoundedCornerShape(4.dp),
                                color = prioColor.copy(alpha = 0.1f)
                            ) {
                                Text(
                                    notification.priority.uppercase(),
                                    style = MaterialTheme.typography.labelSmall,
                                    color = prioColor,
                                    fontWeight = FontWeight.Bold,
                                    modifier = Modifier.padding(horizontal = 5.dp, vertical = 2.dp)
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
