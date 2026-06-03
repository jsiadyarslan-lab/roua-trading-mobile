// =============================================================================
// PositionsView.swift — Roua Trading · Positions Management
// =============================================================================
// Standalone positions management view with:
// - Segmented control: Open Positions / Closed Trades
// - Open positions list with PositionRow for each (swipe to close)
// - Closed trades list with ClosedTradeRow for each
// - Empty states for both tabs
// - Pull-to-refresh
//
// RTL-aware (Arabic). Uses RouaComponents theme system.
// =============================================================================

import SwiftUI

// MARK: - Positions View

/// Dedicated positions management screen.
///
/// This view can be used standalone (e.g., from the tab bar) or embedded
/// within TradingView. It provides a full-screen experience with
/// segmented tabs, pull-to-refresh, and comprehensive position management.
struct PositionsView: View {

    // MARK: - ViewModel

    @StateObject private var viewModel = TradingViewModel()

    // MARK: - Tab State

    @State private var selectedTab: PositionTab = .open

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                tabSelector

                // Content
                TabView(selection: $selectedTab) {
                    openPositionsTab
                        .tag(PositionTab.open)

                    closedTradesTab
                        .tag(PositionTab.closed)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: RouaSpacing.animationFast), value: selectedTab)
            }
            .background(Color.rouaBackground)
            .navigationTitle("الصفقات")  // Positions
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // Position count badge
                    if !viewModel.positions.isEmpty {
                        Badge(
                            text: "\(viewModel.positions.count)",
                            variant: .info
                        )
                    }
                }
            }
        }
        .task {
            await viewModel.loadPositions()
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(PositionTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            selectedTab = tab
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        VStack(spacing: RouaSpacing.sm) {
                            // Tab label
                            HStack(spacing: RouaSpacing.sm) {
                                Text(tab.rawValue)
                                    .rouaFont(
                                        selectedTab == tab ? .calloutBold : .callout,
                                        color: selectedTab == tab ? .rouaTextPrimary : .rouaTextTertiary
                                    )

                                // Count badge
                                if selectedTab == tab {
                                    let count = tab == .open
                                        ? viewModel.positions.count
                                        : viewModel.closedTrades.count
                                    if count > 0 {
                                        Text("\(count)")
                                            .rouaFont(.captionBold, color: .rouaPrimary)
                                            .padding(.horizontal, RouaSpacing.xs)
                                            .padding(.vertical, 1)
                                            .background(
                                                Capsule()
                                                    .fill(Color.rouaPrimary.opacity(0.15))
                                            )
                                    }
                                }
                            }

                            // Underline indicator
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(selectedTab == tab ? Color.rouaPrimary : Color.clear)
                                .frame(height: 3)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tab.englishLabel)
                    .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)

            // Divider
            Rectangle()
                .fill(Color.rouaBorder)
                .frame(height: 1)
        }
        .padding(.top, RouaSpacing.sm)
    }

    // MARK: - Open Positions Tab

    @ViewBuilder
    private var openPositionsTab: some View {
        if viewModel.isLoading && viewModel.positions.isEmpty {
            loadingSkeleton
        } else if viewModel.positions.isEmpty {
            emptyOpenPositions
        } else {
            openPositionsList
        }
    }

    private var emptyOpenPositions: some View {
        VStack {
            EmptyStateView(
                icon: "chart.line.downtrend.xyaxis",
                title: "لا توجد صفقات مفتوحة",  // No open positions
                description: "ابدأ التداول لرؤية صفقاتك المفتوحة هنا",  // Start trading to see open positions here
                buttonTitle: "استكشف الأسواق",  // Explore Markets
                buttonAction: {
                    // TODO: Navigate to markets/scanner
                }
            )
            Spacer()
        }
        .padding(.top, RouaSpacing.xxxl)
    }

    private var openPositionsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: RouaSpacing.sm) {
                // Summary card
                openPositionsSummary

                // Position rows
                ForEach(viewModel.positions) { position in
                    OpenPositionCard(
                        position: position,
                        onClose: { Task { await viewModel.closePosition(id: position.id) } },
                        onTap: {
                            // TODO: Navigate to position detail
                        }
                    )
                    .padding(.horizontal, RouaSpacing.screenPadding)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
                }
            }
            .padding(.vertical, RouaSpacing.md)
        }
        .refreshable {
            viewModel.loadAllData(); await Task.yield()
        }
    }

    // MARK: - Open Positions Summary

    private var openPositionsSummary: some View {
        let totalPnl = viewModel.positions.reduce(0) { $0 + $1.unrealizedPnl }
        let totalValue = viewModel.positions.reduce(0) {
            $0 + $1.currentValue
        }
        let pnlColor: Color = .rouaPnLColor(value: totalPnl)

        return GlassCard(glow: totalPnl >= 0 ? .rouaProfit : .rouaLoss) {
            HStack {
                VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                    Text("إجمالي PnL")  // Total PnL
                        .rouaFont(.caption, color: .rouaTextTertiary)

                    Text(totalPnl.asCurrency())
                        .rouaFont(.title2, color: pnlColor)
                        .monospacedDigit()
                }

                Spacer()

                VStack(alignment: .trailing, spacing: RouaSpacing.xs) {
                    Text("القيمة الإجمالية")  // Total Value
                        .rouaFont(.caption, color: .rouaTextTertiary)

                    Text(totalValue.asCompactCurrency())
                        .rouaFont(.calloutBold, color: .rouaTextPrimary)
                        .monospacedDigit()
                }
            }
        }
        .padding(.horizontal, RouaSpacing.screenPadding)
    }

    // MARK: - Closed Trades Tab

    @ViewBuilder
    private var closedTradesTab: some View {
        if viewModel.isLoading && viewModel.closedTrades.isEmpty {
            loadingSkeleton
        } else if viewModel.closedTrades.isEmpty {
            emptyClosedTrades
        } else {
            closedTradesList
        }
    }

    private var emptyClosedTrades: some View {
        VStack {
            EmptyStateView(
                icon: "clock.arrow.circlepath",
                title: "لا توجد صفقات مغلقة",  // No closed trades
                description: "ستظهر صفقاتك المغلقة والمكتملة هنا"  // Your closed and completed trades will appear here
            )
            Spacer()
        }
        .padding(.top, RouaSpacing.xxxl)
    }

    private var closedTradesList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: RouaSpacing.sm) {
                // Summary stats
                closedTradesSummary

                // Closed trade rows
                ForEach(viewModel.closedTrades) { trade in
                    ClosedTradeRow(trade: trade)
                        .padding(.horizontal, RouaSpacing.screenPadding)
                }
            }
            .padding(.vertical, RouaSpacing.md)
        }
        .refreshable {
            viewModel.loadAllData(); await Task.yield()
        }
    }

    // MARK: - Closed Trades Summary

    private var closedTradesSummary: some View {
        let totalPnl = viewModel.closedTrades.reduce(0) { $0 + $1.realizedPnl }
        let wins = viewModel.closedTrades.filter { $0.isWinner }.count
        let total = viewModel.closedTrades.count
        let winRate = total > 0 ? Double(wins) / Double(total) : 0
        let pnlColor: Color = .rouaPnLColor(value: totalPnl)

        return GlassCard {
            HStack(spacing: RouaSpacing.lg) {
                StatMini(
                    label: "إجمالي الأرباح",  // Total Realized
                    value: totalPnl.asCurrency()
                )
                .frame(maxWidth: .infinity)

                Divider()
                    .background(Color.rouaBorder)
                    .frame(height: 32)

                StatMini(
                    label: "نسبة الفوز",  // Win Rate
                    value: String(format: "%.0f%%", winRate * 100)
                )
                .frame(maxWidth: .infinity)

                Divider()
                    .background(Color.rouaBorder)
                    .frame(height: 32)

                StatMini(
                    label: "الصفقات",  // Trades
                    value: "\(total)"
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, RouaSpacing.screenPadding)
    }

    // MARK: - Loading Skeleton

    private var loadingSkeleton: some View {
        VStack(spacing: RouaSpacing.md) {
            ShimmerView(height: 80)
                .padding(.horizontal, RouaSpacing.screenPadding)
                .padding(.top, RouaSpacing.lg)

            ForEach(0..<4, id: \.self) { _ in
                ShimmerView(height: RouaSpacing.rowHeight)
                    .padding(.horizontal, RouaSpacing.screenPadding)
            }
        }
    }
}

// MARK: - Open Position Card

/// Detailed card for an open position with close action.
///
/// Shows: symbol, side badge, quantity, entry → current price,
/// unrealized PnL, leverage, and swipe-to-close.
struct OpenPositionCard: View {

    let position: Position
    let onClose: () -> Void
    let onTap: (() -> Void)?

    private var pnlColor: Color { .rouaPnLColor(value: position.unrealizedPnl) }
    private var sideLabel: String { position.side.displayName }
    private var sideVariant: BadgeVariant { position.isLong ? .success : .error }

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(spacing: RouaSpacing.sm) {
                // Top row: Symbol + Side + Leverage
                HStack {
                    Text(position.symbol)
                        .rouaFont(.calloutBold, color: .rouaTextPrimary)
                        .lineLimit(1)

                    Badge(text: sideLabel, variant: sideVariant)

                    if position.leverage ?? 1 > 1 {
                        Text(position.leverageLabel)
                            .rouaFont(.captionBold, color: .rouaWarning)
                            .padding(.horizontal, RouaSpacing.xs)
                            .padding(.vertical, 1)
                            .background(
                                Capsule()
                                    .fill(Color.rouaWarning.opacity(0.12))
                            )
                    }

                    Spacer()

                    // Timestamp
                    if let date = Date.fromISO8601(position.openedAt) {
                        Text(date.relativeString)
                            .rouaFont(.footnote, color: .rouaTextTertiary)
                    }
                }

                // Middle row: Quantity + Prices
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("الكمية")  // Quantity
                            .rouaFont(.caption, color: .rouaTextTertiary)
                        Text(String(format: "%.4f", position.quantity))
                            .rouaFont(.mono, color: .rouaTextSecondary)
                            .monospacedDigit()
                    }

                    Spacer()

                    // Price flow
                    VStack(alignment: .center, spacing: 2) {
                        Text("الدخول → الحالي")  // Entry → Current
                            .rouaFont(.caption, color: .rouaTextTertiary)
                        HStack(spacing: RouaSpacing.xs) {
                            Text(position.entryPrice.asPrice())
                            Image(systemName: "arrow.right")
                                .font(.system(size: 8))
                                .foregroundStyle(.rouaTextTertiary)
                            Text((position.currentPrice ?? position.entryPrice).asPrice())
                        }
                        .rouaFont(.monoSmall, color: .rouaTextPrimary)
                        .monospacedDigit()
                    }

                    Spacer()

                    // PnL
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("PnL")
                            .rouaFont(.caption, color: .rouaTextTertiary)
                        Text(position.formattedPnl)
                            .rouaFont(.calloutBold, color: pnlColor)
                            .monospacedDigit()
                        if let pnlPct = position.unrealizedPnlPct {
                            Text(pnlPct.asPercentage())
                                .rouaFont(.footnote, color: pnlColor)
                                .monospacedDigit()
                        }
                    }
                }
            }
            .padding(RouaSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                    .fill(Color.rouaPnLBgColor(value: position.unrealizedPnl))
            )
            .overlay(
                RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                    .stroke(Color.rouaGlassBorder, lineWidth: 0.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    onClose()
                }
            } label: {
                Label("إغلاق", systemImage: "xmark.circle")  // Close
            }
            .tint(.rouaLoss)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(position.symbol) \(sideLabel), quantity \(String(format: "%.4f", position.quantity)), " +
            "P&L \(position.formattedPnl)"
        )
        .accessibilityAddTraits(.isButton)
    }
}

// =============================================================================
// MARK: - Preview
// =============================================================================

#Preview("PositionsView") {
    PositionsView()
}
