// =============================================================================
// TradingView.swift — Roua Trading · Core Trading Screen
// =============================================================================
// Full-screen trading view — the heart of the app.
// Symbol selector, live price, 24h stats, chart, timeframe selector,
// position tabs, and floating Buy/Sell action buttons.
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
/// Layout (top → bottom):
/// 1. Symbol selector header
/// 2. Current price + change badge
/// 3. 24h stats row
/// 4. Chart area (ChartView)
/// 5. Timeframe pill selector
/// 6. Position tabs (Open / Closed)
/// 7. Position list
/// 8. Floating Buy / Sell buttons
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
                    statsRow
                    chartSection
                    timeframeSelector
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
            } else {
                // Shimmer loading
                ShimmerView(width: 180, height: 34)
                    .padding(.bottom, 2)
                ShimmerView(width: 120, height: 24)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, RouaSpacing.screenPadding)
        .padding(.vertical, RouaSpacing.xs)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        let quote = viewModel.currentQuote

        return GlassCard {
            HStack(spacing: 0) {
                StatMini(
                    label: "أعلى 24س",  // 24h High
                    value: quote?.high.asPrice() ?? "—"
                )
                .frame(maxWidth: .infinity)

                Divider()
                    .background(Color.rouaBorder)
                    .frame(height: 32)
                    .padding(.horizontal, RouaSpacing.xs)

                StatMini(
                    label: "أدنى 24س",  // 24h Low
                    value: quote?.low.asPrice() ?? "—"
                )
                .frame(maxWidth: .infinity)

                Divider()
                    .background(Color.rouaBorder)
                    .frame(height: 32)
                    .padding(.horizontal, RouaSpacing.xs)

                StatMini(
                    label: "الحجم",     // Volume
                    value: quote.map { $0.volume.asCompact() } ?? "—"
                )
                .frame(maxWidth: .infinity)

                Divider()
                    .background(Color.rouaBorder)
                    .frame(height: 32)
                    .padding(.horizontal, RouaSpacing.xs)

                StatMini(
                    label: "التغيير",   // Change
                    value: quote.map { $0.changePct.asPercentage() } ?? "—",
                    change: quote?.changePct
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, RouaSpacing.screenPadding)
        .padding(.vertical, RouaSpacing.xs)
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
                    liveCandle: nil,
                    onCrosshairMove: nil
                )
                .frame(height: 260)
                .padding(.vertical, RouaSpacing.sm)
            }
        }
    }

    // MARK: - Timeframe Selector

    private var timeframeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RouaSpacing.sm) {
                ForEach(CandleInterval.allCases) { interval in
                    TimeframePill(
                        title: interval.displayName,
                        isSelected: viewModel.selectedTimeframe == interval,
                        action: { viewModel.switchTimeframe(interval) }
                    )
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
        }
        .padding(.vertical, RouaSpacing.sm)
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

    private var floatingActionButtons: some View {
        HStack(spacing: RouaSpacing.md) {
            // Buy Button
            RouaButton(
                "شراء",  // Buy
                variant: .primary,
                size: .large,
                icon: "arrowtriangle.up.fill",
                iconPosition: .leading
            ) {
                orderSide = .buy
                showOrderSheet = true
            }
            .background(Color.rouaGradientProfit)
            .clipShape(RoundedRectangle(cornerRadius: RouaSpacing.buttonCornerRadius, style: .continuous))

            // Sell Button
            RouaButton(
                "بيع",  // Sell
                variant: .danger,
                size: .large,
                icon: "arrowtriangle.down.fill",
                iconPosition: .leading
            ) {
                orderSide = .sell
                showOrderSheet = true
            }
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
