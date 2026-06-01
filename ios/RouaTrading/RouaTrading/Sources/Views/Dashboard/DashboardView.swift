import SwiftUI

// MARK: - الصفحة الرئيسية الجديدة
struct DashboardView: View {
    @StateObject private var vm = DashboardViewModel()
    @State private var navigateToCouncil = false
    @State private var navigateToExecutor = false
    @State private var navigateToAgent = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaTheme.Spacing.lg) {

                // Error Banner
                if let error = vm.errorMessage {
                    ErrorBanner(message: error) { Task { await vm.retry() } }
                }

                // ١— بطاقة المحفظة
                portfolioCard

                // ٢— أزرار مجلس الذكاء + المنفذ الذكي + الوكيل
                actionButtons

                // ٣— آخر ٣ توصيات من المجلس
                councilBriefsCard

                // ٤— آخر ٣ إشارات من السكانر المتقدم
                scannerSignalsCard

                // ٥— آخر الأخبار
                latestNewsCard

            }.padding(.horizontal, RouaTheme.Spacing.lg)
            .padding(.bottom, RouaTheme.Spacing.xl)
        }
        .background(RouaTheme.Colors.background)
        .refreshable { await vm.loadDashboard() }
        .task { await vm.loadDashboard() }
        .navigationTitle("الرئيسية")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - ١. بطاقة المحفظة
    private var portfolioCard: some View {
        GlassCard {
            VStack(spacing: RouaTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("المحفظة")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(RouaTheme.Colors.textTertiary)
                            .textCase(.uppercase)

                        if vm.isLoading && vm.portfolioSummary == nil {
                            ShimmerView()
                        } else if let p = vm.portfolioSummary {
                            Text(String(format: "$%.2f", p.totalValue))
                                .font(.system(size: 28, weight: .bold, design: .monospaced))
                                .foregroundStyle(RouaTheme.Colors.textPrimary)
                        } else {
                            Text("---")
                                .font(.system(size: 28, weight: .bold, design: .monospaced))
                                .foregroundStyle(RouaTheme.Colors.textTertiary)
                        }
                    }
                    Spacer()
                    PulsingDot()
                }

                Divider().background(RouaTheme.Colors.border)

                HStack(spacing: 0) {
                    StatMini(
                        title: "ربح اليوم",
                        value: vm.portfolioSummary.map { String(format: "$%.2f", $0.dailyPnl) } ?? "---",
                        isPositive: (vm.portfolioSummary?.dailyPnl ?? 0) >= 0
                    )
                    .frame(maxWidth: .infinity)

                    StatMini(
                        title: "الصفقات",
                        value: "\(vm.positions.count)"
                    )
                    .frame(maxWidth: .infinity)

                    StatMini(
                        title: "إجمالي الربح",
                        value: vm.portfolioSummary.map { String(format: "$%.2f", $0.totalPnl) } ?? "---",
                        isPositive: (vm.portfolioSummary?.totalPnl ?? 0) >= 0
                    )
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - ٢. أزرار مجلس الذكاء + المنفذ الذكي + الوكيل
    private var actionButtons: some View {
        HStack(spacing: RouaTheme.Spacing.md) {
            // مجلس الذكاء
            NavigationLink(destination: AIHubView()) {
                VStack(spacing: RouaTheme.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(RouaTheme.Colors.accentGradient)
                            .frame(width: 50, height: 50)
                        Image(systemName: "brain.head.profile.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white)
                    }
                    Text("مجلس الذكاء")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(RouaTheme.Colors.textPrimary)
                }
            }
            .frame(maxWidth: .infinity)

            // المنفذ الذكي
            NavigationLink(destination: SmartExecutorView()) {
                VStack(spacing: RouaTheme.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [RouaTheme.Colors.profit, Color(hex: "00E676")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 50, height: 50)
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white)
                    }
                    Text("المنفذ الذكي")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(RouaTheme.Colors.textPrimary)
                }
            }
            .frame(maxWidth: .infinity)

            // الوكيل
            NavigationLink(destination: AgentView()) {
                VStack(spacing: RouaTheme.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color(hex: "8B5CF6"), Color(hex: "A78BFA")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 50, height: 50)
                        Image(systemName: "robot.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white)
                    }
                    Text("الوكيل")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(RouaTheme.Colors.textPrimary)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - ٣. آخر ٣ توصيات من المجلس
    private var councilBriefsCard: some View {
        VStack(spacing: RouaTheme.Spacing.md) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(RouaTheme.Colors.accent)
                Text("توصيات المجلس")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(RouaTheme.Colors.textPrimary)
                Spacer()
                NavigationLink(destination: AIHubView()) {
                    Text("الكل")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(RouaTheme.Colors.accent)
                }
            }

            if vm.isLoading && vm.councilBriefs.isEmpty {
                ForEach(0..<3, id: \.self) { _ in
                    GlassCard { ShimmerView() }
                }
            } else if vm.councilBriefs.isEmpty {
                GlassCard {
                    VStack(spacing: RouaTheme.Spacing.sm) {
                        Image(systemName: "brain")
                            .font(.system(size: 24))
                            .foregroundStyle(RouaTheme.Colors.textTertiary)
                        Text("لا توجد توصيات حالياً")
                            .font(.system(size: 13))
                            .foregroundStyle(RouaTheme.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, RouaTheme.Spacing.lg)
                }
            } else {
                ForEach(Array(vm.councilBriefs.prefix(3))) { brief in
                    GlassCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(brief.direction == "BUY" ? RouaTheme.Colors.profit : RouaTheme.Colors.loss)
                                        .frame(width: 8, height: 8)
                                    Text(brief.pair)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(RouaTheme.Colors.textPrimary)
                                    Text(brief.direction == "BUY" ? "شراء" : "بيع")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(brief.direction == "BUY" ? RouaTheme.Colors.profit : RouaTheme.Colors.loss)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(brief.direction == "BUY" ? RouaTheme.Colors.profitBackground : RouaTheme.Colors.lossBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                                if let conf = brief.confidence {
                                    Text("الثقة: \(Int(conf))%")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundStyle(RouaTheme.Colors.textTertiary)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                if let entry = brief.entryPrice {
                                    Text(String(format: "$%.2f", entry))
                                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                                        .foregroundStyle(RouaTheme.Colors.textSecondary)
                                }
                                if let tf = brief.timeframe {
                                    Text(tf)
                                        .font(.system(size: 10))
                                        .foregroundStyle(RouaTheme.Colors.textTertiary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - ٤. آخر ٣ إشارات من السكانر المتقدم
    private var scannerSignalsCard: some View {
        VStack(spacing: RouaTheme.Spacing.md) {
            HStack {
                Image(systemName: "wave.3.right")
                    .foregroundStyle(RouaTheme.Colors.profit)
                Text("إشارات السكانر")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(RouaTheme.Colors.textPrimary)
                Spacer()
                NavigationLink(destination: ScannerView()) {
                    Text("الكل")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(RouaTheme.Colors.accent)
                }
            }

            if vm.isLoading && vm.scannerSignals.isEmpty {
                ForEach(0..<3, id: \.self) { _ in
                    GlassCard { ShimmerView() }
                }
            } else if vm.scannerSignals.isEmpty {
                GlassCard {
                    VStack(spacing: RouaTheme.Spacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 24))
                            .foregroundStyle(RouaTheme.Colors.textTertiary)
                        Text("لا توجد إشارات حالياً")
                            .font(.system(size: 13))
                            .foregroundStyle(RouaTheme.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, RouaTheme.Spacing.lg)
                }
            } else {
                ForEach(Array(vm.scannerSignals.prefix(3))) { signal in
                    GlassCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(signal.direction == "BUY" ? RouaTheme.Colors.profit : signal.direction == "SELL" ? RouaTheme.Colors.loss : RouaTheme.Colors.warning)
                                        .frame(width: 8, height: 8)
                                    Text(signal.symbol)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(RouaTheme.Colors.textPrimary)
                                }
                                if let reasons = signal.reasonsAr, !reasons.isEmpty {
                                    Text(reasons.joined(separator: " • "))
                                        .font(.system(size: 10))
                                        .foregroundStyle(RouaTheme.Colors.textTertiary)
                                        .lineLimit(2)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                if let price = signal.price {
                                    Text(String(format: "%.2f", price))
                                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                                        .foregroundStyle(RouaTheme.Colors.textSecondary)
                                }
                                if let change = signal.changePercent {
                                    ChangeBadge(value: change)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - ٥. آخر الأخبار
    private var latestNewsCard: some View {
        VStack(spacing: RouaTheme.Spacing.md) {
            HStack {
                Image(systemName: "newspaper.fill")
                    .foregroundStyle(RouaTheme.Colors.warning)
                Text("آخر الأخبار")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(RouaTheme.Colors.textPrimary)
                Spacer()
            }

            if vm.isLoading && vm.newsArticles.isEmpty {
                ForEach(0..<3, id: \.self) { _ in
                    GlassCard { ShimmerView() }
                }
            } else if vm.newsArticles.isEmpty {
                GlassCard {
                    VStack(spacing: RouaTheme.Spacing.sm) {
                        Image(systemName: "newspaper")
                            .font(.system(size: 24))
                            .foregroundStyle(RouaTheme.Colors.textTertiary)
                        Text("لا توجد أخبار حالياً")
                            .font(.system(size: 13))
                            .foregroundStyle(RouaTheme.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, RouaTheme.Spacing.lg)
                }
            } else {
                ForEach(Array(vm.newsArticles.prefix(5))) { article in
                    GlassCard {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(article.title)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(RouaTheme.Colors.textPrimary)
                                    .lineLimit(2)
                                Spacer()
                                if let sentiment = article.sentiment {
                                    Text(sentiment == "positive" ? "إيجابي" : sentiment == "negative" ? "سلبي" : "محايد")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundStyle(sentiment == "positive" ? RouaTheme.Colors.profit : sentiment == "negative" ? RouaTheme.Colors.loss : RouaTheme.Colors.textTertiary)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(sentiment == "positive" ? RouaTheme.Colors.profitBackground : sentiment == "negative" ? RouaTheme.Colors.lossBackground : RouaTheme.Colors.surfaceElevated)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                            }
                            if let source = article.source {
                                Text(source)
                                    .font(.system(size: 10))
                                    .foregroundStyle(RouaTheme.Colors.textTertiary)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Smart Executor Placeholder
struct SmartExecutorView: View {
    @StateObject private var vm = TradingViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaTheme.Spacing.lg) {
                // Executor Status Card
                GlassCard {
                    VStack(spacing: RouaTheme.Spacing.md) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(RouaTheme.Colors.profit.opacity(0.2))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(RouaTheme.Colors.profit)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("المنفذ الذكي")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(RouaTheme.Colors.textPrimary)
                                Text("ينفذ توصيات المجلس تلقائياً")
                                    .font(.system(size: 12))
                                    .foregroundStyle(RouaTheme.Colors.textTertiary)
                            }
                            Spacer()
                            PulsingDot(color: RouaTheme.Colors.profit)
                        }

                        Divider().background(RouaTheme.Colors.border)

                        HStack(spacing: 0) {
                            StatMini(title: "الصفقات", value: "\(vm.positions.count)")
                                .frame(maxWidth: .infinity)
                            StatMini(
                                title: "الربح",
                                value: vm.portfolioSummary.map { String(format: "$%.2f", $0.unrealizedPnl ?? 0) } ?? "---",
                                isPositive: (vm.portfolioSummary?.unrealizedPnl ?? 0) >= 0
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                }

                // Open Positions
                if !vm.positions.isEmpty {
                    VStack(spacing: RouaTheme.Spacing.md) {
                        Text("الصفقات النشطة")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(RouaTheme.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(vm.positions) { pos in
                            GlassCard {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 4) {
                                            Circle().fill(pos.side == "BUY" ? RouaTheme.Colors.profit : RouaTheme.Colors.loss).frame(width: 6, height: 6)
                                            Text(pos.symbol).font(.system(size: 13, weight: .medium)).foregroundStyle(RouaTheme.Colors.textPrimary)
                                        }
                                        Text(pos.side == "BUY" ? "شراء" : "بيع").font(.system(size: 10)).foregroundStyle(pos.side == "BUY" ? RouaTheme.Colors.profit : RouaTheme.Colors.loss)
                                    }
                                    Spacer()
                                    if let pnl = pos.unrealizedPnlValue {
                                        Text(String(format: "%+.2f", pnl)).font(.system(size: 13, weight: .semibold, design: .monospaced)).foregroundStyle(pnl >= 0 ? RouaTheme.Colors.profit : RouaTheme.Colors.loss)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, RouaTheme.Spacing.lg)
        }
        .background(RouaTheme.Colors.background)
        .task { await vm.loadTradingData() }
        .navigationTitle("المنفذ الذكي")
        .navigationBarTitleDisplayMode(.inline)
    }
}
