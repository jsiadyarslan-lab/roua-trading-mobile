// =============================================================================
// AIModelsView.swift — Roua Trading · AI Models Status Dashboard
// =============================================================================
// Grid of model cards with name, provider, status, latency indicator,
// overall diagnostic summary, and diagnose button.
// Uses AIViewModel.
// =============================================================================

import SwiftUI

struct AIModelsView: View {

    // MARK: - Dependencies

    @ObservedObject var viewModel: AIViewModel

    // MARK: - State

    @State private var isDiagnosing = false
    @State private var showDiagnosticResult = false

    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaSpacing.lg) {
                // Overall summary
                overallSummaryCard

                // Diagnose button
                RouaButton(
                    "تشخيص",
                    variant: .secondary,
                    size: .medium,
                    icon: "stethoscope",
                    isLoading: isDiagnosing,
                    action: runDiagnosis
                )

                // Model cards grid
                SectionHeader(
                    title: "النماذج المتاحة",
                    actionTitle: "\(viewModel.models.filter { $0.available }.count)/\(viewModel.models.count)",
                    action: {}
                )

                if viewModel.models.isEmpty {
                    // Shimmer loading state
                    modelShimmerGrid
                } else {
                    modelGrid
                }

                // Diagnostic result
                if showDiagnosticResult {
                    diagnosticResultCard
                }

                // Bottom spacer
                Color.clear.frame(height: RouaSpacing.xxxl)
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
            .padding(.vertical, RouaSpacing.md)
        }
    }

    // MARK: - Overall Summary Card

    private var overallSummaryCard: some View {
        GlassCard(glow: viewModel.modelsAllAvailable ? .rouaProfit : .rouaWarning) {
            VStack(spacing: RouaSpacing.md) {
                HStack {
                    PulsingDot(
                        status: viewModel.modelsAllAvailable ? .active : .warning,
                        size: 12
                    )

                    VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                        Text(viewModel.modelsAllAvailable ? "جميع النماذج متاحة" : "بعض النماذج غير متاحة")
                            .rouaFont(.calloutBold, color: .rouaTextPrimary)
                        Text("آخر فحص: \(viewModel.modelsLastChecked)")
                            .rouaFont(.caption, color: .rouaTextTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Availability pie indicator
                    AvailabilityIndicator(
                        available: viewModel.models.filter { $0.available }.count,
                        total: viewModel.models.count
                    )
                }

                // Stats row
                HStack(spacing: 0) {
                    StatMini(
                        label: "المتاحة",
                        value: "\(viewModel.models.filter { $0.available }.count)"
                    )
                    .frame(maxWidth: .infinity)

                    StatMini(
                        label: "غير متاحة",
                        value: "\(viewModel.models.filter { !$0.available }.count)"
                    )
                    .frame(maxWidth: .infinity)

                    StatMini(
                        label: "متوسط التأخير",
                        value: viewModel.averageLatency
                    )
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Model Grid

    private var modelGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: RouaSpacing.sm),
                GridItem(.flexible(), spacing: RouaSpacing.sm),
            ],
            spacing: RouaSpacing.sm
        ) {
            ForEach(viewModel.models) { model in
                ModelCard(model: model)
            }
        }
    }

    // MARK: - Model Shimmer Grid

    private var modelShimmerGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: RouaSpacing.sm),
                GridItem(.flexible(), spacing: RouaSpacing.sm),
            ],
            spacing: RouaSpacing.sm
        ) {
            ForEach(0..<6, id: \.self) { _ in
                GlassCard {
                    VStack(alignment: .leading, spacing: RouaSpacing.sm) {
                        ShimmerView(width: 80, height: 14)
                        ShimmerView(width: 60, height: 12)
                        ShimmerView(width: 40, height: 10)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - Diagnostic Result Card

    private var diagnosticResultCard: some View {
        GlassCard {
            VStack(spacing: RouaSpacing.md) {
                HStack {
                    Image(systemName: "checkmark.shield")
                        .font(.system(size: RouaSpacing.iconMedium))
                        .foregroundStyle(.rouaProfit)
                    Text("نتائج التشخيص")
                        .rouaFont(.calloutBold, color: .rouaTextPrimary)
                    Spacer()
                }

                ForEach(viewModel.models) { model in
                    HStack {
                        PulsingDot(
                            status: model.available ? .active : .error,
                            size: 6
                        )
                        Text(model.name)
                            .rouaFont(.footnote, color: .rouaTextPrimary)
                        Spacer()
                        if let latency = model.formattedLatency {
                            Text(latency)
                                .rouaFont(.caption, color: .rouaTextTertiary)
                                .monospacedDigit()
                        }
                    }
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Actions

    private func runDiagnosis() {
        isDiagnosing = true
        viewModel.diagnoseModels()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isDiagnosing = false
            withAnimation(.easeInOut(duration: RouaSpacing.animationDuration)) {
                showDiagnosticResult = true
            }
            // Auto-hide after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                withAnimation(.easeInOut(duration: RouaSpacing.animationDuration)) {
                    showDiagnosticResult = false
                }
            }
        }
    }
}

// MARK: - Model Card

private struct ModelCard: View {

    let model: ModelStatus

    var body: some View {
        GlassCard(glow: model.available ? nil : .rouaLoss) {
            VStack(alignment: .leading, spacing: RouaSpacing.sm) {
                // Status dot + name
                HStack(spacing: RouaSpacing.sm) {
                    PulsingDot(
                        status: model.available ? .active : .error,
                        size: 8
                    )

                    VStack(alignment: .leading, spacing: 1) {
                        Text(model.name)
                            .rouaFont(.footnoteBold, color: .rouaTextPrimary)
                            .lineLimit(1)
                        Text(model.provider)
                            .rouaFont(.caption, color: .rouaTextTertiary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Status badge
                HStack {
                    Badge(
                        text: model.available ? "متاح" : "غير متاح",
                        variant: model.available ? .success : .error
                    )
                    Spacer()

                    // Latency
                    if let latency = model.formattedLatency {
                        HStack(spacing: RouaSpacing.xs) {
                            Image(systemName: "clock")
                                .font(.system(size: 8))
                                .foregroundStyle(latencyColor)
                            Text(latency)
                                .rouaFont(.caption, color: latencyColor)
                                .monospacedDigit()
                        }
                    }
                }

                // Latency bar (visual indicator)
                if let lat = model.latency {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 1, style: .continuous)
                                .fill(Color.rouaSurfaceHover)
                                .frame(height: 2)
                            RoundedRectangle(cornerRadius: 1, style: .continuous)
                                .fill(latencyColor)
                                .frame(
                                    width: geo.size.width * min(lat / 10.0, 1.0),
                                    height: 2
                                )
                        }
                    }
                    .frame(height: 2)
                }
            }
        }
    }

    private var latencyColor: Color {
        guard let lat = model.latency else { return .rouaNeutral }
        switch lat {
        case ..<1.0:  return .rouaProfit
        case 1.0..<3.0: return .rouaWarning
        default:      return .rouaLoss
        }
    }
}

// MARK: - Availability Indicator

private struct AvailabilityIndicator: View {

    let available: Int
    let total: Int

    private var ratio: Double {
        guard total > 0 else { return 0 }
        return Double(available) / Double(total)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.rouaSurfaceHover, lineWidth: 3)

            Circle()
                .trim(from: 0, to: ratio)
                .stroke(ratio >= 1.0 ? Color.rouaProfit : Color.rouaWarning, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(available)/\(total)")
                .rouaFont(.micro, color: .rouaTextSecondary)
        }
        .frame(width: 40, height: 40)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(available) of \(total) models available")
    }
}

// MARK: - Preview

#Preview("AIModelsView") {
    AIModelsView(viewModel: AIViewModel())
}
