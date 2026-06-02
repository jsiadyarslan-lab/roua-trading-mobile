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

    @StateObject private var viewModel = TradingViewModel()

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
                await viewModel.refreshAll()
            }

            // ── Floating Buy / Sell Buttons ──
            floatingActionButtons

            // ── Error Banner ──
            if let error = viewModel.errorMessage {
                VStack {
                    ErrorBanner(
                        message: error,
                        onRetry: { viewModel.retryLastAction() },
                        onDismiss: { viewModel.clearError() }
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
                selectedSymbol: viewModel.selectedSymbol,
                onSelect: { symbol in
                    viewModel.changeSymbol(symbol)
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
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .onChange(of: viewModel.selectedSymbol) { _ in
            viewModel.onSymbolChange()
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
                Text(String(viewModel.selectedSymbol.prefix(2)))
                    .rouaFont(.calloutBold, color: .rouaTextPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.rouaSurfaceLight)
                    .clipShape(Circle())

                // Symbol name
                Text(viewModel.selectedSymbol)
                    .rouaFont(.title3, color: .rouaTextPrimary)
                    .lineLimit(1)

                // Chevron indicator
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.rouaTextTertiary)

                Spacer()

                // Connection status
                PulsingDot(
                    status: viewModel.isConnected ? .active : .inactive,
                    size: 8
                )
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
            .padding(.vertical, RouaSpacing.sm)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Select symbol: \(viewModel.selectedSymbol)")
        .accessibilityHint("Tap to change trading pair")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Price Section

    private var priceSection: some View {
        VStack(alignment: .leading, spacing: RouaSpacing.xs) {
            if let quote = viewModel.quote {
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
        let quote = viewModel.quote

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

    private var chartSection: some View {
        Group {
            if viewModel.isLoadingCandles && viewModel.candles.isEmpty {
                // Loading state
                ShimmerView(height: 260)
                    .padding(.horizontal, RouaSpacing.screenPadding)
                    .padding(.vertical, RouaSpacing.md)
            } else {
                ChartView(
                    candles: viewModel.candles,
                    volumeData: viewModel.volumeData,
                    liveCandle: viewModel.liveCandle,
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
                ForEach(TradingViewModel.chartTimeframes, id: \.self) { tf in
                    TimeframePill(
                        title: tf.displayName,
                        isSelected: viewModel.selectedTimeframe == tf,
                        action: { viewModel.changeTimeframe(tf) }
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
        if viewModel.isLoadingPositions && viewModel.openPositions.isEmpty {
            VStack(spacing: RouaSpacing.sm) {
                ForEach(0..<3, id: \.self) { _ in
                    ShimmerView(height: RouaSpacing.rowHeight)
                        .padding(.horizontal, RouaSpacing.screenPadding)
                }
            }
            .padding(.vertical, RouaSpacing.sm)
        } else if viewModel.openPositions.isEmpty {
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
                ForEach(viewModel.openPositions) { position in
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
                            viewModel.closePosition(position)
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
        if viewModel.isLoadingTrades && viewModel.closedTrades.isEmpty {
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
// MARK: - TradingViewModel
// =============================================================================
// The ViewModel that drives TradingView. Implemented here as a concrete
// @MainActor ObservableObject so the view compiles and works with mock data.
// In production, the actual API/network calls replace the stubs.
// =============================================================================

@MainActor
final class TradingViewModel: ObservableObject {

    // MARK: - Published State

    /// Currently selected trading symbol.
    @Published var selectedSymbol: String = "BTCUSDT"

    /// Latest quote for the selected symbol.
    @Published var quote: Quote?

    /// Candlestick data for the chart.
    @Published var candles: [CandleData] = []

    /// Volume data extracted from candles (for histogram overlay).
    @Published var volumeData: [VolumeDataPoint] = []

    /// Live candle from WebSocket (partial, not yet closed).
    @Published var liveCandle: CandleData?

    /// Currently selected chart timeframe.
    @Published var selectedTimeframe: TimeFrame = .oneHour

    /// Open positions.
    @Published var openPositions: [Position] = []

    /// Closed trades history.
    @Published var closedTrades: [Trade] = []

    /// User's exchange credentials (for OrderSheet).
    @Published var credentials: [Credential] = []

    /// Loading states.
    @Published var isLoadingCandles: Bool = false
    @Published var isLoadingPositions: Bool = false
    @Published var isLoadingTrades: Bool = false

    /// WebSocket connection state.
    @Published var isConnected: Bool = false

    /// Current error message (nil when no error).
    @Published var errorMessage: String?

    /// Whether an order is being placed.
    @Published var isPlacingOrder: Bool = false

    // MARK: - Private

    private let webSocketManager = WebSocketManager()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Chart Timeframes

    /// Timeframes available in the chart selector.
    static let chartTimeframes: [TimeFrame] = [
        .oneMin, .fiveMin, .fifteenMin, .oneHour, .fourHour, .oneDay
    ]

    // MARK: - Lifecycle

    func onAppear() {
        loadChartData()
        loadPositions()
        loadCredentials()
        connectWebSocket()
    }

    func onDisappear() {
        disconnectWebSocket()
    }

    func onSymbolChange() {
        candles = []
        volumeData = []
        liveCandle = nil
        quote = nil
        loadChartData()
        loadPositions()
        webSocketManager.switchSymbol(selectedSymbol.lowercased())
    }

    // MARK: - Data Loading

    func loadChartData() {
        isLoadingCandles = true
        // TODO: Replace with actual API call via APIClient
        // APIClient.shared.request(.exchangeHistory(symbol: selectedSymbol, interval: selectedTimeframe.rawValue, limit: 500))
        //   .sink { ... }

        // Simulated delay
        Task {
            try? await Task.sleep(nanoseconds: 800_000_000)
            let mockCandles = Self.generateMockCandles(count: 200, for: selectedTimeframe)
            self.candles = mockCandles
            self.volumeData = mockCandles.map { VolumeDataPoint(time: $0.time, value: $0.volume, color: $0.isBullish ? .rouaProfit : .rouaLoss) }
            self.isLoadingCandles = false
        }
    }

    func loadPositions() {
        isLoadingPositions = true
        isLoadingTrades = true
        // TODO: Replace with actual API calls
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            self.openPositions = Self.mockOpenPositions
            self.closedTrades = Self.mockClosedTrades
            self.isLoadingPositions = false
            self.isLoadingTrades = false
        }
    }

    func loadCredentials() {
        // TODO: Replace with actual API call
        // APIClient.shared.request(.portfolioCredentials)
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            self.credentials = Self.mockCredentials
        }
    }

    func refreshAll() async {
        loadChartData()
        loadPositions()
    }

    // MARK: - WebSocket

    func connectWebSocket() {
        webSocketManager.onKlineUpdate = { [weak self] kline in
            self?.handleKlineUpdate(kline)
        }
        webSocketManager.onTickerUpdate = { [weak self] ticker in
            self?.handleTickerUpdate(ticker)
        }

        webSocketManager.$connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .connected:
                    self?.isConnected = true
                case .disconnected, .failed:
                    self?.isConnected = false
                case .connecting, .reconnecting:
                    break
                }
            }
            .store(in: &cancellables)

        webSocketManager.connect(
            symbols: [selectedSymbol.lowercased()],
            intervals: [selectedTimeframe.rawValue]
        )
    }

    func disconnectWebSocket() {
        webSocketManager.disconnect()
    }

    private func handleKlineUpdate(_ kline: BinanceKline) {
        guard kline.symbol.uppercased() == selectedSymbol else { return }

        let updatedCandle = CandleData(
            time: Int(kline.openTime / 1000),
            open: Double(kline.open) ?? 0,
            high: Double(kline.high) ?? 0,
            low: Double(kline.low) ?? 0,
            close: Double(kline.close) ?? 0,
            volume: Double(kline.volume) ?? 0
        )

        if kline.isClosed {
            // Closed candle — append to candles array
            if let lastCandle = candles.last, lastCandle.time == updatedCandle.time {
                candles[candles.count - 1] = updatedCandle
            } else {
                candles.append(updatedCandle)
                if candles.count > 500 { candles.removeFirst() }
            }
            liveCandle = nil
        } else {
            // Partial candle — update live candle
            liveCandle = updatedCandle
        }

        // Update volume data
        let volumePoint = VolumeDataPoint(
            time: updatedCandle.time,
            value: updatedCandle.volume,
            color: updatedCandle.isBullish ? .rouaProfit : .rouaLoss
        )
        if let lastVol = volumeData.last, lastVol.time == volumePoint.time {
            volumeData[volumeData.count - 1] = volumePoint
        } else {
            volumeData.append(volumePoint)
        }

        // Update quote price from close
        if var currentQuote = quote {
            currentQuote = Quote(
                symbol: currentQuote.symbol,
                price: updatedCandle.close,
                change: currentQuote.change,
                changePct: currentQuote.changePct,
                high: max(currentQuote.high, updatedCandle.high),
                low: min(currentQuote.low, updatedCandle.low),
                open: currentQuote.open,
                volume: currentQuote.volume,
                bid: currentQuote.bid,
                ask: currentQuote.ask,
                timestamp: currentQuote.timestamp,
                source: currentQuote.source
            )
            quote = currentQuote
        }
    }

    private func handleTickerUpdate(_ ticker: BinanceTicker) {
        guard ticker.symbol.uppercased() == selectedSymbol else { return }

        quote = Quote(
            symbol: ticker.symbol,
            price: Double(ticker.lastPrice) ?? 0,
            change: Double(ticker.priceChange) ?? 0,
            changePct: Double(ticker.priceChangePercent) ?? 0,
            high: Double(ticker.high) ?? 0,
            low: Double(ticker.low) ?? 0,
            open: Double(ticker.open) ?? 0,
            volume: Double(ticker.volume) ?? 0,
            bid: nil,
            ask: nil,
            timestamp: String(ticker.eventTime),
            source: "binance_ws"
        )
    }

    // MARK: - Actions

    func changeSymbol(_ symbol: String) {
        selectedSymbol = symbol
    }

    func changeTimeframe(_ timeframe: TimeFrame) {
        selectedTimeframe = timeframe
        loadChartData()
        webSocketManager.switchSymbol(
            selectedSymbol.lowercased(),
            intervals: [timeframe.rawValue]
        )
    }

    func closePosition(_ position: Position) {
        // TODO: Replace with actual API call
        // APIClient.shared.request(.tradingClosePosition, body: ClosePositionRequest(positionId: position.id))
        withAnimation {
            openPositions.removeAll { $0.id == position.id }
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func placeOrder(
        side: OrderSide,
        type: OrderType,
        quantity: Double,
        price: Double?,
        stopLoss: Double?,
        takeProfit: Double?,
        credentialId: String
    ) {
        isPlacingOrder = true
        // TODO: Replace with actual API call
        // let request = OrderRequest(
        //     exchangeCredentialId: credentialId,
        //     symbol: selectedSymbol,
        //     side: side, type: type,
        //     quantity: quantity, price: price,
        //     stopLoss: stopLoss, takeProfit: takeProfit
        // )
        // APIClient.shared.request(.tradingV2CreateOrder, body: request)

        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            isPlacingOrder = false
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    func retryLastAction() {
        clearError()
        loadChartData()
        loadPositions()
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Mock Data (for development)

    private static func generateMockCandles(count: Int, for timeframe: TimeFrame) -> [CandleData] {
        var candles: [CandleData] = []
        let now = Int(Date().timeIntervalSince1970)
        let interval = timeframe.intervalSeconds
        var basePrice = 67500.0

        for i in 0..<count {
            let time = now - (count - i) * interval
            let change = Double.random(in: -200...200)
            let open = basePrice
            let close = open + change
            let high = max(open, close) + abs(Double.random(in: 0...150))
            let low = min(open, close) - abs(Double.random(in: 0...150))
            let volume = Double.random(in: 50...5000)

            candles.append(CandleData(
                time: time,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            ))
            basePrice = close
        }
        return candles
    }

    private static let mockOpenPositions: [Position] = [
        Position(
            id: "pos1", symbol: "BTCUSDT", side: .buy,
            entryPrice: 66800, currentPrice: 67500, quantity: 0.05,
            unrealizedPnl: 35.0, unrealizedPnlPct: 1.05,
            stopLoss: 66000, takeProfit: 69000,
            leverage: 3, margin: 1113.33,
            openedAt: "2025-01-10T08:00:00Z", closedAt: nil, status: .open
        ),
        Position(
            id: "pos2", symbol: "ETHUSDT", side: .sell,
            entryPrice: 3650, currentPrice: 3620, quantity: 2.0,
            unrealizedPnl: 60.0, unrealizedPnlPct: 0.82,
            stopLoss: 3700, takeProfit: 3550,
            leverage: 5, margin: 1460,
            openedAt: "2025-01-09T14:30:00Z", closedAt: nil, status: .open
        ),
    ]

    private static let mockClosedTrades: [Trade] = [
        Trade(
            id: "t1", symbol: "BTCUSDT", side: .buy,
            entryPrice: 65200, exitPrice: 66800,
            qty: 0.1, realizedPnl: 160, realizedPnlPct: 2.45,
            closeTime: "2025-01-08T16:00:00Z", status: .closed
        ),
        Trade(
            id: "t2", symbol: "SOLUSDT", side: .sell,
            entryPrice: 185, exitPrice: 190,
            qty: 10, realizedPnl: -50, realizedPnlPct: -2.7,
            closeTime: "2025-01-07T12:00:00Z", status: .closed
        ),
    ]

    private static let mockCredentials: [Credential] = [
        Credential(
            id: "cred1", exchange: "Binance", label: "Main Account",
            testnet: false, keyType: "hmac", createdAt: "2024-12-01T00:00:00Z",
            lastValidatedAt: "2025-01-12T10:00:00Z", status: "active"
        ),
        Credential(
            id: "cred2", exchange: "Binance", label: "Testnet",
            testnet: true, keyType: "hmac", createdAt: "2024-12-15T00:00:00Z",
            lastValidatedAt: "2025-01-11T08:00:00Z", status: "active"
        ),
    ]
}

// MARK: - Volume Data Point

/// Data point for the volume histogram overlay on the chart.
struct VolumeDataPoint {
    let time: Int
    let value: Double
    let color: Color
}

// MARK: - Import

import Combine

// =============================================================================
// MARK: - Preview
// =============================================================================

#Preview("TradingView") {
    TradingView()
}
