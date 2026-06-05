// =============================================================================
// HomeView.swift — Roua Trading · Home Dashboard
// =============================================================================
// Information-dense but clean home dashboard with:
//   • Nav bar with title + notification bell
//   • Portfolio Summary Card
//   • Market Movers (horizontal scroll)
//   • AI Signals (active)
//   • Smart Executor Status
//   • Recent News
//   • Quick Actions (2×2 grid)
//   • Pull-to-refresh
//   • Loading shimmer & error handling
// =============================================================================

import SwiftUI

struct HomeView: View {

    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var languageManager: LanguageManager

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
            Circle()
                .fill(Color.rouaGradientPrimary)
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                )

            Text("روا")
                .rouaFont(.title3, color: .rouaTextPrimary)
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
            LazyVStack(spacing: RouaSpacing.xl) {
                // Section 1: Portfolio Summary
                portfolioSummarySection

                // Section 2: Market Movers — always show section header, show placeholder when empty
                marketMoversSection

                // Section 3: AI Signals — always show section header, show placeholder when empty
                aiSignalsSection

                // Section 4: Smart Executor Status
                executorStatusSection

                // Section 5: Recent News — always show section header, show placeholder when empty
                recentNewsSection

                // Section 6: Quick Actions
                quickActionsSection

                // Bottom spacing for tab bar
                Color.clear.frame(height: RouaSpacing.md)
            }
            .padding(.top, RouaSpacing.md)
        }
        .refreshable {
            viewModel.refresh()
        }
    }

    // MARK: - Section 1: Portfolio Summary

    private var portfolioSummarySection: some View {
        GlassCard(glow: .rouaPrimary) {
            VStack(alignment: .leading, spacing: RouaSpacing.md) {
                // Total balance
                VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                    Text("إجمالي المحفظة")
                        .rouaFont(.subheadline, color: .rouaTextSecondary)
                        .accessibilityLabel("إجمالي رصيد المحفظة")

                    HStack(alignment: .firstTextBaseline, spacing: RouaSpacing.sm) {
                        Text(portfolioBalance)
                            .rouaFont(.largeTitle, color: .rouaTextPrimary)
                            .monospacedDigit()

                        Spacer()

                        if let portfolio = viewModel.portfolioSummary, portfolio.totalPnl != 0 {
                            ChangeBadge(
                                value: portfolio.totalPnl,
                                percentage: portfolio.totalPnlPct
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
                        Text(signal.entryPrice.asPrice())
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

                        if let date = Date.fromISO8601(news.publishedAt) {
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
            VStack(spacing: RouaSpacing.lg) {
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
}

// MARK: - Preview

#Preview("HomeView") {
    HomeView()
        .environmentObject(AuthViewModel())
        .environmentObject(LanguageManager())
        .preferredColorScheme(.dark)
}
