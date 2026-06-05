// =============================================================================
// SymbolPickerView.swift — Roua Trading · Symbol Search & Picker
// =============================================================================
// Full-sheet symbol picker with search, popular symbols, recent history,
// and search results from the API.
//
// Each symbol row shows: name, current price, 24h change.
// Tap to select → dismisses the sheet.
//
// RTL-aware (Arabic). Uses RouaComponents theme system.
// =============================================================================

import SwiftUI

// MARK: - Symbol Item

/// Lightweight model for displaying a symbol in the picker list.
struct SymbolItem: Identifiable, Hashable {
    let id: String       // Same as symbol
    let symbol: String
    let name: String
    let price: Double
    let change: Double
    let changePct: Double
    let category: MarketCategory

    var isPositive: Bool { change >= 0 }
}

// MARK: - Symbol Picker View

/// Full-sheet symbol search and selection interface.
///
/// Layout:
/// 1. Search bar at top
/// 2. Popular symbols (when not searching)
/// 3. Recent symbols (when not searching)
/// 4. Search results (when searching)
///
/// Each row: symbol circle, name + full name, price + change badge.
struct SymbolPickerView: View {

    // MARK: - Properties

    let selectedSymbol: String
    let onSelect: (String) -> Void

    // MARK: - State

    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @State private var searchResults: [SymbolItem] = []
    @Environment(\.dismiss) private var dismiss

    // MARK: - Popular Symbols

    private let popularSymbols: [SymbolItem] = [
        SymbolItem(id: "BTCUSDT", symbol: "BTCUSDT", name: "Bitcoin", price: 67500, change: 1250, changePct: 1.89, category: .crypto),
        SymbolItem(id: "ETHUSDT", symbol: "ETHUSDT", name: "Ethereum", price: 3620, change: -45, changePct: -1.23, category: .crypto),
        SymbolItem(id: "SOLUSDT", symbol: "SOLUSDT", name: "Solana", price: 185, change: 8.5, changePct: 4.82, category: .crypto),
        SymbolItem(id: "BNBUSDT", symbol: "BNBUSDT", name: "BNB", price: 610, change: -12, changePct: -1.93, category: .crypto),
        SymbolItem(id: "XRPUSDT", symbol: "XRPUSDT", name: "Ripple", price: 2.35, change: 0.15, changePct: 6.82, category: .crypto),
        SymbolItem(id: "ADAUSDT", symbol: "ADAUSDT", name: "Cardano", price: 0.98, change: -0.03, changePct: -2.97, category: .crypto),
        SymbolItem(id: "DOGEUSDT", symbol: "DOGEUSDT", name: "Dogecoin", price: 0.38, change: 0.02, changePct: 5.56, category: .crypto),
        SymbolItem(id: "AVAXUSDT", symbol: "AVAXUSDT", name: "Avalanche", price: 38.50, change: 1.20, changePct: 3.21, category: .crypto),
    ]

    // MARK: - Recent Symbols

    private let recentSymbols: [SymbolItem] = [
        SymbolItem(id: "BTCUSDT", symbol: "BTCUSDT", name: "Bitcoin", price: 67500, change: 1250, changePct: 1.89, category: .crypto),
        SymbolItem(id: "ETHUSDT", symbol: "ETHUSDT", name: "Ethereum", price: 3620, change: -45, changePct: -1.23, category: .crypto),
        SymbolItem(id: "SOLUSDT", symbol: "SOLUSDT", name: "Solana", price: 185, change: 8.5, changePct: 4.82, category: .crypto),
    ]

    // MARK: - Computed

    /// Whether the search field has text.
    private var hasSearchText: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Filtered search results.
    private var filteredResults: [SymbolItem] {
        if !hasSearchText { return [] }

        let query = searchText.uppercased()
        // First try local filter, then use API results if available
        if !searchResults.isEmpty {
            return searchResults
        }
        return popularSymbols.filter {
            $0.symbol.contains(query) || $0.name.uppercased().contains(query)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: RouaSpacing.lg) {
                    if hasSearchText {
                        // Search results
                        searchResultsSection
                    } else {
                        // Popular symbols
                        popularSymbolsSection

                        // Recent symbols
                        recentSymbolsSection
                    }
                }
                .padding(.bottom, RouaSpacing.xxxl)
            }
            .background(Color.rouaBackground)
            .navigationTitle("اختر زوجاً")  // Select a pair
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.rouaTextTertiary)
                    }
                    .accessibilityLabel("Close")
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "ابحث عن زوج تداول..."  // Search for a trading pair...
            )
            .onChange(of: searchText) {
                performSearch(searchText)
            }
        }
        .presentationBackground(Color.rouaBackground)
    }

    // MARK: - Popular Symbols Section

    private var popularSymbolsSection: some View {
        VStack(spacing: RouaSpacing.md) {
            SectionHeader(title: "الأزواج الشائعة")  // Popular Pairs

            LazyVStack(spacing: RouaSpacing.sm) {
                ForEach(popularSymbols) { item in
                    symbolRow(item)
                }
            }
        }
    }

    // MARK: - Recent Symbols Section

    private var recentSymbolsSection: some View {
        VStack(spacing: RouaSpacing.md) {
            SectionHeader(
                title: "الأخيرة",  // Recent
                actionTitle: "مسح",  // Clear
                action: {
                    // TODO: Clear recent symbols from UserDefaults
                }
            )

            LazyVStack(spacing: RouaSpacing.sm) {
                ForEach(recentSymbols) { item in
                    symbolRow(item)
                }
            }
        }
    }

    // MARK: - Search Results Section

    @ViewBuilder
    private var searchResultsSection: some View {
        if isSearching {
            VStack(spacing: RouaSpacing.sm) {
                ForEach(0..<5, id: \.self) { _ in
                    ShimmerView(height: RouaSpacing.tickerRowHeight)
                }
            }
        } else if filteredResults.isEmpty {
            EmptyStateView(
                icon: "magnifyingglass",
                title: "لا توجد نتائج",  // No results
                description: "جرّب البحث بكلمات مختلفة"  // Try different search terms
            )
            .padding(.top, RouaSpacing.xxxl)
        } else {
            VStack(spacing: RouaSpacing.md) {
                SectionHeader(title: "نتائج البحث")  // Search Results

                LazyVStack(spacing: RouaSpacing.sm) {
                    ForEach(filteredResults) { item in
                        symbolRow(item)
                    }
                }
            }
        }
    }

    // MARK: - Symbol Row

    private func symbolRow(_ item: SymbolItem) -> some View {
        Button {
            selectSymbol(item)
        } label: {
            HStack(spacing: RouaSpacing.md) {
                // Symbol abbreviation circle
                Text(String(item.symbol.prefix(2)))
                    .rouaFont(.captionBold, color: .rouaTextPrimary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(
                                item.symbol == selectedSymbol
                                    ? Color.rouaPrimary.opacity(0.2)
                                    : Color.rouaSurfaceLight
                            )
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                item.symbol == selectedSymbol
                                    ? Color.rouaPrimary
                                    : Color.clear,
                                lineWidth: 1.5
                            )
                    )

                // Name column
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.symbol)
                        .rouaFont(.calloutBold, color: .rouaTextPrimary)
                        .lineLimit(1)

                    Text(item.name)
                        .rouaFont(.footnote, color: .rouaTextSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Category badge
                Badge(
                    text: item.category.displayName,
                    variant: .neutral
                )

                // Price + change
                VStack(alignment: .trailing, spacing: 2) {
                    Text(item.price.asPrice())
                        .rouaFont(.calloutBold, color: .rouaTextPrimary)
                        .monospacedDigit()
                        .lineLimit(1)

                    ChangeBadge(
                        value: item.change,
                        percentage: item.changePct,
                        showArrow: true
                    )
                }
            }
            .padding(.horizontal, RouaSpacing.md)
            .padding(.vertical, RouaSpacing.sm)
            .frame(height: RouaSpacing.tickerRowHeight)
            .background(
                RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                    .fill(
                        item.symbol == selectedSymbol
                            ? Color.rouaPrimary.opacity(0.06)
                            : Color.rouaSurface
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                    .stroke(
                        item.symbol == selectedSymbol
                            ? Color.rouaPrimary.opacity(0.3)
                            : Color.rouaGlassBorder,
                        lineWidth: item.symbol == selectedSymbol ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(item.symbol), \(item.name), price \(item.price.asPrice()), " +
            "\(item.isPositive ? "up" : "down") \(abs(item.changePct)) percent"
        )
        .accessibilityAddTraits(item.symbol == selectedSymbol ? .isSelected : [])
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Actions

    private func selectSymbol(_ item: SymbolItem) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onSelect(item.symbol)
        // TODO: Save to recent symbols in UserDefaults
        dismiss()
    }

    private func performSearch(_ query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true

        // TODO: Replace with actual API call
        // APIClient.shared.request(.exchangeAdapters, query: ["search": query])
        //   .sink { results in self.searchResults = results }

        // Simulated search delay
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            // Simulate: return matching popular symbols
            let q = query.uppercased()
            searchResults = popularSymbols.filter {
                $0.symbol.contains(q) || $0.name.uppercased().contains(q)
            }
            isSearching = false
        }
    }
}

// =============================================================================
// MARK: - Preview
// =============================================================================

#Preview("SymbolPickerView") {
    SymbolPickerView(
        selectedSymbol: "BTCUSDT",
        onSelect: { symbol in print("Selected: \(symbol)") }
    )
}
