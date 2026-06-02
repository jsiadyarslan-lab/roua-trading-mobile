// =============================================================================
// ScannerView.swift — Roua Trading · Detailed Market Scanner
// =============================================================================
// Full-featured scanner with search, timeframe selector, category filter,
// detailed results with signal strength bars, and run button.
// Navigates to DeepAnalysisView on result tap.
// =============================================================================

import SwiftUI

struct ScannerView: View {

    // MARK: - Dependencies

    @StateObject private var viewModel = MarketsViewModel()

    // MARK: - State

    @State private var searchText = ""
    @State private var isRunning = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar

                // Timeframe selector
                timeframeSelector

                // Category filter
                categoryFilter

                // Results or empty state
                if viewModel.scannerResults.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "ابدأ المسح",
                        description: "اضغط على زر التشغيل للبحث عن فرص التداول",
                        buttonTitle: "تشغيل الماسح",
                        buttonAction: runScanner
                    )
                    Spacer()
                } else {
                    resultsList
                }

                // Run scanner button
                runButton
            }
            .background(Color.rouaBackground)
            .navigationTitle("الماسح")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if viewModel.isLoading {
                    LoadingView(message: "جارٍ تحليل الأسواق…")
                }
            }
            .overlay {
                if let error = viewModel.errorMessage {
                    ErrorBanner(
                        message: error,
                        onRetry: { viewModel.refresh() },
                        onDismiss: { viewModel.clearError() }
                    )
                    .padding(.horizontal, RouaSpacing.screenPadding)
                    .padding(.top, RouaSpacing.md)
                    .frame(maxHeight: .infinity, alignment: .top)
                }
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: RouaSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: RouaSpacing.iconMedium))
                .foregroundStyle(.rouaTextTertiary)

            TextField("ابحث عن رمز…", text: $searchText)
                .rouaFont(.callout, color: .rouaTextPrimary)
                .onChange(of: searchText) { _, newValue in
                    viewModel.searchQuery = newValue
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: RouaSpacing.iconMedium))
                        .foregroundStyle(.rouaTextTertiary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(RouaSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                .fill(Color.rouaSurfaceLight)
        )
        .overlay(
            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                .stroke(Color.rouaGlassBorder, lineWidth: 0.5)
        )
        .padding(.horizontal, RouaSpacing.screenPadding)
        .padding(.vertical, RouaSpacing.sm)
    }

    // MARK: - Timeframe Selector

    private var timeframeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RouaSpacing.sm) {
                ForEach(ScannerTimeframe.allCases) { tf in
                    Button {
                        withAnimation(.easeInOut(duration: RouaSpacing.animationFast)) {
                            viewModel.selectedTimeframe = tf
                        }
                    } label: {
                        HStack(spacing: RouaSpacing.xs) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(tf.displayName)
                                .rouaFont(.footnoteBold)
                        }
                        .foregroundStyle(viewModel.selectedTimeframe == tf ? .white : .rouaTextSecondary)
                        .padding(.horizontal, RouaSpacing.md)
                        .padding(.vertical, RouaSpacing.xs)
                        .background(
                            Capsule().fill(
                                viewModel.selectedTimeframe == tf
                                    ? Color.rouaPrimary
                                    : Color.rouaSurfaceLight
                            )
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Timeframe \(tf.displayName)")
                    .accessibilityAddTraits(viewModel.selectedTimeframe == tf ? .isSelected : [])
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
        }
        .padding(.bottom, RouaSpacing.sm)
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RouaSpacing.sm) {
                ForEach(MarketCategory.allCases) { cat in
                    Button {
                        withAnimation(.easeInOut(duration: RouaSpacing.animationFast)) {
                            viewModel.selectedCategory = cat
                        }
                    } label: {
                        Text(cat.displayName)
                            .rouaFont(
                                .captionBold,
                                color: viewModel.selectedCategory == cat ? .white : .rouaTextSecondary
                            )
                            .padding(.horizontal, RouaSpacing.md)
                            .padding(.vertical, RouaSpacing.xs)
                            .background(
                                Capsule().fill(
                                    viewModel.selectedCategory == cat
                                        ? Color.rouaAccent
                                        : Color.rouaSurfaceHover
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
        }
        .padding(.bottom, RouaSpacing.md)
    }

    // MARK: - Results List

    private var resultsList: some View {
        List {
            ForEach(viewModel.scannerResults) { result in
                NavigationLink(destination: LazyView {
                    DeepAnalysisView(symbol: result.symbol)
                }) {
                    DetailedScannerRow(result: result)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: RouaSpacing.xs, leading: 0, bottom: RouaSpacing.xs, trailing: 0))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Run Scanner Button

    private var runButton: some View {
        RouaButton(
            "تشغيل الماسح",
            variant: .primary,
            size: .large,
            icon: "bolt.horizontal",
            isLoading: isRunning,
            action: runScanner
        )
        .padding(.horizontal, RouaSpacing.screenPadding)
        .padding(.vertical, RouaSpacing.md)
    }

    // MARK: - Actions

    private func runScanner() {
        isRunning = true
        viewModel.runScanner()
        // Simulate loading completion after the VM finishes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isRunning = false
        }
    }
}

// MARK: - Detailed Scanner Row

private struct DetailedScannerRow: View {

    let result: ScannerResult

    var body: some View {
        GlassCard {
            VStack(spacing: RouaSpacing.sm) {
                // Top row: symbol + signal + price
                HStack {
                    // Symbol avatar
                    Text(String(result.symbol.prefix(2)))
                        .rouaFont(.captionBold, color: .rouaTextPrimary)
                        .frame(width: 36, height: 36)
                        .background(Color.rouaSurfaceLight)
                        .clipShape(Circle())

                    // Symbol + name
                    VStack(alignment: .leading, spacing: 1) {
                        Text(result.symbol)
                            .rouaFont(.calloutBold, color: .rouaTextPrimary)
                            .lineLimit(1)
                        if let name = result.name {
                            Text(name)
                                .rouaFont(.footnote, color: .rouaTextSecondary)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Signal badge
                    SignalBadge(signal: result.signal)

                    // Price
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.2f", result.price))
                            .rouaFont(.calloutBold, color: .rouaTextPrimary)
                            .monospacedDigit()
                        ChangeBadge(value: result.change, percentage: result.changePct)
                    }
                }

                // Signal strength bar
                VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                    HStack {
                        Text("قوة الإشارة")
                            .rouaFont(.caption, color: .rouaTextTertiary)
                        Spacer()
                        Text("\(result.strength)%")
                            .rouaFont(.captionBold, color: strengthColor)
                            .monospacedDigit()
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Background track
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(Color.rouaSurfaceHover)
                                .frame(height: 4)

                            // Fill bar
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(strengthColor)
                                .frame(
                                    width: geo.size.width * CGFloat(result.strength) / 100.0,
                                    height: 4
                                )
                                .animation(
                                    .easeOut(duration: RouaSpacing.animationDuration),
                                    value: result.strength
                                )
                        }
                    }
                    .frame(height: 4)
                }

                // Recommendation label
                HStack {
                    Image(systemName: recommendationIcon)
                        .font(.system(size: RouaSpacing.iconSmall))
                        .foregroundStyle(strengthColor)
                    Text(result.strengthLabel)
                        .rouaFont(.caption, color: .rouaTextSecondary)
                    Spacer()
                    Badge(text: result.category.displayName, variant: .info)
                }
            }
        }
        .padding(.horizontal, RouaSpacing.screenPadding)
    }

    // MARK: - Computed

    private var strengthColor: Color {
        switch result.strength {
        case 80...100: return .rouaProfit
        case 60..<80:  return .rouaProfit.opacity(0.7)
        case 40..<60:  return .rouaWarning
        case 20..<40:  return .rouaLoss.opacity(0.7)
        default:       return .rouaLoss
        }
    }

    private var recommendationIcon: String {
        switch result.signal {
        case .strongBuy, .buy:   return "arrowtriangle.up.fill"
        case .neutral:           return "minus"
        case .sell, .strongSell: return "arrowtriangle.down.fill"
        }
    }
}

// MARK: - Preview

#Preview("ScannerView") {
    ScannerView()
}
