// =============================================================================
// RouaSpacing.swift — Roua Trading Design System · Spacing & Layout
// =============================================================================
// Consistent spacing, corner radii, and layout metrics.
// All values in points. Use these instead of magic numbers.
// =============================================================================

import SwiftUI

enum RouaSpacing {

    // MARK: - Inline Spacing

    /// 4 pt — tight gaps between icon & text, tiny padding
    static let xs: CGFloat = 4
    /// 8 pt — small gaps, inner chip padding
    static let sm: CGFloat = 8
    /// 12 pt — medium gaps, list item spacing
    static let md: CGFloat = 12
    /// 16 pt — standard padding, card inner padding
    static let lg: CGFloat = 16
    /// 20 pt — section padding, comfortable spacing
    static let xl: CGFloat = 20
    /// 24 pt — large gaps, screen edge insets on iPad
    static let xxl: CGFloat = 24
    /// 32 pt — extra large, major section separators
    static let xxxl: CGFloat = 32

    // MARK: - Padding Presets

    /// Standard card inner padding — 16 pt
    static let cardPadding: CGFloat = 16
    /// Section vertical padding — 20 pt
    static let sectionPadding: CGFloat = 20
    /// Screen horizontal padding — 16 pt
    static let screenPadding: CGFloat = 16

    // MARK: - Corner Radii

    /// Card corner radius — 16 pt
    static let cardCornerRadius: CGFloat = 16
    /// Button corner radius — 12 pt
    static let buttonCornerRadius: CGFloat = 12
    /// Small element corner radius (chips, badges) — 8 pt
    static let smallCornerRadius: CGFloat = 8
    /// Pill / full-round corner radius — 999 pt
    static let pillCornerRadius: CGFloat = 999

    // MARK: - Layout Heights

    /// Custom tab bar height — 83 pt (includes safe area)
    static let tabBarHeight: CGFloat = 83
    /// Navigation bar content height — 44 pt
    static let navBarHeight: CGFloat = 44
    /// Standard button height — 48 pt
    static let buttonHeight: CGFloat = 48
    /// Small button height — 36 pt
    static let buttonHeightSmall: CGFloat = 36
    /// Large button height — 56 pt
    static let buttonHeightLarge: CGFloat = 56
    /// Standard list row height — 64 pt
    static let rowHeight: CGFloat = 64
    /// Compact list row height — 48 pt
    static let rowHeightCompact: CGFloat = 48
    /// Ticker row height — 72 pt
    static let tickerRowHeight: CGFloat = 72

    // MARK: - Icon Sizes

    /// 16 pt — inline icons, badge icons
    static let iconSmall: CGFloat = 16
    /// 20 pt — standard icon alongside text
    static let iconMedium: CGFloat = 20
    /// 24 pt — prominent icons, tab bar icons
    static let iconLarge: CGFloat = 24
    /// 32 pt — featured icons, empty state
    static let iconXL: CGFloat = 32
    /// 48 pt — hero icons
    static let iconXXL: CGFloat = 48
    /// 64 pt — illustration placeholders
    static let iconHero: CGFloat = 64

    // MARK: - Shadow

    /// Standard card shadow radius
    static let shadowRadius: CGFloat = 12
    /// Standard card shadow Y offset
    static let shadowOffsetY: CGFloat = 4
    /// Glow effect radius
    static let glowRadius: CGFloat = 20

    // MARK: - Animation

    /// Standard animation duration — 0.25 s
    static let animationDuration: Double = 0.25
    /// Fast animation duration — 0.15 s
    static let animationFast: Double = 0.15
    /// Slow / spring animation duration — 0.4 s
    static let animationSlow: Double = 0.4
    /// Shimmer animation duration — 1.5 s
    static let shimmerDuration: Double = 1.5
}

// MARK: - EdgeInsets Convenience

extension EdgeInsets {

    /// Card inner padding — all sides `RouaSpacing.cardPadding`.
    static let rouaCard = EdgeInsets(
        top: RouaSpacing.cardPadding,
        leading: RouaSpacing.cardPadding,
        bottom: RouaSpacing.cardPadding,
        trailing: RouaSpacing.cardPadding
    )

    /// Screen horizontal padding — top/bottom 0, leading/trailing `RouaSpacing.screenPadding`.
    static let rouaScreenHorizontal = EdgeInsets(
        top: 0,
        leading: RouaSpacing.screenPadding,
        bottom: 0,
        trailing: RouaSpacing.screenPadding
    )

    /// Section padding — vertical `sectionPadding`, horizontal `screenPadding`.
    static let rouaSection = EdgeInsets(
        top: RouaSpacing.sectionPadding,
        leading: RouaSpacing.screenPadding,
        bottom: RouaSpacing.sectionPadding,
        trailing: RouaSpacing.screenPadding
    )
}

// MARK: - View Layout Helpers

extension View {

    /// Applies standard card inner padding.
    func rouaCardPadding() -> some View {
        padding(RouaSpacing.cardPadding)
    }

    /// Applies horizontal screen-edge padding.
    func rouaScreenPadding() -> some View {
        padding(.horizontal, RouaSpacing.screenPadding)
    }

    /// Applies standard card corner radius.
    func rouaCardCorners() -> some View {
        clipShape(RoundedRectangle(cornerRadius: RouaSpacing.cardCornerRadius, style: .continuous))
    }

    /// Applies button corner radius.
    func rouaButtonCorners() -> some View {
        clipShape(RoundedRectangle(cornerRadius: RouaSpacing.buttonCornerRadius, style: .continuous))
    }
}

// MARK: - Preview

#Preview("RouaSpacing Reference") {
    VStack(spacing: RouaSpacing.lg) {
        ForEach([
            ("xs", RouaSpacing.xs),
            ("sm", RouaSpacing.sm),
            ("md", RouaSpacing.md),
            ("lg", RouaSpacing.lg),
            ("xl", RouaSpacing.xl),
            ("xxl", RouaSpacing.xxl),
            ("xxxl", RouaSpacing.xxxl),
        ], id: \.0) { name, value in
            HStack(spacing: RouaSpacing.md) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(.rouaPrimary)
                    .frame(width: value, height: value)
                Text("\(name) — \(Int(value))pt")
                    .rouaFont(.callout, color: .rouaTextPrimary)
                Spacer()
            }
        }
    }
    .padding()
    .background(Color.rouaBackground)
}
