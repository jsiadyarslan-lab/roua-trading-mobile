// =============================================================================
// RouaTypography.swift — Roua Trading Design System · Typography
// =============================================================================
// Unified type scale for the Roua Trading app.
// All sizes reference @2x/@3x iOS dynamic rendering.
// Monospaced styles for prices, PnL, and ticker data.
// =============================================================================

import SwiftUI

// MARK: - Font Scale

enum RouaFont {
    /// 34 pt · bold — hero headlines, onboarding titles
    case largeTitle
    /// 28 pt · bold — screen titles
    case title1
    /// 22 pt · bold — section titles, modal headers
    case title2
    /// 20 pt · semibold — card titles, prominent labels
    case title3
    /// 17 pt · semibold — navigation items, list headers
    case headline
    /// 17 pt · regular — primary body text
    case body
    /// 17 pt · bold — emphasized body text
    case bodyBold
    /// 16 pt · regular — secondary body, form labels
    case callout
    /// 16 pt · semibold — emphasized callout
    case calloutBold
    /// 15 pt · regular — captions, helper text
    case subheadline
    /// 15 pt · semibold — emphasized subheadline
    case subheadlineBold
    /// 13 pt · regular — timestamps, tags, footnotes
    case footnote
    /// 13 pt · semibold — emphasized footnote
    case footnoteBold
    /// 12 pt · regular — badges, chip labels
    case caption
    /// 12 pt · semibold — emphasized caption
    case captionBold
    /// 10 pt · regular — micro labels, indicators
    case micro
    /// 15 pt · monospaced — prices, PnL figures
    case mono
    /// 13 pt · monospaced — small prices, percentages
    case monoSmall

    /// The resolved SwiftUI `Font`.
    var font: Font {
        switch self {
        case .largeTitle:     return .system(size: 34, weight: .bold, design: .default)
        case .title1:         return .system(size: 28, weight: .bold, design: .default)
        case .title2:         return .system(size: 22, weight: .bold, design: .default)
        case .title3:         return .system(size: 20, weight: .semibold, design: .default)
        case .headline:       return .system(size: 17, weight: .semibold, design: .default)
        case .body:           return .system(size: 17, weight: .regular, design: .default)
        case .bodyBold:       return .system(size: 17, weight: .bold, design: .default)
        case .callout:        return .system(size: 16, weight: .regular, design: .default)
        case .calloutBold:    return .system(size: 16, weight: .semibold, design: .default)
        case .subheadline:    return .system(size: 15, weight: .regular, design: .default)
        case .subheadlineBold: return .system(size: 15, weight: .semibold, design: .default)
        case .footnote:       return .system(size: 13, weight: .regular, design: .default)
        case .footnoteBold:   return .system(size: 13, weight: .semibold, design: .default)
        case .caption:        return .system(size: 12, weight: .regular, design: .default)
        case .captionBold:    return .system(size: 12, weight: .semibold, design: .default)
        case .micro:          return .system(size: 10, weight: .regular, design: .default)
        case .mono:           return .system(size: 15, weight: .regular, design: .monospaced)
        case .monoSmall:      return .system(size: 13, weight: .regular, design: .monospaced)
        }
    }

    /// Point size for the style — useful for fixed-height layouts.
    var size: CGFloat {
        switch self {
        case .largeTitle:     return 34
        case .title1:         return 28
        case .title2:         return 22
        case .title3:         return 20
        case .headline:       return 17
        case .body:           return 17
        case .bodyBold:       return 17
        case .callout:        return 16
        case .calloutBold:    return 16
        case .subheadline:    return 15
        case .subheadlineBold: return 15
        case .footnote:       return 13
        case .footnoteBold:   return 13
        case .caption:        return 12
        case .captionBold:    return 12
        case .micro:          return 10
        case .mono:           return 15
        case .monoSmall:      return 13
        }
    }

    /// Line height multiplier for consistent vertical rhythm.
    var lineHeight: CGFloat {
        switch self {
        case .largeTitle, .title1, .title2:
            return 1.2
        case .title3, .headline, .body, .bodyBold, .callout, .calloutBold:
            return 1.35
        case .subheadline, .subheadlineBold, .footnote, .footnoteBold:
            return 1.4
        case .caption, .captionBold, .micro, .mono, .monoSmall:
            return 1.45
        }
    }

    /// Tracking (letter spacing) in points.
    var tracking: CGFloat {
        switch self {
        case .caption, .captionBold, .micro:
            return 0.2
        case .mono, .monoSmall:
            return 0
        default:
            return -0.1
        }
    }
}

// MARK: - View Modifier

extension View {

    /// Applies a `RouaFont` style to the view, including tracking.
    func rouaFont(_ style: RouaFont) -> some View {
        self
            .font(style.font)
            .tracking(style.tracking)
    }

    /// Applies a `RouaFont` style with a specific color.
    func rouaFont(_ style: RouaFont, color: Color) -> some View {
        self
            .font(style.font)
            .tracking(style.tracking)
            .foregroundStyle(color)
    }

    /// Applies line-height-aware frame height for the given style.
    func rouaLineHeight(_ style: RouaFont) -> some View {
        let height = style.size * style.lineHeight
        return self.frame(minHeight: height, alignment: .leading)
    }
}

// MARK: - Preview

#Preview("RouaTypography Scale") {
    ScrollView {
        VStack(alignment: .leading, spacing: RouaSpacing.lg) {
            ForEach(RouaFont.allCases, id: \.self) { style in
                HStack(alignment: .firstTextBaseline) {
                    Text(String(format: "%.0fpt", style.size))
                        .rouaFont(.caption, color: .rouaTextTertiary)
                        .frame(width: 40, alignment: .trailing)
                    Text(style.displayName)
                        .rouaFont(style)
                        .foregroundStyle(.rouaTextPrimary)
                }
            }
        }
        .padding()
    }
    .background(Color.rouaBackground)
}

// MARK: - Preview Helpers

extension RouaFont: CaseIterable {
    static let allCases: [RouaFont] = [
        .largeTitle, .title1, .title2, .title3,
        .headline, .body, .bodyBold,
        .callout, .calloutBold,
        .subheadline, .subheadlineBold,
        .footnote, .footnoteBold,
        .caption, .captionBold,
        .micro,
        .mono, .monoSmall,
    ]

    var displayName: String {
        switch self {
        case .largeTitle:     return "Large Title"
        case .title1:         return "Title 1"
        case .title2:         return "Title 2"
        case .title3:         return "Title 3"
        case .headline:       return "Headline"
        case .body:           return "Body"
        case .bodyBold:       return "Body Bold"
        case .callout:        return "Callout"
        case .calloutBold:    return "Callout Bold"
        case .subheadline:    return "Subheadline"
        case .subheadlineBold: return "Subheadline Bold"
        case .footnote:       return "Footnote"
        case .footnoteBold:   return "Footnote Bold"
        case .caption:        return "Caption"
        case .captionBold:    return "Caption Bold"
        case .micro:          return "Micro"
        case .mono:           return "Mono 15"
        case .monoSmall:      return "Mono 13"
        }
    }
}
