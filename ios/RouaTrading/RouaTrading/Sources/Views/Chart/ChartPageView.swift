import SwiftUI

// MARK: - Chart Page View — Professional Full-Screen Chart
struct ChartPageView: View {
    @StateObject private var vm = TradingViewModel()
    @ObservedObject private var wsManager = WebSocketManager.shared
    @State private var selectedTimeframe = "1h"
    @State private var showSymbolPicker = false
    @State private var showDrawingPanel = false
    @State private var showIndicatorPanel = false
    @State private var showAIPanel = false
    @State private var showOrderSheet = false
    @State private var tradePanelExpanded = false
    @State private var orderSide = "BUY"

    private let timeframes = ["1m", "5m", "15m", "1h", "4h", "1D", "1W"]
    private let popularSymbols = ["BTC/USDT", "ETH/USDT", "SOL/USDT", "BNB/USDT", "XRP/USDT", "DOGE/USDT", "ADA/USDT", "AVAX/USDT", "AAPL/USDT", "XAU/USDT"]

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // ─── Navigation Bar ───
                navBar

                // ─── Toolbar (Timeframes + Tools) ───
                toolbar

                // ─── Chart Container (fills remaining space) ───
                ZStack(alignment: .topTrailing) {
                    // Chart itself
                    if vm.historicalCandles.isEmpty && vm.isLoading {
                        loadingView
                    } else {
                        CandlestickChartWrapper(
                            candles: vm.historicalCandles,
                            liveCandle: wsManager.lastCandle
                        )
                        .ignoresSafeArea()
                    }

                    // Overlay: Symbol + Price + Trade Button (inside chart, top-right for RTL)
                    chartOverlay
                }
                .frame(maxHeight: .infinity)
            }
        }
        .background(RouaTheme.Colors.background)
        .navigationBarHidden(true)
        .task {
            vm.selectedTimeframe = selectedTimeframe.lowercased()
            await vm.loadTradingData()
            wsManager.connect(symbol: vm.symbol, interval: selectedTimeframe)
        }
        .onDisappear { wsManager.disconnect() }
        .sheet(isPresented: $showOrderSheet) { OrderSheet(vm: vm) }
        .sheet(isPresented: $showSymbolPicker) {
            SymbolPickerView(selectedSymbol: $vm.symbol, symbols: popularSymbols) { symbol in
                vm.symbol = symbol
                Task {
                    await vm.loadTradingData()
                    wsManager.connect(symbol: symbol, interval: selectedTimeframe)
                }
            }
        }
        .sheet(isPresented: $showDrawingPanel) {
            DrawingToolsSheet()
        }
        .sheet(isPresented: $showIndicatorPanel) {
            IndicatorSheet()
        }
        .sheet(isPresented: $showAIPanel) {
            AISmartSheet(symbol: vm.symbol)
        }
    }

    // MARK: - Navigation Bar
    private var navBar: some View {
        HStack(spacing: RouaTheme.Spacing.md) {
            // Symbol Selector
            Button { showSymbolPicker = true } label: {
                HStack(spacing: 4) {
                    Text(vm.symbol.replacingOccurrences(of: "/USDT", with: "/USDT"))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(RouaTheme.Colors.textPrimary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(RouaTheme.Colors.textTertiary)
                }
            }

            Spacer()

            // Notifications bell
            Button { } label: {
                Image(systemName: "bell")
                    .font(.system(size: 16))
                    .foregroundStyle(RouaTheme.Colors.textTertiary)
            }
        }
        .padding(.horizontal, RouaTheme.Spacing.lg)
        .padding(.vertical, RouaTheme.Spacing.sm)
        .background(RouaTheme.Colors.background)
    }

    // MARK: - Toolbar (above chart)
    private var toolbar: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    // Timeframe buttons
                    ForEach(timeframes, id: \.self) { tf in
                        Button {
                            selectedTimeframe = tf
                            vm.selectedTimeframe = tf.lowercased()
                            wsManager.connect(symbol: vm.symbol, interval: tf)
                            Task { await vm.loadHistoricalCandles() }
                        } label: {
                            Text(tf)
                                .font(.system(size: 12, weight: selectedTimeframe == tf ? .bold : .medium))
                                .foregroundStyle(selectedTimeframe == tf ? .white : RouaTheme.Colors.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(selectedTimeframe == tf ? RouaTheme.Colors.accent : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }

                    // Separator
                    Rectangle()
                        .fill(RouaTheme.Colors.border)
                        .frame(width: 1, height: 20)

                    // Chart type button (candlestick default)
                    Button { } label: {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(RouaTheme.Colors.textSecondary)
                            .frame(width: 32, height: 32)
                    }

                    // Drawing tools
                    Button { showDrawingPanel = true } label: {
                        Image(systemName: "pencil.tip.crop.circle")
                            .font(.system(size: 14))
                            .foregroundStyle(RouaTheme.Colors.textSecondary)
                            .frame(width: 32, height: 32)
                    }

                    // Indicators
                    Button { showIndicatorPanel = true } label: {
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 14))
                            .foregroundStyle(RouaTheme.Colors.textSecondary)
                            .frame(width: 32, height: 32)
                    }

                    // AI Smart Panel
                    Button { showAIPanel = true } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "brain")
                                .font(.system(size: 12))
                            Text("AI")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(RouaTheme.Colors.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(RouaTheme.Colors.accent.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                .padding(.horizontal, RouaTheme.Spacing.lg)
            }
            .padding(.vertical, RouaTheme.Spacing.xs)

            Divider().background(RouaTheme.Colors.border)
        }
        .background(RouaTheme.Colors.background)
    }

    // MARK: - Chart Overlay (symbol name + price + trade button)
    private var chartOverlay: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // Symbol name + price (top-right in RTL)
            HStack(spacing: 6) {
                if wsManager.isConnected {
                    PulsingDot(color: RouaTheme.Colors.profit)
                }

                VStack(alignment: .trailing, spacing: 1) {
                    let displayPrice = wsManager.lastPrice ?? vm.currentQuote?.lastPrice ?? 0
                    let displayChange = wsManager.lastTickerChange ?? vm.currentQuote?.changePercent ?? 0

                    Text(String(format: "%.2f", displayPrice))
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundStyle(displayChange >= 0 ? RouaTheme.Colors.profit : RouaTheme.Colors.loss)

                    if displayChange != 0 {
                        ChangeBadge(value: displayChange)
                    }
                }
            }
            .padding(.horizontal, RouaTheme.Spacing.md)
            .padding(.top, RouaTheme.Spacing.sm)

            // Collapsible Trade Button
            VStack(spacing: 0) {
                // Half Buy / Half Sell button
                HStack(spacing: 0) {
                    // Buy half (green)
                    Button {
                        orderSide = "BUY"
                        vm.orderSide = "BUY"
                        showOrderSheet = true
                    } label: {
                        Text("شراء")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 28)
                            .background(RouaTheme.Colors.profit)
                    }

                    // Sell half (red)
                    Button {
                        orderSide = "SELL"
                        vm.orderSide = "SELL"
                        showOrderSheet = true
                    } label: {
                        Text("بيع")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 28)
                            .background(RouaTheme.Colors.loss)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .frame(width: 100)
                .padding(.horizontal, RouaTheme.Spacing.md)
            }

            Spacer()
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md)
                .fill(RouaTheme.Colors.surface)
            VStack(spacing: RouaTheme.Spacing.sm) {
                ProgressView().tint(RouaTheme.Colors.accent)
                Text("جاري تحميل بيانات الشارت...")
                    .font(.system(size: 12))
                    .foregroundStyle(RouaTheme.Colors.textSecondary)
            }
        }
    }
}

// MARK: - Drawing Tools Sheet
struct DrawingToolsSheet: View {
    @Environment(\.dismiss) var dismiss

    private let categories: [(String, [(String, String)])] = [
        ("اتجاهات", [("خط أفقي", "minus"), ("خط عمودي", "line.diagonal"), ("خط اتجاه", "arrow.up.right"), ("شعاع", "sun.max")]),
        ("فيبوناتشي", [("ارتداد", "arrow.triangle.2.circlepath"), ("امتداد", "arrow.up.right.circle"), ("مروحة", "fanblades")]),
        ("أشكال", [("مستطيل", "rectangle"), ("مثلث", "triangle"), ("دائرة", "circle"), ("متوازي أضلاع", "parallelogram")]),
        ("تعليقات", [("نص", "textformat"), ("سهم", "arrow.right"), ("علم", "flag")]),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: RouaTheme.Spacing.lg) {
                    ForEach(categories, id: \.0) { category in
                        VStack(alignment: .leading, spacing: RouaTheme.Spacing.sm) {
                            Text(category.0)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(RouaTheme.Colors.textPrimary)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                                ForEach(category.1, id: \.0) { tool in
                                    Button { dismiss() } label: {
                                        VStack(spacing: 4) {
                                            Image(systemName: tool.1)
                                                .font(.system(size: 18))
                                                .foregroundStyle(RouaTheme.Colors.accent)
                                            Text(tool.0)
                                                .font(.system(size: 9))
                                                .foregroundStyle(RouaTheme.Colors.textSecondary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(RouaTheme.Colors.surfaceElevated)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(RouaTheme.Spacing.lg)
            }
            .background(RouaTheme.Colors.background)
            .navigationTitle("أدوات الرسم")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("إلغاء") { dismiss() }.foregroundStyle(RouaTheme.Colors.textSecondary)
                }
            }
        }
    }
}

// MARK: - Indicator Sheet
struct IndicatorSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var activeIndicators: Set<String> = []

    private let indicators: [(String, String, String)] = [
        ("MA", "المتوسط المتحرك", "#3B82F6"),
        ("EMA", "المتوسط الأسي", "#8B5CF6"),
        ("RSI", "مؤشر القوة النسبية", "#FFB300"),
        ("MACD", "ماكد", "#00C853"),
        ("BB", "بولينجر", "#FF5252"),
        ("STOCH", "الستوكاستك", "#29B6F6"),
        ("ATR", "متوسط المدى الحقيقي", "#FF9800"),
        ("VWAP", "فواب", "#E040FB"),
        ("VOL", "ال حجم", "#3B82F6"),
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(indicators, id: \.0) { ind in
                    HStack(spacing: RouaTheme.Spacing.md) {
                        Circle().fill(Color(hex: ind.2)).frame(width: 10, height: 10)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ind.0).font(.system(size: 14, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary)
                            Text(ind.1).font(.system(size: 11)).foregroundStyle(RouaTheme.Colors.textSecondary)
                        }
                        Spacer()
                        Image(systemName: activeIndicators.contains(ind.0) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(activeIndicators.contains(ind.0) ? RouaTheme.Colors.accent : RouaTheme.Colors.textTertiary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if activeIndicators.contains(ind.0) {
                            activeIndicators.remove(ind.0)
                        } else {
                            activeIndicators.insert(ind.0)
                        }
                    }
                }
            }
            .background(RouaTheme.Colors.background).scrollContentBackground(.hidden)
            .navigationTitle("المؤشرات الفنية")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("تم") { dismiss() }.foregroundStyle(RouaTheme.Colors.accent)
                }
            }
        }
    }
}

// MARK: - AI Smart Sheet
struct AISmartSheet: View {
    let symbol: String
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0
    @State private var isLoading = false
    @State private var analysisResult: String?

    private let tabs = ["أنماط", "SMC", "إليوت", "ويكوف", "AI"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: RouaTheme.Spacing.sm) {
                        ForEach(0..<tabs.count, id: \.self) { i in
                            Button {
                                withAnimation { selectedTab = i }
                            } label: {
                                Text(tabs[i])
                                    .font(.system(size: 13, weight: selectedTab == i ? .bold : .medium))
                                    .foregroundStyle(selectedTab == i ? .white : RouaTheme.Colors.textSecondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedTab == i ? RouaTheme.Colors.accent : RouaTheme.Colors.surfaceElevated)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                    .padding(.horizontal, RouaTheme.Spacing.lg)
                    .padding(.vertical, RouaTheme.Spacing.sm)
                }

                Divider().background(RouaTheme.Colors.border)

                // Content
                ScrollView {
                    VStack(spacing: RouaTheme.Spacing.lg) {
                        if isLoading {
                            ProgressView().tint(RouaTheme.Colors.accent)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if let result = analysisResult {
                            Text(result)
                                .font(.system(size: 14))
                                .foregroundStyle(RouaTheme.Colors.textPrimary)
                                .padding(RouaTheme.Spacing.lg)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RouaTheme.Colors.surfaceElevated)
                                .clipShape(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md))
                        } else {
                            VStack(spacing: RouaTheme.Spacing.md) {
                                Image(systemName: "brain")
                                    .font(.system(size: 40))
                                    .foregroundStyle(RouaTheme.Colors.accent.opacity(0.5))
                                Text("اضغط تحليل للحصول على نتائج AI لـ \(symbol)")
                                    .font(.system(size: 14))
                                    .foregroundStyle(RouaTheme.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 40)
                        }

                        TradingButton(title: "تحليل \(symbol)", style: .primary, isLoading: isLoading) {
                            Task { await runAnalysis() }
                        }
                    }
                    .padding(RouaTheme.Spacing.lg)
                }
            }
            .background(RouaTheme.Colors.background)
            .navigationTitle("التحليل الذكي")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("إلغاء") { dismiss() }.foregroundStyle(RouaTheme.Colors.textSecondary)
                }
            }
        }
    }

    private func runAnalysis() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let request = AIAnalyzeRequest(prompt: "Perform a detailed \(tabs[selectedTab]) analysis for \(symbol)", type: tabs[selectedTab].lowercased(), symbol: symbol, language: "ar")
            let response: AIAnalyzeResponse = try await APIClient.shared.request("/ai/analyze", method: "POST", body: request)
            analysisResult = response.text
        } catch {
            analysisResult = "فشل التحليل: \(error.localizedDescription)"
        }
    }
}
