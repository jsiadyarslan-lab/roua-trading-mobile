import SwiftUI

// MARK: - صفحة تداول: تبويبان (مفتوحة + مغلقة)
struct PositionsView: View {
    @StateObject private var vm = PositionsViewModel()
    @State private var selectedTab = 0 // 0 = مفتوحة, 1 = مغلقة

    var body: some View {
        VStack(spacing: 0) {
            // التبويبات
            HStack(spacing: 0) {
                tabButton(title: "الصفقات المفتوحة", index: 0, count: vm.positions.count)
                tabButton(title: "الصفقات المغلقة", index: 1, count: vm.closedTrades.count)
            }
            .padding(.horizontal, RouaTheme.Spacing.lg)
            .padding(.top, RouaTheme.Spacing.md)

            // المحتوى
            ScrollView(showsIndicators: false) {
                VStack(spacing: RouaTheme.Spacing.lg) {
                    if selectedTab == 0 {
                        openPositionsContent
                    } else {
                        closedPositionsContent
                    }
                }
                .padding(.horizontal, RouaTheme.Spacing.lg)
                .padding(.vertical, RouaTheme.Spacing.lg)
            }
        }
        .background(RouaTheme.Colors.background)
        .task { await vm.loadData() }
        .refreshable { await vm.loadData() }
        .navigationTitle("تداول")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Tab Button
    private func tabButton(title: String, index: Int, count: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = index }
        } label: {
            VStack(spacing: RouaTheme.Spacing.sm) {
                HStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: selectedTab == index ? .bold : .medium))
                        .foregroundStyle(selectedTab == index ? RouaTheme.Colors.accent : RouaTheme.Colors.textTertiary)
                    if count > 0 {
                        Text("\(count)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(selectedTab == index ? RouaTheme.Colors.accent : RouaTheme.Colors.textTertiary)
                            .clipShape(Capsule())
                    }
                }
                Rectangle()
                    .fill(selectedTab == index ? RouaTheme.Colors.accent : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Open Positions Content
    private var openPositionsContent: some View {
        VStack(spacing: RouaTheme.Spacing.lg) {
            // بطاقة تفاصيل الحساب
            accountDetailsCard

            // Error Banner
            if let error = vm.errorMessage {
                ErrorBanner(message: error) { Task { await vm.loadData() } }
            }

            // قائمة الصفقات المفتوحة
            if vm.isLoading && vm.positions.isEmpty {
                ForEach(0..<3, id: \.self) { _ in
                    GlassCard { ShimmerView() }
                }
            } else if vm.positions.isEmpty {
                GlassCard {
                    VStack(spacing: RouaTheme.Spacing.sm) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 32))
                            .foregroundStyle(RouaTheme.Colors.textTertiary)
                        Text("لا توجد صفقات مفتوحة")
                            .font(.system(size: 14))
                            .foregroundStyle(RouaTheme.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, RouaTheme.Spacing.xxl)
                }
            } else {
                ForEach(vm.positions) { pos in
                    PositionRow(position: pos)
                }
            }
        }
    }

    // MARK: - Account Details Card
    private var accountDetailsCard: some View {
        GlassCard {
            VStack(spacing: RouaTheme.Spacing.md) {
                // الرصيد الأساسي
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("الرصيد")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(RouaTheme.Colors.textTertiary)
                        if vm.isLoading && vm.accountOverview == nil {
                            ShimmerView()
                        } else {
                            Text(String(format: "$%.2f", vm.accountOverview?.effectiveTotalValue ?? 0))
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundStyle(RouaTheme.Colors.textPrimary)
                        }
                    }
                    Spacer()
                    // الربح/الخسارة الإجمالي
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("الربح/الخسارة")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(RouaTheme.Colors.textTertiary)
                        let pnl = vm.accountOverview?.effectiveUnrealizedPnl ?? 0
                        Text(String(format: "%+$%.2f", pnl))
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundStyle(pnl >= 0 ? RouaTheme.Colors.profit : RouaTheme.Colors.loss)
                    }
                }

                Divider().background(RouaTheme.Colors.border)

                // تفاصيل الحساب
                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        Text("المتوافر")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(RouaTheme.Colors.textTertiary)
                        Text(String(format: "$%.2f", vm.availableBalance))
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(RouaTheme.Colors.textPrimary)
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle().fill(RouaTheme.Colors.border).frame(width: 1, height: 30)

                    VStack(spacing: 4) {
                        Text("الهامش المستخدم")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(RouaTheme.Colors.textTertiary)
                        Text(String(format: "$%.2f", vm.usedMargin))
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(RouaTheme.Colors.textPrimary)
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle().fill(RouaTheme.Colors.border).frame(width: 1, height: 30)

                    VStack(spacing: 4) {
                        Text("نسبة الهامش")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(RouaTheme.Colors.textTertiary)
                        Text(String(format: "%.1f%%", vm.marginRatio))
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(vm.marginRatio > 80 ? RouaTheme.Colors.loss : vm.marginRatio > 50 ? RouaTheme.Colors.warning : RouaTheme.Colors.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Closed Positions Content
    private var closedPositionsContent: some View {
        VStack(spacing: RouaTheme.Spacing.md) {
            // فلتر الفترة
            periodFilter

            // قائمة الصفقات المغلقة
            if vm.isLoading && vm.closedTrades.isEmpty {
                ForEach(0..<5, id: \.self) { _ in
                    GlassCard { ShimmerView() }
                }
            } else if vm.filteredTrades.isEmpty {
                GlassCard {
                    VStack(spacing: RouaTheme.Spacing.sm) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 32))
                            .foregroundStyle(RouaTheme.Colors.textTertiary)
                        Text("لا توجد صفقات مغلقة")
                            .font(.system(size: 14))
                            .foregroundStyle(RouaTheme.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, RouaTheme.Spacing.xxl)
                }
            } else {
                ForEach(vm.filteredTrades) { trade in
                    ClosedTradeRow(trade: trade)
                }
            }
        }
    }

    // MARK: - Period Filter
    private var periodFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RouaTheme.Spacing.sm) {
                ForEach(PositionsViewModel.Period.allCases, id: \.self) { period in
                    Button {
                        vm.selectedPeriod = period
                    } label: {
                        Text(period.title)
                            .font(.system(size: 12, weight: vm.selectedPeriod == period ? .bold : .medium))
                            .foregroundStyle(vm.selectedPeriod == period ? .white : RouaTheme.Colors.textTertiary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(vm.selectedPeriod == period ? RouaTheme.Colors.accent : RouaTheme.Colors.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md))
                    }
                }
            }
        }
    }
}

// MARK: - Position Row
struct PositionRow: View {
    let position: Position

    var body: some View {
        GlassCard {
            HStack {
                // الاتجاه والرمز
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        // سهم الاتجاه
                        Image(systemName: position.side == "BUY" ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(position.side == "BUY" ? RouaTheme.Colors.profit : RouaTheme.Colors.loss)
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        Text(position.symbol)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(RouaTheme.Colors.textPrimary)

                        Text(position.side == "BUY" ? "شراء" : "بيع")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(position.side == "BUY" ? RouaTheme.Colors.profit : RouaTheme.Colors.loss)
                    }

                    HStack(spacing: RouaTheme.Spacing.lg) {
                        Text("الكمية: \(String(format: "%.4f", position.quantity))")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(RouaTheme.Colors.textTertiary)
                        Text("الدخول: \(String(format: "%.2f", position.entryPrice))")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(RouaTheme.Colors.textTertiary)
                    }
                }

                Spacer()

                // الربح/الخسارة
                VStack(alignment: .trailing, spacing: 4) {
                    if let pnl = position.unrealizedPnlValue {
                        Text(String(format: "%+.2f", pnl))
                            .font(.system(size: 17, weight: .bold, design: .monospaced))
                            .foregroundStyle(pnl >= 0 ? RouaTheme.Colors.profit : RouaTheme.Colors.loss)
                    }
                    if let current = position.currentPrice {
                        Text(String(format: "%.2f", current))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(RouaTheme.Colors.textTertiary)
                    }
                }
            }
        }
    }
}

// MARK: - Closed Trade Row
struct ClosedTradeRow: View {
    let trade: Trade

    var body: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: trade.side == "long" ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(trade.side == "long" ? RouaTheme.Colors.profit : RouaTheme.Colors.loss)
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        Text(trade.symbol)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(RouaTheme.Colors.textPrimary)

                        Text(trade.side == "long" ? "شراء" : "بيع")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(trade.side == "long" ? RouaTheme.Colors.profit : RouaTheme.Colors.loss)
                    }

                    if let entry = trade.entryPrice, let exit = trade.exitPrice {
                        Text("\(String(format: "%.2f", entry)) → \(String(format: "%.2f", exit))")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(RouaTheme.Colors.textTertiary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if let pnl = trade.realizedPnl {
                        Text(String(format: "%+.2f", pnl))
                            .font(.system(size: 17, weight: .bold, design: .monospaced))
                            .foregroundStyle(pnl >= 0 ? RouaTheme.Colors.profit : RouaTheme.Colors.loss)
                    }
                    if let pct = trade.realizedPct {
                        Text(String(format: "%+.2f%%", pct))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(RouaTheme.Colors.textTertiary)
                    }
                }
            }
        }
    }
}
