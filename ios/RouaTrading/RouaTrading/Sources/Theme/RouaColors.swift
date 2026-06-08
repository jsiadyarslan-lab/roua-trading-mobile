// =============================================================================
// RouaColors.swift — Roua Trading Design System · Color Palette
// =============================================================================
// UNIFIED with web unified-tokens.ts — single source of truth.
// Every color MUST match the web exactly.
//
// CANONICAL VALUES (from web unified-tokens.ts):
//   T.bg:        #0B0E14     → rouaBackground
//   T.card:      #1A1D29     → rouaSurface / rouaCard
//   T.cardHover: #1F2335     → rouaCardHover
//   T.accent:    #059669     → rouaAccentPrimary (emerald green — primary brand)
//   T.brand:     #6C5CE7     → rouaBrand (purple)
//   T.gold:      #d4af37     → rouaGold (premium)
//   T.cyan:      #00D4FF     → rouaCyan (info / UI highlights)
//   T.profit:    #10b981     → rouaProfit
//   T.loss:      #ef4444     → rouaLoss
//   T.text:      #F0F2F5     → rouaTextPrimary
//   T.text2:     #8B92A8     → rouaTextSecondary
// =============================================================================

import SwiftUI

extension Color {

    // MARK: - Background (web: T.bg, T.bgLight, T.bgLighter, T.bg2)

    /// Main background — #0B0E14 (web: T.bg)
    static let rouaBackground = Color(hex: "0B0E14")
    /// Light background — #111520 (web: T.bgLight)
    static let rouaBackgroundLight = Color(hex: "111520")
    /// Lighter background — #161B28 (web: T.bgLighter)
    static let rouaBackgroundLighter = Color(hex: "161B28")
    /// Secondary background — #0F1117 (web: T.bg2)
    static let rouaBackground2 = Color(hex: "0F1117")

    // MARK: - Cards & Surfaces (web: T.card, T.cardHover, T.cardBorder, T.surface)

    /// Card / surface background — #1A1D29 (web: T.card, T.surface)
    static let rouaSurface = Color(hex: "1A1D29")
    /// Card alias
    static let rouaCard = Color(hex: "1A1D29")
    /// Card hover state — #1F2335 (web: T.cardHover)
    static let rouaCardHover = Color(hex: "1F2335")
    /// Elevated surface — same as cardHover
    static let rouaSurfaceLight = Color(hex: "1F2335")
    /// Card border — #252A3A (web: T.cardBorder)
    static let rouaCardBorder = Color(hex: "252A3A")
    /// Hover / pressed state fill
    static let rouaSurfaceHover = Color(hex: "222B45")

    // MARK: - Brand (web: T.brand, T.brandLight)

    /// Brand purple — #6C5CE7 (web: T.brand)
    static let rouaBrand = Color(hex: "6C5CE7")
    /// Brand light / lavender — #A29BFE (web: T.brandLight)
    static let rouaBrandLight = Color(hex: "A29BFE")
    /// Backward compat
    static let rouaPrimary = Color(hex: "6C5CE7")
    static let rouaSecondary = Color(hex: "A29BFE")

    // MARK: - Accent — Primary (web: T.accent = #059669 emerald green)

    /// Primary accent — emerald green #059669 (web: T.accent)
    static let rouaAccentPrimary = Color(hex: "059669")
    /// Accent light — #10b981 (web: T.profit)
    static let rouaAccentLight = Color(hex: "10B981")
    /// Accent dark — #047857
    static let rouaAccentDark = Color(hex: "047857")

    // MARK: - Accent — Blue (web: T.blue)

    /// Blue accent — #0A84FF (web: T.blue)
    static let rouaBlue = Color(hex: "0A84FF")

    // MARK: - Accent — Cyan (web: T.cyan = #00D4FF for UI highlights)

    /// Cyan / info highlight — #00D4FF (web: T.cyan)
    static let rouaCyan = Color(hex: "00D4FF")
    /// Backward compat
    static let rouaAccent = Color(hex: "00D4FF")

    // MARK: - Status — Success (web: T.success = #00FFA3)

    /// Success — #00FFA3 (web: T.success)
    static let rouaSuccess = Color(hex: "00FFA3")
    /// Success dim — #00CC82 (web: T.greenDim)
    static let rouaSuccessDim = Color(hex: "00CC82")

    // MARK: - Status — Danger (web: T.danger = #FF4757)

    /// Danger — #FF4757 (web: T.danger)
    static let rouaDanger = Color(hex: "FF4757")

    // MARK: - Profit / Loss (web: T.profit = #10b981, T.loss = #ef4444)

    /// Profit / buy / positive — #10b981 (web: T.profit)
    static let rouaProfit = Color(hex: "10B981")
    /// Loss / sell / negative — #ef4444 (web: T.loss)
    static let rouaLoss = Color(hex: "EF4444")
    /// Profit light — 15% opacity for badges
    static let rouaProfitLight = Color(hex: "10B981", opacity: 0.15)
    /// Loss light — 15% opacity
    static let rouaLossLight = Color(hex: "EF4444", opacity: 0.15)
    /// Profit background — 10% opacity for card fills
    static let rouaProfitBg = Color(hex: "10B981", opacity: 0.1)
    /// Loss background — 10% opacity
    static let rouaLossBg = Color(hex: "EF4444", opacity: 0.1)
    /// Buy action color (same as profit)
    static let rouaBuy = Color(hex: "10B981")
    /// Sell action color (same as loss)
    static let rouaSell = Color(hex: "EF4444")

    // MARK: - Warning / Amber (web: T.warning = #FFB800, T.amber)

    /// Warning / amber — #FFB800 (web: T.warning, T.amber)
    static let rouaWarning = Color(hex: "FFB800")
    /// Warning background — 10% opacity
    static let rouaWarningBg = Color(hex: "FFB800", opacity: 0.1)

    // MARK: - Info (web: T.info = #00D4FF)

    /// Info — #00D4FF (web: T.info)
    static let rouaInfo = Color(hex: "00D4FF")
    /// Info background — 10% opacity
    static let rouaInfoBg = Color(hex: "00D4FF", opacity: 0.1)

    // MARK: - Special (web: T.gold, T.purple, T.yellow)

    /// Gold / premium — #d4af37 (web: T.gold)
    static let rouaGold = Color(hex: "D4AF37")
    /// Purple / AI accent — #B388FF (web: T.purple)
    static let rouaPurple = Color(hex: "B388FF")
    /// Yellow — #FFD93D (web: T.yellow)
    static let rouaYellow = Color(hex: "FFD93D")
    /// Neutral — blue-gray
    static let rouaNeutral = Color(hex: "8B92A8")

    // MARK: - Text (web: T.text = #F0F2F5, T.text2 = #8B92A8, T.textMuted)

    /// Primary text — #F0F2F5 (web: T.text)
    static let rouaTextPrimary = Color(hex: "F0F2F5")
    /// Secondary text — #8B92A8 (web: T.text2, T.text3)
    static let rouaTextSecondary = Color(hex: "8B92A8")
    /// Tertiary text — same as secondary (web: T.text3)
    static let rouaTextTertiary = Color(hex: "8B92A8")
    /// Muted text — #4A5568 (web: T.textMuted)
    static let rouaTextMuted = Color(hex: "4A5568")
    /// Disabled text — white 20%
    static let rouaTextDisabled = Color(hex: "FFFFFF", opacity: 0.2)

    // MARK: - Borders (web: T.border = rgba(255,255,255,0.06), T.border2)

    /// Standard border — white 6% (web: T.border)
    static let rouaBorder = Color(hex: "FFFFFF", opacity: 0.06)
    /// Stronger border — white 12% (web: T.border2)
    static let rouaBorder2 = Color(hex: "FFFFFF", opacity: 0.12)
    /// Light border — white 5%
    static let rouaBorderLight = Color(hex: "FFFFFF", opacity: 0.05)
    /// Accent border — rgba(5,150,105,0.25) (web: T.borderAccent)
    static let rouaBorderAccent = Color(hex: "059669", opacity: 0.25)
    /// Cyan border — rgba(0,212,255,0.16) (web: T.borderCyan)
    static let rouaBorderCyan = Color(hex: "00D4FF", opacity: 0.16)

    // MARK: - Glass / Transparency (web: T.glass, T.navGlass)

    /// Glassmorphism fill — white 4% (web: T.glass)
    static let rouaGlass = Color(hex: "FFFFFF", opacity: 0.04)
    /// Glassmorphism border — white 10%
    static let rouaGlassBorder = Color(hex: "FFFFFF", opacity: 0.1)
    /// Stronger glass fill — white 8%
    static let rouaGlassStrong = Color(hex: "FFFFFF", opacity: 0.08)
    /// Navigation glass — rgba(11,14,20,0.85) (web: T.navGlass)
    static let rouaNavGlass = Color(hex: "0B0E14", opacity: 0.85)

    // MARK: - Gradients (web: T.gradientBrand, T.gradientGreen, T.gradientRed, etc.)

    /// Brand gradient — purple → lavender (web: T.gradientBrand)
    static let rouaGradientBrand = LinearGradient(
        colors: [Color(hex: "6C5CE7"), Color(hex: "A29BFE")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Green/success gradient (web: T.gradientGreen)
    static let rouaGradientGreen = LinearGradient(
        colors: [Color(hex: "00FFA3"), Color(hex: "00CC82")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Profit gradient (web: T.gradientProfit)
    static let rouaGradientProfit = LinearGradient(
        colors: [Color(hex: "00FFA3"), Color(hex: "10B981")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Red/danger gradient (web: T.gradientRed)
    static let rouaGradientRed = LinearGradient(
        colors: [Color(hex: "FF4757"), Color(hex: "FF6B81")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Loss gradient (web: T.gradientLoss)
    static let rouaGradientLoss = LinearGradient(
        colors: [Color(hex: "FF4757"), Color(hex: "EF4444")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Info/accent gradient (web: T.gradientInfo)
    static let rouaGradientInfo = LinearGradient(
        colors: [Color(hex: "00D4FF"), Color(hex: "0A84FF")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Accent gradient — cyan → purple (backward compat)
    static let rouaGradientAccent = LinearGradient(
        colors: [Color(hex: "00D4FF"), Color(hex: "6C5CE7")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Primary brand gradient (backward compat alias)
    static let rouaGradientPrimary = LinearGradient(
        colors: [Color(hex: "6C5CE7"), Color(hex: "A29BFE")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - ShapeStyle Conformance (for .foregroundStyle(.rouaXxx) syntax)

extension ShapeStyle where Self == Color {
    // Brand
    static var rouaPrimary: Color { Color.rouaPrimary }
    static var rouaSecondary: Color { Color.rouaSecondary }
    static var rouaBrand: Color { Color.rouaBrand }
    static var rouaBrandLight: Color { Color.rouaBrandLight }

    // Accent
    static var rouaAccent: Color { Color.rouaAccent }
    static var rouaAccentPrimary: Color { Color.rouaAccentPrimary }
    static var rouaAccentLight: Color { Color.rouaAccentLight }
    static var rouaAccentDark: Color { Color.rouaAccentDark }

    // Color accents
    static var rouaCyan: Color { Color.rouaCyan }
    static var rouaBlue: Color { Color.rouaBlue }
    static var rouaGold: Color { Color.rouaGold }
    static var rouaPurple: Color { Color.rouaPurple }
    static var rouaYellow: Color { Color.rouaYellow }

    // Status
    static var rouaSuccess: Color { Color.rouaSuccess }
    static var rouaSuccessDim: Color { Color.rouaSuccessDim }
    static var rouaDanger: Color { Color.rouaDanger }
    static var rouaProfit: Color { Color.rouaProfit }
    static var rouaLoss: Color { Color.rouaLoss }
    static var rouaBuy: Color { Color.rouaBuy }
    static var rouaSell: Color { Color.rouaSell }
    static var rouaWarning: Color { Color.rouaWarning }
    static var rouaInfo: Color { Color.rouaInfo }
    static var rouaNeutral: Color { Color.rouaNeutral }

    // Text
    static var rouaTextPrimary: Color { Color.rouaTextPrimary }
    static var rouaTextSecondary: Color { Color.rouaTextSecondary }
    static var rouaTextTertiary: Color { Color.rouaTextTertiary }
    static var rouaTextMuted: Color { Color.rouaTextMuted }
    static var rouaTextDisabled: Color { Color.rouaTextDisabled }

    // Backgrounds & Surfaces
    static var rouaBackground: Color { Color.rouaBackground }
    static var rouaBackgroundLight: Color { Color.rouaBackgroundLight }
    static var rouaBackgroundLighter: Color { Color.rouaBackgroundLighter }
    static var rouaBackground2: Color { Color.rouaBackground2 }
    static var rouaSurface: Color { Color.rouaSurface }
    static var rouaCard: Color { Color.rouaCard }
    static var rouaCardHover: Color { Color.rouaCardHover }
    static var rouaSurfaceLight: Color { Color.rouaSurfaceLight }
    static var rouaCardBorder: Color { Color.rouaCardBorder }
}

// MARK: - P/L Color Utility (matches web: getPnlColor, isPnlPositive, getPnlSign)

extension Color {

    /// Returns profit/loss/neutral color based on sign.
    /// Positive → green (#10b981), negative → red (#ef4444), zero → neutral (#8B92A8).
    /// Matches web's getPnlColor() exactly.
    static func rouaPnLColor(value: Double) -> Color {
        if value > 0 { return .rouaProfit }
        if value < 0 { return .rouaLoss }
        return .rouaTextSecondary  // neutral/gray for zero (web: T.text2)
    }

    /// Returns the light (15% opacity) P/L color for badge backgrounds.
    static func rouaPnLLightColor(value: Double) -> Color {
        if value > 0 { return .rouaProfitLight }
        if value < 0 { return .rouaLossLight }
        return .rouaNeutral.opacity(0.15)
    }

    /// Returns the background (10% opacity) P/L color.
    static func rouaPnLBgColor(value: Double) -> Color {
        if value > 0 { return .rouaProfitBg }
        if value < 0 { return .rouaLossBg }
        return .rouaNeutral.opacity(0.1)
    }
}

/// Returns '+' for positive, '-' for negative, '' for zero (matches web's getPnlSign)
func rouaPnlSign(_ value: Double) -> String {
    if value > 0 { return "+" }
    if value < 0 { return "-" }
    return ""
}

/// Returns true ONLY when value is strictly positive (matches web's isPnlPositive)
func rouaIsPnlPositive(_ value: Double) -> Bool {
    return value > 0
}
