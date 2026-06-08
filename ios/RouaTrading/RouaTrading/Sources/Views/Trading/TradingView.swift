// =============================================================================
// TradingView.swift — Roua Trading · Core Trading Screen
// =============================================================================
// Full-screen trading view — the heart of the app.
// Symbol selector, live price, OHLC bar, chart, buy/sell price bar,
// chart toolbar, position tabs, and floating Buy/Sell action buttons.
//
// Layout (top → bottom, matching web m2-shell):
// 1. Symbol selector header + live dot
// 2. Current price + change badge
// 3. OHLC info bar (O=xxx H=xxx L=xxx C=xxx)
// 4. 24h stats row (compact)
// 5. Chart area (ChartView) with volume overlay
// 6. Buy/Sell price bar (bid/ask spread bar)
// 7. Chart toolbar (timeframe pills + drawing/indicators/AI buttons)
// 8. Position tabs (Open / Closed)
// 9. Position list
// 10. Floating Buy / Sell buttons (gradient fills)
//
// Uses: TradingViewModel, ChartView, RouaComponents, RouaColors, RouaTypography
// RTL: All layouts use leading/trailing; Arabic labels where specified.
// =============================================================================

import SwiftUI

// MARK: - Position Tab

/// Tabs displayed below the chart area.
enum PositionTab: String, CaseIterable {
    case open = "مفتوحة"    // Open
    case closed = "مغلقة"   // Closed

    var englishLabel: String {
        switch self {
        case .open:    return "Open"
        case .closed:  return "Closed"
        }
    }
}

// MARK: - Trading View

/// The primary trading screen for the Roua Trading app.
///
/// Matches the web m2-shell trading view layout with:
/// - OHLC info bar above chart
/// - Buy/Sell price bar below chart
/// - Chart toolbar with timeframe pills + tool buttons
/// - Gradient-styled floating Buy/Sell buttons
struct TradingView: View {

    // MARK: - ViewModel

    @StateObject private var viewModel: TradingViewModel

    // MARK: - Initializer

    /// Creates a TradingView for a specific symbol.
    /// - Parameter symbol: The trading symbol (e.g., "BTC/USD"). Defaults to "BTC/USD".
    init(symbol: String = "BTC/USD") {
        _viewModel = StateObject(wrappedValue: {
            let vm = TradingViewModel()
            vm.currentSymbol = symbol
            return vm
        }())
    }

    // MARK: - Sheet State

    @State private var showSymbolPicker = false
    @State private var showOrderSheet = false
    @State private var orderSide: OrderSide = .buy

    // MARK: - Position Tab

    @State private var positionTab: PositionTab = .open

    // MARK: - Animation

    @State private var priceFlash: Bool = false

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            // ── Scrollable Content ──
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    symbolHeader
                    priceSection
                    ohlcBar
                    statsRow
                    chartSection
                    buySellPriceBar
                    chartToolbar
                    positionSection
                }
                .padding(.bottom, RouaSpacing.buttonHeightLarge + RouaSpacing.lg)
            }
            .refreshable {
                viewModel.loadAllData(); await Task.yield()
            }

            // ── Floating Buy / Sell Buttons ──
            floatingActionButtons

            // ── Error Banner ──
            if let error = viewModel.errorMessage {
                VStack {
                    ErrorBanner(
                        message: error,
                        onRetry: { viewModel.loadAllData() },
                        onDismiss: { viewModel.errorMessage = nil }
                    )
                    .padding(.horizontal, RouaSpacing.screenPadding)
                    .padding(.top, RouaSpacing.md)
                    Spacer()
                }
            }
        }
        .background(Color.rouaBackground)
        .ignoresSafeArea(.container, edges: .bottom)
        .sheet(isPresented: $showSymbolPicker) {
            SymbolPickerView(
                selectedSymbol: viewModel.currentSymbol,
                onSelect: { symbol in
                    viewModel.switchSymbol(symbol)
                }
            )
        }
        .sheet(isPresented: $showOrderSheet) {
            OrderSheet(
                viewModel: viewModel,
                initialSide: orderSide
            )
        }
        .onAppear {
            viewModel.loadAllData()
        }
        .onChange(of: viewModel.currentSymbol) {
            // Symbol change is handled by switchSymbol()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Trading screen")
    }

    // MARK: - Symbol Header

    private var symbolHeader: some View {
        Button {
            showSymbolPicker = true
        } label: {
            HStack(spacing: RouaSpacing.sm) {
                // Symbol abbreviation circle
                Text(String(viewModel.currentSymbol.prefix(2)))
                    .rouaFont(.calloutBold, color: .rouaTextPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.rouaSurfaceLight)
                    .clipShape(Circle())

                // Symbol name
                Text(viewModel.currentSymbol)
                    .rouaFont(.title3, color: .rouaTextPrimary)
                    .lineLimit(1)

                // Chevron indicator
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.rouaTextTertiary)

                Spacer()

                // Connection indicator (simple live dot when data exists)
                if viewModel.currentQuote != nil {
                    PulsingDot(
                        status: .active,
                        size: 8
                    )
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
            .padding(.vertical, RouaSpacing.sm)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Select symbol: \(viewModel.currentSymbol)")
        .accessibilityHint("Tap to change trading pair")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Price Section

    private var priceSection: some View {
        VStack(alignment: .leading, spacing: RouaSpacing.xs) {
            if let quote = viewModel.currentQuote {
                HStack(alignment: .firstTextBaseline, spacing: RouaSpacing.sm) {
                    // Current price
                    Text(quote.price.asPrice())
                        .rouaFont(.largeTitle, color: .rouaTextPrimary)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.3), value: quote.price)
                        .id(quote.price) // Force re-render for price flash

                    // Change badge
                    ChangeBadge(
                        value: quote.change,
                        percentage: quote.changePct
                    )
                }
            } else {
                // Shimmer loading
                HStack(spacing: RouaSpacing.sm) {
                    ShimmerView(width: 180, height: 34)
                    ShimmerView(width: 120, height: 24)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, RouaSpacing.screenPadding)
        .padding(.vertical, RouaSpacing.xs)
    }

    // MARK: - OHLC Bar

    /// Compact horizontal bar showing Open, High, Low, Close values from
    /// the latest candle. Matches the web's OHLC info bar above the chart.
    private var ohlcBar: some View {
        let latestCandle = viewModel.liveCandle ?? viewModel.candles.last
        let quote = viewModel.currentQuote

        return HStack(spacing: 0) {
            // Open
            ohlcItem(
                label: "O",
                value: latestCandle?.open ?? quote?.open ?? 0,
                isPositive: latestCandle.map { $0.close >= $0.open } ?? quote.map { $0.change >= 0 } ?? true
            )
            .frame(maxWidth: .infinity)

            // High (always green — it's the high)
            ohlcItem(
                label: "H",
                value: latestCandle?.high ?? quote?.high ?? 0,
                isPositive: true
            )
            .frame(maxWidth: .infinity)

            // Low (always red — it's the low)
            ohlcItem(
                label: "L",
                value: latestCandle?.low ?? quote?.low ?? 0,
                isPositive: false
            )
            .frame(maxWidth: .infinity)

            // Close
            ohlcItem(
                label: "C",
                value: latestCandle?.close ?? quote?.price ?? 0,
                isPositive: latestCandle.map { $0.close >= $0.open } ?? quote.map { $0.change >= 0 } ?? true
            )
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, RouaSpacing.screenPadding)
        .padding(.vertical, RouaSpacing.xs)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("OHLC: Open \(latestCandle?.open.asPrice() ?? "—"), High \(latestCandle?.high.asPrice() ?? "—"), Low \(latestCandle?.low.asPrice() ?? "—"), Close \(latestCandle?.close.asPrice() ?? "—")")
    }

    /// Single OHLC item (label + value).
    private func ohlcItem(label: String, value: Double, isPositive: Bool) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .rouaFont(.captionBold, color: .rouaTextTertiary)
                .monospacedDigit()

            Text(value.asPrice())
                .rouaFont(.caption, color: isPositive ? .rouaProfit : .rouaLoss)
                .monospacedDigit()
                .lineLimit(1)
        }
    }

    // MARK: - Stats Row

    /// Compact 24h stats row matching web style.
    private var statsRow: some View {
        let quote = viewModel.currentQuote

        return HStack(spacing: 0) {
            // 24h High
            VStack(alignment: .leading, spacing: 2) {
                Text("أعلى 24س")  // 24h High
                    .rouaFont(.micro, color: .rouaTextTertiary)
                    .lineLimit(1)
                Text(quote?.high.asPrice() ?? "—")
                    .rouaFont(.captionBold, color: .rouaTextPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)

            // 24h Low
            VStack(alignment: .leading, spacing: 2) {
                Text("أدنى 24س")  // 24h Low
                    .rouaFont(.micro, color: .rouaTextTertiary)
                    .lineLimit(1)
                Text(quote?.low.asPrice() ?? "—")
                    .rouaFont(.captionBold, color: .rouaTextPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)

            // Volume
            VStack(alignment: .leading, spacing: 2) {
                Text("الحجم")     // Volume
                    .rouaFont(.micro, color: .rouaTextTertiary)
                    .lineLimit(1)
                Text(quote.map { $0.volume.asCompact() } ?? "—")
                    .rouaFont(.captionBold, color: .rouaTextPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)

            // Change
            VStack(alignment: .trailing, spacing: 2) {
                Text("التغيير")   // Change
                    .rouaFont(.micro, color: .rouaTextTertiary)
                    .lineLimit(1)
                Text(quote.map { $0.changePct.asPercentage() } ?? "—")
                    .rouaFont(.captionBold, color: .rouaPnLColor(value: quote?.changePct ?? 0))
                    .monospacedDigit()
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, RouaSpacing.screenPadding)
        .padding(.vertical, RouaSpacing.xs)
        .background(Color.rouaGlass)
    }

    // MARK: - Chart Section

    /// Derives volume data from candles for the chart histogram overlay.
    private var chartVolumeData: [VolumeDataPoint] {
        viewModel.candles.map { candle in
            VolumeDataPoint(
                time: candle.time,
                value: candle.volume,
                color: candle.isBullish ? .rouaProfit : .rouaLoss
            )
        }
    }

    private var chartSection: some View {
        Group {
            if viewModel.isLoading && viewModel.candles.isEmpty {
                // Loading state
                ShimmerView(height: 260)
                    .padding(.horizontal, RouaSpacing.screenPadding)
                    .padding(.vertical, RouaSpacing.md)
            } else {
                ChartView(
                    candles: viewModel.candles,
                    volumeData: chartVolumeData,
                    liveCandle: viewModel.liveCandle,
                    onCrosshairMove: nil
                )
                .frame(height: 260)
                .padding(.vertical, RouaSpacing.sm)
            }
        }
    }

    // MARK: - Buy/Sell Price Bar

    /// Bid/Ask spread bar below the chart, matching web's 44px bar.
    /// Left side = bid (green), Right side = ask (red).
    private var buySellPriceBar: some View {
        let quote = viewModel.currentQuote
        let bidPrice = quote?.bid ?? quote?.price
        let askPrice = quote?.ask ?? quote?.price

        return HStack(spacing: 1) {
            // Bid (Buy) side — green background
            HStack(spacing: RouaSpacing.sm) {
                Text("شراء")  // Buy
                    .rouaFont(.caption, color: .white.opacity(0.9))
                Spacer()
                Text(bidPrice?.asPrice() ?? "—")
                    .rouaFont(.calloutBold, color: .white)
                    .monospacedDigit()
            }
            .padding(.horizontal, RouaSpacing.md)
            .padding(.vertical, RouaSpacing.sm)
            .frame(maxWidth: .infinity)
            .background(Color.rouaGradientProfit)

            // Ask (Sell) side — red background
            HStack(spacing: RouaSpacing.sm) {
                Text(askPrice?.asPrice() ?? "—")
                    .rouaFont(.calloutBold, color: .white)
                    .monospacedDigit()
                Spacer()
                Text("بيع")  // Sell
                    .rouaFont(.caption, color: .white.opacity(0.9))
            }
            .padding(.horizontal, RouaSpacing.md)
            .padding(.vertical, RouaSpacing.sm)
            .frame(maxWidth: .infinity)
            .background(Color.rouaGradientLoss)
        }
        .frame(height: 44)
        .clipShape(RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous))
        .padding(.horizontal, RouaSpacing.screenPadding)
        .padding(.vertical, RouaSpacing.xs)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Bid \(bidPrice?.asPrice() ?? "—"), Ask \(askPrice?.asPrice() ?? "—")")
    }

    // MARK: - Chart Toolbar

    /// Toolbar below chart with timeframe selector pills + tool buttons
    /// (drawing, indicators, AI analysis). Matches web chart toolbar.
    private var chartToolbar: some View {
        HStack(spacing: RouaSpacing.sm) {
            // Timeframe pills — scrollable
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: RouaSpacing.xs) {
                    ForEach(CandleInterval.allCases) { interval in
                        TimeframePill(
                            title: interval.displayName,
                            isSelected: viewModel.selectedTimeframe == interval,
                            action: { viewModel.switchTimeframe(interval) }
                        )
                    }
                }
            }

            // Spacer to push tool buttons to trailing edge
            Spacer(minLength: RouaSpacing.xs)

            // Drawing tools button
            ChartToolButton(
                icon: "pencil.line",
                label: "رسم",  // Drawing
                action: { /* TODO: Open drawing tools */ }
            )

            // Indicators button
            ChartToolButton(
                icon: "chart.bar.fill",
                label: "مؤشرات",  // Indicators
                action: { /* TODO: Open indicators panel */ }
            )

            // AI analysis button
            ChartToolButton(
                icon: "brain.head.profile.fill",
                label: "ذكاء",  // AI
                accentColor: .rouaAccent,
                action: { /* TODO: Open AI analysis */ }
            )
        }
        .padding(.horizontal, RouaSpacing.screenPadding)
        .padding(.vertical, RouaSpacing.xs)
    }

    // MARK: - Position Section

    private var positionSection: some View {
        VStack(spacing: 0) {
            // Tab selector
            positionTabSelector

            // Position list content
            if positionTab == .open {
                openPositionsList
            } else {
                closedTradesList
            }
        }
        .padding(.top, RouaSpacing.sm)
    }

    private var positionTabSelector: some View {
        HStack(spacing: 0) {
            ForEach(PositionTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: RouaSpacing.animationFast)) {
                        positionTab = tab
                    }
                } label: {
                    VStack(spacing: RouaSpacing.xs) {
                        Text(tab.rawValue)
                            .rouaFont(
                                positionTab == tab ? .calloutBold : .callout,
                                color: positionTab == tab ? .rouaTextPrimary : .rouaTextTertiary
                            )
                        RoundedRectangle(cornerRadius: 2)
                            .fill(positionTab == tab ? Color.rouaPrimary : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.englishLabel)
                .accessibilityAddTraits(positionTab == tab ? .isSelected : [])
            }
        }
        .padding(.horizontal, RouaSpacing.screenPadding)
        .padding(.vertical, RouaSpacing.sm)
    }

    // MARK: - Open Positions List

    @ViewBuilder
    private var openPositionsList: some View {
        if viewModel.isLoading && viewModel.positions.isEmpty {
            VStack(spacing: RouaSpacing.sm) {
                ForEach(0..<3, id: \.self) { _ in
                    ShimmerView(height: RouaSpacing.rowHeight)
                        .padding(.horizontal, RouaSpacing.screenPadding)
                }
            }
            .padding(.vertical, RouaSpacing.sm)
        } else if viewModel.positions.isEmpty {
            EmptyStateView(
                icon: "chart.line.downtrend.xyaxis",
                title: "لا توجد صفقات مفتوحة",  // No open positions
                description: "ابدأ التداول لرؤية صفقاتك هنا",  // Start trading to see positions here
                buttonTitle: "شراء",  // Buy
                buttonAction: {
                    orderSide = .buy
                    showOrderSheet = true
                }
            )
            .padding(.vertical, RouaSpacing.xxl)
        } else {
            LazyVStack(spacing: RouaSpacing.sm) {
                ForEach(viewModel.positions) { position in
                    PositionRow(
                        symbol: position.symbol,
                        side: position.isLong ? .long : .short,
                        quantity: String(format: "%.4f", position.quantity),
                        entryPrice: position.entryPrice.asPrice(),
                        currentPrice: (position.currentPrice ?? position.entryPrice).asPrice(),
                        pnl: position.unrealizedPnl,
                        pnlPct: position.unrealizedPnlPct ?? 0,
                        onTap: {
                            // TODO: Navigate to position detail
                        }
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task { await viewModel.closePosition(id: position.id) }
                        } label: {
                            Label("إغلاق", systemImage: "xmark.circle")  // Close
                        }
                        .tint(.rouaLoss)
                    }
                    .padding(.horizontal, RouaSpacing.screenPadding)
                }
            }
            .padding(.vertical, RouaSpacing.sm)
        }
    }

    // MARK: - Closed Trades List

    @ViewBuilder
    private var closedTradesList: some View {
        if viewModel.isLoading && viewModel.closedTrades.isEmpty {
            VStack(spacing: RouaSpacing.sm) {
                ForEach(0..<3, id: \.self) { _ in
                    ShimmerView(height: RouaSpacing.rowHeight)
                        .padding(.horizontal, RouaSpacing.screenPadding)
                }
            }
            .padding(.vertical, RouaSpacing.sm)
        } else if viewModel.closedTrades.isEmpty {
            EmptyStateView(
                icon: "clock.arrow.circlepath",
                title: "لا توجد صفقات مغلقة",  // No closed trades
                description: "ستظهر صفقاتك المغلقة هنا"  // Your closed trades will appear here
            )
            .padding(.vertical, RouaSpacing.xxl)
        } else {
            LazyVStack(spacing: RouaSpacing.sm) {
                ForEach(viewModel.closedTrades) { trade in
                    ClosedTradeRow(trade: trade)
                        .padding(.horizontal, RouaSpacing.screenPadding)
                }
            }
            .padding(.vertical, RouaSpacing.sm)
        }
    }

    // MARK: - Floating Action Buttons

    /// Gradient-styled Buy/Sell buttons matching web design.
    /// Buy button uses rouaGradientProfit, Sell uses rouaGradientLoss.
    private var floatingActionButtons: some View {
        HStack(spacing: RouaSpacing.md) {
            // Buy Button — green gradient fill
            Button {
                orderSide = .buy
                showOrderSheet = true
            } label: {
                HStack(spacing: RouaSpacing.sm) {
                    Image(systemName: "arrowtriangle.up.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    Text("شراء")  // Buy
                        .rouaFont(.headline, color: .white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: RouaSpacing.buttonHeightLarge)
                .background(Color.rouaGradientProfit)
                .clipShape(RoundedRectangle(cornerRadius: RouaSpacing.buttonCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: RouaSpacing.buttonCornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Buy")
            .accessibilityAddTraits(.isButton)

            // Sell Button — red gradient fill
            Button {
                orderSide = .sell
                showOrderSheet = true
            } label: {
                HStack(spacing: RouaSpacing.sm) {
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    Text("بيع")  // Sell
                        .rouaFont(.headline, color: .white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: RouaSpacing.buttonHeightLarge)
                .background(Color.rouaGradientLoss)
                .clipShape(RoundedRectangle(cornerRadius: RouaSpacing.buttonCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: RouaSpacing.buttonCornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Sell")
            .accessibilityAddTraits(.isButton)
        }
        .padding(.horizontal, RouaSpacing.screenPadding)
        .padding(.vertical, RouaSpacing.sm)
        .background(
            LinearGradient(
                colors: [Color.rouaBackground.opacity(0), Color.rouaBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 80)
        )
    }
}

// MARK: - Chart Tool Button

/// Icon button for chart toolbar actions (drawing, indicators, AI).
/// Compact circular button with icon and optional label.
struct ChartToolButton: View {

    let icon: String
    let label: String
    var accentColor: Color = .rouaPrimary
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(accentColor)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(accentColor.opacity(0.12))
                    )
                    .overlay(
                        Circle()
                            .stroke(accentColor.opacity(0.25), lineWidth: 0.5)
                    )

                Text(label)
                    .rouaFont(.micro, color: .rouaTextTertiary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isPressed)
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Timeframe Pill

/// Pill-shaped button for timeframe selection.
private struct TimeframePill: View {

    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .rouaFont(
                    isSelected ? .footnoteBold : .footnote,
                    color: isSelected ? .rouaPrimary : .rouaTextTertiary
                )
                .padding(.horizontal, RouaSpacing.md)
                .padding(.vertical, RouaSpacing.sm)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.rouaPrimary.opacity(0.15) : Color.rouaGlass)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.rouaPrimary.opacity(0.3) : Color.rouaGlassBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Closed Trade Row

/// Row for displaying a closed trade with realized PnL.
struct ClosedTradeRow: View {

    let trade: Trade

    private var pnlColor: Color { .rouaPnLColor(value: trade.realizedPnl) }

    var body: some View {
        HStack(spacing: RouaSpacing.md) {
            // Symbol + side
            VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                Text(trade.symbol)
                    .rouaFont(.calloutBold, color: .rouaTextPrimary)
                    .lineLimit(1)
                Badge(
                    text: trade.side.displayName,
                    variant: trade.side.isLong ? .success : .error
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Entry → Exit
            VStack(alignment: .center, spacing: 2) {
                HStack(spacing: 4) {
                    Text(trade.entryPrice.asPrice())
                    Image(systemName: "arrow.right")
                        .font(.system(size: 8))
                    Text(trade.exitPrice.asPrice())
                }
                .rouaFont(.monoSmall, color: .rouaTextSecondary)
                .monospacedDigit()

                Text(trade.qty.asPrice())
                    .rouaFont(.footnote, color: .rouaTextTertiary)
            }

            // Realized PnL
            VStack(alignment: .trailing, spacing: 2) {
                Text(trade.formattedPnl)
                    .rouaFont(.calloutBold, color: pnlColor)
                    .monospacedDigit()
                Text(trade.realizedPnlPct.asPercentage())
                    .rouaFont(.footnote, color: pnlColor)
                    .monospacedDigit()
            }
            .frame(alignment: .trailing)
        }
        .padding(RouaSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                .fill(Color.rouaPnLBgColor(value: trade.realizedPnl))
        )
        .overlay(
            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                .stroke(Color.rouaGlassBorder, lineWidth: 0.5)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(trade.symbol) \(trade.side.displayName), realized P&L \(trade.formattedPnl)"
        )
    }
}

// =============================================================================
// MARK: - Preview
// =============================================================================

#Preview("TradingView") {
    TradingView()
}
