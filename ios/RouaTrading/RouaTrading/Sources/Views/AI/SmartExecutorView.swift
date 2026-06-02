// =============================================================================
// SmartExecutorView.swift — Roua Trading · Smart Executor Control Panel
// =============================================================================
// Status hero card, enable/disable toggle, configuration, emergency stop,
// positions list, exposure summary, and collapsible debug info.
// Uses AIViewModel.
// =============================================================================

import SwiftUI

struct SmartExecutorView: View {

    // MARK: - Dependencies

    @ObservedObject var viewModel: AIViewModel

    // MARK: - State

    @State private var showEmergencyConfirm = false
    @State private var showDebugInfo = false
    @State private var showConfigSheet = false

    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaSpacing.lg) {
                // Status hero card
                statusHeroCard

                // Enable/Disable toggle
                toggleSection

                // Configuration card
                configurationCard

                // Emergency stop button
                emergencyStopButton

                // Positions list
                if !viewModel.executorPositions.isEmpty {
                    SectionHeader(title: "المراكز المفتوحة")
                    positionsList
                }

                // Exposure summary
                exposureSummaryCard

                // Debug info (collapsible)
                debugSection

                // Bottom spacer
                Color.clear.frame(height: RouaSpacing.xxxl)
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
            .padding(.vertical, RouaSpacing.md)
        }
        .alert("إيقاف طوارئ", isPresented: $showEmergencyConfirm) {
            Button("إلغاء", role: .cancel) {}
            Button("إيقاف فوري", role: .destructive) {
                viewModel.emergencyStop()
            }
        } message: {
            Text("هل أنت متأكد؟ سيتم إغلاق جميع المراكز المفتوحة فوراً.")
        }
        .sheet(isPresented: $showConfigSheet) {
            ExecutorConfigSheet(viewModel: viewModel)
        }
    }

    // MARK: - Status Hero Card

    private var statusHeroCard: some View {
        GlassCard(glow: viewModel.executorStatus?.isActive == true ? .rouaProfit : nil) {
            VStack(spacing: RouaSpacing.lg) {
                // Active/Inactive indicator
                HStack(spacing: RouaSpacing.md) {
                    PulsingDot(
                        status: viewModel.executorStatus?.isActive == true ? .active : .inactive,
                        size: 16
                    )

                    VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                        Text(viewModel.executorStatus?.isActive == true ? "المنفذ نشط" : "المنفذ متوقف")
                            .rouaFont(.title3, color: .rouaTextPrimary)
                        if let mode = viewModel.executorStatus?.mode {
                            Text("الوضع: \(mode)")
                                .rouaFont(.subheadline, color: .rouaTextSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Badge(
                        text: viewModel.executorStatus?.isActive == true ? "نشط" : "متوقف",
                        variant: viewModel.executorStatus?.isActive == true ? .success : .neutral
                    )
                }

                Divider()
                    .background(Color.rouaGlassBorder)

                // Stats grid
                HStack(spacing: 0) {
                    StatMini(
                        label: "المراكز",
                        value: "\(viewModel.executorStatus?.totalPositions ?? 0)"
                    )
                    .frame(maxWidth: .infinity)

                    StatMini(
                        label: "إجمالي P&L",
                        value: viewModel.executorStatus?.formattedTotalPnl ?? "$0.00",
                        change: viewModel.executorStatus?.totalPnl
                    )
                    .frame(maxWidth: .infinity)

                    StatMini(
                        label: "يومي P&L",
                        value: viewModel.executorStatus?.formattedDailyPnl ?? "$0.00",
                        change: viewModel.executorStatus?.dailyPnl
                    )
                    .frame(maxWidth: .infinity)
                }

                // Win rate + uptime
                HStack {
                    if let winRate = viewModel.executorStatus?.winRate {
                        StatMini(
                            label: "نسبة الفوز",
                            value: String(format: "%.1f%%", winRate * 100)
                        )
                    }
                    Spacer()
                    if let uptime = viewModel.executorStatus?.formattedUptime {
                        StatMini(
                            label: "مدة التشغيل",
                            value: uptime
                        )
                    }
                }
            }
        }
    }

    // MARK: - Toggle Section

    private var toggleSection: some View {
        GlassCard {
            HStack(spacing: RouaSpacing.lg) {
                VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                    Text(viewModel.executorState?.enabled == true ? "المنفذ مفعّل" : "تفعيل المنفذ")
                        .rouaFont(.calloutBold, color: .rouaTextPrimary)
                    Text("السماح بالتداول التلقائي")
                        .rouaFont(.caption, color: .rouaTextTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Toggle("", isOn: Binding(
                    get: { viewModel.executorState?.enabled ?? false },
                    set: { newValue in
                        viewModel.toggleExecutor(enabled: newValue)
                    }
                ))
                .tint(.rouaProfit)
                .labelsHidden()
                .scaleEffect(1.2)
                .accessibilityLabel("Toggle executor")
            }
        }
    }

    // MARK: - Configuration Card

    private var configurationCard: some View {
        GlassCard(action: { showConfigSheet = true }) {
            VStack(spacing: RouaSpacing.md) {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: RouaSpacing.iconMedium))
                        .foregroundStyle(.rouaPrimary)
                    Text("الإعدادات")
                        .rouaFont(.calloutBold, color: .rouaTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.left")
                        .font(.system(size: RouaSpacing.iconSmall))
                        .foregroundStyle(.rouaTextTertiary)
                }

                HStack(spacing: RouaSpacing.xxxl) {
                    VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                        Text("أقصى مراكز")
                            .rouaFont(.caption, color: .rouaTextTertiary)
                        Text("\(viewModel.executorState?.maxOpenPositions ?? 3)")
                            .rouaFont(.calloutBold, color: .rouaTextPrimary)
                            .monospacedDigit()
                    }

                    VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                        Text("مخاطر لكل صفقة")
                            .rouaFont(.caption, color: .rouaTextTertiary)
                        Text(String(format: "%.1f%%", viewModel.executorState?.riskPerTradePercent ?? 1.0))
                            .rouaFont(.calloutBold, color: .rouaTextPrimary)
                            .monospacedDigit()
                    }

                    Spacer()
                }
            }
        }
    }

    // MARK: - Emergency Stop Button

    private var emergencyStopButton: some View {
        RouaButton(
            "إيقاف طوارئ",
            variant: .danger,
            size: .large,
            icon: "exclamationmark.octagon",
            action: { showEmergencyConfirm = true }
        )
        .accessibilityLabel("Emergency stop all positions")
    }

    // MARK: - Positions List

    private var positionsList: some View {
        VStack(spacing: RouaSpacing.sm) {
            ForEach(viewModel.executorPositions) { position in
                ExecutorPositionRow(position: position)
            }
        }
    }

    // MARK: - Exposure Summary Card

    private var exposureSummaryCard: some View {
        GlassCard {
            VStack(spacing: RouaSpacing.md) {
                SectionHeader(title: "ملخص التعرض")

                HStack(spacing: RouaSpacing.lg) {
                    StatMini(
                        label: "إجمالي التعرض",
                        value: String(format: "$%.2f", viewModel.executorExposure?.totalExposure ?? 0)
                    )
                    .frame(maxWidth: .infinity)

                    StatMini(
                        label: "أكبر مركز",
                        value: String(format: "$%.2f", viewModel.executorExposure?.largestPosition ?? 0)
                    )
                    .frame(maxWidth: .infinity)
                }

                // Concentration risk
                HStack {
                    Text("مخاطر التركز")
                        .rouaFont(.caption, color: .rouaTextTertiary)
                    Spacer()
                    Badge(
                        text: viewModel.executorExposure?.concentrationRiskLabel ?? "N/A",
                        variant: concentrationRiskVariant
                    )
                }

                // Visual risk bar
                if let risk = viewModel.executorExposure?.concentrationRisk {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(Color.rouaSurfaceHover)
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(concentrationRiskColor)
                                .frame(
                                    width: geo.size.width * min(risk, 1.0),
                                    height: 4
                                )
                        }
                    }
                    .frame(height: 4)
                }
            }
        }
    }

    // MARK: - Debug Section

    private var debugSection: some View {
        VStack(spacing: RouaSpacing.sm) {
            Button {
                withAnimation(.easeInOut(duration: RouaSpacing.animationFast)) {
                    showDebugInfo.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "ladybug")
                        .font(.system(size: RouaSpacing.iconSmall))
                        .foregroundStyle(.rouaTextTertiary)
                    Text("معلومات التصحيح")
                        .rouaFont(.caption, color: .rouaTextTertiary)
                    Spacer()
                    Image(systemName: showDebugInfo ? "chevron.up" : "chevron.down")
                        .font(.system(size: RouaSpacing.iconSmall))
                        .foregroundStyle(.rouaTextTertiary)
                }
            }
            .buttonStyle(.plain)

            if showDebugInfo {
                GlassCard {
                    VStack(alignment: .leading, spacing: RouaSpacing.sm) {
                        DebugRow(label: "النشاط الأخير", value: viewModel.executorStatus?.lastActivity ?? "—")
                        DebugRow(label: "مدة التشغيل", value: viewModel.executorStatus?.formattedUptime ?? "—")
                        DebugRow(label: "عدد المراكز", value: "\(viewModel.executorPositions.count)")
                        DebugRow(label: "تنفيذ تلقائي", value: (viewModel.executorState?.autoExecuteSignals ?? false) ? "نعم" : "لا")
                    }
                }
            }
        }
    }

    // MARK: - Computed

    private var concentrationRiskVariant: BadgeVariant {
        switch viewModel.executorExposure?.concentrationRisk ?? 0 {
        case ..<0.3: return .success
        case 0.3..<0.6: return .warning
        default: return .error
        }
    }

    private var concentrationRiskColor: Color {
        switch viewModel.executorExposure?.concentrationRisk ?? 0 {
        case ..<0.3: return .rouaProfit
        case 0.3..<0.6: return .rouaWarning
        default: return .rouaLoss
        }
    }
}

// MARK: - Executor Position Row

private struct ExecutorPositionRow: View {

    let position: SmartExecutorPosition

    private var pnlColor: Color {
        .rouaPnLColor(value: position.unrealizedPnl)
    }

    var body: some View {
        GlassCard {
            HStack(spacing: RouaSpacing.md) {
                // Symbol + side
                VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                    Text(position.symbol)
                        .rouaFont(.calloutBold, color: .rouaTextPrimary)
                        .lineLimit(1)
                    Badge(
                        text: position.side.displayName,
                        variant: position.side.isLong ? .success : .error
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Entry → Current
                VStack(alignment: .center, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(String(format: "%.2f", position.entryPrice))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 8))
                        Text(String(format: "%.2f", position.currentPrice))
                    }
                    .rouaFont(.monoSmall, color: .rouaTextSecondary)
                    .monospacedDigit()

                    Text("×\(String(format: "%.4f", position.quantity))")
                        .rouaFont(.caption, color: .rouaTextTertiary)
                        .monospacedDigit()
                }

                // PnL
                VStack(alignment: .trailing, spacing: 2) {
                    Text(position.formattedPnl)
                        .rouaFont(.calloutBold, color: pnlColor)
                        .monospacedDigit()
                    if let sl = position.stopLoss {
                        Text("SL: \(String(format: "%.2f", sl))")
                            .rouaFont(.caption, color: .rouaTextTertiary)
                            .monospacedDigit()
                    }
                }
            }
        }
    }
}

// MARK: - Debug Row

private struct DebugRow: View {

    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .rouaFont(.caption, color: .rouaTextTertiary)
            Spacer()
            Text(value)
                .rouaFont(.monoSmall, color: .rouaTextSecondary)
        }
    }
}

// MARK: - Executor Config Sheet

struct ExecutorConfigSheet: View {

    @ObservedObject var viewModel: AIViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var maxPositions: Double = 3
    @State private var riskPercent: Double = 1.0
    @State private var autoExecute: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: RouaSpacing.xxl) {
                // Max positions slider
                VStack(alignment: .leading, spacing: RouaSpacing.sm) {
                    Text("أقصى عدد مراكز")
                        .rouaFont(.subheadlineBold, color: .rouaTextPrimary)
                    HStack {
                        Text("1")
                            .rouaFont(.caption, color: .rouaTextTertiary)
                        Slider(value: $maxPositions, in: 1...10, step: 1)
                            .tint(.rouaPrimary)
                        Text("10")
                            .rouaFont(.caption, color: .rouaTextTertiary)
                    }
                    Text("\(Int(maxPositions)) مراكز")
                        .rouaFont(.calloutBold, color: .rouaPrimary)
                        .monospacedDigit()
                }

                // Risk per trade slider
                VStack(alignment: .leading, spacing: RouaSpacing.sm) {
                    Text("مخاطر لكل صفقة %")
                        .rouaFont(.subheadlineBold, color: .rouaTextPrimary)
                    HStack {
                        Text("0.5%")
                            .rouaFont(.caption, color: .rouaTextTertiary)
                        Slider(value: $riskPercent, in: 0.5...5.0, step: 0.5)
                            .tint(.rouaPrimary)
                        Text("5%")
                            .rouaFont(.caption, color: .rouaTextTertiary)
                    }
                    Text(String(format: "%.1f%%", riskPercent))
                        .rouaFont(.calloutBold, color: .rouaPrimary)
                        .monospacedDigit()
                }

                // Auto-execute toggle
                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                            Text("تنفيذ تلقائي للإشارات")
                                .rouaFont(.calloutBold, color: .rouaTextPrimary)
                            Text("تنفيذ الإشارات تلقائياً عند صدورها")
                                .rouaFont(.caption, color: .rouaTextTertiary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Toggle("", isOn: $autoExecute)
                            .tint(.rouaProfit)
                            .labelsHidden()
                    }
                }

                Spacer()

                // Save button
                RouaButton(
                    "حفظ الإعدادات",
                    variant: .primary,
                    size: .large,
                    icon: "checkmark"
                ) {
                    viewModel.updateExecutorConfig(
                        maxPositions: Int(maxPositions),
                        riskPercent: riskPercent,
                        autoExecute: autoExecute
                    )
                    dismiss()
                }
            }
            .padding(RouaSpacing.screenPadding)
            .background(Color.rouaBackground)
            .navigationTitle("إعدادات المنفذ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("إلغاء") { dismiss() }
                        .foregroundStyle(.rouaTextSecondary)
                }
            }
        }
        .onAppear {
            maxPositions = Double(viewModel.executorState?.maxOpenPositions ?? 3)
            riskPercent = viewModel.executorState?.riskPerTradePercent ?? 1.0
            autoExecute = viewModel.executorState?.autoExecuteSignals ?? false
        }
    }
}

// MARK: - Preview

#Preview("SmartExecutorView") {
    SmartExecutorView(viewModel: AIViewModel())
}
