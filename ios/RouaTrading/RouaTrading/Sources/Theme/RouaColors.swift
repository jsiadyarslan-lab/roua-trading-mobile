// =============================================================================
// RouaColors.swift — Roua Trading Design System · Color Palette
// =============================================================================
// Dark-native trading app color system with glassmorphism support.
// Green/red for profit/loss. Purple brand identity. RTL-aware (no directional colors).
// =============================================================================

import SwiftUI

extension Color {

    // MARK: - Brand

    /// Primary brand color — vibrant purple
    static let rouaPrimary = Color(hex: "6C5CE7")
    /// Secondary brand color — soft lavender
    static let rouaSecondary = Color(hex: "A29BFE")
    /// Accent color — electric cyan
    static let rouaAccent = Color(hex: "00D2FF")

    // MARK: - Trading

    /// Profit / buy / positive — vivid green
    static let rouaProfit = Color(hex: "00C853")
    /// Loss / sell / negative — vivid red
    static let rouaLoss = Color(hex: "FF1744")
    /// Profit with 15 % opacity — for badges, chips, tags
    static let rouaProfitLight = Color(hex: "00C853").opacity(0.15)
    /// Loss with 15 % opacity
    static let rouaLossLight = Color(hex: "FF1744").opacity(0.15)
    /// Profit background — 10 % opacity for card fills
    static let rouaProfitBg = Color(hex: "00C853").opacity(0.1)
    /// Loss background — 10 % opacity
    static let rouaLossBg = Color(hex: "FF1744").opacity(0.1)

    // MARK: - Semantic

    /// Buy action color
    static let rouaBuy = Color(hex: "00C853")
    /// Sell action color
    static let rouaSell = Color(hex: "FF1744")
    /// Warning — amber
    static let rouaWarning = Color(hex: "FFB800")
    /// Informational — cyan
    static let rouaInfo = Color(hex: "00D2FF")
    /// Neutral — blue-gray
    static let rouaNeutral = Color(hex: "78909C")

    // MARK: - Backgrounds

    /// Deepest background — near-black navy
    static let rouaBackground = Color(hex: "0A0E17")
    /// Card / surface background
    static let rouaSurface = Color(hex: "131825")
    /// Elevated surface (sheets, popovers)
    static let rouaSurfaceLight = Color(hex: "1A2035")
    /// Hover / pressed state fill
    static let rouaSurfaceHover = Color(hex: "222B45")

    // MARK: - Glass

    /// Glassmorphism fill — white 5 %
    static let rouaGlass = Color.white.opacity(0.05)
    /// Glassmorphism border — white 10 %
    static let rouaGlassBorder = Color.white.opacity(0.1)
    /// Stronger glass fill — white 8 %
    static let rouaGlassStrong = Color.white.opacity(0.08)

    // MARK: - Text

    /// Primary text — pure white
    static let rouaTextPrimary = Color.white
    /// Secondary text — white 70 %
    static let rouaTextSecondary = Color.white.opacity(0.7)
    /// Tertiary text — white 40 %
    static let rouaTextTertiary = Color.white.opacity(0.4)
    /// Disabled text — white 20 %
    static let rouaTextDisabled = Color.white.opacity(0.2)

    // MARK: - Borders

    /// Standard border — white 8 %
    static let rouaBorder = Color.white.opacity(0.08)
    /// Light border — white 5 %
    static let rouaBorderLight = Color.white.opacity(0.05)

    // MARK: - Gradients

    /// Primary brand gradient — purple → lavender
    static let rouaGradientPrimary = LinearGradient(
        colors: [Color(hex: "6C5CE7"), Color(hex: "A29BFE")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Profit gradient — green → mint
    static let rouaGradientProfit = LinearGradient(
        colors: [Color(hex: "00C853"), Color(hex: "69F0AE")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Loss gradient — red → salmon
    static let rouaGradientLoss = LinearGradient(
        colors: [Color(hex: "FF1744"), Color(hex: "FF8A80")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Accent gradient — cyan → purple
    static let rouaGradientAccent = LinearGradient(
        colors: [Color(hex: "00D2FF"), Color(hex: "6C5CE7")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Hex Initializer

    /// Creates a `Color` from a hexadecimal string.
    /// Supports 6-character (RGB) and 8-character (RGBA) formats, with or without `#` prefix.
    /// - Parameter hex: Hex string, e.g. `"FF1744"` or `"FF1744CC"`.
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var rgbValue: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&rgbValue)

        let a, r, g, b: UInt64
        switch sanitized.count {
        case 6: // RGB
            (a, r, g, b) = (255, (rgbValue >> 16) & 0xFF, (rgbValue >> 8) & 0xFF, rgbValue & 0xFF)
        case 8: // RGBA
            (a, r, g, b) = ((rgbValue >> 24) & 0xFF, (rgbValue >> 16) & 0xFF, (rgbValue >> 8) & 0xFF, rgbValue & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0
        )
    }
}

// MARK: - SwiftUI ColorScheme Convenience

extension Color {

    /// Returns `rouaProfit` or `rouaLoss` depending on sign.
    /// Positive → green, negative → red, zero → neutral.
    static func rouaPnLColor(value: Double) -> Color {
        if value > 0 { return .rouaProfit }
        if value < 0 { return .rouaLoss }
        return .rouaNeutral
    }

    /// Returns the light (15 % opacity) PnL color for badge backgrounds.
    static func rouaPnLLightColor(value: Double) -> Color {
        if value > 0 { return .rouaProfitLight }
        if value < 0 { return .rouaLossLight }
        return .rouaNeutral.opacity(0.15)
    }

    /// Returns the background (10 % opacity) PnL color.
    static func rouaPnLBgColor(value: Double) -> Color {
        if value > 0 { return .rouaProfitBg }
        if value < 0 { return .rouaLossBg }
        return .rouaNeutral.opacity(0.1)
    }
}

// MARK: - Preview

#Preview("RouaColors Palette") {
    ScrollView {
        VStack(alignment: .leading, spacing: RouaSpacing.lg) {
            ColorSection(title: "Brand", colors: [
                ("Primary", .rouaPrimary),
                ("Secondary", .rouaSecondary),
                ("Accent", .rouaAccent),
            ])
            ColorSection(title: "Trading", colors: [
                ("Profit", .rouaProfit),
                ("Loss", .rouaLoss),
                ("Profit Light", .rouaProfitLight),
                ("Loss Light", .rouaLossLight),
            ])
            ColorSection(title: "Backgrounds", colors: [
                ("Background", .rouaBackground),
                ("Surface", .rouaSurface),
                ("Surface Light", .rouaSurfaceLight),
                ("Surface Hover", .rouaSurfaceHover),
            ])
            ColorSection(title: "Glass", colors: [
                ("Glass", .rouaGlass),
                ("Glass Border", .rouaGlassBorder),
                ("Glass Strong", .rouaGlassStrong),
            ])
        }
        .padding()
    }
    .background(Color.rouaBackground)
}

private struct ColorSection: View {
    let title: String
    let colors: [(String, Color)]

    var body: some View {
        VStack(alignment: .leading, spacing: RouaSpacing.sm) {
            Text(title)
                .rouaFont(.headline)
                .foregroundStyle(.rouaTextSecondary)

            ForEach(colors, id: \.0) { name, color in
                HStack(spacing: RouaSpacing.md) {
                    RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius)
                        .fill(color)
                        .frame(width: 40, height: 40)
                    Text(name)
                        .rouaFont(.callout)
                        .foregroundStyle(.rouaTextPrimary)
                    Spacer()
                }
            }
        }
    }
}
