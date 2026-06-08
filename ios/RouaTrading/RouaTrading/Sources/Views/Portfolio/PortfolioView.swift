// =============================================================================
// PortfolioView.swift — Roua Trading · Portfolio Management
// =============================================================================
// Tabbed portfolio view matching the web design with 4 tabs:
// الصفقات (Trades), الأداء (Performance), المخاطر (Risk), مدرب الذكاء (AI Coach)
// Uses RouaColors, RouaTypography, RouaSpacing, and RouaComponents.
// Supports RTL layout, accessibility, and smooth animations.
// =============================================================================

import SwiftUI

// MARK: - Portfolio Tab

enum PortfolioTab: String, CaseIterable, Identifiable {
    case trades      = "الصفقات"
    case performance = "الأداء"
    case risk        = "المخاطر"
    case aiCoach     = "مدرب الذكاء"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .trades:      return "chart.line.uptrend.xyaxis"
        case .performance: return "chart.bar.fill"
        case .risk:        return "shield.lefthalf.filled"
        case .aiCoach:     return "brain.head.profile"
        }
    }
}

// MARK: - Agent Action (local to view)

/// Represents a pending agent action that requires user confirmation.
enum AgentAction {
    case start(strategy: AgentStrategy)
    case stop

    var message: String {
        switch self {
        case .start: return "هل تريد تشغيل وكيل التداول؟"
        case .stop:  return "هل تريد إيقاف وكيل التداول؟"
        }
    }
}

// MARK: - P&L Category

/// Breakdown category for P&L display.
enum PnLCategory: String, CaseIterable, Identifiable {
    case smartExecutor = "المنفذ الذكي"
    case agent         = "الوكيل"
    case paper         = "تجريبي"
    case manual        = "يدوي"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .smartExecutor: return .rouaPrimary
        case .agent:         return .rouaProfit
        case .paper:         return .rouaWarning
        case .manual:        return .rouaCyan
        }
    }

    var iconName: String {
        switch self {
        case .smartExecutor: return "bolt.fill"
        case .agent:         return "brain.head.profile"
        case .paper:         return "doc.text"
        case .manual:        return "hand.raised"
        }
    }
}

// MARK: - Portfolio View

struct PortfolioView: View {

    @StateObject private var viewModel = PortfolioViewModel()
    @State private var selectedTab: PortfolioTab = .trades
    @State private var showAddCredential = false
    @State private var showAgentConfirmation = false

    // Local state previously on inline ViewModel
    @State private var selectedStrategy: AgentStrategy = .auto
    @State private var maxPositionSize: Double = 10
    @State private var maxDailyLoss: Double = 5
    @State private var maxOpenPositions: Int = 5
    @State private var maxOpenPositionsDouble: Double = 5
    @State private var riskPerTrade: Double = 2
    @State private var agentActionPending: AgentAction?
    @State private var isAgentToggling = false

    // Trades tab local state
    @State private var expandedPositionId: String?
    @State private var searchQuery = ""
    @State private var filterSide: OrderSide?
    @State private var showPanicConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.rouaBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Stats Row (horizontal scroll of 7 mini stat cards)
                    statsRow
                        .padding(.top, RouaSpacing.sm)

                    // P&L by Category
                    pnlByCategorySection
                        .padding(.top, RouaSpacing.sm)

                    // Underline Tab Control
                    underlineTabControl
                        .padding(.horizontal, RouaSpacing.screenPadding)
                        .padding(.top, RouaSpacing.md)

                    // Tab Content
                    Group {
                        switch selectedTab {
                        case .trades:
                            tradesTab
                        case .performance:
                            performanceTab
                        case .risk:
                            riskTab
                        case .aiCoach:
                            aiCoachTab
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("المحفظة")
                        .rouaFont(.headline, color: .rouaTextPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: RouaSpacing.sm) {
                        Button {
                            viewModel.loadAll()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: RouaSpacing.iconMedium))
                                .foregroundStyle(.rouaTextSecondary)
                        }
                        .accessibilityLabel("تحديث")

                        Button {
                            exportCSV()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: RouaSpacing.iconMedium))
                                .foregroundStyle(.rouaTextSecondary)
                        }
                        .accessibilityLabel("تصدير CSV")
                    }
                }
            }
            .task {
                viewModel.loadAll()
            }
            .refreshable {
                viewModel.loadAll()
            }
            .overlay {
                // Only show full-screen loading on first load when ALL data is empty.
                if viewModel.isLoading
                    && viewModel.portfolioSummary == nil
                    && viewModel.credentials.isEmpty
                    && viewModel.agentState == nil {
                    LoadingView(message: "جاري التحميل...")
                }
            }
            .alert(
                "تأكيد",
                isPresented: $showAgentConfirmation,
                presenting: agentActionPending
            ) { action in
                Button("إلغاء", role: .cancel) {}
                Button("تأكيد") {
                    confirmAgentAction(action)
                }
            } message: { action in
                Text(action.message)
            }
            .alert("إغلاق جميع الصفقات", isPresented: $showPanicConfirm) {
                Button("إلغاء", role: .cancel) {}
                Button("إغلاق الكل", role: .destructive) {
                    panicCloseAll()
                }
            } message: {
                Text("هل أنت متأكد من إغلاق جميع الصفقات المفتوحة؟")
            }
            .sheet(isPresented: $showAddCredential) {
                AddCredentialSheet(isPresented: $showAddCredential)
            }
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RouaSpacing.sm) {
                let summary = viewModel.portfolioSummary
                let perf = viewModel.performance

                miniStatCard(
                    title: "صفقات مفتوحة",
                    value: "\(summary?.openPositionsCount ?? 0)",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .rouaPrimary
                )
                miniStatCard(
                    title: "ربح غير محقق",
                    value: "$\(formatNumber(summary?.unrealizedPnl ?? 0))",
                    icon: "dollarsign.circle",
                    color: .rouaPnLColor(value: summary?.unrealizedPnl ?? 0)
                )
                miniStatCard(
                    title: "ربح محقق",
                    value: "$\(formatNumber(perf?.totalPnl ?? 0))",
                    icon: "checkmark.circle",
                    color: .rouaProfit
                )
                miniStatCard(
                    title: "إجمالي الربح",
                    value: "$\(formatNumber(summary?.totalPnl ?? 0))",
                    icon: "trendingup",
                    color: .rouaProfit
                )
                miniStatCard(
                    title: "إجمالي الخسارة",
                    value: "$\(formatNumber(perf?.avgLoss ?? 0))",
                    icon: "trendingdown",
                    color: .rouaLoss
                )
                miniStatCard(
                    title: "نسبة الفوز",
                    value: perf?.formattedWinRate ?? "0.0%",
                    icon: "percent",
                    color: .rouaProfit
                )
                miniStatCard(
                    title: "نسبة شارب",
                    value: perf?.sharpeRatio.map { String(format: "%.2f", $0) } ?? "—",
                    icon: "waveform.path",
                    color: .rouaCyan
                )
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
        }
    }

    private func miniStatCard(
        title: String,
        value: String,
        icon: String,
        color: Color
    ) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                HStack(spacing: RouaSpacing.xs) {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                        .foregroundStyle(color)
                    Text(title)
                        .rouaFont(.caption, color: .rouaTextTertiary)
                        .lineLimit(1)
                }
                Text(value)
                    .rouaFont(.calloutBold, color: color)
                    .monospacedDigit()
                    .lineLimit(1)
            }
            .frame(minWidth: 100)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: - P&L by Category

    private var pnlByCategorySection: some View {
        VStack(alignment: .leading, spacing: RouaSpacing.sm) {
            SectionHeader(title: "الربح/الخسارة حسب الفئة")

            GlassCard {
                VStack(spacing: RouaSpacing.md) {
                    ForEach(PnLCategory.allCases) { category in
                        pnlCategoryRow(category: category, value: pnlValueForCategory(category))
                    }
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
        }
    }

    private func pnlCategoryRow(category: PnLCategory, value: Double) -> some View {
        VStack(alignment: .leading, spacing: RouaSpacing.xs) {
            HStack {
                HStack(spacing: RouaSpacing.xs) {
                    Image(systemName: category.iconName)
                        .font(.system(size: RouaSpacing.iconSmall))
                        .foregroundStyle(category.color)
                    Text(category.rawValue)
                        .rouaFont(.footnote, color: .rouaTextPrimary)
                }
                Spacer()
                Text("$\(formatNumber(value))")
                    .rouaFont(.footnoteBold, color: .rouaPnLColor(value: value))
                    .monospacedDigit()
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color.rouaSurfaceLight)
                        .frame(height: 4)

                    // Filled portion
                    let totalAbs = abs(pnlValueForCategory(.smartExecutor))
                        + abs(pnlValueForCategory(.agent))
                        + abs(pnlValueForCategory(.paper))
                        + abs(pnlValueForCategory(.manual))
                    let fraction = totalAbs > 0 ? abs(value) / totalAbs : 0

                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(category.color)
                        .frame(width: geo.size.width * min(fraction, 1.0), height: 4)
                }
            }
            .frame(height: 4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(category.rawValue): $\(formatNumber(value))")
    }

    private func pnlValueForCategory(_ category: PnLCategory) -> Double {
        // Placeholder values — in production these would come from the API
        switch category {
        case .smartExecutor:
            return viewModel.performance?.totalPnl ?? 0
        case .agent:
            return viewModel.agentPositions.map { $0.unrealizedPnl }.reduce(0, +)
        case .paper:
            return 0
        case .manual:
            return viewModel.portfolioSummary?.dailyPnL ?? 0
        }
    }

    // MARK: - Underline Tab Control

    private var underlineTabControl: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(PortfolioTab.allCases) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: RouaSpacing.animationFast)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: RouaSpacing.xs) {
                            HStack(spacing: RouaSpacing.xs) {
                                Image(systemName: tab.iconName)
                                    .font(.system(size: RouaSpacing.iconSmall))
                                Text(tab.rawValue)
                                    .rouaFont(.footnoteBold)
                            }
                            .foregroundStyle(selectedTab == tab ? .rouaPrimary : .rouaTextSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, RouaSpacing.sm)

                            // Underline indicator
                            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                                .fill(selectedTab == tab ? Color.rouaPrimary : Color.clear)
                                .frame(height: 3)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tab.rawValue)
                    .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
                }
            }

            // Bottom border
            Rectangle()
                .fill(Color.rouaBorder)
                .frame(height: 0.5)
        }
    }

    // MARK: - Agent Action Handler

    private func confirmAgentAction(_ action: AgentAction) {
        isAgentToggling = true
        switch action {
        case .start(let strategy):
            let request = AgentStartRequest(
                strategy: strategy,
                credentialId: nil,
                symbols: nil,
                maxPositionSizePercent: maxPositionSize,
                maxDailyLossPercent: maxDailyLoss,
                maxOpenPositions: maxOpenPositions,
                riskPerTradePercent: riskPerTrade,
                strategyParams: nil
            )
            Task {
                await viewModel.startAgent(request)
                isAgentToggling = false
            }
        case .stop:
            Task {
                await viewModel.stopAgent()
                isAgentToggling = false
            }
        }
    }

    // MARK: - Export CSV

    private func exportCSV() {
        // Placeholder — in production would generate and share CSV
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // MARK: - Panic Close All

    private func panicCloseAll() {
        Task {
            await viewModel.stopAgent(emergency: true)
        }
    }
}

// MARK: - Trades Tab

extension PortfolioView {

    private var tradesTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaSpacing.lg) {
                // Agent Status Card (compact)
                compactAgentStatusCard

                // Search & Filter
                searchFilterBar

                // Panic Close All
                if !filteredPositions.isEmpty {
                    RouaButton(
                        "إغلاق جميع الصفقات",
                        variant: .danger,
                        size: .small,
                        icon: "exclamationmark.triangle.fill"
                    ) {
                        showPanicConfirm = true
                    }
                    .padding(.horizontal, RouaSpacing.screenPadding)
                }

                // Position List
                if filteredPositions.isEmpty {
                    EmptyStateView(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "لا توجد صفقات",
                        description: "لا توجد صفقات مفتوحة حالياً"
                    )
                } else {
                    ForEach(filteredPositions) { position in
                        expandablePositionRow(position)
                            .padding(.horizontal, RouaSpacing.screenPadding)
                    }
                }
            }
            .padding(.vertical, RouaSpacing.lg)
        }
    }

    // MARK: - Compact Agent Status

    private var compactAgentStatusCard: some View {
        GlassCard(glow: viewModel.agentState?.isActive == true ? .rouaProfit : nil) {
            HStack(spacing: RouaSpacing.md) {
                PulsingDot(
                    status: viewModel.agentState?.isActive == true ? .active : .inactive,
                    size: 8
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.agentState?.isActive == true ? "الوكيل نشط" : "الوكيل متوقف")
                        .rouaFont(.subheadlineBold, color: .rouaTextPrimary)

                    if let strategy = viewModel.agentState?.strategy {
                        Text(strategy)
                            .rouaFont(.caption, color: .rouaTextSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                RouaButton(
                    viewModel.agentState?.isActive == true ? "إيقاف" : "تشغيل",
                    variant: viewModel.agentState?.isActive == true ? .danger : .primary,
                    size: .small,
                    icon: viewModel.agentState?.isActive == true ? "stop.fill" : "play.fill",
                    isLoading: isAgentToggling
                ) {
                    agentActionPending = viewModel.agentState?.isActive == true
                        ? .stop
                        : .start(strategy: selectedStrategy)
                    showAgentConfirmation = true
                }
                .frame(maxWidth: 120)
            }
        }
        .padding(.horizontal, RouaSpacing.screenPadding)
    }

    // MARK: - Search & Filter

    private var searchFilterBar: some View {
        VStack(spacing: RouaSpacing.sm) {
            // Search field
            HStack(spacing: RouaSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: RouaSpacing.iconMedium))
                    .foregroundStyle(.rouaTextTertiary)

                TextField("بحث عن صفقة...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .rouaFont(.body, color: .rouaTextPrimary)

                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: RouaSpacing.iconMedium))
                            .foregroundStyle(.rouaTextTertiary)
                    }
                }
            }
            .padding(RouaSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius)
                    .fill(Color.rouaSurfaceLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius)
                    .stroke(Color.rouaGlassBorder, lineWidth: 1)
            )

            // Side filter pills
            HStack(spacing: RouaSpacing.sm) {
                sideFilterPill(label: "الكل", filter: nil)
                sideFilterPill(label: "شراء", filter: .buy)
                sideFilterPill(label: "بيع", filter: .sell)
            }
        }
        .padding(.horizontal, RouaSpacing.screenPadding)
    }

    private func sideFilterPill(label: String, filter: OrderSide?) -> some View {
        Button {
            withAnimation(.easeInOut(duration: RouaSpacing.animationFast)) {
                filterSide = filter
            }
        } label: {
            Text(label)
                .rouaFont(
                    filterSide == filter ? .footnoteBold : .footnote,
                    color: filterSide == filter ? .white : .rouaTextSecondary
                )
                .padding(.horizontal, RouaSpacing.md)
                .padding(.vertical, RouaSpacing.xs)
                .background(
                    Capsule().fill(filterSide == filter ? Color.rouaPrimary : Color.rouaSurfaceLight)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("تصفية: \(label)")
        .accessibilityAddTraits(filterSide == filter ? .isSelected : [])
    }

    // MARK: - Filtered Positions

    private var filteredPositions: [Position] {
        let allPositions = viewModel.portfolioSummary?.positions ?? []
        return allPositions.filter { position in
            // Side filter
            if let filterSide, position.side != filterSide { return false }
            // Search query
            if !searchQuery.isEmpty {
                return position.symbol.localizedCaseInsensitiveContains(searchQuery)
            }
            return true
        }
    }

    // MARK: - Expandable Position Row

    private func expandablePositionRow(_ position: Position) -> some View {
        GlassCard {
            VStack(spacing: 0) {
                // Main row
                HStack(spacing: RouaSpacing.md) {
                    VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                        Text(position.symbol)
                            .rouaFont(.calloutBold, color: .rouaTextPrimary)
                            .lineLimit(1)
                        Badge(
                            text: position.isLong ? "Long" : "Short",
                            variant: position.isLong ? .success : .error
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(position.formattedPnl)
                            .rouaFont(.calloutBold, color: .rouaPnLColor(value: position.unrealizedPnl))
                            .monospacedDigit()
                        if let pct = position.unrealizedPnlPct {
                            let sign = pct >= 0 ? "+" : ""
                            Text("\(sign)\(String(format: "%.2f", pct))%")
                                .rouaFont(.footnote, color: .rouaPnLColor(value: position.unrealizedPnl))
                                .monospacedDigit()
                        }
                    }

                    // Expand chevron
                    Image(systemName: expandedPositionId == position.id ? "chevron.up" : "chevron.down")
                        .font(.system(size: RouaSpacing.iconSmall, weight: .bold))
                        .foregroundStyle(.rouaTextTertiary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: RouaSpacing.animationFast)) {
                        expandedPositionId = expandedPositionId == position.id ? nil : position.id
                    }
                }

                // Expanded details
                if expandedPositionId == position.id {
                    expandedPositionDetails(position)
                        .padding(.top, RouaSpacing.md)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private func expandedPositionDetails(_ position: Position) -> some View {
        VStack(spacing: RouaSpacing.md) {
            Divider().overlay(Color.rouaGlassBorder)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: RouaSpacing.md) {
                StatMini(
                    label: "الكمية",
                    value: String(format: "%.4f", position.quantity)
                )
                StatMini(
                    label: "سعر الدخول",
                    value: String(format: "%.2f", position.entryPrice)
                )
                StatMini(
                    label: "السعر الحالي",
                    value: String(format: "%.2f", position.currentPrice ?? position.entryPrice)
                )
                if let leverage = position.leverage {
                    StatMini(label: "الرافعة", value: "\(Int(leverage))×")
                }
                if let sl = position.stopLoss {
                    StatMini(label: "وقف الخسارة", value: String(format: "%.2f", sl))
                }
                if let tp = position.takeProfit {
                    StatMini(label: "جني الأرباح", value: String(format: "%.2f", tp))
                }
            }

            // Close position button
            RouaButton(
                "إغلاق الصفقة",
                variant: .danger,
                size: .small,
                icon: "xmark.circle"
            ) {
                closePosition(position.id)
            }
        }
    }

    private func closePosition(_ positionId: String) {
        Task {
            let request = ClosePositionRequest(positionId: positionId, quantity: nil)
            _ = try? await APIClient.shared.requestRaw(.tradingClosePosition, body: request)
            viewModel.loadAll()
        }
    }
}

// MARK: - Performance Tab

extension PortfolioView {

    private var performanceTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaSpacing.lg) {
                if let metrics = viewModel.performance {
                    // Equity Curve Placeholder
                    equityCurvePlaceholder
                        .padding(.horizontal, RouaSpacing.screenPadding)

                    // Daily P&L Stats
                    dailyPnLSection(metrics)
                        .padding(.horizontal, RouaSpacing.screenPadding)

                    // Performance Metrics Grid
                    performanceMetricsGrid(metrics)
                        .padding(.horizontal, RouaSpacing.screenPadding)
                } else if viewModel.isLoading {
                    performanceShimmer
                } else {
                    EmptyStateView(
                        icon: "chart.bar",
                        title: "لا توجد بيانات أداء",
                        description: "ستظهر بيانات الأداء بعد تنفيذ صفقات"
                    )
                }
            }
            .padding(.vertical, RouaSpacing.lg)
        }
    }

    // MARK: - Equity Curve Placeholder

    private var equityCurvePlaceholder: some View {
        VStack(alignment: .leading, spacing: RouaSpacing.md) {
            SectionHeader(title: "منحنى رأس المال")

            GlassCard(glow: .rouaPrimary) {
                VStack(spacing: RouaSpacing.md) {
                    // Chart placeholder — draw a simple line representation
                    GeometryReader { geo in
                        ZStack {
                            // Grid lines
                            VStack(spacing: 0) {
                                ForEach(0..<5) { _ in
                                    Rectangle()
                                        .fill(Color.rouaBorder)
                                        .frame(height: 0.5)
                                    Spacer()
                                }
                            }

                            // Simulated equity curve path
                            Path { path in
                                let w = geo.size.width
                                let h = geo.size.height
                                path.move(to: CGPoint(x: 0, y: h * 0.6))
                                path.addCurve(
                                    to: CGPoint(x: w, y: h * 0.3),
                                    control1: CGPoint(x: w * 0.3, y: h * 0.5),
                                    control2: CGPoint(x: w * 0.7, y: h * 0.2)
                                )
                            }
                            .stroke(Color.rouaPrimary, style: StrokeStyle(lineWidth: 2, lineCap: .round))

                            // Gradient fill under curve
                            Path { path in
                                let w = geo.size.width
                                let h = geo.size.height
                                path.move(to: CGPoint(x: 0, y: h))
                                path.addLine(to: CGPoint(x: 0, y: h * 0.6))
                                path.addCurve(
                                    to: CGPoint(x: w, y: h * 0.3),
                                    control1: CGPoint(x: w * 0.3, y: h * 0.5),
                                    control2: CGPoint(x: w * 0.7, y: h * 0.2)
                                )
                                path.addLine(to: CGPoint(x: w, y: h))
                                path.closeSubpath()
                            }
                            .fill(
                                LinearGradient(
                                    colors: [Color.rouaPrimary.opacity(0.3), Color.rouaPrimary.opacity(0.0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                    }
                    .frame(height: 180)

                    Text("المنحنى التقريبي — الرسم البياني الكامل قريباً")
                        .rouaFont(.caption, color: .rouaTextTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }

    // MARK: - Daily P&L Section

    private func dailyPnLSection(_ metrics: PerformanceMetrics) -> some View {
        VStack(alignment: .leading, spacing: RouaSpacing.sm) {
            SectionHeader(title: "ربح/خسارة يومي")

            GlassCard {
                VStack(spacing: RouaSpacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                            Text("إجمالي الربح/الخسارة")
                                .rouaFont(.footnote, color: .rouaTextSecondary)
                            Text(metrics.formattedTotalPnl)
                                .rouaFont(.title3, color: .rouaPnLColor(value: metrics.totalPnl))
                                .monospacedDigit()
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: RouaSpacing.xs) {
                            Text("العائد اليومي")
                                .rouaFont(.footnote, color: .rouaTextSecondary)
                            Text(metrics.dailyReturn.map { String(format: "%.2f%%", $0) } ?? "—")
                                .rouaFont(.title3, color: .rouaPnLColor(value: metrics.dailyReturn ?? 0))
                                .monospacedDigit()
                        }
                    }

                    // Mini bar chart placeholder
                    HStack(alignment: .bottom, spacing: 2) {
                        ForEach(0..<14, id: \.self) { index in
                            let height = CGFloat.random(in: 20...80)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(index % 3 == 0 ? Color.rouaLoss.opacity(0.6) : Color.rouaProfit.opacity(0.6))
                                .frame(width: 12, height: height)
                        }
                    }
                    .frame(height: 80)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Performance Metrics Grid

    private func performanceMetricsGrid(_ metrics: PerformanceMetrics) -> some View {
        VStack(alignment: .leading, spacing: RouaSpacing.sm) {
            SectionHeader(title: "مقاييس الأداء")

            GlassCard {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: RouaSpacing.lg) {
                    StatMini(label: "إجمالي الصفقات", value: "\(metrics.totalTrades)")
                    StatMini(label: "نسبة الفوز", value: metrics.formattedWinRate)
                    StatMini(
                        label: "الربح/الخسارة",
                        value: metrics.formattedTotalPnl,
                        change: metrics.totalPnl
                    )
                    if let sharpe = metrics.sharpeRatio {
                        StatMini(label: "نسبة شارب", value: String(format: "%.2f", sharpe))
                    }
                    if let drawdown = metrics.formattedMaxDrawdown {
                        StatMini(label: "أقصى تراجع", value: drawdown)
                    }
                    if let wins = metrics.winningTrades {
                        StatMini(label: "صفقات رابحة", value: "\(wins)")
                    }
                    if let losses = metrics.losingTrades {
                        StatMini(label: "صفقات خاسرة", value: "\(losses)")
                    }
                    if let best = metrics.bestTrade {
                        StatMini(label: "أفضل صفقة", value: String(format: "$%.2f", best))
                    }
                    if let worst = metrics.worstTrade {
                        StatMini(label: "أسوأ صفقة", value: String(format: "$%.2f", worst))
                    }
                    if let pf = metrics.profitFactor {
                        StatMini(label: "عامل الربح", value: String(format: "%.2f", pf))
                    }
                    if let consec = metrics.consecutiveWins {
                        StatMini(label: "انتصارات متتالية", value: "\(consec)")
                    }
                }
            }
        }
    }

    private var performanceShimmer: some View {
        VStack(spacing: RouaSpacing.lg) {
            GlassCard {
                VStack(alignment: .leading, spacing: RouaSpacing.md) {
                    ShimmerView(width: 150, height: 14)
                    ShimmerView(height: 180)
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)

            GlassCard {
                VStack(alignment: .leading, spacing: RouaSpacing.md) {
                    ShimmerView(width: 120, height: 14)
                    HStack {
                        ShimmerView(width: 100, height: 28)
                        Spacer()
                        ShimmerView(width: 80, height: 28)
                    }
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
        }
        .padding(.vertical, RouaSpacing.lg)
    }
}

// MARK: - Risk Tab

extension PortfolioView {

    private var riskTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaSpacing.lg) {
                // Risk Score Card
                riskScoreCard
                    .padding(.horizontal, RouaSpacing.screenPadding)

                // Risk Metrics Grid
                riskMetricsGrid
                    .padding(.horizontal, RouaSpacing.screenPadding)

                // Risk Parameters (from Agent)
                riskParametersSection

                // Risk Recommendations
                if let report = viewModel.riskReport, !report.recommendations.isEmpty {
                    riskRecommendations(report)
                        .padding(.horizontal, RouaSpacing.screenPadding)
                }
            }
            .padding(.vertical, RouaSpacing.lg)
        }
    }

    // MARK: - Risk Score Card

    private var riskScoreCard: some View {
        GlassCard(glow: riskGlowColor) {
            VStack(spacing: RouaSpacing.md) {
                HStack {
                    Text("مستوى المخاطر")
                        .rouaFont(.subheadline, color: .rouaTextSecondary)

                    Spacer()

                    if let report = viewModel.riskReport {
                        Badge(
                            text: report.riskLevel.displayName,
                            variant: riskBadgeVariant(for: report.riskLevel)
                        )
                    }
                }

                if let report = viewModel.riskReport {
                    // Risk score gauge
                    ZStack {
                        Circle()
                            .stroke(Color.rouaSurfaceLight, lineWidth: 8)
                            .frame(width: 100, height: 100)

                        Circle()
                            .trim(from: 0, to: min(report.overallRisk / 100, 1.0))
                            .stroke(
                                riskScoreColor(for: report.overallRisk),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))

                        Text("\(Int(report.overallRisk))")
                            .rouaFont(.title2, color: riskScoreColor(for: report.overallRisk))
                            .monospacedDigit()
                    }
                } else {
                    ZStack {
                        Circle()
                            .stroke(Color.rouaSurfaceLight, lineWidth: 8)
                            .frame(width: 100, height: 100)

                        Text("—")
                            .rouaFont(.title2, color: .rouaTextTertiary)
                    }
                }
            }
        }
    }

    private var riskGlowColor: Color? {
        guard let report = viewModel.riskReport else { return nil }
        return riskScoreColor(for: report.overallRisk)
    }

    private func riskScoreColor(for score: Double) -> Color {
        switch score {
        case 0..<25:  return .rouaProfit
        case 25..<50: return .rouaWarning
        case 50..<75: return .rouaLoss
        default:      return .rouaDanger
        }
    }

    private func riskBadgeVariant(for level: RiskLevel) -> BadgeVariant {
        switch level {
        case .low:      return .success
        case .medium:   return .warning
        case .high:     return .error
        case .critical: return .error
        }
    }

    // MARK: - Risk Metrics Grid

    private var riskMetricsGrid: some View {
        VStack(alignment: .leading, spacing: RouaSpacing.sm) {
            SectionHeader(title: "مقاييس المخاطر")

            GlassCard {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: RouaSpacing.lg) {
                    let metrics = viewModel.performance
                    let summary = viewModel.portfolioSummary
                    let report = viewModel.riskReport

                    StatMini(
                        label: "عامل الربح",
                        value: metrics?.profitFactor.map { String(format: "%.2f", $0) } ?? "—"
                    )
                    StatMini(
                        label: "أقصى تراجع",
                        value: metrics?.formattedMaxDrawdown
                            ?? summary.map { String(format: "%.1f%%", $0.maxDrawdownPercent) }
                            ?? "—"
                    )
                    StatMini(
                        label: "نسبة شارب",
                        value: metrics?.sharpeRatio.map { String(format: "%.2f", $0) } ?? "—"
                    )
                    StatMini(
                        label: "متوسط الربح",
                        value: metrics.map { "$\(formatNumber($0.avgWin))" } ?? "—"
                    )
                    StatMini(
                        label: "متوسط الخسارة",
                        value: metrics.map { "$\(formatNumber($0.avgLoss))" } ?? "—"
                    )
                    StatMini(
                        label: "المخاطرة/المكافأة",
                        value: riskRewardRatio
                    )
                    if let report {
                        StatMini(
                            label: "تركيز المراكز",
                            value: String(format: "%.0f%%", report.positionConcentration * 100)
                        )
                        StatMini(
                            label: "تنويع المحفظة",
                            value: String(format: "%.0f%%", report.diversificationScore)
                        )
                        StatMini(
                            label: "تعرض الرافعة",
                            value: String(format: "%.1f×", report.leverageExposure)
                        )
                    }
                }
            }
        }
    }

    private var riskRewardRatio: String {
        guard let metrics = viewModel.performance, metrics.avgLoss != 0 else { return "—" }
        let ratio = abs(metrics.avgWin / metrics.avgLoss)
        return String(format: "%.2f", ratio)
    }

    // MARK: - Risk Recommendations

    private func riskRecommendations(_ report: RiskReport) -> some View {
        VStack(alignment: .leading, spacing: RouaSpacing.sm) {
            SectionHeader(title: "توصيات المخاطر")

            GlassCard {
                VStack(alignment: .leading, spacing: RouaSpacing.md) {
                    ForEach(report.recommendations.indices, id: \.self) { index in
                        HStack(alignment: .top, spacing: RouaSpacing.sm) {
                            Image(systemName: "exclamationmark.shield.fill")
                                .font(.system(size: RouaSpacing.iconSmall))
                                .foregroundStyle(.rouaWarning)
                                .padding(.top, 2)

                            Text(report.recommendations[index])
                                .rouaFont(.footnote, color: .rouaTextPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if index < report.recommendations.count - 1 {
                            Divider().overlay(Color.rouaGlassBorder)
                        }
                    }

                    if let analysis = report.aiAnalysis, !analysis.isEmpty {
                        Divider().overlay(Color.rouaGlassBorder)

                        HStack(alignment: .top, spacing: RouaSpacing.sm) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: RouaSpacing.iconSmall))
                                .foregroundStyle(.rouaPurple)
                                .padding(.top, 2)

                            VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                                Text("تحليل الذكاء الاصطناعي")
                                    .rouaFont(.footnoteBold, color: .rouaPurple)
                                Text(analysis)
                                    .rouaFont(.footnote, color: .rouaTextSecondary)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - AI Coach Tab

extension PortfolioView {

    private var aiCoachTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaSpacing.lg) {
                // AI Coach Header
                aiCoachHeader
                    .padding(.horizontal, RouaSpacing.screenPadding)

                // Recommendations
                aiRecommendations
                    .padding(.horizontal, RouaSpacing.screenPadding)

                // Strategy Selector
                strategySelectorSection

                // Risk Parameters
                riskParametersSection

                // Quick Actions
                aiQuickActions
                    .padding(.horizontal, RouaSpacing.screenPadding)
            }
            .padding(.vertical, RouaSpacing.lg)
        }
    }

    // MARK: - AI Coach Header

    private var aiCoachHeader: some View {
        GlassCard(glow: .rouaPurple) {
            VStack(spacing: RouaSpacing.md) {
                HStack(spacing: RouaSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(Color.rouaPurple.opacity(0.2))
                            .frame(width: 48, height: 48)
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: RouaSpacing.iconXL))
                            .foregroundStyle(.rouaPurple)
                    }

                    VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                        Text("مدرب التداول الذكي")
                            .rouaFont(.headline, color: .rouaTextPrimary)
                        Text("توصيات مخصصة بناءً على أدائك")
                            .rouaFont(.footnote, color: .rouaTextSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let metrics = viewModel.performance {
                    // Performance summary
                    HStack(spacing: RouaSpacing.lg) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("الصفقات")
                                .rouaFont(.caption, color: .rouaTextTertiary)
                            Text("\(metrics.totalTrades)")
                                .rouaFont(.calloutBold, color: .rouaTextPrimary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("نسبة الفوز")
                                .rouaFont(.caption, color: .rouaTextTertiary)
                            Text(metrics.formattedWinRate)
                                .rouaFont(.calloutBold, color: .rouaProfit)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("الربح/الخسارة")
                                .rouaFont(.caption, color: .rouaTextTertiary)
                            Text(metrics.formattedTotalPnl)
                                .rouaFont(.calloutBold, color: .rouaPnLColor(value: metrics.totalPnl))
                        }
                    }
                }
            }
        }
    }

    // MARK: - AI Recommendations

    private var aiRecommendations: some View {
        VStack(alignment: .leading, spacing: RouaSpacing.sm) {
            SectionHeader(title: "التوصيات")

            GlassCard {
                VStack(alignment: .leading, spacing: RouaSpacing.md) {
                    // Generate contextual recommendations
                    ForEach(aiRecommendationItems, id: \.title) { item in
                        HStack(alignment: .top, spacing: RouaSpacing.sm) {
                            Image(systemName: item.icon)
                                .font(.system(size: RouaSpacing.iconMedium))
                                .foregroundStyle(item.color)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .rouaFont(.footnoteBold, color: .rouaTextPrimary)
                                Text(item.description)
                                    .rouaFont(.caption, color: .rouaTextSecondary)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if item.title != aiRecommendationItems.last?.title {
                            Divider().overlay(Color.rouaGlassBorder)
                        }
                    }
                }
            }
        }
    }

    private struct AIRecommendationItem {
        let title: String
        let description: String
        let icon: String
        let color: Color
    }

    private var aiRecommendationItems: [AIRecommendationItem] {
        var items: [AIRecommendationItem] = []

        // Win rate recommendation
        if let metrics = viewModel.performance {
            if metrics.winRate < 0.5 && metrics.totalTrades > 5 {
                items.append(AIRecommendationItem(
                    title: "تحسين نسبة الفوز",
                    description: "نسبة الفوز الحالية \(metrics.formattedWinRate) أقل من 50%. فكر في تضييق وقف الخسارة أو تحسين معايير الدخول.",
                    icon: "chart.pie",
                    color: .rouaWarning
                ))
            } else if metrics.winRate >= 0.6 {
                items.append(AIRecommendationItem(
                    title: "أداء ممتاز",
                    description: "نسبة الفوز \(metrics.formattedWinRate) أعلى من المتوسط. حافظ على استراتيجيتك الحالية.",
                    icon: "star.fill",
                    color: .rouaProfit
                ))
            }

            // Risk/reward recommendation
            if metrics.avgLoss > 0 && metrics.avgWin > 0 {
                let rr = metrics.avgWin / metrics.avgLoss
                if rr < 1.0 {
                    items.append(AIRecommendationItem(
                        title: "تحسين نسبة المخاطرة/المكافأة",
                        description: "متوسط الربح أقل من متوسط الخسارة. حاول تمديد أهداف جني الأرباح.",
                        icon: "scale.3d",
                        color: .rouaLoss
                    ))
                }
            }

            // Drawdown recommendation
            if let drawdown = metrics.maxDrawdown, drawdown > 0.15 {
                items.append(AIRecommendationItem(
                    title: "تقليل التراجع",
                    description: "أقصى تراجع \(String(format: "%.1f%%", drawdown * 100)) مرتفع. فكر في تقليل حجم الصفقات.",
                    icon: "arrow.down.right.and.arrow.up.left",
                    color: .rouaWarning
                ))
            }
        }

        // Risk report recommendations
        if let report = viewModel.riskReport {
            if report.diversificationScore < 50 {
                items.append(AIRecommendationItem(
                    title: "تنويع المحفظة",
                    description: "درجة التنويع \(String(format: "%.0f%%", report.diversificationScore)). وزّع استثماراتك على أصول متعددة.",
                    icon: "square.grid.2x2",
                    color: .rouaCyan
                ))
            }
        }

        // Default if no specific recommendations
        if items.isEmpty {
            items.append(AIRecommendationItem(
                title: "ابدأ التداول",
                description: "قم بتنفيذ صفقاتك الأولى لتلقي توصيات مخصصة من مدرب الذكاء الاصطناعي.",
                icon: "lightbulb.fill",
                color: .rouaPurple
            ))
        }

        return items
    }

    // MARK: - Quick Actions

    private var aiQuickActions: some View {
        VStack(alignment: .leading, spacing: RouaSpacing.sm) {
            SectionHeader(title: "إجراءات سريعة")

            VStack(spacing: RouaSpacing.sm) {
                // Start / Stop Agent
                RouaButton(
                    viewModel.agentState?.isActive == true ? "إيقاف الوكيل" : "تشغيل الوكيل",
                    variant: viewModel.agentState?.isActive == true ? .danger : .primary,
                    icon: viewModel.agentState?.isActive == true ? "stop.fill" : "play.fill",
                    isLoading: isAgentToggling
                ) {
                    agentActionPending = viewModel.agentState?.isActive == true
                        ? .stop
                        : .start(strategy: selectedStrategy)
                    showAgentConfirmation = true
                }

                // Add Credential
                RouaButton(
                    "إضافة بيانات اعتماد",
                    variant: .secondary,
                    icon: "key.fill"
                ) {
                    showAddCredential = true
                }
            }
        }
    }
}

// MARK: - Shared: Strategy Selector & Risk Parameters

extension PortfolioView {

    private var strategySelectorSection: some View {
        VStack(spacing: RouaSpacing.md) {
            SectionHeader(title: "استراتيجية التداول")

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: RouaSpacing.sm) {
                ForEach(AgentStrategy.allCases, id: \.self) { strategy in
                    Button {
                        selectedStrategy = strategy
                    } label: {
                        HStack(spacing: RouaSpacing.xs) {
                            if selectedStrategy == strategy {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            Text(strategy.displayName)
                                .rouaFont(selectedStrategy == strategy ? .footnoteBold : .footnote)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, RouaSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                                .fill(selectedStrategy == strategy
                                      ? Color.rouaPrimary.opacity(0.2)
                                      : Color.rouaSurfaceLight)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                                .stroke(selectedStrategy == strategy
                                        ? Color.rouaPrimary
                                        : Color.rouaGlassBorder,
                                        lineWidth: selectedStrategy == strategy ? 1.5 : 0.5)
                        )
                        .foregroundStyle(selectedStrategy == strategy
                                         ? .rouaPrimary
                                         : .rouaTextSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(strategy.displayName)
                    .accessibilityAddTraits(selectedStrategy == strategy ? .isSelected : [])
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
        }
    }

    private var riskParametersSection: some View {
        VStack(spacing: RouaSpacing.md) {
            SectionHeader(title: "معلمات المخاطر")

            GlassCard {
                VStack(spacing: RouaSpacing.md) {
                    riskParameterRow(
                        label: "أقصى حجم الصفقة",
                        value: "\(Int(maxPositionSize))%",
                        slider: $maxPositionSize,
                        range: 1...100
                    )
                    riskParameterRow(
                        label: "أقصى خسارة يومية",
                        value: "\(Int(maxDailyLoss))%",
                        slider: $maxDailyLoss,
                        range: 1...50
                    )
                    riskParameterRow(
                        label: "أقصى صفقات مفتوحة",
                        value: "\(maxOpenPositions)",
                        sliderProxy: $maxOpenPositionsDouble,
                        range: 1...20
                    )
                    riskParameterRow(
                        label: "المخاطرة لكل صفقة",
                        value: "\(Int(riskPerTrade))%",
                        slider: $riskPerTrade,
                        range: 1...10
                    )
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
        }
    }

    private func riskParameterRow(
        label: String,
        value: String,
        slider: Binding<Double>? = nil,
        sliderProxy: Binding<Double>? = nil,
        range: ClosedRange<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: RouaSpacing.xs) {
            HStack {
                Text(label)
                    .rouaFont(.footnote, color: .rouaTextSecondary)
                Spacer()
                Text(value)
                    .rouaFont(.footnoteBold, color: .rouaPrimary)
                    .monospacedDigit()
            }

            if let slider {
                Slider(value: slider, in: range, step: 1)
                    .tint(.rouaPrimary)
                    .onChange(of: slider.wrappedValue) { _, newValue in
                        if sliderProxy != nil {
                            maxOpenPositions = Int(newValue)
                        }
                    }
            } else if let sliderProxy {
                Slider(value: sliderProxy, in: range, step: 1)
                    .tint(.rouaPrimary)
                    .onChange(of: sliderProxy.wrappedValue) { _, newValue in
                        maxOpenPositions = Int(newValue)
                    }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Add Credential Sheet

struct AddCredentialSheet: View {

    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss

    @State private var exchange = ""
    @State private var label = ""
    @State private var apiKey = ""
    @State private var apiSecret = ""
    @State private var passphrase = ""
    @State private var isTestnet = false
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rouaBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: RouaSpacing.lg) {
                        // Exchange
                        VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                            Text("التبادل")
                                .rouaFont(.footnote, color: .rouaTextSecondary)
                            TextField("مثال: Binance", text: $exchange)
                                .textFieldStyle(.plain)
                                .rouaFont(.body, color: .rouaTextPrimary)
                                .padding(RouaSpacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius)
                                        .fill(Color.rouaSurfaceLight)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius)
                                        .stroke(Color.rouaGlassBorder, lineWidth: 1)
                                )
                        }

                        // Label
                        VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                            Text("التسمية")
                                .rouaFont(.footnote, color: .rouaTextSecondary)
                            TextField("مثال: حسابي الرئيسي", text: $label)
                                .textFieldStyle(.plain)
                                .rouaFont(.body, color: .rouaTextPrimary)
                                .padding(RouaSpacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius)
                                        .fill(Color.rouaSurfaceLight)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius)
                                        .stroke(Color.rouaGlassBorder, lineWidth: 1)
                                )
                        }

                        // API Key
                        VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                            Text("مفتاح API")
                                .rouaFont(.footnote, color: .rouaTextSecondary)
                            SecureField("أدخل مفتاح API", text: $apiKey)
                                .textFieldStyle(.plain)
                                .rouaFont(.body, color: .rouaTextPrimary)
                                .padding(RouaSpacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius)
                                        .fill(Color.rouaSurfaceLight)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius)
                                        .stroke(Color.rouaGlassBorder, lineWidth: 1)
                                )
                        }

                        // API Secret
                        VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                            Text("سر API")
                                .rouaFont(.footnote, color: .rouaTextSecondary)
                            SecureField("أدخل سر API", text: $apiSecret)
                                .textFieldStyle(.plain)
                                .rouaFont(.body, color: .rouaTextPrimary)
                                .padding(RouaSpacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius)
                                        .fill(Color.rouaSurfaceLight)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius)
                                        .stroke(Color.rouaGlassBorder, lineWidth: 1)
                                )
                        }

                        // Passphrase (optional)
                        VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                            Text("عبارة المرور (اختياري)")
                                .rouaFont(.footnote, color: .rouaTextSecondary)
                            SecureField("أدخل عبارة المرور", text: $passphrase)
                                .textFieldStyle(.plain)
                                .rouaFont(.body, color: .rouaTextPrimary)
                                .padding(RouaSpacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius)
                                        .fill(Color.rouaSurfaceLight)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius)
                                        .stroke(Color.rouaGlassBorder, lineWidth: 1)
                                )
                        }

                        // Testnet toggle
                        HStack {
                            Text("حساب تجريبي (Testnet)")
                                .rouaFont(.subheadline, color: .rouaTextPrimary)
                            Spacer()
                            Toggle("", isOn: $isTestnet)
                                .tint(.rouaPrimary)
                                .labelsHidden()
                        }
                        .padding(RouaSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius)
                                .fill(Color.rouaSurfaceLight)
                        )

                        // Add button
                        RouaButton(
                            "إضافة بيانات الاعتماد",
                            variant: .primary,
                            icon: "plus",
                            isLoading: isSubmitting,
                            isDisabled: exchange.isEmpty || apiKey.isEmpty || apiSecret.isEmpty
                        ) {
                            addCredential()
                        }
                    }
                    .padding(.horizontal, RouaSpacing.screenPadding)
                    .padding(.vertical, RouaSpacing.lg)
                }
            }
            .navigationTitle("إضافة بيانات اعتماد")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") { dismiss() }
                        .rouaFont(.subheadline, color: .rouaTextSecondary)
                }
            }
        }
    }

    private func addCredential() {
        isSubmitting = true
        let request = CreateCredentialRequest(
            exchange: exchange,
            label: label.isEmpty ? exchange : label,
            apiKey: apiKey,
            apiSecret: apiSecret,
            passphrase: passphrase.isEmpty ? nil : passphrase,
            testnet: isTestnet ? true : nil,
            keyType: nil
        )
        Task {
            do {
                let _: Data = try await APIClient.shared.requestRaw(
                    .portfolioCreateCredential,
                    body: request
                )
                isSubmitting = false
                dismiss()
            } catch {
                isSubmitting = false
            }
        }
    }
}

// MARK: - Helper

private func formatNumber(_ value: Double) -> String {
    if value >= 1_000_000 {
        return String(format: "%.2fM", value / 1_000_000)
    } else if value >= 1_000 {
        return String(format: "%.2fK", value / 1_000)
    } else {
        return String(format: "%.2f", value)
    }
}

// MARK: - Asset Color Extension

extension AssetBalance {
    /// Deterministic color for allocation chart.
    var allocationColor: Color {
        let colors: [Color] = [
            .rouaPrimary, .rouaAccent, .rouaProfit,
            .rouaWarning, .rouaInfo, .rouaSecondary,
            .rouaLoss, .rouaNeutral, .rouaPurple,
        ]
        let hash = asset.hashValue
        let index = abs(hash) % colors.count
        return colors[index]
    }
}

// MARK: - Preview

#Preview("Portfolio") {
    PortfolioView()
}
