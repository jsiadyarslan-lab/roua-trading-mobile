// =============================================================================
// HomeView.swift — Roua Trading · Home Dashboard
// =============================================================================
// Information-dense home dashboard matching the web (m2-shell) design:
//   • Header: 🌙 Logo + "رؤى" / "ROUA TRADING" + Account balance/P&L
//   • Live ticker strip: Horizontal scroll of symbols with price & % change
//   • Scrolling news ticker bar
//   • Mode selector: Trader / Investor / AI (pill-style)
//   • Portfolio Summary Card (gradient glow)
//   • Market Movers (horizontal scroll)
//   • AI Signals (active)
//   • Smart Executor Status
//   • Recent News
//   • Quick Actions (2×2 grid)
//   • Pull-to-refresh
//   • Loading shimmer & error handling
// =============================================================================

import SwiftUI

// MARK: - Trading Mode Enum

/// Dashboard mode selector matching web's Trader / Investor / AI switcher.
enum TradingMode: String, CaseIterable {
    case trader
    case investor
    case ai

    var displayName: String {
        switch self {
        case .trader:   return "المتداول"
        case .investor: return "المستثمر"
        case .ai:       return "الذكاء"
        }
    }

    var icon: String {
        switch self {
        case .trader:   return "chart.line.uptrend.xyaxis"
        case .investor: return "building.columns.fill"
        case .ai:       return "brain.head.profile.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .trader:   return .rouaAccent       // cyan
        case .investor: return .rouaProfit        // green
        case .ai:       return .rouaPrimary       // purple
        }
    }
}

struct HomeView: View {

    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var languageManager: LanguageManager

    // MARK: - Local State

    @State private var selectedMode: TradingMode = .trader
    @State private var newsTickerOffset: CGFloat = 0
    @State private var tickerScrollProxy: ScrollViewProxy?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Background
                Color.rouaBackground
                    .ignoresSafeArea()

                // Main content
                contentView

                // Error banner (overlay at top)
                if let errorMessage = viewModel.errorMessage {
                    VStack {
                        ErrorBanner(
                            message: errorMessage,
                            onRetry: { viewModel.loadDashboard() },
                            onDismiss: { viewModel.errorMessage = nil }
                        )
                        .padding(.horizontal, RouaSpacing.screenPadding)
                        .padding(.top, RouaSpacing.sm)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    navBarTitle
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    notificationBell
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .animation(.easeOut(duration: RouaSpacing.animationDuration), value: viewModel.errorMessage)
        .task {
            viewModel.loadDashboard()
        }
    }

    // MARK: - Navigation Bar

    private var navBarTitle: some View {
        HStack(spacing: RouaSpacing.sm) {
            // 🌙 Moon logo — matching web
            Text("🌙")
                .font(.system(size: 22))

            VStack(alignment: .leading, spacing: 0) {
                Text("رؤى")
                    .rouaFont(.title3, color: .rouaTextPrimary)

                Text("ROUA TRADING")
                    .rouaFont(.micro, color: .rouaTextTertiary)
                    .tracking(1.5)
            }
        }
    }

    private var notificationBell: some View {
        HStack(spacing: RouaSpacing.sm) {
            // Language toggle button
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    languageManager.toggle()
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Text(languageManager.isArabic ? "EN" : "ع")
                    .rouaFont(.captionBold, color: .rouaPrimary)
                    .frame(width: 28, height: 28)
                    .background(Color.rouaPrimary.opacity(0.15))
                    .clipShape(Circle())
            }
            .accessibilityLabel(languageManager.isArabic ? "Switch to English" : "التبديل إلى العربية")

            // Notification bell
            Button {
                // Navigate to notifications
            } label: {
                Image(systemName: "bell.fill")
                    .font(.system(size: RouaSpacing.iconMedium))
                    .foregroundStyle(.rouaTextSecondary)
            }
            .accessibilityLabel("الإشعارات")
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            loadingShimmerView
        } else {
            scrollableContent
        }
    }

    // MARK: - Scrollable Content

    private var scrollableContent: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                // Header: Account balance & P/L display
                headerBalanceSection

                // Live ticker strip
                tickerStripSection

                // News ticker bar
                newsTickerBar

                // Mode selector (pill-style)
                modeSelectorSection

                // Sections with standard spacing
                VStack(spacing: RouaSpacing.xl) {
                    // Section 1: Portfolio Summary
                    portfolioSummarySection

                    // Section 2: Market Movers
                    marketMoversSection

                    // Section 3: AI Signals
                    aiSignalsSection

                    // Section 4: Smart Executor Status
                    executorStatusSection

                    // Section 5: Recent News
                    recentNewsSection

                    // Section 6: Quick Actions
                    quickActionsSection

                    // Bottom spacing for tab bar
                    Color.clear.frame(height: RouaSpacing.md)
                }
            }
        }
        .refreshable {
            viewModel.refresh()
        }
    }

    // MARK: - Header: Account Balance & P/L

    private var headerBalanceSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                Text("رصيد الحساب")
                    .rouaFont(.caption, color: .rouaTextTertiary)
                    .accessibilityLabel("رصيد الحساب")

                Text(portfolioBalance)
                    .rouaFont(.title2, color: .rouaTextPrimary)
                    .monospacedDigit()
                    .accessibilityLabel("الرصيد: \(portfolioBalance)")
            }

            Spacer()

            if let portfolio = viewModel.portfolioSummary, let pnl = portfolio.totalPnl, pnl != 0 {
                VStack(alignment: .trailing, spacing: RouaSpacing.xs) {
                    Text("الأرباح والخسائر")
                        .rouaFont(.caption, color: .rouaTextTertiary)

                    ChangeBadge(
                        value: pnl,
                        percentage: portfolio.totalPnlPct ?? 0
                    )
                }
            }
        }
        .padding(.horizontal, RouaSpacing.screenPadding)
        .padding(.top, RouaSpacing.md)
        .padding(.bottom, RouaSpacing.sm)
    }

    // MARK: - Live Ticker Strip

    private var tickerStripSection: some View {
        VStack(spacing: 0) {
            if !combinedTickerItems.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: RouaSpacing.lg) {
                        ForEach(combinedTickerItems, id: \.symbol) { item in
                            tickerStripItem(item: item)
                        }
                    }
                    .padding(.horizontal, RouaSpacing.screenPadding)
                }
                .frame(height: 36)
            } else {
                // Shimmer placeholder
                HStack(spacing: RouaSpacing.lg) {
                    ForEach(0..<5, id: \.self) { _ in
                        ShimmerView(width: 100, height: 20, cornerRadius: RouaSpacing.smallCornerRadius)
                    }
                    .padding(.horizontal, RouaSpacing.screenPadding)
                }
                .frame(height: 36)
            }

            // Separator
            Rectangle()
                .fill(Color.rouaGlassBorder.opacity(0.5))
                .frame(height: 0.5)
        }
        .padding(.vertical, RouaSpacing.xs)
    }

    @ViewBuilder
    private func tickerStripItem(item: TickerStripItem) -> some View {
        HStack(spacing: RouaSpacing.xs) {
            // Symbol
            Text(item.symbol.replacingOccurrences(of: "/USDT", with: ""))
                .rouaFont(.captionBold, color: .rouaTextSecondary)
                .lineLimit(1)

            // Price
            Text(item.price)
                .rouaFont(.monoSmall, color: .rouaTextPrimary)
                .monospacedDigit()
                .lineLimit(1)

            // % change badge
            Text(item.changePct)
                .rouaFont(.caption, color: .rouaPnLColor(value: item.change))
                .monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.symbol), \(item.price), \(item.changePct)")
    }

    // MARK: - News Ticker Bar

    private var newsTickerBar: some View {
        Group {
            if !viewModel.recentNews.isEmpty {
                VStack(spacing: 0) {
                    HStack(spacing: RouaSpacing.sm) {
                        // Breaking news icon
                        Image(systemName: "newspaper.fill")
                            .font(.system(size: RouaSpacing.iconSmall))
                            .foregroundStyle(.rouaAccent)

                        // Scrolling headline
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: RouaSpacing.xxxl) {
                                ForEach(viewModel.recentNews.prefix(10)) { news in
                                    Text(news.title)
                                        .rouaFont(.caption, color: .rouaTextSecondary)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.trailing, UIScreen.main.bounds.width)
                        }
                        .disabled(true) // Let it scroll freely
                    }
                    .padding(.horizontal, RouaSpacing.screenPadding)
                    .padding(.vertical, RouaSpacing.sm)

                    // Separator
                    Rectangle()
                        .fill(Color.rouaGlassBorder.opacity(0.5))
                        .frame(height: 0.5)
                }
                .background(Color.rouaBackgroundLight.opacity(0.5))
            }
        }
    }

    // MARK: - Mode Selector

    private var modeSelectorSection: some View {
        HStack(spacing: RouaSpacing.xs) {
            ForEach(TradingMode.allCases, id: \.self) { mode in
                modePill(mode: mode)
            }
        }
        .padding(.horizontal, RouaSpacing.screenPadding)
        .padding(.vertical, RouaSpacing.sm)
    }

    @ViewBuilder
    private func modePill(mode: TradingMode) -> some View {
        let isSelected = selectedMode == mode

        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedMode = mode
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: RouaSpacing.xs) {
                Image(systemName: mode.icon)
                    .font(.system(size: 12))

                Text(mode.displayName)
                    .rouaFont(.captionBold)
            }
            .foregroundStyle(isSelected ? .white : .rouaTextSecondary)
            .padding(.horizontal, RouaSpacing.md)
            .padding(.vertical, RouaSpacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? mode.accentColor.opacity(0.25) : Color.clear)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? mode.accentColor.opacity(0.5) : Color.rouaGlassBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mode.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Section 1: Portfolio Summary

    private var portfolioSummarySection: some View {
        ZStack {
            // Gradient glow effect behind the card (matching web)
            RoundedRectangle(cornerRadius: RouaSpacing.cardCornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.rouaPrimary.opacity(0.15),
                            Color.rouaAccent.opacity(0.10),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blur(radius: 24)
                .padding(.horizontal, -8)
                .padding(.vertical, -4)

            // Main card
            GlassCard(glow: .rouaPrimary) {
                VStack(alignment: .leading, spacing: RouaSpacing.md) {
                    // Total balance
                    VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                        HStack(spacing: RouaSpacing.xs) {
                            Image(systemName: "wallet.fill")
                                .font(.system(size: RouaSpacing.iconSmall))
                                .foregroundStyle(.rouaPrimary)

                            Text("إجمالي المحفظة")
                                .rouaFont(.subheadline, color: .rouaTextSecondary)
                        }
                        .accessibilityLabel("إجمالي رصيد المحفظة")

                        HStack(alignment: .firstTextBaseline, spacing: RouaSpacing.sm) {
                            Text(portfolioBalance)
                                .rouaFont(.largeTitle, color: .rouaTextPrimary)
                                .monospacedDigit()

                            Spacer()

                            if let portfolio = viewModel.portfolioSummary, let pnl = portfolio.totalPnl, pnl != 0 {
                                ChangeBadge(
                                    value: pnl,
                                    percentage: portfolio.totalPnlPct ?? 0
                                )
                            }
                        }
                    }

                    // Divider
                    Rectangle()
                        .fill(Color.rouaGlassBorder)
                        .frame(height: 1)

                    // Mini stat row
                    HStack(spacing: 0) {
                        StatMini(
                            label: "ربح اليوم",
                            value: dayPnL,
                            change: viewModel.portfolioSummary?.unrealizedPnl
                        )
                        .frame(maxWidth: .infinity)

                        Rectangle()
                            .fill(Color.rouaGlassBorder)
                            .frame(width: 1, height: 32)

                        StatMini(
                            label: "صفقات مفتوحة",
                            value: "\(viewModel.positionsSummary?.positionCount ?? 0)"
                        )
                        .frame(maxWidth: .infinity)

                        Rectangle()
                            .fill(Color.rouaGlassBorder)
                            .frame(width: 1, height: 32)

                        StatMini(
                            label: "قيمة المحفظة",
                            value: portfolioValue
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.horizontal, RouaSpacing.screenPadding)
    }

    // MARK: - Section 2: Market Movers

    private var marketMoversSection: some View {
        VStack(spacing: RouaSpacing.sm) {
            SectionHeader(
                title: "حراك السوق",
                actionTitle: "عرض الكل"
            ) {
                // Navigate to Markets tab
            }

            if viewModel.topGainers.isEmpty && viewModel.topLosers.isEmpty {
                GlassCard {
                    VStack(spacing: RouaSpacing.sm) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: RouaSpacing.iconLarge))
                            .foregroundStyle(.rouaTextTertiary)
                        Text("جارٍ تحميل بيانات السوق…")
                            .rouaFont(.subheadline, color: .rouaTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, RouaSpacing.xl)
                }
                .padding(.horizontal, RouaSpacing.screenPadding)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: RouaSpacing.md) {
                        // Gainers
                        ForEach(viewModel.topGainers.prefix(3)) { result in
                            moverCard(result: result)
                        }

                        // Losers
                        ForEach(viewModel.topLosers.prefix(3)) { result in
                            moverCard(result: result)
                        }
                    }
                    .padding(.horizontal, RouaSpacing.screenPadding)
                }
            }
        }
    }

    @ViewBuilder
    private func moverCard(result: ScannerResult) -> some View {
        let isPositive = result.change >= 0

        NavigationLink {
            TradingView(symbol: result.symbol)
        } label: {
            GlassCard {
                VStack(alignment: .leading, spacing: RouaSpacing.sm) {
                    HStack {
                        Text(String(result.symbol.prefix(2)))
                            .rouaFont(.captionBold, color: .rouaTextPrimary)
                            .frame(width: 32, height: 32)
                            .background(Color.rouaSurfaceLight)
                            .clipShape(Circle())

                        Spacer()

                        Badge(
                            text: isPositive ? "↑" : "↓",
                            variant: isPositive ? .success : .error
                        )
                    }

                    Text(result.symbol)
                        .rouaFont(.calloutBold, color: .rouaTextPrimary)
                        .lineLimit(1)

                    HStack {
                        Text(result.price.asPrice())
                            .rouaFont(.monoSmall, color: .rouaTextPrimary)
                            .monospacedDigit()

                        Spacer()

                        Text(result.formattedChangePct)
                            .rouaFont(.captionBold, color: .rouaPnLColor(value: result.change))
                            .monospacedDigit()
                    }
                }
                .frame(width: 150)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section 3: AI Signals

    private var aiSignalsSection: some View {
        VStack(spacing: RouaSpacing.sm) {
            SectionHeader(
                title: "إشارات الذكاء الاصطناعي",
                actionTitle: "عرض الكل"
            ) {
                // Navigate to AI Hub > Signals
            }

            if viewModel.activeSignals.isEmpty {
                GlassCard {
                    VStack(spacing: RouaSpacing.sm) {
                        Image(systemName: "signal")
                            .font(.system(size: RouaSpacing.iconLarge))
                            .foregroundStyle(.rouaTextTertiary)
                        Text("لا توجد إشارات نشطة حالياً")
                            .rouaFont(.subheadline, color: .rouaTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, RouaSpacing.xl)
                }
                .padding(.horizontal, RouaSpacing.screenPadding)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: RouaSpacing.md) {
                        ForEach(viewModel.activeSignals) { signal in
                            signalCard(signal: signal)
                        }
                    }
                    .padding(.horizontal, RouaSpacing.screenPadding)
                }
            }
        }
    }

    @ViewBuilder
    private func signalCard(signal: Signal) -> some View {
        let directionColor: Color = signal.direction == .bullish ? .rouaProfit : signal.direction == .bearish ? .rouaLoss : .rouaNeutral
        let directionVariant: BadgeVariant = signal.direction == .bullish ? .success : signal.direction == .bearish ? .error : .neutral

        GlassCard(glow: directionColor) {
            VStack(alignment: .leading, spacing: RouaSpacing.sm) {
                HStack {
                    Text(signal.symbol)
                        .rouaFont(.calloutBold, color: .rouaTextPrimary)

                    Spacer()

                    Badge(text: signal.direction.displayName, variant: directionVariant)
                }

                HStack {
                    // Confidence meter
                    VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                        Text("الثقة")
                            .rouaFont(.micro, color: .rouaTextTertiary)
                        ProgressView(value: Double(signal.confidence), total: 100)
                            .tint(directionColor)
                            .frame(width: 60)
                    }

                    Spacer()

                    // Entry price
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("الدخول")
                            .rouaFont(.micro, color: .rouaTextTertiary)
                        Text((signal.entryPrice ?? 0).asPrice())
                            .rouaFont(.monoSmall, color: .rouaTextPrimary)
                            .monospacedDigit()
                    }
                }
            }
            .frame(width: 200)
        }
    }

    // MARK: - Section 4: Smart Executor Status

    private var executorStatusSection: some View {
        VStack(spacing: RouaSpacing.sm) {
            SectionHeader(
                title: "المنفّذ الذكي",
                actionTitle: "التفاصيل"
            ) {
                // Navigate to AI Hub > Smart Executor
            }

            GlassCard {
                VStack(alignment: .leading, spacing: RouaSpacing.md) {
                    HStack(spacing: RouaSpacing.sm) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: RouaSpacing.iconSmall))
                            .foregroundStyle(.rouaAccent)

                        Text("المنفّذ الذكي")
                            .rouaFont(.calloutBold, color: .rouaTextPrimary)

                        Spacer()

                        PulsingDot(status: .inactive, size: 8)
                    }

                    Text("قم بتفعيل المنفّذ الذكي للتداول التلقائي بناءً على إشارات الذكاء الاصطناعي")
                        .rouaFont(.subheadline, color: .rouaTextSecondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
        }
    }

    // MARK: - Section 5: Recent News

    private var recentNewsSection: some View {
        VStack(spacing: RouaSpacing.sm) {
            SectionHeader(
                title: "آخر الأخبار",
                actionTitle: "عرض الكل"
            ) {
                // Navigate to Markets > News
            }

            if viewModel.recentNews.isEmpty {
                GlassCard {
                    VStack(spacing: RouaSpacing.sm) {
                        Image(systemName: "newspaper")
                            .font(.system(size: RouaSpacing.iconLarge))
                            .foregroundStyle(.rouaTextTertiary)
                        Text("جارٍ تحميل الأخبار…")
                            .rouaFont(.subheadline, color: .rouaTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, RouaSpacing.xl)
                }
                .padding(.horizontal, RouaSpacing.screenPadding)
            } else {
                VStack(spacing: RouaSpacing.sm) {
                    ForEach(viewModel.recentNews.prefix(5)) { news in
                        newsRow(news: news)
                    }
                }
                .padding(.horizontal, RouaSpacing.screenPadding)
            }
        }
    }

    @ViewBuilder
    private func newsRow(news: NewsItem) -> some View {
        GlassCard(action: {
            // Navigate to news detail
        }) {
            HStack(alignment: .top, spacing: RouaSpacing.md) {
                VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                    Text(news.title)
                        .rouaFont(.calloutBold, color: .rouaTextPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: RouaSpacing.sm) {
                        Badge(
                            text: news.sentiment.displayName,
                            variant: news.sentiment == .positive ? .success : news.sentiment == .negative ? .error : .neutral
                        )

                        if let publishedAt = news.publishedAt, let date = Date.fromISO8601(publishedAt) {
                            Text(date.relativeString)
                                .rouaFont(.footnote, color: .rouaTextTertiary)
                        }

                        if let source = news.source {
                            Text("· \(source)")
                                .rouaFont(.footnote, color: .rouaTextTertiary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - Section 6: Quick Actions

    private var quickActionsSection: some View {
        VStack(spacing: RouaSpacing.sm) {
            SectionHeader(title: "إجراءات سريعة")

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: RouaSpacing.md),
                    GridItem(.flexible(), spacing: RouaSpacing.md)
                ],
                spacing: RouaSpacing.md
            ) {
                quickActionButton(
                    title: "صفقة جديدة",
                    icon: "plus.circle.fill",
                    color: .rouaProfit
                ) {
                    // Navigate to new trade
                }

                quickActionButton(
                    title: "الماسح",
                    icon: "magnifyingglass",
                    color: .rouaAccent
                ) {
                    // Navigate to scanner
                }

                quickActionButton(
                    title: "مجلس الذكاء",
                    icon: "brain.head.profile.fill",
                    color: .rouaPrimary
                ) {
                    // Navigate to AI Council
                }

                quickActionButton(
                    title: "المختبر العصبي",
                    icon: "cpu",
                    color: .rouaWarning
                ) {
                    // Navigate to Neural Lab
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
        }
    }

    @ViewBuilder
    private func quickActionButton(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        GlassCard(action: action) {
            VStack(spacing: RouaSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: RouaSpacing.iconMedium))
                        .foregroundStyle(color)
                }

                Text(title)
                    .rouaFont(.captionBold, color: .rouaTextPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Loading Shimmer

    private var loadingShimmerView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Header balance shimmer
                HStack {
                    VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                        ShimmerView(width: 80, height: 10)
                        ShimmerView(width: 140, height: 22)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: RouaSpacing.xs) {
                        ShimmerView(width: 60, height: 10)
                        ShimmerView(width: 100, height: 18)
                    }
                }
                .padding(.horizontal, RouaSpacing.screenPadding)
                .padding(.vertical, RouaSpacing.md)

                // Ticker strip shimmer
                HStack(spacing: RouaSpacing.lg) {
                    ForEach(0..<5, id: \.self) { _ in
                        ShimmerView(width: 100, height: 16, cornerRadius: RouaSpacing.smallCornerRadius)
                    }
                }
                .padding(.horizontal, RouaSpacing.screenPadding)
                .padding(.vertical, RouaSpacing.sm)

                // News ticker shimmer
                ShimmerView(height: 20)
                    .padding(.horizontal, RouaSpacing.screenPadding)
                    .padding(.vertical, RouaSpacing.sm)

                // Mode selector shimmer
                HStack(spacing: RouaSpacing.xs) {
                    ForEach(0..<3, id: \.self) { _ in
                        ShimmerView(width: 80, height: 30, cornerRadius: RouaSpacing.pillCornerRadius)
                    }
                }
                .padding(.horizontal, RouaSpacing.screenPadding)
                .padding(.vertical, RouaSpacing.sm)

                // Rest of sections with standard spacing
                VStack(spacing: RouaSpacing.xl) {
                    // Portfolio shimmer
                    VStack(alignment: .leading, spacing: RouaSpacing.sm) {
                        ShimmerView(width: 120, height: 14)
                        ShimmerView(width: 200, height: 34)
                        ShimmerView(height: 1, cornerRadius: 0)
                        HStack(spacing: RouaSpacing.lg) {
                            VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                                ShimmerView(width: 60, height: 10)
                                ShimmerView(width: 80, height: 16)
                            }
                            VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                                ShimmerView(width: 60, height: 10)
                                ShimmerView(width: 80, height: 16)
                            }
                            VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                                ShimmerView(width: 60, height: 10)
                                ShimmerView(width: 80, height: 16)
                            }
                        }
                    }
                    .padding(RouaSpacing.cardPadding)
                    .background(
                        RoundedRectangle(cornerRadius: RouaSpacing.cardCornerRadius, style: .continuous)
                            .fill(Color.rouaGlass)
                    )
                    .padding(.horizontal, RouaSpacing.screenPadding)

                    // Movers shimmer
                    VStack(alignment: .leading, spacing: RouaSpacing.sm) {
                        ShimmerView(width: 100, height: 18)
                        HStack(spacing: RouaSpacing.md) {
                            ForEach(0..<3, id: \.self) { _ in
                                ShimmerView(width: 150, height: 80)
                            }
                        }
                        .padding(.horizontal, RouaSpacing.screenPadding)
                    }

                    // News shimmer
                    VStack(alignment: .leading, spacing: RouaSpacing.sm) {
                        ShimmerView(width: 80, height: 18)
                        ForEach(0..<3, id: \.self) { _ in
                            ShimmerView(height: 60)
                                .padding(.horizontal, RouaSpacing.screenPadding)
                        }
                    }
                }
            }
            .padding(.top, RouaSpacing.md)
        }
    }

    // MARK: - Computed Helpers

    private var portfolioBalance: String {
        viewModel.portfolioSummary?.totalBalance.asCurrency() ?? "$0.00"
    }

    private var portfolioValue: String {
        guard let summary = viewModel.positionsSummary, summary.totalPositionValue > 0 else {
            return "$0.00"
        }
        return summary.totalPositionValue.asCurrency()
    }

    private var dayPnL: String {
        viewModel.portfolioSummary?.unrealizedPnl.asCurrency() ?? "$0.00"
    }

    // MARK: - Ticker Strip Data

    /// Combines top gainers and losers into a flat list for the ticker strip.
    private var combinedTickerItems: [TickerStripItem] {
        var items: [TickerStripItem] = []

        for gainer in viewModel.topGainers.prefix(5) {
            items.append(TickerStripItem(
                symbol: gainer.symbol,
                price: gainer.price.asPrice(),
                change: gainer.change,
                changePct: gainer.formattedChangePct
            ))
        }

        for loser in viewModel.topLosers.prefix(5) {
            items.append(TickerStripItem(
                symbol: loser.symbol,
                price: loser.price.asPrice(),
                change: loser.change,
                changePct: loser.formattedChangePct
            ))
        }

        return items
    }
}

// MARK: - Ticker Strip Item

/// Lightweight model for the ticker strip display.
private struct TickerStripItem: Identifiable {
    let id = UUID()
    let symbol: String
    let price: String
    let change: Double
    let changePct: String
}

// MARK: - Preview

#Preview("HomeView") {
    HomeView()
        .environmentObject(AuthViewModel())
        .environmentObject(LanguageManager())
        .preferredColorScheme(.dark)
}
