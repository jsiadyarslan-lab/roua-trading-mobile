package com.roua.trading.design.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable

private val DarkColorScheme = darkColorScheme(
    primary = RouaColors.Accent,
    onPrimary = RouaColors.TextPrimary,
    primaryContainer = RouaColors.AccentDark,
    secondary = RouaColors.AccentLight,
    onSecondary = RouaColors.TextPrimary,
    tertiary = RouaColors.Profit,
    background = RouaColors.Background,
    onBackground = RouaColors.TextPrimary,
    surface = RouaColors.Surface,
    onSurface = RouaColors.TextPrimary,
    surfaceVariant = RouaColors.SurfaceElevated,
    onSurfaceVariant = RouaColors.TextSecondary,
    error = RouaColors.Loss,
    onError = RouaColors.TextPrimary,
    outline = RouaColors.Border,
    outlineVariant = RouaColors.BorderLight,
)

@Composable
fun RouaTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = DarkColorScheme,
        typography = RouaTypography,
        content = content
    )
}
