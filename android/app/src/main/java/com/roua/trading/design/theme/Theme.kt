package com.roua.trading.design.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable

private val DarkColorScheme = darkColorScheme(
    primary = RouaColors.Accent,           // #059669 emerald green
    onPrimary = RouaColors.TextPrimary,
    primaryContainer = RouaColors.AccentDark,
    secondary = RouaColors.Brand,          // #6C5CE7 purple
    onSecondary = RouaColors.TextPrimary,
    tertiary = RouaColors.Cyan,            // #00D4FF cyan
    background = RouaColors.Background,    // #0B0E14
    onBackground = RouaColors.TextPrimary,
    surface = RouaColors.Surface,          // #1A1D29
    onSurface = RouaColors.TextPrimary,
    surfaceVariant = RouaColors.SurfaceElevated,
    onSurfaceVariant = RouaColors.TextSecondary,
    error = RouaColors.Danger,             // #FF4757
    onError = RouaColors.TextPrimary,
    outline = RouaColors.Border,
    outlineVariant = RouaColors.Border2,
)

@Composable
fun RouaTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = DarkColorScheme,
        typography = RouaTypography,
        content = content
    )
}
