// =============================================================================
// NeuralLabView.swift — Roua Trading · Neural Lab
// =============================================================================
// Advanced AI/ML features: Backtest, Compare, Train Model, Predict, Swarm.
// Uses RouaColors, RouaTypography, RouaSpacing, and RouaComponents.
// Supports RTL layout, accessibility, and smooth animations.
// =============================================================================

import SwiftUI

// MARK: - Neural Lab Tab

enum NeuralLabTab: String, CaseIterable, Identifiable {
    case backtest = "اختبار راجع"
    case compare  = "مقارنة"
    case train    = "تدريب"
    case predict  = "تنبؤ"
    case swarm    = "سرب"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .backtest: return "chart.line.flattrend.xyaxis"
        case .compare:  return "arrow.left.arrow.right"
        case .train:    return "cpu"
        case .predict:  return "crystalball"
        case .swarm:    return "ant.cluster"
        }
    }
}

// MARK: - Neural Architecture

enum NeuralArchitecture: String, CaseIterable, Identifiable {
    case lstm        = "LSTM"
    case gru         = "GRU"
    case transformer = "TRANSFORMER"
    case ensemble    = "ENSEMBLE"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .lstm:        return "LSTM"
        case .gru:         return "GRU"
        case .transformer: return "Transformer"
        case .ensemble:    return "Ensemble"
        }
    }
}

// MARK: - Prediction Horizon

enum PredictionHorizon: String, CaseIterable, Identifiable {
    case oneHour   = "1h"
    case fourHour  = "4h"
    case oneDay    = "1d"
    case sevenDay  = "7d"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .oneHour:  return "ساعة واحدة"
        case .fourHour: return "4 ساعات"
        case .oneDay:   return "يوم واحد"
        case .sevenDay: return "7 أيام"
        }
    }
}

// MARK: - Neural Lab View

struct NeuralLabView: View {

    @StateObject private var viewModel = NeuralLabViewModel()
    @State private var selectedTab: NeuralLabTab = .backtest

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rouaBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Tab Bar
                    tabBar
                        .padding(.horizontal, RouaSpacing.screenPadding)
                        .padding(.top, RouaSpacing.md)

                    // Content
                    ScrollView(showsIndicators: false) {
                        Group {
                            switch selectedTab {
                            case .backtest: backtestTab
                            case .compare:  compareTab
                            case .train:    trainTab
                            case .predict:  predictTab
                            case .swarm:    swarmTab
                            }
                        }
                        .padding(.vertical, RouaSpacing.lg)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("المختبر العصبي")
                        .rouaFont(.headline, color: .rouaTextPrimary)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingView(message: viewModel.loadingMessage)
                }
            }
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RouaSpacing.xs) {
                ForEach(NeuralLabTab.allCases) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: RouaSpacing.animationFast)) {
                            selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: RouaSpacing.xs) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: RouaSpacing.iconSmall))
                            Text(tab.rawValue)
                                .rouaFont(.captionBold)
                        }
                        .padding(.horizontal, RouaSpacing.md)
                        .padding(.vertical, RouaSpacing.sm)
                        .background(
                            Capsule()
                                .fill(selectedTab == tab ? Color.rouaPrimary : Color.rouaSurfaceLight)
                        )
                        .foregroundStyle(selectedTab == tab ? .white : .rouaTextSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tab.rawValue)
                    .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
                }
            }
        }
    }
}

// MARK: - Backtest Tab

extension NeuralLabView {

    private var backtestTab: some View {
        VStack(spacing: RouaSpacing.lg) {
            // Configuration
            GlassCard {
                VStack(spacing: RouaSpacing.md) {
                    // Symbol picker
                    symbolPickerField(
                        title: "الرمز",
                        text: $viewModel.backtestSymbol,
                        placeholder: "مثال: BTC/USDT"
                    )

                    // Strategy selector
                    strategyPickerField

                    // Date range
                    HStack(spacing: RouaSpacing.md) {
                        dateField(title: "من", date: $viewModel.backtestStartDate)
                        dateField(title: "إلى", date: $viewModel.backtestEndDate)
                    }

                    // Initial capital
                    amountField(
                        title: "رأس المال الأولي",
                        text: $viewModel.backtestCapital,
                        placeholder: "10000"
                    )

                    // Run button
                    RouaButton(
                        "تشغيل الاختبار",
                        variant: .primary,
                        icon: "play.fill",
                        isLoading: viewModel.isBacktesting
                    ) {
                        Task { await viewModel.runBacktest() }
                    }
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)

            // Results
            if let result = viewModel.backtestResult {
                backtestResults(result)
            }
        }
    }

    private func backtestResults(_ result: BacktestResult) -> some View {
        VStack(spacing: RouaSpacing.lg) {
            // Key Metrics
            SectionHeader(title: "النتائج")

            GlassCard {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: RouaSpacing.lg) {
                    StatMini(
                        label: "العائد الإجمالي",
                        value: result.formattedTotalReturn,
                        change: result.totalReturn
                    )
                    StatMini(label: "نسبة الفوز", value: result.formattedWinRate)
                    StatMini(
                        label: "أقصى تراجع",
                        value: String(format: "%.1f%%", result.maxDrawdown * 100)
                    )
                    StatMini(
                        label: "نسبة شارب",
                        value: String(format: "%.2f", result.sharpeRatio)
                    )
                    StatMini(label: "إجمالي الصفقات", value: "\(result.totalTrades)")
                    StatMini(label: "صفقات رابحة", value: "\(result.winningTrades)")
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)

            // Equity Curve
            equityCurveView(result.equity)
                .padding(.horizontal, RouaSpacing.screenPadding)

            // Trade List
            if !result.trades.isEmpty {
                tradeListSection(result.trades)
            }
        }
    }

    private func equityCurveView(_ data: [Double]) -> some View {
        VStack(alignment: .leading, spacing: RouaSpacing.sm) {
            SectionHeader(title: "منحنى رأس المال")

            GlassCard {
                EquityCurveChart(data: data)
                    .frame(height: 180)
            }
        }
    }

    private func tradeListSection(_ trades: [BacktestTrade]) -> some View {
        VStack(spacing: RouaSpacing.sm) {
            SectionHeader(
                title: "الصفقات",
                actionTitle: "\(trades.count)"
            { }

            ForEach(trades.prefix(20)) { trade in
                GlassCard {
                    HStack(spacing: RouaSpacing.md) {
                        // Side
                        Badge(
                            text: trade.side.displayName,
                            variant: trade.side.isLong ? .success : .error
                        )

                        // Symbol + prices
                        VStack(alignment: .leading, spacing: 2) {
                            Text(trade.symbol)
                                .rouaFont(.footnoteBold, color: .rouaTextPrimary)
                            HStack(spacing: 4) {
                                Text(String(format: "%.2f", trade.entryPrice))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 8))
                                Text(String(format: "%.2f", trade.exitPrice))
                            }
                            .rouaFont(.monoSmall, color: .rouaTextTertiary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // PnL
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(trade.formattedPnl)
                                .rouaFont(.footnoteBold, color: .rouaPnLColor(value: trade.pnl))
                                .monospacedDigit()
                            Text(String(format: "%.1f%%", trade.pnlPct * 100))
                                .rouaFont(.micro, color: .rouaPnLColor(value: trade.pnl))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, RouaSpacing.screenPadding)
    }
}

// MARK: - Compare Tab

extension NeuralLabView {

    private var compareTab: some View {
        VStack(spacing: RouaSpacing.lg) {
            // Configuration
            GlassCard {
                VStack(spacing: RouaSpacing.md) {
                    symbolPickerField(
                        title: "الرمز",
                        text: $viewModel.compareSymbol,
                        placeholder: "مثال: BTC/USDT"
                    )

                    HStack(spacing: RouaSpacing.md) {
                        dateField(title: "من", date: $viewModel.compareStartDate)
                        dateField(title: "إلى", date: $viewModel.compareEndDate)
                    }

                    RouaButton(
                        "مقارنة جميع الاستراتيجيات",
                        variant: .primary,
                        icon: "arrow.left.arrow.right",
                        isLoading: viewModel.isComparing
                    ) {
                        Task { await viewModel.runComparison() }
                    }
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)

            // Results
            if let result = viewModel.compareResult {
                comparisonResults(result)
            }
        }
    }

    private func comparisonResults(_ result: CompareResult) -> some View {
        VStack(spacing: RouaSpacing.md) {
            SectionHeader(title: "نتائج المقارنة")

            if let best = result.bestStrategy, let bestResult = best.result {
                GlassCard(glow: .rouaProfit) {
                    HStack {
                        VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                            Text("أفضل استراتيجية")
                                .rouaFont(.caption, color: .rouaTextTertiary)
                            Text(best.strategy)
                                .rouaFont(.calloutBold, color: .rouaProfit)
                            Text(bestResult.formattedTotalReturn)
                                .rouaFont(.mono, color: .rouaProfit)
                                .monospacedDigit()
                        }
                        Spacer()
                        Image(systemName: "trophy.fill")
                            .font(.system(size: RouaSpacing.iconXXL))
                            .foregroundStyle(.rouaWarning)
                    }
                }
                .padding(.horizontal, RouaSpacing.screenPadding)
            }

            // Comparison table
            GlassCard {
                VStack(spacing: 0) {
                    // Header
                    HStack(spacing: RouaSpacing.sm) {
                        Text("الاستراتيجية")
                            .rouaFont(.captionBold, color: .rouaTextTertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("العائد")
                            .rouaFont(.captionBold, color: .rouaTextTertiary)
                            .frame(width: 70)
                        Text("الفوز")
                            .rouaFont(.captionBold, color: .rouaTextTertiary)
                            .frame(width: 50)
                        Text("التراجع")
                            .rouaFont(.captionBold, color: .rouaTextTertiary)
                            .frame(width: 50)
                    }
                    .padding(.bottom, RouaSpacing.sm)

                    Divider().background(Color.rouaGlassBorder)

                    ForEach(result.comparison) { item in
                        VStack(spacing: 0) {
                            HStack(spacing: RouaSpacing.sm) {
                                Text(item.strategy)
                                    .rouaFont(.footnote, color: .rouaTextPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                if let r = item.result {
                                    Text(r.formattedTotalReturn)
                                        .rouaFont(.monoSmall, color: .rouaPnLColor(value: r.totalReturn))
                                        .frame(width: 70)
                                    Text(r.formattedWinRate)
                                        .rouaFont(.monoSmall, color: .rouaTextSecondary)
                                        .frame(width: 50)
                                    Text(String(format: "%.1f%%", r.maxDrawdown * 100))
                                        .rouaFont(.monoSmall, color: .rouaTextSecondary)
                                        .frame(width: 50)
                                } else {
                                    Text(item.error ?? "خطأ")
                                        .rouaFont(.micro, color: .rouaLoss)
                                        .frame(width: 170)
                                }
                            }
                            .padding(.vertical, RouaSpacing.sm)

                            Divider().background(Color.rouaGlassBorder)
                        }
                    }
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
        }
    }
}

// MARK: - Train Tab

extension NeuralLabView {

    private var trainTab: some View {
        VStack(spacing: RouaSpacing.lg) {
            // Configuration
            GlassCard {
                VStack(spacing: RouaSpacing.md) {
                    symbolPickerField(
                        title: "الرمز",
                        text: $viewModel.trainSymbol,
                        placeholder: "مثال: BTC/USDT"
                    )

                    // Architecture selector
                    VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                        Text("البنية")
                            .rouaFont(.footnote, color: .rouaTextSecondary)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                        ], spacing: RouaSpacing.sm) {
                            ForEach(NeuralArchitecture.allCases) { arch in
                                Button {
                                    viewModel.trainArchitecture = arch
                                } label: {
                                    Text(arch.displayName)
                                        .rouaFont(
                                            viewModel.trainArchitecture == arch ? .footnoteBold : .footnote,
                                            color: viewModel.trainArchitecture == arch ? .rouaPrimary : .rouaTextSecondary
                                        )
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, RouaSpacing.sm)
                                        .background(
                                            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius)
                                                .fill(viewModel.trainArchitecture == arch
                                                      ? Color.rouaPrimary.opacity(0.2)
                                                      : Color.rouaSurfaceLight)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius)
                                                .stroke(viewModel.trainArchitecture == arch
                                                        ? Color.rouaPrimary
                                                        : Color.rouaGlassBorder,
                                                        lineWidth: viewModel.trainArchitecture == arch ? 1.5 : 0.5)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Horizon selector
                    VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                        Text("أفق التنبؤ")
                            .rouaFont(.footnote, color: .rouaTextSecondary)

                        Picker("أفق التنبؤ", selection: $viewModel.trainHorizon) {
                            ForEach(PredictionHorizon.allCases) { h in
                                Text(h.displayName).tag(h)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(.rouaPrimary)
                    }

                    // Train button
                    RouaButton(
                        "تدريب",
                        variant: .primary,
                        icon: "cpu",
                        isLoading: viewModel.isTraining
                    ) {
                        Task { await viewModel.trainModel() }
                    }
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)

            // Trained models
            trainedModelsList
        }
    }

    private var trainedModelsList: some View {
        VStack(spacing: RouaSpacing.sm) {
            SectionHeader(title: "النماذج المدربة")

            if viewModel.trainedModels.isEmpty {
                EmptyStateView(
                    icon: "cpu",
                    title: "لا توجد نماذج",
                    description: "قم بتدريب نموذجك الأول للبدء"
                )
            } else {
                ForEach(viewModel.trainedModels) { model in
                    GlassCard {
                        HStack(spacing: RouaSpacing.md) {
                            // Status indicator
                            PulsingDot(
                                status: model.isReady ? .active : .warning,
                                size: 8
                            )

                            // Model info
                            VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                                HStack(spacing: RouaSpacing.xs) {
                                    Text(model.symbol)
                                        .rouaFont(.calloutBold, color: .rouaTextPrimary)
                                    Badge(
                                        text: model.architecture,
                                        variant: .info
                                    )
                                }

                                HStack(spacing: RouaSpacing.md) {
                                    if let accuracy = model.formattedAccuracy {
                                        Text("الدقة: \(accuracy)")
                                            .rouaFont(.footnote, color: .rouaTextSecondary)
                                    }
                                    if let loss = model.loss {
                                        Text("الخسارة: \(String(format: "%.4f", loss))")
                                            .rouaFont(.footnote, color: .rouaTextSecondary)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            // Status badge
                            Badge(
                                text: model.status,
                                variant: model.isReady ? .success : .warning
                            )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, RouaSpacing.screenPadding)
    }
}

// MARK: - Predict Tab

extension NeuralLabView {

    private var predictTab: some View {
        VStack(spacing: RouaSpacing.lg) {
            // Configuration
            GlassCard {
                VStack(spacing: RouaSpacing.md) {
                    symbolPickerField(
                        title: "الرمز",
                        text: $viewModel.predictSymbol,
                        placeholder: "مثال: BTC/USDT"
                    )

                    // Steps
                    VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                        Text("عدد الخطوات (1-100)")
                            .rouaFont(.footnote, color: .rouaTextSecondary)

                        HStack(spacing: RouaSpacing.md) {
                            TextField("1", value: $viewModel.predictSteps, format: .number)
                                .textFieldStyle(.plain)
                                .rouaFont(.body, color: .rouaTextPrimary)
                                .keyboardType(.numberPad)
                                .padding(RouaSpacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius)
                                        .fill(Color.rouaSurfaceLight)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius)
                                        .stroke(Color.rouaGlassBorder, lineWidth: 1)
                                )

                            Stepper("", value: $viewModel.predictSteps, in: 1...100)
                                .labelsHidden()
                                .tint(.rouaPrimary)
                        }
                    }

                    // Predict button
                    RouaButton(
                        "تنبؤ",
                        variant: .primary,
                        icon: "crystalball",
                        isLoading: viewModel.isPredicting
                    ) {
                        Task { await viewModel.predict() }
                    }
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)

            // Prediction Results
            if let result = viewModel.predictionResult {
                predictionResults(result)
            }
        }
    }

    private func predictionResults(_ result: NeuralPredictResult) -> some View {
        VStack(spacing: RouaSpacing.lg) {
            // Summary
            SectionHeader(title: "نتائج التنبؤ")

            GlassCard {
                VStack(spacing: RouaSpacing.md) {
                    HStack {
                        StatMini(label: "الرمز", value: result.symbol)
                        if let confidence = result.confidence {
                            StatMini(
                                label: "الثقة",
                                value: String(format: "%.1f%%", confidence * 100)
                            )
                        }
                        if let finalPrice = result.finalPredictedPrice {
                            StatMini(
                                label: "السعر المتوقع",
                                value: String(format: "%.2f", finalPrice)
                            )
                        }
                    }

                    // Model badge
                    Badge(text: result.model, variant: .info)
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)

            // Prediction chart
            predictionChart(result.predictions)
                .padding(.horizontal, RouaSpacing.screenPadding)

            // Prediction table
            if !result.predictions.isEmpty {
                predictionTable(result.predictions)
            }
        }
    }

    private func predictionChart(_ points: [PredictionPoint]) -> some View {
        VStack(alignment: .leading, spacing: RouaSpacing.sm) {
            SectionHeader(title: "المسار المتوقع")

            GlassCard {
                PredictionChartView(points: points)
                    .frame(height: 200)
            }
        }
    }

    private func predictionTable(_ points: [PredictionPoint]) -> some View {
        VStack(spacing: RouaSpacing.sm) {
            SectionHeader(title: "نقاط التنبؤ")

            GlassCard {
                VStack(spacing: 0) {
                    // Header
                    HStack(spacing: RouaSpacing.sm) {
                        Text("الخطوة")
                            .rouaFont(.captionBold, color: .rouaTextTertiary)
                            .frame(width: 50)
                        Text("السعر")
                            .rouaFont(.captionBold, color: .rouaTextTertiary)
                            .frame(maxWidth: .infinity)
                        Text("أدنى")
                            .rouaFont(.captionBold, color: .rouaTextTertiary)
                            .frame(width: 70)
                        Text("أعلى")
                            .rouaFont(.captionBold, color: .rouaTextTertiary)
                            .frame(width: 70)
                    }
                    .padding(.bottom, RouaSpacing.sm)

                    Divider().background(Color.rouaGlassBorder)

                    ForEach(points.prefix(20)) { point in
                        VStack(spacing: 0) {
                            HStack(spacing: RouaSpacing.sm) {
                                Text("#\(point.time)")
                                    .rouaFont(.monoSmall, color: .rouaTextTertiary)
                                    .frame(width: 50)
                                Text(String(format: "%.2f", point.price))
                                    .rouaFont(.monoSmall, color: .rouaTextPrimary)
                                    .frame(maxWidth: .infinity)
                                if let lower = point.lower {
                                    Text(String(format: "%.2f", lower))
                                        .rouaFont(.monoSmall, color: .rouaLoss)
                                        .frame(width: 70)
                                } else {
                                    Text("—").frame(width: 70)
                                }
                                if let upper = point.upper {
                                    Text(String(format: "%.2f", upper))
                                        .rouaFont(.monoSmall, color: .rouaProfit)
                                        .frame(width: 70)
                                } else {
                                    Text("—").frame(width: 70)
                                }
                            }
                            .padding(.vertical, RouaSpacing.xs)

                            Divider().background(Color.rouaGlassBorder)
                        }
                    }
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
        }
    }
}

// MARK: - Swarm Tab

extension NeuralLabView {

    private var swarmTab: some View {
        VStack(spacing: RouaSpacing.lg) {
            // Configuration
            GlassCard {
                VStack(spacing: RouaSpacing.md) {
                    // Number of agents
                    VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                        Text("عدد الوكلاء")
                            .rouaFont(.footnote, color: .rouaTextSecondary)

                        HStack(spacing: RouaSpacing.md) {
                            TextField("3", value: $viewModel.swarmAgentCount, format: .number)
                                .textFieldStyle(.plain)
                                .rouaFont(.body, color: .rouaTextPrimary)
                                .keyboardType(.numberPad)
                                .padding(RouaSpacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius)
                                        .fill(Color.rouaSurfaceLight)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius)
                                        .stroke(Color.rouaGlassBorder, lineWidth: 1)
                                )

                            Stepper("", value: $viewModel.swarmAgentCount, in: 1...20)
                                .labelsHidden()
                                .tint(.rouaPrimary)
                        }
                    }

                    // Symbol(s)
                    symbolPickerField(
                        title: "الرمز(الرموز)",
                        text: $viewModel.swarmSymbols,
                        placeholder: "مثال: BTC/USDT, ETH/USDT"
                    )

                    // Risk tolerance
                    VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                        HStack {
                            Text("تحمل المخاطر")
                                .rouaFont(.footnote, color: .rouaTextSecondary)
                            Spacer()
                            Text(viewModel.riskToleranceLabel)
                                .rouaFont(.footnoteBold, color: .rouaPrimary)
                        }

                        Slider(value: $viewModel.swarmRiskTolerance, in: 0...1, step: 0.1)
                            .tint(.rouaPrimary)
                    }

                    // Start Swarm button
                    RouaButton(
                        "تشغيل السرب",
                        variant: .primary,
                        icon: "ant.cluster",
                        isLoading: viewModel.isStartingSwarm
                    ) {
                        Task { await viewModel.startSwarm() }
                    }
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)

            // Active swarms
            activeSwarmsList
        }
    }

    private var activeSwarmsList: some View {
        VStack(spacing: RouaSpacing.sm) {
            SectionHeader(title: "الأسراب النشطة")

            if viewModel.swarmResults.isEmpty {
                EmptyStateView(
                    icon: "ant.cluster",
                    title: "لا توجد أسراب",
                    description: "ابدأ سرب وكلاء للتجارة التلقائية"
                )
            } else {
                ForEach(viewModel.swarmResults) { swarm in
                    GlassCard {
                        HStack(spacing: RouaSpacing.md) {
                            // Status dot
                            PulsingDot(
                                status: swarm.isComplete ? .active : .warning,
                                size: 8
                            )

                            // Info
                            VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                                HStack(spacing: RouaSpacing.xs) {
                                    Text("سرب")
                                        .rouaFont(.calloutBold, color: .rouaTextPrimary)
                                    Badge(
                                        text: swarm.status,
                                        variant: swarm.isComplete ? .success : .warning
                                    )
                                }

                                HStack(spacing: RouaSpacing.md) {
                                    if let agents = swarm.agents?.count {
                                        Text("\(agents) وكلاء")
                                            .rouaFont(.footnote, color: .rouaTextSecondary)
                                    }
                                    if let trades = swarm.totalTrades {
                                        Text("\(trades) صفقة")
                                            .rouaFont(.footnote, color: .rouaTextSecondary)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            // PnL
                            if let pnl = swarm.totalPnl {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(swarm.formattedTotalPnl ?? "")
                                        .rouaFont(.calloutBold, color: .rouaPnLColor(value: pnl))
                                        .monospacedDigit()
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, RouaSpacing.screenPadding)
    }
}

// MARK: - Shared Form Fields

extension NeuralLabView {

    private func symbolPickerField(
        title: String,
        text: Binding<String>,
        placeholder: String
    ) -> some View {
        VStack(alignment: .leading, spacing: RouaSpacing.xs) {
            Text(title)
                .rouaFont(.footnote, color: .rouaTextSecondary)
            TextField(placeholder, text: text)
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
    }

    private func amountField(
        title: String,
        text: Binding<String>,
        placeholder: String
    ) -> some View {
        VStack(alignment: .leading, spacing: RouaSpacing.xs) {
            Text(title)
                .rouaFont(.footnote, color: .rouaTextSecondary)
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .rouaFont(.mono, color: .rouaTextPrimary)
                .keyboardType(.decimalPad)
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
    }

    private func dateField(title: String, date: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: RouaSpacing.xs) {
            Text(title)
                .rouaFont(.footnote, color: .rouaTextSecondary)
            DatePicker("", selection: date, displayedComponents: .date)
                .labelsHidden()
                .tint(.rouaPrimary)
        }
    }

    private var strategyPickerField: some View {
        VStack(alignment: .leading, spacing: RouaSpacing.xs) {
            Text("الاستراتيجية")
                .rouaFont(.footnote, color: .rouaTextSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: RouaSpacing.xs) {
                    ForEach(AgentStrategy.allCases, id: \.self) { strategy in
                        Button {
                            viewModel.backtestStrategy = strategy
                        } label: {
                            Text(strategy.displayName)
                                .rouaFont(
                                    viewModel.backtestStrategy == strategy ? .footnoteBold : .footnote,
                                    color: viewModel.backtestStrategy == strategy ? .rouaPrimary : .rouaTextSecondary
                                )
                                .padding(.horizontal, RouaSpacing.md)
                                .padding(.vertical, RouaSpacing.xs)
                                .background(
                                    Capsule()
                                        .fill(viewModel.backtestStrategy == strategy
                                              ? Color.rouaPrimary.opacity(0.2)
                                              : Color.rouaSurfaceLight)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(viewModel.backtestStrategy == strategy
                                                ? Color.rouaPrimary
                                                : Color.clear,
                                                lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Equity Curve Chart

struct EquityCurveChart: View {
    let data: [Double]

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let minY = data.min() ?? 0
            let maxY = data.max() ?? 1
            let range = max(maxY - minY, 0.001)

            Path { path in
                guard !data.isEmpty else { return }

                for (index, value) in data.enumerated() {
                    let x = width * CGFloat(index) / CGFloat(max(data.count - 1, 1))
                    let y = height - (height * CGFloat(value - minY) / CGFloat(range))

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(
                LinearGradient(
                    colors: [.rouaPrimary, .rouaAccent],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 2
            )

            // Gradient fill under curve
            Path { path in
                guard !data.isEmpty else { return }

                for (index, value) in data.enumerated() {
                    let x = width * CGFloat(index) / CGFloat(max(data.count - 1, 1))
                    let y = height - (height * CGFloat(value - minY) / CGFloat(range))

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }

                // Close the path along the bottom
                if let lastX = data.indices.last {
                    let x = width * CGFloat(lastX) / CGFloat(max(data.count - 1, 1))
                    path.addLine(to: CGPoint(x: x, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height))
                    path.closeSubpath()
                }
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
}

// MARK: - Prediction Chart View

struct PredictionChartView: View {
    let points: [PredictionPoint]

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let allPrices = points.map(\.price)
                + (points.compactMap(\.lower))
                + (points.compactMap(\.upper))
            let minY = allPrices.min() ?? 0
            let maxY = allPrices.max() ?? 1
            let range = max(maxY - minY, 0.001)

            ZStack {
                // Confidence interval band
                confidenceBand(
                    width: width, height: height,
                    minY: minY, range: range
                )

                // Upper bound
                boundLine(
                    keyPath: \.upper,
                    width: width, height: height,
                    minY: minY, range: range,
                    color: .rouaLoss.opacity(0.5)
                )

                // Lower bound
                boundLine(
                    keyPath: \.lower,
                    width: width, height: height,
                    minY: minY, range: range,
                    color: .rouaProfit.opacity(0.5)
                )

                // Main prediction line
                Path { path in
                    for (index, point) in points.enumerated() {
                        let x = width * CGFloat(index) / CGFloat(max(points.count - 1, 1))
                        let y = height - (height * CGFloat(point.price - minY) / CGFloat(range))

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.rouaPrimary, lineWidth: 2)
            }
        }
    }

    private func confidenceBand(
        width: CGFloat, height: CGFloat,
        minY: Double, range: Double
    ) -> some View {
        Path { path in
            // Upper edge (forward)
            for (index, point) in points.enumerated() {
                guard let upper = point.upper else { return }
                let x = width * CGFloat(index) / CGFloat(max(points.count - 1, 1))
                let y = height - (height * CGFloat(upper - minY) / CGFloat(range))
                if index == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            // Lower edge (reverse)
            for (index, point) in points.enumerated().reversed() {
                guard let lower = point.lower else { return }
                let x = width * CGFloat(index) / CGFloat(max(points.count - 1, 1))
                let y = height - (height * CGFloat(lower - minY) / CGFloat(range))
                path.addLine(to: CGPoint(x: x, y: y))
            }
            path.closeSubpath()
        }
        .fill(Color.rouaPrimary.opacity(0.1))
    }

    private func boundLine(
        keyPath: KeyPath<PredictionPoint, Double?>,
        width: CGFloat, height: CGFloat,
        minY: Double, range: Double,
        color: Color
    ) -> some View {
        Path { path in
            var started = false
            for (index, point) in points.enumerated() {
                guard let value = point[keyPath: keyPath] else { continue }
                let x = width * CGFloat(index) / CGFloat(max(points.count - 1, 1))
                let y = height - (height * CGFloat(value - minY) / CGFloat(range))
                if !started {
                    path.move(to: CGPoint(x: x, y: y))
                    started = true
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
        .stroke(color, lineWidth: 1, style: StrokeStyle(lineCap: .round, dash: [4, 4]))
    }
}

// MARK: - Neural Lab View Model

@MainActor
final class NeuralLabViewModel: ObservableObject {

    // Backtest
    @Published var backtestSymbol = ""
    @Published var backtestStrategy: AgentStrategy = .auto
    @Published var backtestStartDate = Date().addingTimeInterval(-30 * 86_400)
    @Published var backtestEndDate = Date()
    @Published var backtestCapital = "10000"
    @Published var backtestResult: BacktestResult?
    @Published var isBacktesting = false

    // Compare
    @Published var compareSymbol = ""
    @Published var compareStartDate = Date().addingTimeInterval(-30 * 86_400)
    @Published var compareEndDate = Date()
    @Published var compareResult: CompareResult?
    @Published var isComparing = false

    // Train
    @Published var trainSymbol = ""
    @Published var trainArchitecture: NeuralArchitecture = .lstm
    @Published var trainHorizon: PredictionHorizon = .oneDay
    @Published var trainedModels: [NeuralModelInfo] = []
    @Published var isTraining = false

    // Predict
    @Published var predictSymbol = ""
    @Published var predictSteps: Int = 10
    @Published var predictionResult: NeuralPredictResult?
    @Published var isPredicting = false

    // Swarm
    @Published var swarmAgentCount: Int = 3
    @Published var swarmSymbols = ""
    @Published var swarmRiskTolerance: Double = 0.5
    @Published var swarmResults: [SwarmResult] = []
    @Published var isStartingSwarm = false

    // General
    @Published var isLoading = false
    @Published var loadingMessage: String? = nil

    var riskToleranceLabel: String {
        switch swarmRiskTolerance {
        case 0..<0.3: return "منخفض"
        case 0.3..<0.7: return "متوسط"
        default: return "عالي"
        }
    }

    func runBacktest() async {
        isBacktesting = true
        loadingMessage = "جاري تشغيل الاختبار..."
        isLoading = true
        // TODO: Call API service
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        isLoading = false
        isBacktesting = false
        loadingMessage = nil
    }

    func runComparison() async {
        isComparing = true
        loadingMessage = "جاري المقارنة..."
        isLoading = true
        // TODO: Call API service
        try? await Task.sleep(nanoseconds: 2_500_000_000)
        isLoading = false
        isComparing = false
        loadingMessage = nil
    }

    func trainModel() async {
        isTraining = true
        loadingMessage = "جاري تدريب النموذج..."
        isLoading = true
        // TODO: Call API service
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        isLoading = false
        isTraining = false
        loadingMessage = nil
    }

    func predict() async {
        isPredicting = true
        loadingMessage = "جاري التنبؤ..."
        isLoading = true
        // TODO: Call API service
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        isLoading = false
        isPredicting = false
        loadingMessage = nil
    }

    func startSwarm() async {
        isStartingSwarm = true
        loadingMessage = "جاري تشغيل السرب..."
        isLoading = true
        // TODO: Call API service
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        isLoading = false
        isStartingSwarm = false
        loadingMessage = nil
    }
}

// MARK: - Preview

#Preview("Neural Lab") {
    NeuralLabView()
}
