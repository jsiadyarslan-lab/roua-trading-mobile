import SwiftUI

// MARK: - Agent View (Autonomous Trader)
struct AgentView: View {
    @State private var isRunning = false
    @State private var selectedStrategy = "AUTO"
    @State private var isLoading = false
    @State private var performance: AgentPerformance?
    @State private var openPositions: [Position] = []
    @State private var marketRegime: String?
    @State private var showStartConfirm = false
    @State private var showEmergencyConfirm = false

    struct AgentPerformance {
        let dailyPnl: Double
        let dailyTrades: Int
        let winRate: Double
        let openPositions: Int
        let consecutiveLosses: Int
    }

    private let strategies: [(String, String, String, [String])] = [
        ("AUTO", "تلقائي", "كشف نظام السوق + اختيار تلقائي", ["ذكي", "AI"]),
        ("SWING", "سوينج", "صفقات متأرجحة على مدى أيام", ["متوسط"]),
        ("GRID", "شبكة", "أوامر شراء/بيع في شبكة أسعار", ["هادئ"]),
        ("MEAN_REVERSION", "ارتداد المتوسط", "العودة للمتوسط عند الانحراف", ["نطاق"]),
        ("MOMENTUM_BREAKOUT", "اختراق", "دخول عند كسر مستويات", ["صاعد"]),
        ("DCA", "متوسط التكلفة", "شراء دوري بتكلفة متوسطة", ["هابط"]),
        ("VWAP_RSI", "VWAP+RSI", "دمج VWAP مع RSI", ["فني"]),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaTheme.Spacing.lg) {
                // Status Card
                GlassCard {
                    VStack(spacing: RouaTheme.Spacing.md) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Circle().fill(isRunning ? RouaTheme.Colors.profit : RouaTheme.Colors.loss).frame(width: 10, height: 10)
                                    Text(isRunning ? "يعمل" : "متوقف").font(.system(size: 16, weight: .semibold)).foregroundStyle(isRunning ? RouaTheme.Colors.profit : RouaTheme.Colors.loss)
                                }
                                if let regime = marketRegime {
                                    Text("نظام السوق: \(regime)").font(.system(size: 12)).foregroundStyle(RouaTheme.Colors.textSecondary)
                                }
                            }
                            Spacer()
                            Text(selectedStrategy).font(.system(size: 20, weight: .bold, design: .monospaced)).foregroundStyle(RouaTheme.Colors.accent).padding(.horizontal, 12).padding(.vertical, 6).background(RouaTheme.Colors.accent.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        if let perf = performance {
                            HStack(spacing: RouaTheme.Spacing.md) {
                                StatMini(title: "P&L يومي", value: String(format: "%.2f%%", perf.dailyPnl), isPositive: perf.dailyPnl >= 0)
                                StatMini(title: "صفقات", value: "\(perf.dailyTrades)")
                                StatMini(title: "فوز", value: String(format: "%.0f%%", perf.winRate), isPositive: perf.winRate >= 50)
                                StatMini(title: "خسائر متتالية", value: "\(perf.consecutiveLosses)", isPositive: perf.consecutiveLosses == 0)
                            }
                        }
                    }
                }

                // Strategies Grid
                Text("الاستراتيجيات").font(.system(size: 14, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                    ForEach(strategies, id: \.0) { strategy in
                        Button { withAnimation { selectedStrategy = strategy.0 } } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(strategy.0).font(.system(size: 13, weight: selectedStrategy == strategy.0 ? .bold : .medium)).foregroundStyle(selectedStrategy == strategy.0 ? .white : RouaTheme.Colors.textPrimary)
                                Text(strategy.2).font(.system(size: 10)).foregroundStyle(RouaTheme.Colors.textSecondary).lineLimit(2)
                                HStack(spacing: 4) {
                                    ForEach(strategy.3, id: \.self) { tag in
                                        Text(tag).font(.system(size: 9, weight: .medium)).foregroundStyle(RouaTheme.Colors.accent).padding(.horizontal, 5).padding(.vertical, 2).background(RouaTheme.Colors.accent.opacity(0.08)).clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(RouaTheme.Spacing.md)
                            .background(selectedStrategy == strategy.0 ? RouaTheme.Colors.accent.opacity(0.15) : RouaTheme.Colors.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md))
                            .overlay(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md).stroke(selectedStrategy == strategy.0 ? RouaTheme.Colors.accent : Color.clear, lineWidth: 1))
                        }
                    }
                }

                // Control Buttons
                HStack(spacing: RouaTheme.Spacing.md) {
                    TradingButton(title: isRunning ? "⏸ إيقاف مؤقت" : "▶ تشغيل", style: isRunning ? .secondary : .buy, isLoading: isLoading) {
                        if isRunning { Task { await stopAgent() } } else { showStartConfirm = true }
                    }
                    if isRunning {
                        TradingButton(title: "🛑 طوارئ", style: .danger, isLoading: false) { showEmergencyConfirm = true }
                    }
                }

                // Open Positions
                if !openPositions.isEmpty {
                    Text("المراكز المفتوحة").font(.system(size: 14, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(openPositions) { pos in
                        GlassCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) { Circle().fill(pos.side == "BUY" ? RouaTheme.Colors.profit : RouaTheme.Colors.loss).frame(width: 6, height: 6); Text(pos.symbol).font(.system(size: 13, weight: .medium)).foregroundStyle(RouaTheme.Colors.textPrimary) }
                                    Text(pos.side == "BUY" ? "شراء" : "بيع").font(.system(size: 10)).foregroundStyle(pos.side == "BUY" ? RouaTheme.Colors.profit : RouaTheme.Colors.loss)
                                }
                                Spacer()
                                if let pnl = pos.unrealizedPnl { Text(String(format: "%+.2f", pnl)).font(.system(size: 14, weight: .semibold, design: .monospaced)).foregroundStyle(pnl >= 0 ? RouaTheme.Colors.profit : RouaTheme.Colors.loss) }
                            }
                        }
                    }
                }

                Text("⚠️ الوكيل المستقل يفتح ويغلق صفقات تلقائياً. وقف الخسارة إلزامي. لا يمكنه سحب أموال.")
                    .font(.system(size: 10)).foregroundStyle(RouaTheme.Colors.warning).padding(RouaTheme.Spacing.md).frame(maxWidth: .infinity, alignment: .leading).background(RouaTheme.Colors.warningBackground).clipShape(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md))
            }
            .padding(RouaTheme.Spacing.lg)
        }
        .alert("تشغيل الوكيل", isPresented: $showStartConfirm) {
            Button("تشغيل", role: .none) { Task { await startAgent() } }
            Button("إلغاء", role: .cancel) {}
        } message: { Text("سيبدأ الوكيل بالتداول تلقائياً باستراتيجية \(selectedStrategy). هل أنت متأكد؟") }
        .alert("إيقاف طوارئ", isPresented: $showEmergencyConfirm) {
            Button("إيقاف + إغلاق الكل", role: .destructive) { Task { await emergencyStop() } }
            Button("إلغاء", role: .cancel) {}
        } message: { Text("سيتم إغلاق جميع المراكز المفتوحة فوراً!") }
        .task { await loadAgentStatus() }
    }

    private func loadAgentStatus() async {
        do {
            struct AgentStatusResponse: Codable { let success: Bool?; let data: AgentStatusData? }
            struct AgentStatusData: Codable { let running: Bool?; let strategy: String?; let regime: String?; let dailyPnl: Double?; let dailyTrades: Int?; let winRate: Double?; let consecutiveLosses: Int? }
            let response: AgentStatusResponse = try await APIClient.shared.request("/agent/trader/status")
            isRunning = response.data?.running ?? false
            if let strat = response.data?.strategy { selectedStrategy = strat }
            marketRegime = response.data?.regime
            if let data = response.data {
                performance = AgentPerformance(dailyPnl: data.dailyPnl ?? 0, dailyTrades: data.dailyTrades ?? 0, winRate: data.winRate ?? 0, openPositions: 0, consecutiveLosses: data.consecutiveLosses ?? 0)
            }
            let positions: [Position] = try await APIClient.shared.request("/agent/trader/open-positions")
            openPositions = positions
        } catch { print("[Agent] Status error: \(error.localizedDescription)") }
    }

    private func startAgent() async {
        isLoading = true; defer { isLoading = false }
        do {
            let _: Data = try await APIClient.shared.rawDataRequest("/agent/trader/start", method: "POST", body: ["strategy": selectedStrategy])
            isRunning = true; await loadAgentStatus()
        } catch { print("[Agent] Start error: \(error.localizedDescription)") }
    }

    private func stopAgent() async {
        isLoading = true; defer { isLoading = false }
        do {
            let _: Data = try await APIClient.shared.rawDataRequest("/agent/trader/stop", method: "POST", body: ["emergency": false])
            isRunning = false
        } catch { print("[Agent] Stop error: \(error.localizedDescription)") }
    }

    private func emergencyStop() async {
        isLoading = true; defer { isLoading = false }
        do {
            let _: Data = try await APIClient.shared.rawDataRequest("/agent/trader/stop", method: "POST", body: ["emergency": true])
            isRunning = false; openPositions = []
        } catch { print("[Agent] Emergency stop error: \(error.localizedDescription)") }
    }
}
