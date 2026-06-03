// =============================================================================
// DeepAnalysisView.swift — Roua Trading · Deep Analysis for a Symbol
// =============================================================================
// Shows symbol header, AI consensus, technical indicator grid,
// support/resistance levels, and multi-timeframe analysis tabs.
// Uses MarketsViewModel for /scanner/analysis/:symbol and /ai/consensus.
// =============================================================================

import SwiftUI

struct DeepAnalysisView: View {

    // MARK: - Properties

    let symbol: String

    @StateObject private var viewModel = MarketsViewModel()
    @StateObject private var aiViewModel = AIViewModel()
    @State private var selectedTimeframe: AnalysisTimeframe = .oneHour
    @State private var showConsensus = false

    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaSpacing.lg) {
                // Symbol header with price
                symbolHeader

                // Multi-timeframe tabs
                timeframeTabs

                // AI Consensus section
                aiConsensusSection

                // Technical indicators grid
                technicalIndicatorsSection

                // Support / Resistance levels
                supportResistanceSection

                // Analysis text
                analysisTextSection
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
            .padding(.vertical, RouaSpacing.md)
        }
        .background(Color.rouaBackground)
        .navigationTitle(symbol)
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.isLoading {
                LoadingView(message: "جارٍ تحليل \(symbol)…")
            }
        }
        .task {
            await viewModel.loadDeepAnalysis(symbol: symbol)
            await aiViewModel.loadConsensus(symbol: symbol)
        }
        .onChange(of: selectedTimeframe) { _, _ in
            Task { await viewModel.loadDeepAnalysis(symbol: symbol) }
        }
    }

    // MARK: - Symbol Header

    private var symbolHeader: some View {
        GlassCard(glow: .rouaPrimary) {
            HStack {
                // Symbol avatar
                Text(String(symbol.prefix(2)))
                    .rouaFont(.title3, color: .white)
                    .frame(width: 56, height: 56)
                    .background(Color.rouaGradientPrimary)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                    Text(symbol)
                        .rouaFont(.title3, color: .rouaTextPrimary)
                    if let analysis = viewModel.deepAnalysis {
                        HStack(spacing: RouaSpacing.sm) {
                            SignalBadge(signal: analysis.recommendation)
                            Text("\(analysis.confidence)%")
                                .rouaFont(.captionBold, color: .rouaPrimary)
                                .monospacedDigit()
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Confidence circle
                if let analysis = viewModel.deepAnalysis {
                    ConfidenceRing(
                        value: analysis.confidence,
                        signal: analysis.recommendation
                    )
                }
            }
        }
    }

    // MARK: - Timeframe Tabs

    private var timeframeTabs: some View {
        HStack(spacing: 0) {
            ForEach(AnalysisTimeframe.allCases) { tf in
                Button {
                    withAnimation(.easeInOut(duration: RouaSpacing.animationFast)) {
                        selectedTimeframe = tf
                    }
                } label: {
                    Text(tf.displayName)
                        .rouaFont(
                            .footnoteBold,
                            color: selectedTimeframe == tf ? .white : .rouaTextSecondary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, RouaSpacing.sm)
                        .background(
                            selectedTimeframe == tf
                                ? Color.rouaPrimary
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tf.displayName)
                .accessibilityAddTraits(selectedTimeframe == tf ? .isSelected : [])
            }
        }
        .padding(RouaSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                .fill(Color.rouaSurfaceLight)
        )
    }

    // MARK: - AI Consensus Section

    private var aiConsensusSection: some View {
        VStack(spacing: RouaSpacing.sm) {
            SectionHeader(title: "إجماع الذكاء الاصطناعي") {
                showConsensus.toggle()
            }

            if let consensus = aiViewModel.consensusResult {
                GlassCard {
                    VStack(spacing: RouaSpacing.md) {
                        // Consensus signal + confidence
                        HStack {
                            SignalBadge(signal: mapBriefDirectionToSignal(consensus.consensus))
                            Spacer()
                            Text("الثقة: \(consensus.confidence)%")
                                .rouaFont(.calloutBold, color: confidenceColor(consensus.confidence))
                                .monospacedDigit()
                        }

                        // Summary
                        Text(consensus.summary)
                            .rouaFont(.subheadline, color: .rouaTextSecondary)
                            .lineLimit(4)

                        // Model votes
                        if showConsensus {
                            Divider()
                                .background(Color.rouaGlassBorder)

                            ForEach(consensus.models) { vote in
                                ModelVoteRow(vote: vote)
                            }
                        }

                        // Toggle button
                        Button {
                            withAnimation(.easeInOut(duration: RouaSpacing.animationFast)) {
                                showConsensus.toggle()
                            }
                        } label: {
                            HStack(spacing: RouaSpacing.xs) {
                                Text(showConsensus ? "إخفاء التفاصيل" : "عرض التفاصيل")
                                    .rouaFont(.captionBold, color: .rouaPrimary)
                                Image(systemName: showConsensus ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.rouaPrimary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                GlassCard {
                    HStack {
                        Image(systemName: "brain")
                            .foregroundStyle(.rouaTextTertiary)
                        Text("لا يوجد إجماع بعد")
                            .rouaFont(.subheadline, color: .rouaTextTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, RouaSpacing.md)
                }
            }
        }
    }

    // MARK: - Technical Indicators Section

    private var technicalIndicatorsSection: some View {
        VStack(spacing: RouaSpacing.sm) {
            SectionHeader(title: "المؤشرات الفنية")

            if let indicators = viewModel.deepAnalysis?.indicators {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: RouaSpacing.sm),
                        GridItem(.flexible(), spacing: RouaSpacing.sm),
                    ],
                    spacing: RouaSpacing.sm
                ) {
                    IndicatorCard(title: "RSI", value: indicators.rsi, suffix: "", interpretation: indicators.rsiLabel)
                    IndicatorCard(title: "MACD", value: indicators.macd, suffix: "", interpretation: indicators.isMacdBullishCross.map { $0 ? "Bullish Cross" : "Bearish Cross" })
                    IndicatorCard(title: "SMA 20", value: indicators.sma20, suffix: "")
                    IndicatorCard(title: "SMA 50", value: indicators.sma50, suffix: "")
                    IndicatorCard(title: "EMA 12", value: indicators.ema12, suffix: "")
                    IndicatorCard(title: "EMA 26", value: indicators.ema26, suffix: "")
                    IndicatorCard(title: "BB Upper", value: indicators.bollingerUpper, suffix: "")
                    IndicatorCard(title: "BB Lower", value: indicators.bollingerLower, suffix: "")
                    IndicatorCard(title: "ATR", value: indicators.atr, suffix: "")
                    IndicatorCard(title: "Stoch %K", value: indicators.stochasticK, suffix: "%")
                    IndicatorCard(title: "Stoch %D", value: indicators.stochasticD, suffix: "%")
                    IndicatorCard(title: "MACD Hist", value: indicators.macdHistogram, suffix: "")
                }
            } else {
                // Shimmer placeholders
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: RouaSpacing.sm),
                        GridItem(.flexible(), spacing: RouaSpacing.sm),
                    ],
                    spacing: RouaSpacing.sm
                ) {
                    ForEach(0..<8, id: \.self) { _ in
                        GlassCard {
                            VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                                ShimmerView(width: 40, height: 12)
                                ShimmerView(width: 80, height: 16)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Support / Resistance Section

    private var supportResistanceSection: some View {
        VStack(spacing: RouaSpacing.sm) {
            SectionHeader(title: "الدعم والمقاومة")

            if let analysis = viewModel.deepAnalysis {
                HStack(spacing: RouaSpacing.md) {
                    // Support levels
                    VStack(alignment: .leading, spacing: RouaSpacing.sm) {
                        HStack(spacing: RouaSpacing.xs) {
                            Image(systemName: "shield.fill")
                                .font(.system(size: RouaSpacing.iconSmall))
                                .foregroundStyle(.rouaProfit)
                            Text("الدعم")
                                .rouaFont(.footnoteBold, color: .rouaProfit)
                        }
                        if let support = analysis.support, !support.isEmpty {
                            ForEach(support.indices, id: \.self) { idx in
                                Text("S\(idx + 1): \(String(format: "%.2f", support[idx]))")
                                    .rouaFont(.mono, color: .rouaTextPrimary)
                                    .monospacedDigit()
                            }
                        } else {
                            Text("—")
                                .rouaFont(.footnote, color: .rouaTextTertiary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(RouaSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                            .fill(Color.rouaProfitBg)
                    )

                    // Resistance levels
                    VStack(alignment: .leading, spacing: RouaSpacing.sm) {
                        HStack(spacing: RouaSpacing.xs) {
                            Image(systemName: "shield.fill")
                                .font(.system(size: RouaSpacing.iconSmall))
                                .foregroundStyle(.rouaLoss)
                            Text("المقاومة")
                                .rouaFont(.footnoteBold, color: .rouaLoss)
                        }
                        if let resistance = analysis.resistance, !resistance.isEmpty {
                            ForEach(resistance.indices, id: \.self) { idx in
                                Text("R\(idx + 1): \(String(format: "%.2f", resistance[idx]))")
                                    .rouaFont(.mono, color: .rouaTextPrimary)
                                    .monospacedDigit()
                            }
                        } else {
                            Text("—")
                                .rouaFont(.footnote, color: .rouaTextTertiary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(RouaSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                            .fill(Color.rouaLossBg)
                    )
                }
            } else {
                GlassCard {
                    HStack {
                        ShimmerView(width: 120, height: 16)
                        Spacer()
                        ShimmerView(width: 120, height: 16)
                    }
                }
            }
        }
    }

    // MARK: - Analysis Text Section

    private var analysisTextSection: some View {
        VStack(spacing: RouaSpacing.sm) {
            SectionHeader(title: "التحليل")

            if let analysis = viewModel.deepAnalysis {
                GlassCard {
                    Text(analysis.analysis)
                        .rouaFont(.subheadline, color: .rouaTextSecondary)
                        .lineLimit(nil)
                }
            } else {
                GlassCard {
                    VStack(alignment: .leading, spacing: RouaSpacing.sm) {
                        ShimmerView(height: 14)
                        ShimmerView(height: 14)
                        ShimmerView(width: 200, height: 14)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func confidenceColor(_ value: Int) -> Color {
        switch value {
        case 80...100: return .rouaProfit
        case 60..<80:  return .rouaPrimary
        case 40..<60:  return .rouaWarning
        default:       return .rouaLoss
        }
    }

    private func mapBriefDirectionToSignal(_ direction: BriefDirection) -> SignalDirection {
        switch direction {
        case .bullish:  return .buy
        case .bearish:  return .sell
        case .neutral:  return .neutral
        }
    }
}

// MARK: - Analysis Timeframe

enum AnalysisTimeframe: String, CaseIterable, Identifiable {
    case fifteenMin = "15min"
    case oneHour    = "1H"
    case fourHour   = "4H"
    case oneDay     = "1D"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var apiValue: String {
        switch self {
        case .fifteenMin: return "15min"
        case .oneHour:    return "1h"
        case .fourHour:   return "4h"
        case .oneDay:     return "1day"
        }
    }
}

// MARK: - Confidence Ring

private struct ConfidenceRing: View {

    let value: Int
    let signal: SignalDirection

    @State private var animatedValue: Double = 0

    private var ringColor: Color {
        switch signal {
        case .strongBuy, .buy:   return .rouaProfit
        case .neutral:           return .rouaWarning
        case .sell, .strongSell: return .rouaLoss
        }
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color.rouaSurfaceHover, lineWidth: 4)

            // Value arc
            Circle()
                .trim(from: 0, to: animatedValue / 100.0)
                .stroke(ringColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Center text
            Text("\(value)")
                .rouaFont(.captionBold, color: ringColor)
                .monospacedDigit()
        }
        .frame(width: 48, height: 48)
        .onAppear {
            withAnimation(.easeOut(duration: RouaSpacing.animationSlow)) {
                animatedValue = Double(value)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Confidence: \(value)%")
    }
}

// MARK: - Model Vote Row

private struct ModelVoteRow: View {

    let vote: ModelVote

    var body: some View {
        HStack(spacing: RouaSpacing.sm) {
            // Model avatar
            Text(String(vote.model.prefix(1)))
                .rouaFont(.captionBold, color: .rouaTextPrimary)
                .frame(width: 28, height: 28)
                .background(Color.rouaSurfaceLight)
                .clipShape(Circle())

            // Model info
            VStack(alignment: .leading, spacing: 1) {
                Text(vote.model)
                    .rouaFont(.footnoteBold, color: .rouaTextPrimary)
                    .lineLimit(1)
                Text(vote.provider)
                    .rouaFont(.caption, color: .rouaTextTertiary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Vote badge
            SignalBadge(signal: vote.recommendation)

            // Confidence
            Text("\(vote.confidence)%")
                .rouaFont(.footnoteBold, color: .rouaPrimary)
                .monospacedDigit()
        }
        .padding(.vertical, RouaSpacing.xs)
    }
}

// MARK: - Indicator Card

private struct IndicatorCard: View {

    let title: String
    let value: Double?
    let suffix: String
    var interpretation: String? = nil

    private var displayValue: String {
        guard let v = value else { return "—" }
        return String(format: "%.2f", v) + suffix
    }

    private var valueColor: Color {
        guard let v = value else { return .rouaTextTertiary }
        // For RSI: color based on oversold/overbought
        if title == "RSI" {
            if v < 30 { return .rouaProfit }      // Oversold = potential buy
            if v > 70 { return .rouaLoss }         // Overbought = potential sell
        }
        // For MACD Histogram: green if positive
        if title == "MACD Hist" {
            return v >= 0 ? .rouaProfit : .rouaLoss
        }
        return .rouaTextPrimary
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                Text(title)
                    .rouaFont(.caption, color: .rouaTextTertiary)
                    .lineLimit(1)

                Text(displayValue)
                    .rouaFont(.calloutBold, color: valueColor)
                    .monospacedDigit()
                    .lineLimit(1)

                if let interp = interpretation {
                    Text(interp)
                        .rouaFont(.micro, color: .rouaTextTertiary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Preview

#Preview("DeepAnalysisView") {
    NavigationStack {
        DeepAnalysisView(symbol: "BTCUSDT")
    }
}
