package com.roua.trading.design.theme

import androidx.compose.ui.graphics.Color

/**
 * Roua Trading — Unified Design Tokens (Android)
 *
 * Single source of truth aligned with the web's unified-tokens.ts
 * Every color MUST match the web exactly.
 *
 * CANONICAL VALUES (from web unified-tokens.ts):
 *   T.bg:        #0B0E14     → Background
 *   T.card:      #1A1D29     → Surface / Card
 *   T.cardHover: #1F2335     → CardHover
 *   T.accent:    #059669     → Accent (emerald green — primary brand)
 *   T.brand:     #6C5CE7     → Brand (purple)
 *   T.gold:      #d4af37     → Gold (premium)
 *   T.cyan:      #00D4FF     → Cyan (info / UI highlights)
 *   T.profit:    #10b981     → Profit green
 *   T.loss:      #ef4444     → Loss red
 *   T.text:      #F0F2F5     → Primary text
 *   T.text2:     #8B92A8     → Secondary text
 */
object RouaColors {
    // ── Background (web: T.bg, T.bgLight, T.bgLighter, T.bg2) ──
    val Background = Color(0xFF0B0E14)
    val BackgroundLight = Color(0xFF111520)
    val BackgroundLighter = Color(0xFF161B28)
    val Background2 = Color(0xFF0F1117)

    // ── Cards & Surfaces (web: T.card, T.cardHover, T.cardBorder, T.surface) ──
    val Card = Color(0xFF1A1D29)
    val CardHover = Color(0xFF1F2335)
    val CardBorder = Color(0xFF252A3A)
    val Surface = Color(0xFF1A1D29)
    val SurfaceElevated = Color(0xFF1F2335)

    // ── Brand (web: T.brand, T.brandLight) ──
    val Brand = Color(0xFF6C5CE7)
    val BrandLight = Color(0xFFA29BFE)

    // ── Accent — Primary (web: T.accent = #059669 emerald green) ──
    val Accent = Color(0xFF059669)
    val AccentLight = Color(0xFF10B981)
    val AccentDark = Color(0xFF047857)

    // ── Accent — Blue (web: T.blue) ──
    val Blue = Color(0xFF0A84FF)

    // ── Accent — Cyan (web: T.cyan = #00D4FF for UI highlights) ──
    val Cyan = Color(0xFF00D4FF)
    val CyanBright = Color(0xFF00D4FF)

    // ── Status — Success (web: T.success = #00FFA3) ──
    val Success = Color(0xFF00FFA3)
    val SuccessDim = Color(0xFF00CC82)

    // ── Status — Danger (web: T.danger = #FF4757) ──
    val Danger = Color(0xFFFF4757)

    // ── Profit / Loss (web: T.profit = #10b981, T.loss = #ef4444) ──
    val Profit = Color(0xFF10B981)
    val ProfitLight = Color(0xFF69F0AE)
    val ProfitBackground = Color(0x1A10B981)

    val Loss = Color(0xFFEF4444)
    val LossLight = Color(0xFFFF5252)
    val LossBackground = Color(0x1AEF4444)

    // ── Warning / Amber (web: T.warning = #FFB800, T.amber) ──
    val Warning = Color(0xFFFFB800)
    val WarningBackground = Color(0x1AFFB800)
    val Amber = Color(0xFFFFB800)

    // ── Info (web: T.info = #00D4FF) ──
    val Info = Color(0xFF00D4FF)
    val InfoBackground = Color(0x1A00D4FF)

    // ── Special (web: T.gold, T.purple, T.yellow) ──
    val Gold = Color(0xFFD4AF37)
    val Purple = Color(0xFFB388FF)
    val Yellow = Color(0xFFFFD93D)

    // ── Text (web: T.text = #F0F2F5, T.text2 = #8B92A8, T.textMuted) ──
    val TextPrimary = Color(0xFFF0F2F5)
    val TextSecondary = Color(0xFF8B92A8)
    val TextTertiary = Color(0xFF8B92A8)
    val TextMuted = Color(0xFF4A5568)
    val TextDisabled = Color(0xFF475569)

    // ── Borders (web: T.border = rgba(255,255,255,0.06), T.border2) ──
    val Border = Color(0x0FFFFFFF)          // rgba(255,255,255,0.06)
    val Border2 = Color(0x1FFFFFFF)         // rgba(255,255,255,0.12)
    val BorderAccent = Color(0x40059669)     // rgba(5,150,105,0.25)
    val BorderCyan = Color(0x2900D4FF)       // rgba(0,212,255,0.16)
    val CardBorderLight = Color(0xFF252A3A)

    // ── Glass / Transparency (web: T.glass, T.navGlass) ──
    val Glass = Color(0x0AFFFFFF)            // rgba(255,255,255,0.04)
    val NavGlass = Color(0xD90B0E14)         // rgba(11,14,20,0.85)

    // ── Gradients (applied via Brush.linearGradient in composables) ──
    // Brand:  #6C5CE7 → #A29BFE
    // Profit: #00FFA3 → #10B981
    // Loss:   #FF4757 → #EF4444
    // Info:   #00D4FF → #0A84FF

    // ── Shadows (web: T.shadowCard, T.glowAccent, T.glowProfit, T.glowLoss) ──
    // Applied via Modifier.shadow() and custom drawBehind{}
}

/**
 * P/L Color Utility — matches web's getPnlColor(), isPnlPositive(), getPnlSign()
 *
 * Rule: ZERO is NEUTRAL (not profit, not loss).
 *   > 0 → profit color (green)
 *   < 0 → loss color (red)
 *   = 0 → neutral/muted color (gray)
 */
fun getPnlColor(value: Double): Color {
    return when {
        value > 0 -> RouaColors.Profit
        value < 0 -> RouaColors.Loss
        else -> RouaColors.TextSecondary
    }
}

fun getPnlColor(value: Float): Color = getPnlColor(value.toDouble())

fun isPnlPositive(value: Double): Boolean = value > 0
fun isPnlPositive(value: Float): Boolean = value > 0

fun getPnlSign(value: Double): String = when {
    value > 0 -> "+"
    value < 0 -> "-"
    else -> ""
}
