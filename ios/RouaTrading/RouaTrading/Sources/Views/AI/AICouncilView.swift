// =============================================================================
// AICouncilView.swift — Roua Trading · Strategic Council Experience
// =============================================================================
// Active briefs list with cards, direction badges, confidence bars,
// model votes breakdown, status badges, and session trigger.
// Uses AIViewModel.
// =============================================================================

import SwiftUI

struct AICouncilView: View {

    // MARK: - Dependencies

    @ObservedObject var viewModel: AIViewModel

    // MARK: - State

    @State private var expandedBriefId: String? = nil
    @State private var showNewSessionSheet = false
    @State private var selectedPairs: Set<String> = []
    @State private var isTriggering = false

    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaSpacing.lg) {
                // Session status
                sessionStatusCard

                // Trigger new session button
                triggerSessionButton

                // Active briefs
                SectionHeader(
                    title: "التحليلات النشطة",
                    actionTitle: viewModel.councilBriefs.isEmpty ? nil : "الكل",
                    action: {}
                )

                if viewModel.councilBriefs.isEmpty {
                    EmptyStateView(
                        icon: "brain.head.profile",
                        title: "لا توجد تحليلات",
                        description: "ابدأ جلسة جديدة لتلقي تحليلات الذكاء الاصطناعي"
                    )
                    .padding(.vertical, RouaSpacing.xxxl)
                } else {
                    ForEach(viewModel.councilBriefs) { brief in
                        BriefCard(
                            brief: brief,
                            isExpanded: expandedBriefId == brief.id,
                            onToggle: {
                                withAnimation(.easeInOut(duration: RouaSpacing.animationFast)) {
                                    expandedBriefId = expandedBriefId == brief.id ? nil : brief.id
                                }
                            }
                        )
                    }
                }

                // Briefs history
                if !viewModel.briefHistory.isEmpty {
                    SectionHeader(title: "السجل")

                    ForEach(viewModel.briefHistory) { brief in
                        BriefCard(
                            brief: brief,
                            isExpanded: expandedBriefId == brief.id,
                            onToggle: {
                                withAnimation(.easeInOut(duration: RouaSpacing.animationFast)) {
                                    expandedBriefId = expandedBriefId == brief.id ? nil : brief.id
                                }
                            }
                        )
                        .opacity(0.7)
                    }
                }

                // Bottom spacer for scroll content
                Color.clear.frame(height: RouaSpacing.xxxl)
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
            .padding(.vertical, RouaSpacing.md)
        }
        .sheet(isPresented: $showNewSessionSheet) {
            NewSessionSheet(
                selectedPairs: $selectedPairs,
                isTriggering: $isTriggering,
                onTrigger: triggerNewSession
            )
        }
    }

    // MARK: - Session Status Card

    private var sessionStatusCard: some View {
        GlassCard(glow: viewModel.councilSession?.isRunning == true ? .rouaProfit : nil) {
            HStack(spacing: RouaSpacing.md) {
                PulsingDot(
                    status: viewModel.councilSession?.isRunning == true ? .active : .inactive,
                    size: 12
                )

                VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                    Text(viewModel.councilSession?.isRunning == true ? "المجلس نشط" : "المجلس غير نشط")
                        .rouaFont(.calloutBold, color: .rouaTextPrimary)
                    if let lastSession = viewModel.councilSession?.lastSession {
                        Text("آخر جلسة: \(lastSession)")
                            .rouaFont(.caption, color: .rouaTextTertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if viewModel.councilSession?.isRunning == true {
                    Badge(text: "نشط", variant: .success)
                }
            }
        }
    }

    // MARK: - Trigger Session Button

    private var triggerSessionButton: some View {
        RouaButton(
            "تفعيل جلسة جديدة",
            variant: .primary,
            size: .large,
            icon: "bolt.horizontal",
            isLoading: isTriggering,
            action: { showNewSessionSheet = true }
        )
    }

    // MARK: - Actions

    private func triggerNewSession() {
        isTriggering = true
        let pairs = Array(selectedPairs)
        Task { await viewModel.triggerCouncil(pairs: pairs.isEmpty ? ["BTCUSDT"] : pairs) }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            isTriggering = false
            showNewSessionSheet = false
            selectedPairs.removeAll()
        }
    }
}

// MARK: - Brief Card

private struct BriefCard: View {

    let brief: Brief
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        GlassCard(action: onToggle) {
            VStack(spacing: RouaSpacing.md) {
                // Top: Symbol + Direction + Status
                HStack {
                    // Symbol avatar
                    Text(String(brief.symbol.prefix(2)))
                        .rouaFont(.captionBold, color: .rouaTextPrimary)
                        .frame(width: 36, height: 36)
                        .background(directionColor.opacity(0.2))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(brief.symbol)
                            .rouaFont(.calloutBold, color: .rouaTextPrimary)
                            .lineLimit(1)
                        Text(brief.source)
                            .rouaFont(.caption, color: .rouaTextTertiary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    DirectionBadge(direction: brief.direction)
                    StatusBadge(status: brief.status)
                }

                // Confidence bar
                VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                    HStack {
                        Text("الثقة")
                            .rouaFont(.caption, color: .rouaTextTertiary)
                        Spacer()
                        Text("\(brief.confidence)%")
                            .rouaFont(.captionBold, color: confidenceColor)
                            .monospacedDigit()
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(Color.rouaSurfaceHover)
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(directionColor)
                                .frame(
                                    width: geo.size.width * CGFloat(brief.confidence) / 100.0,
                                    height: 4
                                )
                        }
                    }
                    .frame(height: 4)
                }

                // Summary
                Text(brief.analysis)
                    .rouaFont(.subheadline, color: .rouaTextSecondary)
                    .lineLimit(isExpanded ? nil : 2)

                // Time remaining
                if let expiresAt = brief.expiresAt, brief.status == .active {
                    HStack(spacing: RouaSpacing.xs) {
                        Image(systemName: "clock")
                            .font(.system(size: RouaSpacing.iconSmall))
                            .foregroundStyle(.rouaTextTertiary)
                        Text("ينتهي: \(expiresAt)")
                            .rouaFont(.caption, color: .rouaTextTertiary)
                    }
                }

                // Expanded: Model votes breakdown
                if isExpanded && !brief.models.isEmpty {
                    Divider()
                        .background(Color.rouaGlassBorder)

                    Text("تصويت النماذج")
                        .rouaFont(.footnoteBold, color: .rouaTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(brief.models) { model in
                        ModelAnalysisRow(model: model)
                    }
                }
            }
        }
    }

    // MARK: - Computed

    private var directionColor: Color {
        switch brief.direction {
        case .bullish:  return .rouaProfit
        case .bearish:  return .rouaLoss
        case .neutral:  return .rouaNeutral
        }
    }

    private var confidenceColor: Color {
        switch brief.confidence {
        case 80...100: return .rouaProfit
        case 50..<80:  return .rouaWarning
        default:       return .rouaLoss
        }
    }
}

// MARK: - Direction Badge

private struct DirectionBadge: View {

    let direction: BriefDirection

    private var color: Color {
        switch direction {
        case .bullish: return .rouaProfit
        case .bearish: return .rouaLoss
        case .neutral: return .rouaNeutral
        }
    }

    private var bgColor: Color {
        switch direction {
        case .bullish: return .rouaProfitLight
        case .bearish: return .rouaLossLight
        case .neutral: return .rouaNeutral.opacity(0.15)
        }
    }

    private var icon: String {
        switch direction {
        case .bullish: return "arrowtriangle.up.fill"
        case .bearish: return "arrowtriangle.down.fill"
        case .neutral: return "minus"
        }
    }

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text(direction.displayName)
                .rouaFont(.micro)
        }
        .foregroundStyle(color)
        .padding(.horizontal, RouaSpacing.sm)
        .padding(.vertical, 3)
        .background(Capsule().fill(bgColor))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Direction: \(direction.displayName)")
    }
}

// MARK: - Status Badge (Brief)

private struct StatusBadge: View {

    let status: BriefStatus

    private var variant: BadgeVariant {
        switch status {
        case .active:    return .success
        case .expired:   return .neutral
        case .executed:  return .info
        case .dismissed: return .warning
        }
    }

    var body: some View {
        Badge(text: status.displayName, variant: variant)
    }
}

// MARK: - Model Analysis Row

private struct ModelAnalysisRow: View {

    let model: ModelAnalysis

    var body: some View {
        HStack(spacing: RouaSpacing.sm) {
            Text(String(model.model.prefix(1)))
                .rouaFont(.captionBold, color: .rouaTextPrimary)
                .frame(width: 24, height: 24)
                .background(Color.rouaSurfaceLight)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(model.model)
                    .rouaFont(.footnoteBold, color: .rouaTextPrimary)
                    .lineLimit(1)
                Text(model.reasoning)
                    .rouaFont(.caption, color: .rouaTextSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Confidence mini bar
            MiniConfidenceBar(value: model.confidence)
        }
        .padding(.vertical, RouaSpacing.xs)
    }
}

// MARK: - Mini Confidence Bar

private struct MiniConfidenceBar: View {

    let value: Int

    private var color: Color {
        switch value {
        case 80...100: return .rouaProfit
        case 50..<80:  return .rouaPrimary
        default:       return .rouaWarning
        }
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(value)%")
                .rouaFont(.captionBold, color: color)
                .monospacedDigit()

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 1, style: .continuous)
                        .fill(Color.rouaSurfaceHover)
                    RoundedRectangle(cornerRadius: 1, style: .continuous)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(value) / 100.0)
                }
            }
            .frame(width: 50, height: 3)
        }
        .frame(width: 60)
    }
}

// MARK: - New Session Sheet

private struct NewSessionSheet: View {

    @Binding var selectedPairs: Set<String>
    @Binding var isTriggering: Bool
    let onTrigger: () -> Void

    private let popularPairs = [
        "BTCUSDT", "ETHUSDT", "BNBUSDT", "XRPUSDT",
        "SOLUSDT", "ADAUSDT", "DOGEUSDT", "EURUSD",
        "GBPUSD", "XAUUSD"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: RouaSpacing.lg) {
                // Info text
                Text("اختر الأزواج التي تريد تحليلها بواسطة المجلس")
                    .rouaFont(.subheadline, color: .rouaTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, RouaSpacing.screenPadding)

                // Pairs grid
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                        ],
                        spacing: RouaSpacing.sm
                    ) {
                        ForEach(popularPairs, id: \.self) { pair in
                            Button {
                                if selectedPairs.contains(pair) {
                                    selectedPairs.remove(pair)
                                } else {
                                    selectedPairs.insert(pair)
                                }
                            } label: {
                                HStack(spacing: RouaSpacing.xs) {
                                    Image(systemName: selectedPairs.contains(pair) ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: RouaSpacing.iconSmall))
                                        .foregroundStyle(selectedPairs.contains(pair) ? .rouaPrimary : .rouaTextTertiary)
                                    Text(pair)
                                        .rouaFont(.callout, color: .rouaTextPrimary)
                                }
                                .padding(RouaSpacing.md)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                                        .fill(selectedPairs.contains(pair) ? Color.rouaPrimary.opacity(0.15) : Color.rouaSurfaceLight)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                                        .stroke(selectedPairs.contains(pair) ? Color.rouaPrimary : Color.rouaGlassBorder, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(pair)\(selectedPairs.contains(pair) ? ", selected" : "")")
                        }
                    }
                    .padding(.horizontal, RouaSpacing.screenPadding)
                }

                Spacer()

                // Selected count + trigger button
                if !selectedPairs.isEmpty {
                    Text("\(selectedPairs.count) أزواج محددة")
                        .rouaFont(.subheadline, color: .rouaTextSecondary)
                }

                RouaButton(
                    "تفعيل الجلسة",
                    variant: .primary,
                    size: .large,
                    icon: "bolt.horizontal",
                    isLoading: isTriggering,
                    isDisabled: selectedPairs.isEmpty,
                    action: onTrigger
                )
                .padding(.horizontal, RouaSpacing.screenPadding)
                .padding(.bottom, RouaSpacing.lg)
            }
            .background(Color.rouaBackground)
            .navigationTitle("جلسة جديدة")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview

#Preview("AICouncilView") {
    AICouncilView(viewModel: AIViewModel())
}
