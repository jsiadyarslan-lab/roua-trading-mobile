// =============================================================================
// SignalsView.swift — Roua Trading · AI Signals Dashboard
// =============================================================================
// Active signals list with direction, confidence, entry/SL/TP,
// source/reasoning, execute & dismiss actions.
// Signal history and new signal generation.
// Uses AIViewModel.
// =============================================================================

import SwiftUI

struct SignalsView: View {

    // MARK: - Dependencies

    @ObservedObject var viewModel: AIViewModel

    // MARK: - State

    @State private var showNewSignalSheet = false
    @State private var newSignalSymbol = ""
    @State private var isGenerating = false

    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaSpacing.lg) {
                // Generate signal button
                RouaButton(
                    "إنشاء إشارة",
                    variant: .secondary,
                    size: .medium,
                    icon: "plus",
                    iconPosition: .leading,
                    action: { showNewSignalSheet = true }
                )

                // Active signals
                SectionHeader(
                    title: "الإشارات النشطة",
                    actionTitle: viewModel.activeSignals.isEmpty ? nil : "\(viewModel.activeSignals.count)",
                    action: {}
                )

                if viewModel.activeSignals.isEmpty {
                    EmptyStateView(
                        icon: "signal",
                        title: "لا توجد إشارات",
                        description: "قم بإنشاء إشارة جديدة للبدء"
                    )
                    .padding(.vertical, RouaSpacing.xxxl)
                } else {
                    ForEach(viewModel.activeSignals) { signal in
                        SignalCard(
                            signal: signal,
                            onExecute: { Task { await viewModel.executeSignal(id: signal.id, credentialId: "") } },
                            onDismiss: { viewModel.dismissSignal(id: signal.id) }
                        )
                    }
                }

                // Signal history
                if !viewModel.activeSignals.filter({ $0.status != .active }).isEmpty {
                    SectionHeader(title: "السجل")

                    ForEach(viewModel.activeSignals.filter { $0.status != .active }) { signal in
                        SignalHistoryCard(signal: signal)
                    }
                    .opacity(0.7)
                }

                // Bottom spacer
                Color.clear.frame(height: RouaSpacing.xxxl)
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
            .padding(.vertical, RouaSpacing.md)
        }
        .sheet(isPresented: $showNewSignalSheet) {
            NewSignalSheet(
                symbol: $newSignalSymbol,
                isGenerating: $isGenerating,
                onGenerate: generateSignal
            )
        }
    }

    // MARK: - Actions

    private func generateSignal() {
        guard !newSignalSymbol.isEmpty else { return }
        isGenerating = true
        Task {
            await viewModel.generateSignal(pair: newSignalSymbol.uppercased())
            isGenerating = false
            showNewSignalSheet = false
            newSignalSymbol = ""
        }
    }
}

// MARK: - Signal Card

private struct SignalCard: View {

    let signal: Signal
    let onExecute: () -> Void
    let onDismiss: () -> Void

    private var directionColor: Color {
        switch signal.direction {
        case .bullish:  return .rouaProfit
        case .bearish:  return .rouaLoss
        case .neutral:  return .rouaNeutral
        }
    }

    private var directionIcon: String {
        switch signal.direction {
        case .bullish:  return "arrowtriangle.up.fill"
        case .bearish:  return "arrowtriangle.down.fill"
        case .neutral:  return "minus"
        }
    }

    var body: some View {
        GlassCard(glow: directionColor) {
            VStack(spacing: RouaSpacing.md) {
                // Header: symbol + direction + confidence
                HStack {
                    // Direction indicator
                    Image(systemName: directionIcon)
                        .font(.system(size: RouaSpacing.iconLarge))
                        .foregroundStyle(directionColor)

                    VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                        Text(signal.symbol)
                            .rouaFont(.calloutBold, color: .rouaTextPrimary)
                        HStack(spacing: RouaSpacing.xs) {
                            Text(signal.direction.displayName)
                                .rouaFont(.captionBold, color: directionColor)
                            Text("•")
                                .foregroundStyle(.rouaTextTertiary)
                            Text("\(signal.confidence)%")
                                .rouaFont(.captionBold, color: .rouaPrimary)
                                .monospacedDigit()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Confidence ring
                    MiniConfidenceRing(value: signal.confidence, color: directionColor)

                    // Dismiss button
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: RouaSpacing.iconSmall, weight: .bold))
                            .foregroundStyle(.rouaTextTertiary)
                    }
                    .accessibilityLabel("Dismiss signal")
                }

                // Price levels: Entry / SL / TP
                HStack(spacing: RouaSpacing.md) {
                    PriceLevelView(
                        label: "الدخول",
                        value: signal.entryPrice ?? 0,
                        color: .rouaPrimary
                    )
                    if let sl = signal.stopLoss {
                        PriceLevelView(
                            label: "وقف الخسارة",
                            value: sl,
                            color: .rouaLoss
                        )
                    }
                    if let tp = signal.takeProfit {
                        PriceLevelView(
                            label: "جني الأرباح",
                            value: tp,
                            color: .rouaProfit
                        )
                    }
                    if let rr = signal.formattedRiskReward {
                        VStack(spacing: RouaSpacing.xs) {
                            Text("R:R")
                                .rouaFont(.caption, color: .rouaTextTertiary)
                            Text(rr)
                                .rouaFont(.captionBold, color: .rouaAccent)
                                .monospacedDigit()
                        }
                    }
                }

                // Source + reasoning
                if let reasoning = signal.reasoning {
                    VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                        HStack(spacing: RouaSpacing.xs) {
                            Image(systemName: "lightbulb")
                                .font(.system(size: RouaSpacing.iconSmall))
                                .foregroundStyle(.rouaWarning)
                            Text("السبب")
                                .rouaFont(.captionBold, color: .rouaWarning)
                        }
                        Text(reasoning)
                            .rouaFont(.footnote, color: .rouaTextSecondary)
                            .lineLimit(3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Source + time
                HStack {
                    HStack(spacing: RouaSpacing.xs) {
                        Image(systemName: "cpu")
                            .font(.system(size: 10))
                            .foregroundStyle(.rouaTextTertiary)
                        Text(signal.source ?? "AI")
                            .rouaFont(.caption, color: .rouaTextTertiary)
                    }
                    Spacer()
                    Text(signal.createdAt)
                        .rouaFont(.caption, color: .rouaTextTertiary)
                }

                // Execute button
                RouaButton(
                    signal.direction == .bullish ? "شراء" : "بيع",
                    variant: signal.direction == .bullish ? .primary : .danger,
                    size: .medium,
                    icon: signal.direction == .bullish ? "arrowtriangle.up" : "arrowtriangle.down",
                    action: onExecute
                )
            }
        }
    }
}

// MARK: - Price Level View

private struct PriceLevelView: View {

    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: RouaSpacing.xs) {
            Text(label)
                .rouaFont(.caption, color: .rouaTextTertiary)
            Text(String(format: "%.2f", value))
                .rouaFont(.footnoteBold, color: color)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Mini Confidence Ring

private struct MiniConfidenceRing: View {

    let value: Int
    let color: Color

    @State private var animated: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.rouaSurfaceHover, lineWidth: 3)
            Circle()
                .trim(from: 0, to: animated / 100.0)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(value)")
                .rouaFont(.micro, color: color)
                .monospacedDigit()
        }
        .frame(width: 36, height: 36)
        .onAppear {
            withAnimation(.easeOut(duration: RouaSpacing.animationSlow)) {
                animated = Double(value)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Confidence \(value)%")
    }
}

// MARK: - Signal History Card

private struct SignalHistoryCard: View {

    let signal: Signal

    private var statusVariant: BadgeVariant {
        switch signal.status {
        case .active:    return .success
        case .executed:  return .info
        case .expired:   return .neutral
        case .cancelled: return .warning
        case nil:        return .neutral
        }
    }

    private var directionColor: Color {
        switch signal.direction {
        case .bullish:  return .rouaProfit
        case .bearish:  return .rouaLoss
        case .neutral:  return .rouaNeutral
        }
    }

    var body: some View {
        GlassCard {
            HStack(spacing: RouaSpacing.md) {
                Image(systemName: signal.direction == .bullish ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                    .font(.system(size: RouaSpacing.iconMedium))
                    .foregroundStyle(directionColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(signal.symbol)
                        .rouaFont(.calloutBold, color: .rouaTextPrimary)
                    Text(String(format: "%.2f", signal.entryPrice ?? 0))
                        .rouaFont(.monoSmall, color: .rouaTextSecondary)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Badge(text: (signal.status ?? .active).displayName, variant: statusVariant)

                Text(signal.createdAt)
                    .rouaFont(.caption, color: .rouaTextTertiary)
            }
        }
    }
}

// MARK: - New Signal Sheet

private struct NewSignalSheet: View {

    @Binding var symbol: String
    @Binding var isGenerating: Bool
    let onGenerate: () -> Void

    @FocusState private var isFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: RouaSpacing.xxl) {
                // Symbol input
                VStack(alignment: .leading, spacing: RouaSpacing.sm) {
                    Text("رمز الأداة")
                        .rouaFont(.subheadlineBold, color: .rouaTextPrimary)

                    TextField("مثال: BTCUSDT", text: $symbol)
                        .rouaFont(.callout, color: .rouaTextPrimary)
                        .padding(RouaSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                                .fill(Color.rouaSurfaceLight)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                                .stroke(Color.rouaGlassBorder, lineWidth: 0.5)
                        )
                        .focused($isFieldFocused)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }

                // Quick picks
                VStack(alignment: .leading, spacing: RouaSpacing.sm) {
                    Text("اختيار سريع")
                        .rouaFont(.subheadline, color: .rouaTextSecondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: RouaSpacing.sm) {
                            ForEach(["BTCUSDT", "ETHUSDT", "EURUSD", "XAUUSD"], id: \.self) { pair in
                                Button {
                                    symbol = pair
                                } label: {
                                    Text(pair)
                                        .rouaFont(.footnoteBold, color: symbol == pair ? .white : .rouaTextSecondary)
                                        .padding(.horizontal, RouaSpacing.md)
                                        .padding(.vertical, RouaSpacing.sm)
                                        .background(
                                            Capsule().fill(symbol == pair ? Color.rouaPrimary : Color.rouaSurfaceLight)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Spacer()

                // Generate button
                RouaButton(
                    "إنشاء إشارة",
                    variant: .primary,
                    size: .large,
                    icon: "sparkles",
                    isLoading: isGenerating,
                    isDisabled: symbol.trimmingCharacters(in: .whitespaces).isEmpty,
                    action: onGenerate
                )
            }
            .padding(RouaSpacing.screenPadding)
            .background(Color.rouaBackground)
            .navigationTitle("إشارة جديدة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("إلغاء") { symbol = "" }
                        .foregroundStyle(.rouaTextSecondary)
                }
            }
            .onAppear {
                isFieldFocused = true
            }
        }
    }
}

// MARK: - Preview

#Preview("SignalsView") {
    SignalsView(viewModel: AIViewModel())
}
