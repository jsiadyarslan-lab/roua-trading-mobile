import SwiftUI

// MARK: - AI Hub View (Council + Executor + Strategy + Coach + Signals + Neural)
struct AIHubView: View {
    @State private var selectedTab = 0

    private let tabs = [
        ("المجلس", "brain.head.profile"),
        ("المنفذ", "bolt.fill"),
        ("الاستراتيجية", "shield.checkered"),
        ("المدرب", "figure.run"),
        ("الإشارات", "antenna.radiowaves.left.and.right"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: RouaTheme.Spacing.sm) {
                    ForEach(0..<tabs.count, id: \.self) { i in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = i }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: tabs[i].1)
                                    .font(.system(size: 12))
                                Text(tabs[i].0)
                                    .font(.system(size: 13, weight: selectedTab == i ? .bold : .medium))
                            }
                            .foregroundStyle(selectedTab == i ? .white : RouaTheme.Colors.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedTab == i ? RouaTheme.Colors.accent : RouaTheme.Colors.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(.horizontal, RouaTheme.Spacing.lg)
                .padding(.vertical, RouaTheme.Spacing.sm)
            }

            Divider().background(RouaTheme.Colors.border)

            // Content
            Group {
                switch selectedTab {
                case 0: AICouncilView()
                case 1: SmartExecutorView()
                case 2: StrategicCouncilView()
                case 3: AICoachView()
                case 4: SignalsView()
                default: EmptyView()
                }
            }
            .frame(maxHeight: .infinity)
        }
        .background(RouaTheme.Colors.background)
        .navigationTitle("الذكاء الاصطناعي")
    }
}

// MARK: - AI Council View (8-model consensus)
struct AICouncilView: View {
    @State private var isLoading = false
    @State private var consensusScore: Int?
    @State private var consensusDirection: String?
    @State private var masterStrategy: String?
    @State private var votes: [CouncilVote] = []

    struct CouncilVote: Identifiable {
        let id = UUID()
        let role: String
        let direction: String
        let confidence: Int
        let model: String
    }

    private let roles = [
        ("محلل فني", "chart.xyaxis.line"),
        ("محلل مشاعر", "face.smiling"),
        ("خبير مخاطر", "exclamationmark.shield"),
        ("خبير ماكرو", "globe"),
        ("خبير أنماط", "square.on.square"),
        ("منفذ استراتيجي", "bolt"),
        ("محلل تباعد", "arrow.left.arrow.right"),
        ("محلل سيناريو", "sparkles"),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaTheme.Spacing.lg) {
                // Consensus Gauge
                GlassCard {
                    VStack(spacing: RouaTheme.Spacing.md) {
                        Text("مقياس الإجماع")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(RouaTheme.Colors.textTertiary)

                        if let score = consensusScore {
                            ZStack {
                                Circle()
                                    .stroke(RouaTheme.Colors.surfaceElevated, lineWidth: 8)
                                    .frame(width: 100, height: 100)
                                Circle()
                                    .trim(from: 0, to: CGFloat(score) / 100)
                                    .stroke(score >= 70 ? RouaTheme.Colors.profit : score >= 40 ? RouaTheme.Colors.warning : RouaTheme.Colors.loss, lineWidth: 8)
                                    .frame(width: 100, height: 100)
                                VStack(spacing: 2) {
                                    Text("\(score)%")
                                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                                        .foregroundStyle(RouaTheme.Colors.textPrimary)
                                    Text(consensusDirection ?? "")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(consensusDirection == "شراء" ? RouaTheme.Colors.profit : consensusDirection == "بيع" ? RouaTheme.Colors.loss : RouaTheme.Colors.warning)
                                }
                            }
                        } else {
                            ProgressView().tint(RouaTheme.Colors.accent)
                                .frame(height: 100)
                        }

                        if let strategy = masterStrategy {
                            Text(strategy)
                                .font(.system(size: 12))
                                .foregroundStyle(RouaTheme.Colors.textSecondary)
                                .lineLimit(5)
                                .padding(.horizontal, RouaTheme.Spacing.sm)
                        }
                    }
                }

                // Votes List
                if !votes.isEmpty {
                    Text("تصويت النماذج").font(.system(size: 14, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(votes) { vote in
                        GlassCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(vote.role).font(.system(size: 13, weight: .medium)).foregroundStyle(RouaTheme.Colors.textPrimary)
                                    HStack(spacing: 4) {
                                        Text(vote.direction).font(.system(size: 11, weight: .semibold)).foregroundStyle(vote.direction == "شراء" ? RouaTheme.Colors.profit : vote.direction == "بيع" ? RouaTheme.Colors.loss : RouaTheme.Colors.warning)
                                        Text("\(vote.confidence)%").font(.system(size: 10, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textTertiary)
                                    }
                                }
                                Spacer()
                                Text(vote.model).font(.system(size: 10, weight: .medium)).foregroundStyle(RouaTheme.Colors.accent).padding(.horizontal, 6).padding(.vertical, 3).background(RouaTheme.Colors.accent.opacity(0.1)).clipShape(Capsule())
                            }
                        }
                    }
                }

                // Trigger button
                TradingButton(title: "تشغيل مجلس AI", style: .primary, isLoading: isLoading) {
                    Task { await fetchConsensus() }
                }
            }
            .padding(RouaTheme.Spacing.lg)
        }
        .task { await fetchConsensus() }
    }

    private func fetchConsensus() async {
        isLoading = true
        defer { isLoading = false }

        do {
            struct ConsensusResponse: Codable {
                let success: Bool?
                let data: ConsensusData?
            }
            struct ConsensusData: Codable {
                let consensus: ConsensusInfo?
                let votes: [VoteData]?
            }
            struct ConsensusInfo: Codable {
                let score: Int?
                let direction: String?
                let masterStrategy: String?
            }
            struct VoteData: Codable {
                let role: String?
                let direction: String?
                let confidence: Int?
                let model: String?
            }

            let response: ConsensusResponse = try await APIClient.shared.request("/ai/consensus")
            if let data = response.data {
                consensusScore = data.consensus?.score
                consensusDirection = data.consensus?.direction == "BUY" ? "شراء" : data.consensus?.direction == "SELL" ? "بيع" : "إمساك"
                masterStrategy = data.consensus?.masterStrategy

                votes = (data.votes ?? []).map { v in
                    CouncilVote(
                        role: v.role ?? "غير معروف",
                        direction: v.direction == "BUY" ? "شراء" : v.direction == "SELL" ? "بيع" : "إمساك",
                        confidence: v.confidence ?? 0,
                        model: v.model ?? "AI"
                    )
                }
            }
        } catch {
            print("[AI Council] Error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Smart Executor View
struct SmartExecutorView: View {
    @State private var isEnabled = false
    @State private var isLoading = false
    @State private var activePositions: [Position] = []
    @State private var todayExecutions = 0
    @State private var dailyPnl: Double = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaTheme.Spacing.lg) {
                // Status Card
                GlassCard {
                    VStack(spacing: RouaTheme.Spacing.md) {
                        HStack {
                            Text("المنفذ الذكي")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(RouaTheme.Colors.textPrimary)
                            Spacer()
                            Circle()
                                .fill(isEnabled ? RouaTheme.Colors.profit : RouaTheme.Colors.loss)
                                .frame(width: 10, height: 10)
                        }

                        // Stats Grid
                        HStack(spacing: RouaTheme.Spacing.md) {
                            StatMini(title: "تنفيذات اليوم", value: "\(todayExecutions)")
                            StatMini(title: "P&L يومي", value: String(format: "$%.2f", dailyPnl), isPositive: dailyPnl >= 0)
                            StatMini(title: "مراكز مفتوحة", value: "\(activePositions.count)")
                        }

                        // Toggle
                        HStack {
                            Button {
                                Task { await toggleExecutor(enable: !isEnabled) }
                            } label: {
                                Text(isEnabled ? "إيقاف المنفذ" : "تشغيل المنفذ")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(isEnabled ? RouaTheme.Colors.loss : RouaTheme.Colors.profit)
                                    .clipShape(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md))
                            }
                        }
                    }
                }

                // Emergency Stop
                TradingButton(title: "🛑 إيقاف طوارئ — إغلاق الكل", style: .danger, isLoading: false) {
                    Task { await emergencyStop() }
                }

                // Open Positions
                if !activePositions.isEmpty {
                    Text("المراكز المفتوحة").font(.system(size: 14, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(activePositions) { pos in
                        GlassCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(pos.symbol).font(.system(size: 14, weight: .medium)).foregroundStyle(RouaTheme.Colors.textPrimary)
                                    Text(pos.side == "BUY" ? "شراء" : "بيع").font(.system(size: 10)).foregroundStyle(pos.side == "BUY" ? RouaTheme.Colors.profit : RouaTheme.Colors.loss)
                                }
                                Spacer()
                                if let pnl = pos.unrealizedPnl {
                                    Text(String(format: "%+.2f", pnl)).font(.system(size: 14, weight: .semibold, design: .monospaced)).foregroundStyle(pnl >= 0 ? RouaTheme.Colors.profit : RouaTheme.Colors.loss)
                                }
                            }
                        }
                    }
                }
            }
            .padding(RouaTheme.Spacing.lg)
        }
        .task { await loadStatus() }
    }

    private func loadStatus() async {
        do {
            struct ExecutorStatus: Codable { let enabled: Bool?; let todayExecutions: Int?; let dailyPnl: Double? }
            struct StatusResponse: Codable { let success: Bool?; let data: ExecutorStatus? }
            let response: StatusResponse = try await APIClient.shared.request("/smart-executor/user/status")
            isEnabled = response.data?.enabled ?? false
            todayExecutions = response.data?.todayExecutions ?? 0
            dailyPnl = response.data?.dailyPnl ?? 0

            let positions: [Position] = try await APIClient.shared.request("/smart-executor/positions")
            activePositions = positions
        } catch {
            print("[SmartExecutor] Error: \(error.localizedDescription)")
        }
    }

    private func toggleExecutor(enable: Bool) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let path = enable ? "/smart-executor/user/enable" : "/smart-executor/user/disable"
            let _: Data = try await APIClient.shared.rawDataRequest(path, method: "POST")
            isEnabled = enable
        } catch {
            print("[SmartExecutor] Toggle error: \(error.localizedDescription)")
        }
    }

    private func emergencyStop() async {
        do {
            let _: Data = try await APIClient.shared.rawDataRequest("/smart-executor/emergency-stop", method: "POST")
            isEnabled = false
            activePositions = []
        } catch {
            print("[SmartExecutor] Emergency stop error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Strategic Council View
struct StrategicCouncilView: View {
    @State private var briefs: [StrategicBrief] = []
    @State private var isLoading = false

    struct StrategicBrief: Identifiable {
        let id = UUID()
        let pair: String
        let direction: String
        let timeframe: String
        let entryPrice: Double?
        let stopLoss: Double?
        let takeProfit: Double?
        let confidence: Int?
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaTheme.Spacing.lg) {
                // Trigger button
                TradingButton(title: "تشغيل جلسة استراتيجية", style: .primary, isLoading: isLoading) {
                    Task { await triggerSession() }
                }

                if briefs.isEmpty && !isLoading {
                    GlassCard {
                        VStack(spacing: RouaTheme.Spacing.sm) {
                            Image(systemName: "shield.checkered").font(.system(size: 32)).foregroundStyle(RouaTheme.Colors.textTertiary)
                            Text("لا توجد إيجازات استراتيجية حالياً").font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textSecondary)
                        }.frame(maxWidth: .infinity).padding(.vertical, RouaTheme.Spacing.xl)
                    }
                }

                ForEach(briefs) { brief in
                    GlassCard {
                        VStack(alignment: .leading, spacing: RouaTheme.Spacing.sm) {
                            HStack {
                                Text(brief.pair).font(.system(size: 15, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary)
                                Spacer()
                                Text(brief.direction).font(.system(size: 12, weight: .bold)).foregroundStyle(brief.direction == "شراء" ? RouaTheme.Colors.profit : RouaTheme.Colors.loss).padding(.horizontal, 8).padding(.vertical, 4).background(brief.direction == "شراء" ? RouaTheme.Colors.profitBackground : RouaTheme.Colors.lossBackground).clipShape(Capsule())
                            }
                            Text(brief.timeframe).font(.system(size: 11)).foregroundStyle(RouaTheme.Colors.textTertiary)

                            HStack(spacing: RouaTheme.Spacing.lg) {
                                if let entry = brief.entryPrice {
                                    VStack(spacing: 2) {
                                        Text("الدخول").font(.system(size: 10)).foregroundStyle(RouaTheme.Colors.textTertiary)
                                        Text(String(format: "%.2f", entry)).font(.system(size: 12, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textPrimary)
                                    }
                                }
                                if let sl = brief.stopLoss {
                                    VStack(spacing: 2) {
                                        Text("وقف").font(.system(size: 10)).foregroundStyle(RouaTheme.Colors.textTertiary)
                                        Text(String(format: "%.2f", sl)).font(.system(size: 12, design: .monospaced)).foregroundStyle(RouaTheme.Colors.loss)
                                    }
                                }
                                if let tp = brief.takeProfit {
                                    VStack(spacing: 2) {
                                        Text("هدف").font(.system(size: 10)).foregroundStyle(RouaTheme.Colors.textTertiary)
                                        Text(String(format: "%.2f", tp)).font(.system(size: 12, design: .monospaced)).foregroundStyle(RouaTheme.Colors.profit)
                                    }
                                }
                                if let conf = brief.confidence {
                                    Spacer()
                                    VStack(spacing: 2) {
                                        Text("ثقة").font(.system(size: 10)).foregroundStyle(RouaTheme.Colors.textTertiary)
                                        Text("\(conf)%").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundStyle(conf >= 70 ? RouaTheme.Colors.profit : RouaTheme.Colors.warning)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(RouaTheme.Spacing.lg)
        }
        .task { await loadBriefs() }
    }

    private func loadBriefs() async {
        isLoading = true
        defer { isLoading = false }
        do {
            struct BriefsResponse: Codable { let success: Bool?; let data: BriefData? }
            struct BriefData: Codable { let active: [BriefItem]? }
            struct BriefItem: Codable { let pair: String?; let direction: String?; let timeframe: String?; let entryPrice: Double?; let stopLoss: Double?; let takeProfit: Double?; let confidence: Int? }
            let response: BriefsResponse = try await APIClient.shared.request("/strategic-council/briefs")
            briefs = (response.data?.active ?? []).map { item in
                StrategicBrief(
                    pair: item.pair ?? "---",
                    direction: item.direction == "BUY" ? "شراء" : item.direction == "SELL" ? "بيع" : "إمساك",
                    timeframe: item.timeframe ?? "---",
                    entryPrice: item.entryPrice,
                    stopLoss: item.stopLoss,
                    takeProfit: item.takeProfit,
                    confidence: item.confidence
                )
            }
        } catch {
            print("[StrategicCouncil] Error: \(error.localizedDescription)")
        }
    }

    private func triggerSession() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let _: Data = try await APIClient.shared.rawDataRequest("/strategic-council/trigger", method: "POST", body: ["pairs": ["BTC/USDT", "ETH/USDT"]])
            // Wait for processing then reload
            try await Task.sleep(nanoseconds: 5_000_000_000)
            await loadBriefs()
        } catch {
            print("[StrategicCouncil] Trigger error: \(error.localizedDescription)")
        }
    }
}

// MARK: - AI Coach View
struct AICoachView: View {
    @State private var question = ""
    @State private var isLoading = false
    @State private var advice: String?
    @State private var history: [(question: String, answer: String)] = []

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaTheme.Spacing.lg) {
                if let advice = advice {
                    GlassCard {
                        VStack(alignment: .leading, spacing: RouaTheme.Spacing.sm) {
                            Text("نصيحة المدرب").font(.system(size: 14, weight: .semibold)).foregroundStyle(RouaTheme.Colors.accent)
                            Text(advice).font(.system(size: 13)).foregroundStyle(RouaTheme.Colors.textPrimary).lineLimit(20)
                        }
                    }
                }

                TradingButton(title: "الحصول على نصيحة أداء", style: .primary, isLoading: isLoading) {
                    Task { await getPerformanceAdvice() }
                }

                // Ask a question
                GlassCard {
                    VStack(spacing: RouaTheme.Spacing.md) {
                        TextField("اسأل المدرب...", text: $question)
                            .font(.system(size: 14))
                            .foregroundStyle(RouaTheme.Colors.textPrimary)
                            .padding()
                            .background(RouaTheme.Colors.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md))

                        TradingButton(title: "سؤال", style: .primary, isLoading: isLoading) {
                            Task { await askCoach() }
                        }
                    }
                }

                // History
                if !history.isEmpty {
                    Text("الأسئلة السابقة").font(.system(size: 14, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(history, id: \.question) { item in
                        GlassCard {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.question).font(.system(size: 12, weight: .medium)).foregroundStyle(RouaTheme.Colors.accent)
                                Text(item.answer).font(.system(size: 12)).foregroundStyle(RouaTheme.Colors.textSecondary).lineLimit(5)
                            }
                        }
                    }
                }
            }
            .padding(RouaTheme.Spacing.lg)
        }
    }

    private func getPerformanceAdvice() async {
        isLoading = true
        defer { isLoading = false }
        do {
            struct CoachResponse: Codable { let success: Bool?; let data: CoachData? }
            struct CoachData: Codable { let advice: String? }
            let response: CoachResponse = try await APIClient.shared.request("/coach/performance", method: "POST")
            advice = response.data?.advice ?? "لا توجد نصائح حالياً"
        } catch {
            advice = "فشل الحصول على النصيحة: \(error.localizedDescription)"
        }
    }

    private func askCoach() async {
        guard !question.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            struct AskResponse: Codable { let success: Bool?; let data: AskData? }
            struct AskData: Codable { let answer: String? }
            let response: AskResponse = try await APIClient.shared.request("/coach/ask", method: "POST", body: ["question": question, "locale": "ar"])
            let answer = response.data?.answer ?? "لا إجابة"
            history.insert((question: question, answer: answer), at: 0)
            question = ""
        } catch {
            print("[Coach] Error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Signals View
struct SignalsView: View {
    @State private var signals: [SignalItem] = []
    @State private var isLoading = false

    private let quickPairs = ["BTC/USDT", "ETH/USDT", "SOL/USDT", "XAU/USDT", "AAPL/USDT", "TSLA/USDT"]

    struct SignalItem: Identifiable {
        let id = UUID()
        let pair: String
        let direction: String
        let confidence: Int?
        let entry: Double?
        let sl: Double?
        let tp: Double?
        let reason: String?
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaTheme.Spacing.lg) {
                // Quick Generate
                Text("توليد إشارة سريعة").font(.system(size: 14, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(quickPairs, id: \.self) { pair in
                        Button {
                            Task { await generateSignal(for: pair) }
                        } label: {
                            Text(pair.replacingOccurrences(of: "/USDT", with: ""))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(RouaTheme.Colors.accent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(RouaTheme.Colors.accent.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }

                // Signals List
                if signals.isEmpty && !isLoading {
                    GlassCard {
                        VStack(spacing: RouaTheme.Spacing.sm) {
                            Image(systemName: "antenna.radiowaves.left.and.right").font(.system(size: 28)).foregroundStyle(RouaTheme.Colors.textTertiary)
                            Text("لا توجد إشارات نشطة").font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textSecondary)
                        }.frame(maxWidth: .infinity).padding(.vertical, RouaTheme.Spacing.xl)
                    }
                }

                ForEach(signals) { signal in
                    GlassCard {
                        VStack(alignment: .leading, spacing: RouaTheme.Spacing.sm) {
                            HStack {
                                Text(signal.pair).font(.system(size: 15, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary)
                                Spacer()
                                Text(signal.direction).font(.system(size: 12, weight: .bold)).foregroundStyle(signal.direction == "شراء" ? RouaTheme.Colors.profit : signal.direction == "بيع" ? RouaTheme.Colors.loss : RouaTheme.Colors.warning).padding(.horizontal, 8).padding(.vertical, 4).background(signal.direction == "شراء" ? RouaTheme.Colors.profitBackground : RouaTheme.Colors.lossBackground).clipShape(Capsule())
                            }

                            HStack(spacing: RouaTheme.Spacing.lg) {
                                if let entry = signal.entry { VStack(spacing: 2) { Text("الدخول").font(.system(size: 10)).foregroundStyle(RouaTheme.Colors.textTertiary); Text(String(format: "%.2f", entry)).font(.system(size: 12, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textPrimary) } }
                                if let sl = signal.sl { VStack(spacing: 2) { Text("وقف").font(.system(size: 10)).foregroundStyle(RouaTheme.Colors.textTertiary); Text(String(format: "%.2f", sl)).font(.system(size: 12, design: .monospaced)).foregroundStyle(RouaTheme.Colors.loss) } }
                                if let tp = signal.tp { VStack(spacing: 2) { Text("هدف").font(.system(size: 10)).foregroundStyle(RouaTheme.Colors.textTertiary); Text(String(format: "%.2f", tp)).font(.system(size: 12, design: .monospaced)).foregroundStyle(RouaTheme.Colors.profit) } }
                                if let conf = signal.confidence { Spacer(); VStack(spacing: 2) { Text("ثقة").font(.system(size: 10)).foregroundStyle(RouaTheme.Colors.textTertiary); Text("\(conf)%").font(.system(size: 12, weight: .bold)).foregroundStyle(RouaTheme.Colors.accent) } }
                            }

                            if let reason = signal.reason {
                                Text(reason).font(.system(size: 11)).foregroundStyle(RouaTheme.Colors.textSecondary).lineLimit(3)
                            }
                        }
                    }
                }
            }
            .padding(RouaTheme.Spacing.lg)
        }
        .task { await loadSignals() }
    }

    private func loadSignals() async {
        isLoading = true
        defer { isLoading = false }
        do {
            struct SignalsResponse: Codable { let success: Bool?; let data: [SignalData]? }
            struct SignalData: Codable { let pair: String?; let direction: String?; let confidence: Int?; let entryPrice: Double?; let stopLoss: Double?; let takeProfit: Double?; let reason: String? }
            let response: SignalsResponse = try await APIClient.shared.request("/signals/active")
            signals = (response.data ?? []).map { s in
                SignalItem(
                    pair: s.pair ?? "---",
                    direction: s.direction == "BUY" ? "شراء" : s.direction == "SELL" ? "بيع" : "إمساك",
                    confidence: s.confidence,
                    entry: s.entryPrice,
                    sl: s.stopLoss,
                    tp: s.takeProfit,
                    reason: s.reason
                )
            }
        } catch {
            print("[Signals] Error: \(error.localizedDescription)")
        }
    }

    private func generateSignal(for pair: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let encoded = pair.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? pair
            struct GenResponse: Codable { let success: Bool?; let data: SignalData? }
            struct SignalData: Codable { let pair: String?; let direction: String?; let confidence: Int?; let entryPrice: Double?; let stopLoss: Double?; let takeProfit: Double?; let reason: String? }
            let response: GenResponse = try await APIClient.shared.request("/signals/generate/\(encoded)", method: "POST")
            if let data = response.data {
                signals.insert(SignalItem(
                    pair: data.pair ?? pair,
                    direction: data.direction == "BUY" ? "شراء" : data.direction == "SELL" ? "بيع" : "إمساك",
                    confidence: data.confidence,
                    entry: data.entryPrice,
                    sl: data.stopLoss,
                    tp: data.takeProfit,
                    reason: data.reason
                ), at: 0)
            }
        } catch {
            print("[Signals] Generate error: \(error.localizedDescription)")
        }
    }
}
