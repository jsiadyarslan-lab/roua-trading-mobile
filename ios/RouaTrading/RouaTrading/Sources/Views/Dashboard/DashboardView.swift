import SwiftUI

struct DashboardView: View {
    @StateObject private var vm = DashboardViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaTheme.Spacing.lg) {
                // Error Banner
                if let error = vm.errorMessage {
                    ErrorBanner(message: error) { Task { await vm.retry() } }
                }

                // Portfolio Summary (only if auth data available)
                if vm.isAuthDataAvailable {
                    portfolioCard
                }

                // Market Overview (ALWAYS visible — public data)
                marketOverviewSection

                // Active Positions (auth required)
                if vm.isAuthDataAvailable {
                    positionsSection
                }

                // Recent Trades (auth required)
                if !vm.trades.isEmpty && vm.isAuthDataAvailable {
                    tradesSection
                }
            }.padding(.horizontal, RouaTheme.Spacing.lg)
        }.background(RouaTheme.Colors.background).refreshable { await vm.loadDashboard() }
        .task { await vm.loadDashboard() }
        .navigationTitle("لوحة المعلومات")
    }

    // MARK: - Portfolio Card
    private var portfolioCard: some View {
        GlassCard {
            VStack(spacing: RouaTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("قيمة المحفظة").font(.system(size: 10, weight: .medium)).foregroundStyle(RouaTheme.Colors.textTertiary).textCase(.uppercase)
                        if vm.isLoading && vm.portfolioSummary == nil {
                            ShimmerView()
                        } else if let p = vm.portfolioSummary {
                            Text(String(format: "$%.2f", p.totalValue)).font(.system(size: 20, weight: .bold, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textPrimary)
                        } else {
                            Text("---").font(.system(size: 20, weight: .bold, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textTertiary)
                        }
                    }
                    Spacer()
                    PulsingDot()
                }
                HStack(spacing: RouaTheme.Spacing.lg) {
                    StatMini(title: "ربح اليوم", value: vm.portfolioSummary.map { String(format: "$%.2f", $0.dailyPnl) } ?? "---", isPositive: (vm.portfolioSummary?.dailyPnl ?? 0) >= 0)
                    StatMini(title: "الصفقات", value: "\(vm.positions.count)")
                    StatMini(title: "إجمالي الربح", value: vm.portfolioSummary.map { String(format: "$%.2f", $0.totalPnl) } ?? "---", isPositive: (vm.portfolioSummary?.totalPnl ?? 0) >= 0)
                }
            }
        }
    }

    // MARK: - Market Overview (public — always works)
    private var marketOverviewSection: some View {
        VStack(spacing: RouaTheme.Spacing.md) {
            Text("أسعار السوق").font(.system(size: 16, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)

            if vm.isLoading && vm.topQuotes.isEmpty {
                ForEach(0..<3, id: \.self) { _ in
                    GlassCard { ShimmerView() }
                }
            } else if vm.topQuotes.isEmpty {
                GlassCard {
                    VStack(spacing: RouaTheme.Spacing.sm) {
                        Image(systemName: "chart.line.uptrend.xyaxis").font(.system(size: 28)).foregroundStyle(RouaTheme.Colors.textTertiary)
                        Text("جاري تحميل أسعار السوق...").font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textSecondary)
                    }.frame(maxWidth: .infinity).padding(.vertical, RouaTheme.Spacing.xl)
                }
            } else {
                ForEach(vm.topQuotes, id: \.symbol) { quote in
                    GlassCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(quote.symbol).font(.system(size: 14, weight: .medium)).foregroundStyle(RouaTheme.Colors.textPrimary)
                                if let name = quote.name {
                                    Text(name).font(.system(size: 11)).foregroundStyle(RouaTheme.Colors.textTertiary).lineLimit(1)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(String(format: "%.2f", quote.lastPrice)).font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textPrimary)
                                if let changePct = quote.changePercent, changePct != 0 {
                                    ChangeBadge(value: changePct)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Positions Section
    private var positionsSection: some View {
        VStack(spacing: RouaTheme.Spacing.md) {
            Text("الصفقات النشطة (\(vm.positions.count))").font(.system(size: 16, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)

            if vm.isLoading && vm.positions.isEmpty {
                ForEach(0..<3, id: \.self) { _ in
                    GlassCard { ShimmerView() }
                }
            } else if vm.positions.isEmpty {
                GlassCard {
                    VStack(spacing: RouaTheme.Spacing.sm) {
                        Image(systemName: "chart.bar").font(.system(size: 28)).foregroundStyle(RouaTheme.Colors.textTertiary)
                        Text("لا توجد صفقات مفتوحة").font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textSecondary)
                    }.frame(maxWidth: .infinity).padding(.vertical, RouaTheme.Spacing.xl)
                }
            } else {
                ForEach(vm.positions) { pos in
                    GlassCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Circle().fill(pos.side == "BUY" ? RouaTheme.Colors.profit : RouaTheme.Colors.loss).frame(width: 8, height: 8)
                                    Text(pos.symbol).font(.system(size: 14, weight: .medium)).foregroundStyle(RouaTheme.Colors.textPrimary)
                                    Text(pos.side == "BUY" ? "شراء" : "بيع").font(.system(size: 10, weight: .medium)).foregroundStyle(pos.side == "BUY" ? RouaTheme.Colors.profit : RouaTheme.Colors.loss)
                                }
                                Text("الكمية: \(String(format: "%.4f", pos.quantity))").font(.system(size: 11, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textTertiary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                if let pnl = pos.unrealizedPnlValue { Text(String(format: "%+.2f", pnl)).font(.system(size: 16, weight: .semibold, design: .monospaced)).foregroundStyle(pnl >= 0 ? RouaTheme.Colors.profit : RouaTheme.Colors.loss) }
                                Text("الدخول: \(String(format: "%.2f", pos.entryPrice))").font(.system(size: 11, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textTertiary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Trades Section
    private var tradesSection: some View {
        VStack(spacing: RouaTheme.Spacing.md) {
            Text("آخر الصفقات المغلقة").font(.system(size: 16, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)

            ForEach(Array(vm.trades.prefix(10))) { trade in
                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Circle().fill(trade.side == "long" ? RouaTheme.Colors.profit : RouaTheme.Colors.loss).frame(width: 8, height: 8)
                                Text(trade.symbol).font(.system(size: 14, weight: .medium)).foregroundStyle(RouaTheme.Colors.textPrimary)
                                Text(trade.side == "long" ? "شراء" : "بيع").font(.system(size: 10, weight: .medium)).foregroundStyle(trade.side == "long" ? RouaTheme.Colors.profit : RouaTheme.Colors.loss)
                            }
                            if let entry = trade.entryPrice, let exit = trade.exitPrice {
                                Text("\(String(format: "%.2f", entry)) → \(String(format: "%.2f", exit))").font(.system(size: 11, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textTertiary)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            if let pnl = trade.realizedPnl { Text(String(format: "%+.2f", pnl)).font(.system(size: 16, weight: .semibold, design: .monospaced)).foregroundStyle(pnl >= 0 ? RouaTheme.Colors.profit : RouaTheme.Colors.loss) }
                            if let pct = trade.realizedPct { Text(String(format: "%+.2f%%", pct)).font(.system(size: 11, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textTertiary) }
                        }
                    }
                }
            }
        }
    }
}
