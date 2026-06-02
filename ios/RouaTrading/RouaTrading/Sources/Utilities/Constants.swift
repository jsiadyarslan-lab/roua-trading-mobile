import SwiftUI

// MARK: - Animation Constants

/// Standard animation durations and curves used throughout the app.
enum Animations {
    /// Very fast transition (0.15s) — micro-interactions, toggles.
    static let fast: Double = 0.15

    /// Standard transition (0.25s) — button taps, view transitions.
    static let standard: Double = 0.25

    /// Medium transition (0.35s) — sheet presentations, modals.
    static let medium: Double = 0.35

    /// Slow transition (0.5s) — page transitions, hero animations.
    static let slow: Double = 0.5

    /// Chart animation duration (0.6s).
    static let chart: Double = 0.6

    /// Spring animation for interactive elements.
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.75)

    /// Smooth ease-in-out for general transitions.
    static let easeInOut = Animation.easeInOut(duration: 0.25)

    /// Bouncy spring for playful interactions.
    static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)

    /// Gentle spring for subtle feedback.
    static let gentle = Animation.spring(response: 0.4, dampingFraction: 0.85)
}

// MARK: - Spacing Constants

/// Standard spacing values for consistent layouts.
enum Spacing {
    /// 2pt — tight grouping (icon + label).
    static let xxSmall: CGFloat = 2

    /// 4pt — minimal spacing.
    static let xSmall: CGFloat = 4

    /// 6pt — compact spacing.
    static let small: CGFloat = 6

    /// 8pt — standard compact spacing.
    static let compact: CGFloat = 8

    /// 12pt — default spacing.
    static let `default`: CGFloat = 12

    /// 16pt — medium spacing.
    static let medium: CGFloat = 16

    /// 20pt — comfortable spacing.
    static let comfortable: CGFloat = 20

    /// 24pt — large spacing.
    static let large: CGFloat = 24

    /// 32pt — section spacing.
    static let xLarge: CGFloat = 32

    /// 48pt — major section break.
    static let xxLarge: CGFloat = 48

    /// 64pt — screen-level padding.
    static let huge: CGFloat = 64
}

// MARK: - Chart Configuration

/// Configuration constants for chart rendering.
enum ChartConfig {
    /// Default number of visible candlesticks.
    static let defaultCandleCount: Int = 100

    /// Maximum number of candlesticks to display.
    static let maxCandleCount: Int = 500

    /// Minimum candle body height in points.
    static let minCandleBodyHeight: CGFloat = 1.0

    /// Candle wick width in points.
    static let wickWidth: CGFloat = 1.0

    /// Y-axis label width in points.
    static let yAxisLabelWidth: CGFloat = 70

    /// X-axis label height in points.
    static let xAxisLabelHeight: CGFloat = 24

    /// Chart padding (top, bottom).
    static let verticalPadding: CGFloat = 16

    /// Grid line dash pattern.
    static let gridLineDash: [CGFloat] = [4, 4]

    /// Volume bar height ratio (relative to chart height).
    static let volumeHeightRatio: CGFloat = 0.2

    /// Supported timeframe intervals.
    static let timeframes = ["1m", "3m", "5m", "15m", "30m", "1h", "4h", "1d", "1w", "1M"]

    /// Human-readable labels for timeframes.
    static let timeframeLabels: [String: String] = [
        "1m": "1M",
        "3m": "3M",
        "5m": "5M",
        "15m": "15M",
        "30m": "30M",
        "1h": "1H",
        "4h": "4H",
        "1d": "1D",
        "1w": "1W",
        "1M": "1MO",
    ]

    /// Binance interval values for API calls.
    static let binanceIntervals: [String: String] = [
        "1m": "1m",
        "3m": "3m",
        "5m": "5m",
        "15m": "15m",
        "30m": "30m",
        "1h": "1h",
        "4h": "4h",
        "1d": "1d",
        "1w": "1w",
        "1M": "1M",
    ]
}

// MARK: - Notification Names

/// Custom `Notification.Name` constants for app-wide events.
extension Notification.Name {
    /// Fired when the user successfully authenticates.
    static let userDidAuthenticate = Notification.Name("com.roua.trading.userDidAuthenticate")

    /// Fired when the user logs out.
    static let userDidLogout = Notification.Name("com.roua.trading.userDidLogout")

    /// Fired when the session expires and the user needs to re-authenticate.
    static let sessionDidExpire = Notification.Name("com.roua.trading.sessionDidExpire")

    /// Fired when a new notification is received.
    static let notificationReceived = Notification.Name("com.roua.trading.notificationReceived")

    /// Fired when a trading signal is auto-executed.
    static let signalAutoExecuted = Notification.Name("com.roua.trading.signalAutoExecuted")

    /// Fired when the active trading symbol changes.
    static let activeSymbolChanged = Notification.Name("com.roua.trading.activeSymbolChanged")

    /// Fired when the market status changes.
    static let marketStatusChanged = Notification.Name("com.roua.trading.marketStatusChanged")

    /// Fired when the executor status changes.
    static let executorStatusChanged = Notification.Name("com.roua.trading.executorStatusChanged")

    /// Fired when the AI agent status changes.
    static let agentStatusChanged = Notification.Name("com.roua.trading.agentStatusChanged")

    /// Fired when portfolio balances update.
    static let portfolioBalancesUpdated = Notification.Name("com.roua.trading.portfolioBalancesUpdated")

    /// Fired when a WebSocket connection state changes.
    static let webSocketStateChanged = Notification.Name("com.roua.trading.webSocketStateChanged")
}

// MARK: - Format Strings

/// Standard format strings for consistent display.
enum FormatStrings {
    /// ISO 8601 date format.
    static let iso8601 = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

    /// Short date format (e.g., "Jan 15").
    static let shortDate = "MMM d"

    /// Full date format (e.g., "Jan 15, 2025").
    static let fullDate = "MMM d, yyyy"

    /// Date and time format (e.g., "Jan 15, 2:30 PM").
    static let dateTime = "MMM d, h:mm a"

    /// Time format (e.g., "2:30 PM").
    static let timeOnly = "h:mm a"

    /// 24-hour time format (e.g., "14:30").
    static let time24h = "HH:mm"

    /// Currency format with 2 decimals.
    static let currency2 = "$%.2f"

    /// Currency format with 4 decimals.
    static let currency4 = "$%.4f"

    /// Percentage format.
    static let percentage = "%+.2f%%"

    /// Compact number format (K, M, B).
    static let compact = "%.1f%@"

    /// Large price format with commas.
    static let largePrice = "$%,.2f"
}

// MARK: - Trading Constants

/// Trading-specific constants.
enum TradingConstants {
    /// Supported quote currencies.
    static let supportedQuotes = ["USDT", "BUSD", "BTC", "ETH", "BNB"]

    /// Default quote currency.
    static let defaultQuote = "USDT"

    /// Default trading pair.
    static let defaultSymbol = "BTCUSDT"

    /// Minimum order quantity.
    static let minOrderQuantity: Double = 0.001

    /// Maximum leverage.
    static let maxLeverage: Int = 125

    /// Default leverage.
    static let defaultLeverage: Int = 1

    /// Order types supported.
    static let orderTypes = ["MARKET", "LIMIT", "STOP_MARKET", "TAKE_PROFIT_MARKET", "STOP", "TAKE_PROFIT"]

    /// Position sides.
    static let positionSides = ["LONG", "SHORT", "BOTH"]

    /// Candlestick intervals for the trading view.
    static let klineIntervals = ChartConfig.timeframes
}

// MARK: - UI Constants

/// UI-related constants.
enum UIConstants {
    /// Tab bar height.
    static let tabBarHeight: CGFloat = 49

    /// Navigation bar height.
    static let navigationBarHeight: CGFloat = 44

    /// Standard corner radius.
    static let cornerRadius: CGFloat = 12

    /// Small corner radius.
    static let smallCornerRadius: CGFloat = 8

    /// Large corner radius.
    static let largeCornerRadius: CGFloat = 20

    /// Button height.
    static let buttonHeight: CGFloat = 50

    /// Small button height.
    static let smallButtonHeight: CGFloat = 36

    /// Row height for list items.
    static let rowHeight: CGFloat = 64

    /// Compact row height.
    static let compactRowHeight: CGFloat = 48

    /// Icon size for standard icons.
    static let iconSize: CGFloat = 24

    /// Small icon size.
    static let smallIconSize: CGFloat = 16

    /// Large icon size.
    static let largeIconSize: CGFloat = 32

    /// Avatar size.
    static let avatarSize: CGFloat = 40

    /// Thumbnail size.
    static let thumbnailSize: CGFloat = 80

    /// Maximum content width for readability on iPad.
    static let maxContentWidth: CGFloat = 672

    /// Haptic feedback intensity.
    static let hapticIntensity: CGFloat = 0.6
}

// MARK: - Color Constants

/// Named color constants for consistent theming.
///
/// These map to the app's Asset Catalog colors when available,
/// falling back to hex values for programmatic use.
enum AppColors {
    // Brand
    static let primary = Color(hex: "6C5CE7")
    static let secondary = Color(hex: "A29BFE")

    // Semantic
    static let success = Color(hex: "00B894")
    static let warning = Color(hex: "FDCB6E")
    static let danger = Color(hex: "E17055")
    static let info = Color(hex: "74B9FF")

    // Long / Short
    static let long = Color(hex: "00B894")
    static let short = Color(hex: "E17055")

    // Backgrounds
    static let backgroundPrimary = Color(hex: "1A1A2E")
    static let backgroundSecondary = Color(hex: "16213E")
    static let backgroundTertiary = Color(hex: "0F3460")
    static let backgroundCard = Color(hex: "1E1E3F")

    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.35)

    // Borders
    static let borderLight = Color.white.opacity(0.1)
    static let borderMedium = Color.white.opacity(0.2)
}
