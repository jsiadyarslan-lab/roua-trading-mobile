// =============================================================================
// RouaComponents.swift — Roua Trading Design System · Reusable Components
// =============================================================================
// Glassmorphism cards, trading buttons, PnL badges, status dots, shimmer,
// stat displays, error banners, loading/empty states, section headers,
// ticker rows, position rows, status badges, avatars.
//
// All components:
//   • Use RouaColors / RouaTypography / RouaSpacing
//   • Support RTL layout (Arabic)
//   • Include accessibility labels
//   • Animate smoothly with consistent durations
// =============================================================================

import SwiftUI

// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║  GLASS CARD                                                              ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

/// Glassmorphism card with blur, gradient border, and optional glow.
///
/// Usage:
/// ```swift
/// GlassCard {
///     Text("Hello")
/// }
/// GlassCard(glow: .rouaPrimary) { … }
/// ```
struct GlassCard<Content: View>: View {

    let glow: Color?
    let action: (() -> Void)?
    @ViewBuilder let content: () -> Content

    /// - Parameters:
    ///   - glow: Optional color for outer glow effect. Pass `nil` for no glow.
    ///   - action: Optional tap action. If `nil`, card is non-interactive.
    ///   - content: Card body.
    init(
        glow: Color? = nil,
        action: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.glow = glow
        self.action = action
        self.content = content
    }

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    cardBody
                }
                .buttonStyle(.plain)
            } else {
                cardBody
            }
        }
        .accessibilityElement(children: .contain)
        .accessibility(addTraits: action != nil ? .isButton : [])
    }

    private var cardBody: some View {
        content()
            .padding(RouaSpacing.cardPadding)
            .background(
                ZStack {
                    // Frosted glass fill
                    RoundedRectangle(cornerRadius: RouaSpacing.cardCornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(0.6)
                    // Tinted overlay
                    RoundedRectangle(cornerRadius: RouaSpacing.cardCornerRadius, style: .continuous)
                        .fill(Color.rouaGlass)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: RouaSpacing.cardCornerRadius, style: .continuous)
                    .stroke(Color.rouaGlassBorder, lineWidth: 1)
            )
            .shadow(
                color: glow?.opacity(0.3) ?? .clear,
                radius: RouaSpacing.glowRadius,
                x: 0, y: 0
            )
            .shadow(
                color: .black.opacity(0.2),
                radius: RouaSpacing.shadowRadius,
                x: 0, y: RouaSpacing.shadowOffsetY
            )
            .contentShape(RoundedRectangle(cornerRadius: RouaSpacing.cardCornerRadius, style: .continuous))
    }
}

// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║  ROUA BUTTON                                                             ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

enum RouaButtonVariant {
    case primary      // Gradient fill
    case secondary    // Outline with tint
    case danger       // Red fill
    case ghost        // Text only
}

enum RouaButtonSize {
    case small
    case medium
    case large

    var height: CGFloat {
        switch self {
        case .small:  return RouaSpacing.buttonHeightSmall
        case .medium: return RouaSpacing.buttonHeight
        case .large:  return RouaSpacing.buttonHeightLarge
        }
    }

    var font: RouaFont {
        switch self {
        case .small:  return .footnoteBold
        case .medium: return .calloutBold
        case .large:  return .headline
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small:  return RouaSpacing.iconSmall
        case .medium: return RouaSpacing.iconMedium
        case .large:  return RouaSpacing.iconLarge
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .small:  return RouaSpacing.md
        case .medium: return RouaSpacing.lg
        case .large:  return RouaSpacing.xl
        }
    }
}

/// Primary trading button with variants, sizes, loading/disabled states, and haptic feedback.
struct RouaButton: View {

    let title: String
    let variant: RouaButtonVariant
    let size: RouaButtonSize
    let icon: String?           // SF Symbol name
    let iconPosition: IconPosition
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    enum IconPosition {
        case leading
        case trailing
    }

    init(
        _ title: String,
        variant: RouaButtonVariant = .primary,
        size: RouaButtonSize = .medium,
        icon: String? = nil,
        iconPosition: IconPosition = .leading,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.variant = variant
        self.size = size
        self.icon = icon
        self.iconPosition = iconPosition
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            guard !isDisabled, !isLoading else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            contentView
                .frame(height: size.height)
                .frame(maxWidth: .infinity)
                .background(backgroundView)
                .clipShape(RoundedRectangle(cornerRadius: RouaSpacing.buttonCornerRadius, style: .continuous))
                .overlay(borderOverlay)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeOut(duration: RouaSpacing.animationFast), value: isPressed)
        .opacity(isDisabled ? 0.4 : 1.0)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
        .accessibilityRemoveTraits(isDisabled ? .isButton : [])
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        HStack(spacing: RouaSpacing.sm) {
            if isLoading {
                ProgressView()
                    .tint(foregroundColor)
                    .scaleEffect(0.8)
            } else {
                if let icon, iconPosition == .leading {
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize))
                }
                Text(title)
                    .rouaFont(size.font, color: foregroundColor)
                if let icon, iconPosition == .trailing {
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize))
                }
            }
        }
        .padding(.horizontal, size.horizontalPadding)
    }

    // MARK: - Styling

    @ViewBuilder
    private var backgroundView: some View {
        switch variant {
        case .primary:
            Color.rouaGradientPrimary
        case .secondary:
            Color.clear
        case .danger:
            Color.rouaGradientLoss
        case .ghost:
            Color.clear
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        switch variant {
        case .secondary:
            RoundedRectangle(cornerRadius: RouaSpacing.buttonCornerRadius, style: .continuous)
                .stroke(Color.rouaPrimary, lineWidth: 1.5)
        case .ghost:
            EmptyView()
        default:
            EmptyView()
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary, .danger:
            return .white
        case .secondary:
            return .rouaPrimary
        case .ghost:
            return .rouaTextSecondary
        }
    }
}

// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║  CHANGE BADGE                                                            ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

/// Profit / loss change indicator with value, percentage, and directional arrow.
///
/// Automatically colors green for positive, red for negative.
struct ChangeBadge: View {

    let value: Double        // Absolute change
    let percentage: Double   // Percentage change
    let showArrow: Bool

    init(value: Double, percentage: Double, showArrow: Bool = true) {
        self.value = value
        self.percentage = percentage
        self.showArrow = showArrow
    }

    private var isPositive: Bool { value >= 0 }
    private var color: Color { .rouaPnLColor(value: value) }
    private var bgColor: Color { .rouaPnLLightColor(value: value) }

    var body: some View {
        HStack(spacing: RouaSpacing.xs) {
            if showArrow {
                Image(systemName: isPositive ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                    .font(.system(size: 8))
            }
            Text(formattedValue)
                .rouaFont(.footnoteBold)
            Text("(\(formattedPct))")
                .rouaFont(.footnote)
        }
        .foregroundStyle(color)
        .padding(.horizontal, RouaSpacing.sm)
        .padding(.vertical, RouaSpacing.xs)
        .background(bgColor)
        .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(isPositive ? "Up" : "Down") \(formattedValue), \(formattedPct) percent")
    }

    private var formattedValue: String {
        let sign = isPositive ? "+" : ""
        return "\(sign)\(String(format: "%.2f", value))"
    }

    private var formattedPct: String {
        let sign = isPositive ? "+" : ""
        return "\(sign)\(String(format: "%.2f", percentage))%"
    }
}

// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║  PULSING DOT                                                             ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

enum PulsingDotStatus {
    case active    // green
    case error     // red
    case warning   // yellow
    case inactive  // gray

    var color: Color {
        switch self {
        case .active:   return .rouaProfit
        case .error:    return .rouaLoss
        case .warning:  return .rouaWarning
        case .inactive: return .rouaNeutral
        }
    }
}

/// Animated status indicator dot with a pulse effect.
struct PulsingDot: View {

    let status: PulsingDotStatus
    let size: CGFloat

    init(status: PulsingDotStatus, size: CGFloat = 8) {
        self.status = status
        self.size = size
    }

    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Pulse ring
            Circle()
                .fill(status.color.opacity(0.3))
                .frame(width: size * (isPulsing ? 2.2 : 1.0), height: size * (isPulsing ? 2.2 : 1.0))

            // Solid dot
            Circle()
                .fill(status.color)
                .frame(width: size, height: size)
        }
        .animation(
            status == .inactive
                ? .none
                : .easeInOut(duration: RouaSpacing.animationSlow).repeatForever(autoreverses: true),
            value: isPulsing
        )
        .onAppear { isPulsing = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Status: \(statusAccessibility)")
    }

    private var statusAccessibility: String {
        switch status {
        case .active:   return "Active"
        case .error:    return "Error"
        case .warning:  return "Warning"
        case .inactive: return "Inactive"
        }
    }
}

// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║  SHIMMER VIEW                                                            ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

/// Loading skeleton with a shimmer animation.
struct ShimmerView: View {

    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat

    init(width: CGFloat? = nil, height: CGFloat = 16, cornerRadius: CGFloat = RouaSpacing.smallCornerRadius) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    @State private var phase: CGFloat = -1

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.rouaSurfaceLight)
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.0),
                                .white.opacity(0.06),
                                .white.opacity(0.0),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: phase * 400)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .onAppear {
                withAnimation(.linear(duration: RouaSpacing.shimmerDuration).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Loading")
            .accessibilityAddTraits(.isStaticText)
    }
}

// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║  STAT MINI                                                               ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

/// Compact stat display with label, value, and optional change indicator.
struct StatMini: View {

    let label: String
    let value: String
    let change: Double?

    init(label: String, value: String, change: Double? = nil) {
        self.label = label
        self.value = value
        self.change = change
    }

    var body: some View {
        VStack(alignment: .leading, spacing: RouaSpacing.xs) {
            Text(label)
                .rouaFont(.caption, color: .rouaTextTertiary)
                .lineLimit(1)
            HStack(spacing: RouaSpacing.xs) {
                Text(value)
                    .rouaFont(.calloutBold, color: .rouaTextPrimary)
                    .lineLimit(1)
                if let change {
                    ChangeBadge(value: change, percentage: change, showArrow: false)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)\(change.map { ", \($0 >= 0 ? "up" : "down") \($0)" } ?? "")")
    }
}

// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║  ERROR BANNER                                                            ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

/// Slide-in error notification banner with dismiss and retry actions.
struct ErrorBanner: View {

    let message: String
    let onRetry: (() -> Void)?
    let onDismiss: () -> Void

    @State private var isVisible = false

    init(message: String, onRetry: (() -> Void)? = nil, onDismiss: @escaping () -> Void) {
        self.message = message
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }

    var body: some View {
        HStack(spacing: RouaSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: RouaSpacing.iconMedium))
                .foregroundStyle(.rouaLoss)

            Text(message)
                .rouaFont(.subheadline, color: .rouaTextPrimary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let onRetry {
                Button {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    onRetry()
                } label: {
                    Text("Retry")
                        .rouaFont(.footnoteBold, color: .rouaLoss)
                }
                .accessibilityLabel("Retry")
            }

            Button {
                withAnimation(.easeOut(duration: RouaSpacing.animationFast)) {
                    isVisible = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onDismiss()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: RouaSpacing.iconSmall, weight: .bold))
                    .foregroundStyle(.rouaTextTertiary)
            }
            .accessibilityLabel("Dismiss error")
        }
        .padding(RouaSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                .fill(Color.rouaLossBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                .stroke(Color.rouaLoss.opacity(0.3), lineWidth: 1)
        )
        .offset(y: isVisible ? 0 : -20)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║  LOADING VIEW                                                            ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

/// Full-screen translucent loading overlay with spinner and optional message.
struct LoadingView: View {

    let message: String?

    init(message: String? = nil) {
        self.message = message
    }

    var body: some View {
        ZStack {
            Color.rouaBackground.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: RouaSpacing.lg) {
                ProgressView()
                    .tint(.rouaPrimary)
                    .scaleEffect(1.5)

                if let message {
                    Text(message)
                        .rouaFont(.subheadline, color: .rouaTextSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(RouaSpacing.xxxl)
            .background(
                RoundedRectangle(cornerRadius: RouaSpacing.cardCornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: RouaSpacing.cardCornerRadius, style: .continuous)
                    .stroke(Color.rouaGlassBorder, lineWidth: 1)
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(message ?? "Loading")
    }
}

// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║  EMPTY STATE VIEW                                                        ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

/// No-data placeholder with icon, title, description, and optional action.
struct EmptyStateView: View {

    let icon: String        // SF Symbol
    let title: String
    let description: String
    let buttonTitle: String?
    let buttonAction: (() -> Void)?

    init(
        icon: String,
        title: String,
        description: String,
        buttonTitle: String? = nil,
        buttonAction: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
    }

    var body: some View {
        VStack(spacing: RouaSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: RouaSpacing.iconHero))
                .foregroundStyle(.rouaTextTertiary)

            VStack(spacing: RouaSpacing.sm) {
                Text(title)
                    .rouaFont(.title3, color: .rouaTextPrimary)
                    .multilineTextAlignment(.center)

                Text(description)
                    .rouaFont(.subheadline, color: .rouaTextSecondary)
                    .multilineTextAlignment(.center)
            }

            if let buttonTitle, let buttonAction {
                RouaButton(
                    buttonTitle,
                    variant: .secondary,
                    size: .medium,
                    action: buttonAction
                )
                .frame(maxWidth: 200)
            }
        }
        .padding(RouaSpacing.xxxl)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(title). \(description)")
    }
}

// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║  SECTION HEADER                                                          ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

/// Section header with title and optional trailing action button.
struct SectionHeader: View {

    let title: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        HStack {
            Text(title)
                .rouaFont(.headline, color: .rouaTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .rouaFont(.subheadlineBold, color: .rouaPrimary)
                }
                .accessibilityLabel(actionTitle)
            }
        }
        .padding(.horizontal, RouaSpacing.screenPadding)
        .accessibilityElement(children: .contain)
    }
}

// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║  TICKER ROW                                                              ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

/// Market ticker row for scanner / markets list.
struct TickerRow: View {

    let symbol: String
    let name: String
    let price: String
    let change: Double
    let changePct: Double
    let onTap: (() -> Void)?

    init(
        symbol: String,
        name: String,
        price: String,
        change: Double,
        changePct: Double,
        onTap: (() -> Void)? = nil
    ) {
        self.symbol = symbol
        self.name = name
        self.price = price
        self.change = change
        self.changePct = changePct
        self.onTap = onTap
    }

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: RouaSpacing.md) {
                // Symbol circle
                Text(String(symbol.prefix(2)))
                    .rouaFont(.captionBold, color: .rouaTextPrimary)
                    .frame(width: 40, height: 40)
                    .background(Color.rouaSurfaceLight)
                    .clipShape(Circle())

                // Name column — supports RTL
                VStack(alignment: .leading, spacing: 2) {
                    Text(symbol)
                        .rouaFont(.calloutBold, color: .rouaTextPrimary)
                        .lineLimit(1)
                    Text(name)
                        .rouaFont(.footnote, color: .rouaTextSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Sparkline placeholder
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.rouaSurfaceHover)
                    .frame(width: 60, height: 24)

                // Price + change
                VStack(alignment: .trailing, spacing: 2) {
                    Text(price)
                        .rouaFont(.calloutBold, color: .rouaTextPrimary)
                        .monospacedDigit()
                        .lineLimit(1)
                    ChangeBadge(value: change, percentage: changePct, showArrow: true)
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
            .padding(.vertical, RouaSpacing.sm)
            .frame(height: RouaSpacing.tickerRowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(symbol), \(name), price \(price), \(change >= 0 ? "up" : "down") \(abs(change))")
        .accessibilityAddTraits(.isButton)
    }
}

// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║  POSITION ROW                                                            ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

/// Portfolio position row with symbol, side, PnL, and prices.
struct PositionRow: View {

    let symbol: String
    let side: PositionSide
    let quantity: String
    let entryPrice: String
    let currentPrice: String
    let pnl: Double
    let pnlPct: Double
    let onTap: (() -> Void)?

    enum PositionSide: String {
        case long
        case short

        var label: String {
            switch self {
            case .long:  return "Long"
            case .short: return "Short"
            }
        }

        var color: Color {
            switch self {
            case .long:  return .rouaBuy
            case .short: return .rouaSell
            }
        }
    }

    init(
        symbol: String,
        side: PositionSide,
        quantity: String,
        entryPrice: String,
        currentPrice: String,
        pnl: Double,
        pnlPct: Double,
        onTap: (() -> Void)? = nil
    ) {
        self.symbol = symbol
        self.side = side
        self.quantity = quantity
        self.entryPrice = entryPrice
        self.currentPrice = currentPrice
        self.pnl = pnl
        self.pnlPct = pnlPct
        self.onTap = onTap
    }

    private var pnlColor: Color { .rouaPnLColor(value: pnl) }

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: RouaSpacing.md) {
                // Symbol + side badge
                VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                    Text(symbol)
                        .rouaFont(.calloutBold, color: .rouaTextPrimary)
                        .lineLimit(1)
                    Badge(text: side.label, variant: side == .long ? .success : .error)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Quantity + prices
                VStack(alignment: .center, spacing: 2) {
                    Text("×\(quantity)")
                        .rouaFont(.footnote, color: .rouaTextTertiary)
                    HStack(spacing: 4) {
                        Text(entryPrice)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 8))
                        Text(currentPrice)
                    }
                    .rouaFont(.monoSmall, color: .rouaTextSecondary)
                    .monospacedDigit()
                }

                // PnL
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formattedPnL)
                        .rouaFont(.calloutBold, color: pnlColor)
                        .monospacedDigit()
                    Text(formattedPnLPct)
                        .rouaFont(.footnote, color: pnlColor)
                        .monospacedDigit()
                }
                .frame(alignment: .trailing)
            }
            .padding(RouaSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                    .fill(Color.rouaPnLBgColor(value: pnl))
            )
            .overlay(
                RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                    .stroke(Color.rouaGlassBorder, lineWidth: 0.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(symbol) \(side.label), P&L \(formattedPnL)")
        .accessibilityAddTraits(.isButton)
    }

    private var formattedPnL: String {
        let sign = pnl >= 0 ? "+" : ""
        return "\(sign)$\(String(format: "%.2f", abs(pnl)))"
    }

    private var formattedPnLPct: String {
        let sign = pnlPct >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", pnlPct))%"
    }
}

// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║  BADGE                                                                   ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

enum BadgeVariant {
    case success
    case warning
    case error
    case info
    case neutral

    var foreground: Color {
        switch self {
        case .success: return .rouaProfit
        case .warning: return .rouaWarning
        case .error:   return .rouaLoss
        case .info:    return .rouaInfo
        case .neutral: return .rouaNeutral
        }
    }

    var background: Color {
        switch self {
        case .success: return .rouaProfitLight
        case .warning: return .rouaWarning.opacity(0.15)
        case .error:   return .rouaLossLight
        case .info:    return .rouaInfo.opacity(0.15)
        case .neutral: return .rouaNeutral.opacity(0.15)
        }
    }
}

/// Small badge / pill for status indicators.
struct Badge: View {

    let text: String
    let variant: BadgeVariant

    var body: some View {
        Text(text)
            .rouaFont(.captionBold, color: variant.foreground)
            .padding(.horizontal, RouaSpacing.sm)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(variant.background)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(text)
    }
}

// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║  AVATAR VIEW                                                             ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

enum AvatarSize {
    case small   // 32
    case medium  // 44
    case large   // 64
    case xLarge  // 88

    var dimension: CGFloat {
        switch self {
        case .small:  return 32
        case .medium: return 44
        case .large:  return 64
        case .xLarge: return 88
        }
    }

    var font: RouaFont {
        switch self {
        case .small:  return .captionBold
        case .medium: return .footnoteBold
        case .large:  return .calloutBold
        case .xLarge: return .title3
        }
    }
}

/// User avatar displaying an image or initials with size variants.
struct AvatarView: View {

    let imageURL: String?
    let initials: String
    let size: AvatarSize

    init(imageURL: String? = nil, initials: String, size: AvatarSize = .medium) {
        self.imageURL = imageURL
        self.initials = String(initials.prefix(2)).uppercased()
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.rouaGradientPrimary)
                .frame(width: size.dimension, height: size.dimension)

            // Image placeholder — replace with AsyncImage in production
            if imageURL != nil {
                // In production: AsyncImage(url: URL(string: imageURL))
                Circle()
                    .fill(Color.rouaSurfaceLight)
                    .frame(width: size.dimension, height: size.dimension)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: size.dimension * 0.4))
                            .foregroundStyle(.rouaTextTertiary)
                    )
            } else {
                Text(initials)
                    .rouaFont(size.font, color: .white)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Avatar: \(initials)")
    }
}

// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║  PREVIEWS                                                                ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

#Preview("GlassCard") {
    ZStack {
        Color.rouaBackground.ignoresSafeArea()
        VStack(spacing: RouaSpacing.lg) {
            GlassCard {
                VStack(alignment: .leading, spacing: RouaSpacing.sm) {
                    Text("Portfolio Value")
                        .rouaFont(.subheadline, color: .rouaTextSecondary)
                    Text("$12,450.00")
                        .rouaFont(.largeTitle, color: .rouaTextPrimary)
                    ChangeBadge(value: 245.50, percentage: 2.01)
                }
            }
            GlassCard(glow: .rouaPrimary) {
                Text("Glowing Card")
                    .rouaFont(.headline, color: .rouaTextPrimary)
            }
            GlassCard(action: { print("tapped") }) {
                Text("Tappable Card")
                    .rouaFont(.callout, color: .rouaTextPrimary)
            }
        }
        .padding()
    }
}

#Preview("RouaButton") {
    ScrollView {
        VStack(spacing: RouaSpacing.lg) {
            RouaButton("Buy", variant: .primary, icon: "plus") {}
            RouaButton("Sell", variant: .danger, icon: "minus") {}
            RouaButton("Filter", variant: .secondary, icon: "line.3.horizontal.decrease") {}
            RouaButton("Skip", variant: .ghost) {}
            RouaButton("Loading…", variant: .primary, isLoading: true) {}
            RouaButton("Disabled", variant: .primary, isDisabled: true) {}
            RouaButton("Small", variant: .primary, size: .small) {}
            RouaButton("Large", variant: .primary, size: .large) {}
            RouaButton("Next", variant: .primary, icon: "arrow.right", iconPosition: .trailing) {}
        }
        .padding()
    }
    .background(Color.rouaBackground)
}

#Preview("ChangeBadge") {
    VStack(spacing: RouaSpacing.md) {
        ChangeBadge(value: 245.50, percentage: 2.01)
        ChangeBadge(value: -132.10, percentage: -1.35)
        ChangeBadge(value: 0, percentage: 0, showArrow: false)
    }
    .padding()
    .background(Color.rouaBackground)
}

#Preview("PulsingDot") {
    HStack(spacing: RouaSpacing.xl) {
        PulsingDot(status: .active)
        PulsingDot(status: .error)
        PulsingDot(status: .warning)
        PulsingDot(status: .inactive)
    }
    .padding()
    .background(Color.rouaBackground)
}

#Preview("ShimmerView") {
    VStack(alignment: .leading, spacing: RouaSpacing.md) {
        ShimmerView(width: 200, height: 24)
        ShimmerView(width: 150, height: 16)
        ShimmerView(width: 120, height: 40, cornerRadius: RouaSpacing.buttonCornerRadius)
        ShimmerView(height: 80)
    }
    .padding()
    .background(Color.rouaBackground)
}

#Preview("StatMini") {
    HStack(spacing: RouaSpacing.xl) {
        StatMini(label: "Balance", value: "$12,450")
        StatMini(label: "P&L", value: "+$245", change: 2.01)
        StatMini(label: "Win Rate", value: "68%")
    }
    .padding()
    .background(Color.rouaBackground)
}

#Preview("ErrorBanner") {
    VStack(spacing: RouaSpacing.md) {
        ErrorBanner(message: "Failed to load market data.") {}
        ErrorBanner(message: "Network connection lost.", onRetry: { print("retry") }) {}
    }
    .padding()
    .background(Color.rouaBackground)
}

#Preview("LoadingView") {
    LoadingView(message: "Placing order…")
}

#Preview("EmptyStateView") {
    ZStack {
        Color.rouaBackground.ignoresSafeArea()
        EmptyStateView(
            icon: "chart.line.flattrend.xyaxis",
            title: "No Positions",
            description: "Start trading to see your positions here.",
            buttonTitle: "Explore Markets",
            buttonAction: {}
        )
    }
}

#Preview("SectionHeader") {
    VStack(spacing: RouaSpacing.md) {
        SectionHeader(title: "Watchlist")
        SectionHeader(title: "Top Movers", actionTitle: "See All") {}
    }
    .background(Color.rouaBackground)
}

#Preview("TickerRow") {
    VStack(spacing: 0) {
        TickerRow(symbol: "AAPL", name: "Apple Inc.", price: "189.45", change: 3.20, changePct: 1.72)
        TickerRow(symbol: "TSLA", name: "Tesla Inc.", price: "248.10", change: -5.60, changePct: -2.21)
        TickerRow(symbol: "GOOGL", name: "Alphabet Inc.", price: "141.80", change: 0.50, changePct: 0.35)
    }
    .background(Color.rouaBackground)
}

#Preview("PositionRow") {
    VStack(spacing: RouaSpacing.sm) {
        PositionRow(
            symbol: "AAPL",
            side: .long,
            quantity: "10",
            entryPrice: "182.00",
            currentPrice: "189.45",
            pnl: 74.50,
            pnlPct: 4.09
        )
        PositionRow(
            symbol: "TSLA",
            side: .short,
            quantity: "5",
            entryPrice: "255.00",
            currentPrice: "248.10",
            pnl: 34.50,
            pnlPct: 2.71
        )
        PositionRow(
            symbol: "NVDA",
            side: .long,
            quantity: "8",
            entryPrice: "480.00",
            currentPrice: "465.30",
            pnl: -117.60,
            pnlPct: -3.06
        )
    }
    .padding()
    .background(Color.rouaBackground)
}

#Preview("Badge") {
    HStack(spacing: RouaSpacing.sm) {
        Badge(text: "Long", variant: .success)
        Badge(text: "Short", variant: .error)
        Badge(text: "Pending", variant: .warning)
        Badge(text: "Info", variant: .info)
        Badge(text: "Closed", variant: .neutral)
    }
    .padding()
    .background(Color.rouaBackground)
}

#Preview("AvatarView") {
    HStack(spacing: RouaSpacing.lg) {
        AvatarView(initials: "MA", size: .small)
        AvatarView(initials: "KH", size: .medium)
        AvatarView(initials: "SA", size: .large)
        AvatarView(imageURL: "placeholder", initials: "RZ", size: .xLarge)
    }
    .padding()
    .background(Color.rouaBackground)
}
