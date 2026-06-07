// =============================================================================
// MarketsView.swift — Roua Trading · Markets Tab
// =============================================================================
// Top-level Markets tab with segmented control: الماسح (Scanner),
// خريطة الحرارة (Heatmap), الأخبار (News).
// Uses MarketsViewModel for data, RouaComponents for UI primitives.
// =============================================================================

import SwiftUI

// MARK: - Markets Tab

enum MarketsSegment: String, CaseIterable, Identifiable {
    case scanner = "الماسح"
    case heatmap = "خريطة الحرارة"
    case news    = "الأخبار"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .scanner: return "magnifyingglass"
        case .heatmap: return "square.grid.3x3.fill"
        case .news:    return "newspaper"
        }
    }
}

struct MarketsView: View {

    // MARK: - Dependencies

    @StateObject private var viewModel = MarketsViewModel()

    // MARK: - State

    @State private var selectedSegment: MarketsSegment = .scanner
    @State private var selectedNewsFilter: NewsFilter = .all

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented control
                segmentedControl

                // Content
                Group {
                    switch selectedSegment {
                    case .scanner:
                        ScannerTabContent(viewModel: viewModel)
                    case .heatmap:
                        HeatmapTabContent(viewModel: viewModel)
                    case .news:
                        NewsTabContent(viewModel: viewModel, selectedFilter: $selectedNewsFilter)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color.rouaBackground)
            .navigationTitle("الأسواق")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.loadAll()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(.rouaPrimary)
                    }
                    .accessibilityLabel("Refresh markets")
                }
            }
            .task {
                viewModel.loadAll()
            }
            .refreshable {
                viewModel.loadAll(); await Task.yield()
            }
            .overlay {
                if viewModel.isLoading && viewModel.scanResults.isEmpty
                    && viewModel.heatmapData.isEmpty
                    && viewModel.newsItems.isEmpty {
                    LoadingView(message: "جارٍ تحميل بيانات السوق…")
                }
            }
            .overlay {
                if let error = viewModel.errorMessage {
                    ErrorBanner(
                        message: error,
                        onRetry: { viewModel.loadAll() },
                        onDismiss: { viewModel.errorMessage = nil }
                    )
                    .padding(.horizontal, RouaSpacing.screenPadding)
                    .padding(.top, RouaSpacing.md)
                    .frame(maxHeight: .infinity, alignment: .top)
                }
            }
        }
    }

    // MARK: - Segmented Control

    private var segmentedControl: some View {
        HStack(spacing: 0) {
            ForEach(MarketsSegment.allCases) { segment in
                Button {
                    withAnimation(.easeInOut(duration: RouaSpacing.animationFast)) {
                        selectedSegment = segment
                    }
                } label: {
                    HStack(spacing: RouaSpacing.xs) {
                        Image(systemName: segment.icon)
                            .font(.system(size: RouaSpacing.iconSmall))
                        Text(segment.rawValue)
                            .rouaFont(.subheadlineBold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, RouaSpacing.sm)
                    .background(
                        selectedSegment == segment
                            ? Color.rouaPrimary.opacity(0.2)
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous))
                }
                .foregroundStyle(selectedSegment == segment ? .rouaPrimary : .rouaTextSecondary)
                .buttonStyle(.plain)
                .accessibilityLabel(segment.rawValue)
                .accessibilityAddTraits(selectedSegment == segment ? .isSelected : [])
            }
        }
        .padding(RouaSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                .fill(Color.rouaSurfaceLight)
        )
        .padding(.horizontal, RouaSpacing.screenPadding)
        .padding(.vertical, RouaSpacing.sm)
    }
}

// MARK: - Scanner Tab Content

private struct ScannerTabContent: View {

    @ObservedObject var viewModel: MarketsViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Timeframe selector
            timeframeSelector

            // Category filter
            categoryFilter

            // Results list
            if viewModel.scanResults.isEmpty {
                Spacer()
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "لا توجد نتائج",
                    description: "قم بتشغيل الماسح للعثور على فرص التداول",
                    buttonTitle: "تشغيل الماسح",
                    buttonAction: { Task { await viewModel.runScan() } }
                )
                Spacer()
            } else {
                scannerResultsList
            }
        }
    }

    // MARK: Timeframe Selector

    private var timeframeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RouaSpacing.sm) {
                ForEach(TimeFrame.allCases) { tf in
                    Button {
                        withAnimation(.easeInOut(duration: RouaSpacing.animationFast)) {
                            viewModel.updateTimeframe(tf)
                        }
                    } label: {
                        Text(tf.displayName)
                            .rouaFont(
                                .footnoteBold,
                                color: viewModel.selectedTimeframe == tf ? .white : .rouaTextSecondary
                            )
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
                    .accessibilityLabel(tf.displayName)
                    .accessibilityAddTraits(viewModel.selectedTimeframe == tf ? .isSelected : [])
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
        }
        .padding(.vertical, RouaSpacing.sm)
    }

    // MARK: Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RouaSpacing.sm) {
                ForEach(MarketCategory.allCases) { cat in
                    Button {
                        withAnimation(.easeInOut(duration: RouaSpacing.animationFast)) {
                            viewModel.updateCategory(cat)
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
                    .accessibilityLabel(cat.displayName)
                    .accessibilityAddTraits(viewModel.selectedCategory == cat ? .isSelected : [])
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
        }
        .padding(.bottom, RouaSpacing.sm)
    }

    // MARK: Results List

    private var scannerResultsList: some View {
        List {
            ForEach(viewModel.scanResults) { result in
                NavigationLink(destination: LazyView(DeepAnalysisView(symbol: result.symbol))) {
                    ScannerResultRow(result: result)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: RouaSpacing.xs, leading: 0, bottom: RouaSpacing.xs, trailing: 0))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Scanner Result Row

private struct ScannerResultRow: View {

    let result: ScannerResult

    var body: some View {
        HStack(spacing: RouaSpacing.md) {
            // Symbol avatar
            Text(String(result.symbol.prefix(2)))
                .rouaFont(.captionBold, color: .rouaTextPrimary)
                .frame(width: 40, height: 40)
                .background(Color.rouaSurfaceLight)
                .clipShape(Circle())

            // Symbol + Name
            VStack(alignment: .leading, spacing: 2) {
                Text(result.symbol)
                    .rouaFont(.calloutBold, color: .rouaTextPrimary)
                    .lineLimit(1)
                Text(result.name ?? "")
                    .rouaFont(.footnote, color: .rouaTextSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Signal badge
            SignalBadge(signal: result.signal)

            // Price + change
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.2f", result.price))
                    .rouaFont(.calloutBold, color: .rouaTextPrimary)
                    .monospacedDigit()
                ChangeBadge(value: result.change, percentage: result.changePct)
            }
        }
        .padding(.horizontal, RouaSpacing.screenPadding)
        .padding(.vertical, RouaSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                .fill(Color.rouaGlass)
        )
        .overlay(
            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                .stroke(Color.rouaGlassBorder, lineWidth: 0.5)
        )
    }
}

// MARK: - Signal Badge (Compact)

struct SignalBadge: View {

    let signal: SignalDirection

    private var color: Color {
        switch signal {
        case .strongBuy:  return .rouaProfit
        case .buy:        return .rouaProfit.opacity(0.7)
        case .neutral:    return .rouaNeutral
        case .sell:       return .rouaLoss.opacity(0.7)
        case .strongSell: return .rouaLoss
        case .unknown:    return .rouaNeutral
        }
    }

    private var bgColor: Color {
        switch signal {
        case .strongBuy:  return .rouaProfitLight
        case .buy:        return .rouaProfitLight.opacity(0.6)
        case .neutral:    return .rouaNeutral.opacity(0.15)
        case .sell:       return .rouaLossLight.opacity(0.6)
        case .strongSell: return .rouaLossLight
        case .unknown:    return .rouaNeutral.opacity(0.15)
        }
    }

    var body: some View {
        Text(signal.displayName)
            .rouaFont(.micro, color: color)
            .padding(.horizontal, RouaSpacing.sm)
            .padding(.vertical, 3)
            .background(Capsule().fill(bgColor))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Signal: \(signal.displayName)")
    }
}

// MARK: - Heatmap Tab Content

private struct HeatmapTabContent: View {

    @ObservedObject var viewModel: MarketsViewModel

    private let columns = [
        GridItem(.flexible(), spacing: RouaSpacing.xs),
        GridItem(.flexible(), spacing: RouaSpacing.xs),
        GridItem(.flexible(), spacing: RouaSpacing.xs),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: RouaSpacing.sm) {
                    ForEach(MarketCategory.allCases) { cat in
                        Button {
                            withAnimation(.easeInOut(duration: RouaSpacing.animationFast)) {
                                viewModel.updateCategory(cat)
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
            .padding(.vertical, RouaSpacing.sm)

            if viewModel.heatmapData.isEmpty {
                Spacer()
                EmptyStateView(
                    icon: "square.grid.3x3",
                    title: "لا توجد بيانات",
                    description: "خريطة الحرارة غير متوفرة حالياً"
                )
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: RouaSpacing.xs) {
                        ForEach(viewModel.heatmapData) { item in
                            HeatmapCell(item: item)
                                .onTapGesture {
                                    // Navigate to deep analysis
                                }
                        }
                    }
                    .padding(.horizontal, RouaSpacing.screenPadding)
                    .padding(.vertical, RouaSpacing.sm)
                }
            }
        }
    }
}

// MARK: - Heatmap Cell

private struct HeatmapCell: View {

    let item: HeatmapItem

    private var cellColor: Color {
        if item.changePct > 0 {
            return .rouaProfit.opacity(0.3 + item.colorIntensity * 0.5)
        } else if item.changePct < 0 {
            return .rouaLoss.opacity(0.3 + item.colorIntensity * 0.5)
        }
        return .rouaNeutral.opacity(0.2)
    }

    var body: some View {
        VStack(spacing: RouaSpacing.xs) {
            Text(item.symbol)
                .rouaFont(.captionBold, color: .rouaTextPrimary)
                .lineLimit(1)

            Text(item.formattedChangePct)
                .rouaFont(.micro, color: item.changePct >= 0 ? .rouaProfit : .rouaLoss)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .frame(height: heightForItem)
        .background(
            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                .fill(cellColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                .stroke(Color.rouaGlassBorder, lineWidth: 0.5)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.symbol), \(item.formattedChangePct)")
    }

    private var heightForItem: CGFloat {
        // Scale height by sizeWeight relative to a baseline
        let base: CGFloat = 60
        let maxH: CGFloat = 100
        let normalized = min(item.sizeWeight / 1_000_000_000, 1.0)
        return base + normalized * (maxH - base)
    }
}

// MARK: - News Tab Content

private struct NewsTabContent: View {

    @ObservedObject var viewModel: MarketsViewModel
    @Binding var selectedFilter: NewsFilter

    var body: some View {
        VStack(spacing: 0) {
            // Sentiment filter
            sentimentFilter

            // News list
            if viewModel.newsItems.isEmpty {
                Spacer()
                EmptyStateView(
                    icon: "newspaper",
                    title: "لا توجد أخبار",
                    description: "لم يتم العثور على أخبار حالياً"
                )
                Spacer()
            } else {
                newsList
            }
        }
    }

    private var filteredNews: [NewsItem] {
        switch selectedFilter {
        case .all:
            return viewModel.newsItems
        case .positive:
            return viewModel.newsItems.filter { $0.sentiment == .positive }
        case .negative:
            return viewModel.newsItems.filter { $0.sentiment == .negative }
        case .neutral:
            return viewModel.newsItems.filter { $0.sentiment == .neutral }
        }
    }

    private var sentimentFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RouaSpacing.sm) {
                ForEach(NewsFilter.allCases) { filter in
                    Button {
                        withAnimation(.easeInOut(duration: RouaSpacing.animationFast)) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filter.displayName)
                            .rouaFont(
                                .captionBold,
                                color: selectedFilter == filter ? .white : .rouaTextSecondary
                            )
                            .padding(.horizontal, RouaSpacing.md)
                            .padding(.vertical, RouaSpacing.xs)
                            .background(
                                Capsule().fill(
                                    selectedFilter == filter
                                        ? Color.rouaPrimary
                                        : Color.rouaSurfaceHover
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
        }
        .padding(.vertical, RouaSpacing.sm)
    }

    private var newsList: some View {
        List {
            ForEach(filteredNews) { item in
                NewsItemRow(item: item)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: RouaSpacing.xs, leading: 0, bottom: RouaSpacing.xs, trailing: 0))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - News Filter

enum NewsFilter: String, CaseIterable, Identifiable {
    case all      = "ALL"
    case positive = "POSITIVE"
    case negative = "NEGATIVE"
    case neutral  = "NEUTRAL"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all:      return "الكل"
        case .positive: return "إيجابي"
        case .negative: return "سلبي"
        case .neutral:  return "محايد"
        }
    }
}

// MARK: - News Item Row

private struct NewsItemRow: View {

    let item: NewsItem

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: RouaSpacing.sm) {
                // Title + sentiment
                HStack(alignment: .top) {
                    Text(item.title)
                        .rouaFont(.subheadlineBold, color: .rouaTextPrimary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    sentimentBadge
                }

                // Summary
                if item.summary != nil {
                    Text(item.truncatedSummary())
                        .rouaFont(.footnote, color: .rouaTextSecondary)
                        .lineLimit(2)
                }

                // Source + time
                HStack {
                    if let source = item.source {
                        HStack(spacing: RouaSpacing.xs) {
                            Image(systemName: "doc.text")
                                .font(.system(size: RouaSpacing.iconSmall))
                                .foregroundStyle(.rouaTextTertiary)
                            Text(source)
                                .rouaFont(.caption, color: .rouaTextTertiary)
                        }
                    }

                    Spacer()

                    if let publishedAt = item.publishedAt, let date = Date.fromISO8601(publishedAt) {
                        Text(date.relativeString)
                            .rouaFont(.caption, color: .rouaTextTertiary)
                    }
                }

                // External link
                if let url = item.url, let linkURL = URL(string: url) {
                    Button {
                        UIApplication.shared.open(linkURL)
                    } label: {
                        HStack(spacing: RouaSpacing.xs) {
                            Text("اقرأ المزيد")
                                .rouaFont(.captionBold, color: .rouaPrimary)
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: RouaSpacing.iconSmall))
                                .foregroundStyle(.rouaPrimary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Read full article")
                }
            }
        }
        .padding(.horizontal, RouaSpacing.screenPadding)
    }

    private var sentimentBadge: some View {
        let (fgColor, bgColor, icon) = sentimentColors
        return HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text(item.sentiment.displayName)
                .rouaFont(.micro)
        }
        .foregroundStyle(fgColor)
        .padding(.horizontal, RouaSpacing.sm)
        .padding(.vertical, 2)
        .background(Capsule().fill(bgColor))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sentiment: \(item.sentiment.displayName)")
    }

    private var sentimentColors: (Color, Color, String) {
        switch item.sentiment {
        case .positive: return (.rouaProfit, .rouaProfitLight, "arrowtriangle.up.fill")
        case .negative: return (.rouaLoss, .rouaLossLight, "arrowtriangle.down.fill")
        case .neutral:  return (.rouaNeutral, .rouaNeutral.opacity(0.15), "minus")
        }
    }
}

// MARK: - LazyView Helper

/// Prevents premature view instantiation in NavigationLink destinations.
struct LazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    var body: some View { build() }
}

// MARK: - Preview

#Preview("MarketsView") {
    MarketsView()
}
