// =============================================================================
// PortfolioView.swift — Roua Trading · Portfolio Management
// =============================================================================
// Tabbed portfolio view with Balances, Credentials, and Agent tabs.
// Uses RouaColors, RouaTypography, RouaSpacing, and RouaComponents.
// Supports RTL layout, accessibility, and smooth animations.
// =============================================================================

import SwiftUI

// MARK: - Portfolio Tab

enum PortfolioTab: String, CaseIterable, Identifiable {
    case balances    = "الأرصدة"
    case credentials = "بيانات الاعتماد"
    case agent       = "وكيل التداول"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .balances:    return "wallet.pass"
        case .credentials: return "key.fill"
        case .agent:       return "brain.head.profile"
        }
    }
}

// MARK: - Portfolio View

struct PortfolioView: View {

    @StateObject private var viewModel = PortfolioViewModel()
    @State private var selectedTab: PortfolioTab = .balances
    @State private var showAddCredential = false
    @State private var showAgentConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.rouaBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Segmented Control
                    segmentedControl
                        .padding(.horizontal, RouaSpacing.screenPadding)
                        .padding(.top, RouaSpacing.md)

                    // Tab Content
                    Group {
                        switch selectedTab {
                        case .balances:
                            balancesTab
                        case .credentials:
                            credentialsTab
                        case .agent:
                            agentTab
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("المحفظة")
                        .rouaFont(.headline, color: .rouaTextPrimary)
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingView(message: "جاري التحميل...")
                }
            }
            .alert(
                "تأكيد",
                isPresented: $showAgentConfirmation,
                presenting: viewModel.agentActionPending
            ) { action in
                Button("إلغاء", role: .cancel) {}
                Button("تأكيد") {
                    viewModel.confirmAgentAction(action)
                }
            } message: { action in
                Text(action.message)
            }
            .sheet(isPresented: $showAddCredential) {
                AddCredentialSheet(viewModel: viewModel)
            }
        }
    }

    // MARK: - Segmented Control

    private var segmentedControl: some View {
        HStack(spacing: RouaSpacing.xs) {
            ForEach(PortfolioTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: RouaSpacing.animationFast)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: RouaSpacing.xs) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: RouaSpacing.iconSmall))
                        Text(tab.rawValue)
                            .rouaFont(.footnoteBold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, RouaSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: RouaSpacing.buttonCornerRadius, style: .continuous)
                            .fill(selectedTab == tab ? Color.rouaPrimary : Color.rouaSurfaceLight)
                    )
                    .foregroundStyle(selectedTab == tab ? .white : .rouaTextSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.rawValue)
                .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
            }
        }
        .padding(RouaSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: RouaSpacing.buttonCornerRadius, style: .continuous)
                .fill(Color.rouaSurfaceLight.opacity(0.5))
        )
    }
}

// MARK: - Balances Tab

extension PortfolioView {

    private var balancesTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaSpacing.lg) {
                if let balances = viewModel.balances {
                    // Total Balance Card
                    totalBalanceCard(balances)

                    // Asset Allocation
                    assetAllocationSection(balances)

                    // Assets List
                    assetsListSection(balances)
                } else if viewModel.isLoading {
                    balancesShimmer
                } else if let error = viewModel.errorMessage {
                    ErrorBanner(message: error, onRetry: { Task { await viewModel.refresh() } }) {
                        viewModel.errorMessage = nil
                    }
                    .padding(.horizontal, RouaSpacing.screenPadding)
                    .padding(.top, RouaSpacing.md)
                } else {
                    EmptyStateView(
                        icon: "wallet.pass",
                        title: "لا توجد أرصدة",
                        description: "أضف بيانات اعتماد التبادل لعرض الأرصدة",
                        buttonTitle: "إضافة بيانات اعتماد"
                    ) {
                        showAddCredential = true
                    }
                }
            }
            .padding(.vertical, RouaSpacing.lg)
        }
    }

    private func totalBalanceCard(_ balances: Balances) -> some View {
        GlassCard(glow: .rouaPrimary) {
            VStack(alignment: .leading, spacing: RouaSpacing.md) {
                Text("إجمالي الرصيد")
                    .rouaFont(.subheadline, color: .rouaTextSecondary)

                Text("$\(formatNumber(balances.totalBalance))")
                    .rouaFont(.largeTitle, color: .rouaTextPrimary)
                    .monospacedDigit()

                HStack(spacing: RouaSpacing.lg) {
                    ChangeBadge(
                        value: balances.totalPnl,
                        percentage: balances.totalBalance > 0
                            ? (balances.totalPnl / balances.totalBalance) * 100
                            : 0
                    )

                    StatMini(
                        label: "متاح",
                        value: "$\(formatNumber(balances.availableBalance))"
                    )

                    StatMini(
                        label: "الأصول",
                        value: "\(balances.activeAssetCount)"
                    )
                }
            }
        }
        .padding(.horizontal, RouaSpacing.screenPadding)
    }

    private func assetAllocationSection(_ balances: Balances) -> some View {
        VStack(spacing: RouaSpacing.md) {
            SectionHeader(title: "توزيع الأصول")

            if balances.assets.filter({ $0.total > 0 }).isEmpty {
                Text("لا توجد أصول")
                    .rouaFont(.footnote, color: .rouaTextTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, RouaSpacing.md)
            } else {
                // Horizontal colored bars representing allocation
                let totalUSD = balances.assets.map(\.usdValue).reduce(0, +)
                let sortedAssets = balances.assets
                    .filter { $0.usdValue > 0 }
                    .sorted { $0.usdValue > $1.usdValue }

                VStack(spacing: RouaSpacing.xs) {
                    // Bar visualization
                    GeometryReader { geometry in
                        HStack(spacing: 2) {
                            ForEach(sortedAssets, id: \.asset) { asset in
                                let ratio = totalUSD > 0 ? asset.usdValue / totalUSD : 0
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(asset.allocationColor)
                                    .frame(width: max(2, geometry.size.width * ratio))
                            }
                        }
                    }
                    .frame(height: 8)
                    .clipShape(RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius))

                    // Legend
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: RouaSpacing.xs) {
                        ForEach(sortedAssets.prefix(9), id: \.asset) { asset in
                            HStack(spacing: RouaSpacing.xs) {
                                Circle()
                                    .fill(asset.allocationColor)
                                    .frame(width: 8, height: 8)
                                Text(asset.asset)
                                    .rouaFont(.micro, color: .rouaTextTertiary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .padding(.horizontal, RouaSpacing.screenPadding)
            }
        }
    }

    private func assetsListSection(_ balances: Balances) -> some View {
        VStack(spacing: RouaSpacing.sm) {
            SectionHeader(title: "الأصول")

            ForEach(balances.assets.filter { $0.total > 0 }) { asset in
                assetRow(asset)
            }
        }
        .padding(.horizontal, RouaSpacing.screenPadding)
    }

    private func assetRow(_ asset: AssetBalance) -> some View {
        GlassCard {
            VStack(spacing: RouaSpacing.sm) {
                // Header row
                HStack {
                    Text(asset.asset)
                        .rouaFont(.calloutBold, color: .rouaTextPrimary)

                    if asset.hasPosition {
                        Badge(text: "مفتوح", variant: .info)
                    }

                    Spacer()

                    if let pnl = asset.pnl, let pct = asset.pnlPct {
                        ChangeBadge(value: pnl, percentage: pct)
                    }
                }

                // Amount details
                HStack(spacing: RouaSpacing.xl) {
                    StatMini(label: "متاح", value: formatNumber(asset.free))
                    StatMini(label: "مستخدم", value: formatNumber(asset.used))
                    StatMini(label: "الإجمالي", value: formatNumber(asset.total))
                }

                // USD value
                HStack {
                    Text("القيمة بالدولار")
                        .rouaFont(.caption, color: .rouaTextTertiary)
                    Spacer()
                    Text("$\(formatNumber(asset.usdValue))")
                        .rouaFont(.mono, color: .rouaTextPrimary)
                        .monospacedDigit()
                }
            }
        }
    }

    private var balancesShimmer: some View {
        VStack(spacing: RouaSpacing.lg) {
            GlassCard {
                VStack(alignment: .leading, spacing: RouaSpacing.md) {
                    ShimmerView(width: 100, height: 14)
                    ShimmerView(width: 200, height: 34)
                    HStack(spacing: RouaSpacing.lg) {
                        ShimmerView(width: 80, height: 28)
                        ShimmerView(width: 80, height: 28)
                    }
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)

            ForEach(0..<3, id: \.self) { _ in
                GlassCard {
                    VStack(alignment: .leading, spacing: RouaSpacing.sm) {
                        ShimmerView(width: 60, height: 16)
                        ShimmerView(width: 180, height: 14)
                    }
                }
                .padding(.horizontal, RouaSpacing.screenPadding)
            }
        }
        .padding(.vertical, RouaSpacing.lg)
    }
}

// MARK: - Credentials Tab

extension PortfolioView {

    private var credentialsTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaSpacing.lg) {
                SectionHeader(
                    title: "بيانات الاعتماد",
                    actionTitle: "+ إضافة"
                ) {
                    showAddCredential = true
                }

                if viewModel.credentials.isEmpty {
                    EmptyStateView(
                        icon: "key",
                        title: "لا توجد بيانات اعتماد",
                        description: "أضف مفاتيح API الخاصة بالتبادل للبدء في التداول",
                        buttonTitle: "إضافة بيانات اعتماد"
                    ) {
                        showAddCredential = true
                    }
                } else {
                    ForEach(viewModel.credentials) { credential in
                        credentialRow(credential)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.deleteCredential(id: credential.id)
                                } label: {
                                    Label("حذف", systemImage: "trash")
                                }

                                Button {
                                    viewModel.testCredential(id: credential.id)
                                } label: {
                                    Label("اختبار", systemImage: "antenna.radiowaves.left.and.right")
                                }
                                .tint(.rouaInfo)
                            }
                    }
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
            .padding(.vertical, RouaSpacing.lg)
        }
    }

    private func credentialRow(_ credential: Credential) -> some View {
        GlassCard {
            HStack(spacing: RouaSpacing.md) {
                // Exchange icon
                Image(systemName: "building.columns")
                    .font(.system(size: RouaSpacing.iconLarge))
                    .foregroundStyle(.rouaPrimary)
                    .frame(width: 40, height: 40)
                    .background(Color.rouaPrimary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius))

                // Info
                VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                    Text(credential.exchange)
                        .rouaFont(.calloutBold, color: .rouaTextPrimary)

                    Text(credential.label)
                        .rouaFont(.footnote, color: .rouaTextSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Status badge
                Badge(
                    text: credential.testnet ? "تجريبي" : "نشط",
                    variant: credential.testnet ? .warning : .success
                )

                // Validation indicator
                if credential.isRecentlyValidated {
                    PulsingDot(status: .active, size: 6)
                }
            }
        }
    }
}

// MARK: - Agent Tab

extension PortfolioView {

    private var agentTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaSpacing.lg) {
                // Agent Status Card
                agentStatusCard

                // Strategy Selector
                strategySelectorSection

                // Risk Parameters
                riskParametersSection

                // Open Positions
                if !viewModel.openPositions.isEmpty {
                    openPositionsSection
                }

                // Performance Metrics
                if viewModel.performanceMetrics != nil {
                    performanceSection
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
            .padding(.vertical, RouaSpacing.lg)
        }
    }

    private var agentStatusCard: some View {
        GlassCard(glow: viewModel.agentState?.isActive == true ? .rouaProfit : nil) {
            VStack(spacing: RouaSpacing.md) {
                HStack {
                    PulsingDot(
                        status: viewModel.agentState?.isActive == true ? .active : .inactive,
                        size: 10
                    )

                    Text(viewModel.agentState?.isActive == true ? "الوكيل نشط" : "الوكيل متوقف")
                        .rouaFont(.headline, color: .rouaTextPrimary)

                    Spacer()

                    if let strategy = viewModel.agentState?.strategy {
                        Badge(text: strategy, variant: .info)
                    }
                }

                // Start / Stop Button
                RouaButton(
                    viewModel.agentState?.isActive == true ? "إيقاف الوكيل" : "تشغيل الوكيل",
                    variant: viewModel.agentState?.isActive == true ? .danger : .primary,
                    icon: viewModel.agentState?.isActive == true ? "stop.fill" : "play.fill",
                    isLoading: viewModel.isAgentToggling
                ) {
                    viewModel.agentActionPending = viewModel.agentState?.isActive == true
                        ? .stop
                        : .start(strategy: viewModel.selectedStrategy)
                    showAgentConfirmation = true
                }
            }
        }
    }

    private var strategySelectorSection: some View {
        VStack(spacing: RouaSpacing.md) {
            SectionHeader(title: "استراتيجية التداول")

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: RouaSpacing.sm) {
                ForEach(AgentStrategy.allCases, id: \.self) { strategy in
                    Button {
                        viewModel.selectedStrategy = strategy
                    } label: {
                        HStack(spacing: RouaSpacing.xs) {
                            if viewModel.selectedStrategy == strategy {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            Text(strategy.displayName)
                                .rouaFont(viewModel.selectedStrategy == strategy ? .footnoteBold : .footnote)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, RouaSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                                .fill(viewModel.selectedStrategy == strategy
                                      ? Color.rouaPrimary.opacity(0.2)
                                      : Color.rouaSurfaceLight)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                                .stroke(viewModel.selectedStrategy == strategy
                                        ? Color.rouaPrimary
                                        : Color.rouaGlassBorder,
                                        lineWidth: viewModel.selectedStrategy == strategy ? 1.5 : 0.5)
                        )
                        .foregroundStyle(viewModel.selectedStrategy == strategy
                                         ? .rouaPrimary
                                         : .rouaTextSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(strategy.displayName)
                    .accessibilityAddTraits(viewModel.selectedStrategy == strategy ? .isSelected : [])
                }
            }
        }
    }

    private var riskParametersSection: some View {
        VStack(spacing: RouaSpacing.md) {
            SectionHeader(title: "معلمات المخاطر")

            GlassCard {
                VStack(spacing: RouaSpacing.md) {
                    riskParameterRow(
                        label: "أقصى حجم الصفقة",
                        value: "\(Int(viewModel.maxPositionSize))%",
                        slider: $viewModel.maxPositionSize,
                        range: 1...100
                    )
                    riskParameterRow(
                        label: "أقصى خسارة يومية",
                        value: "\(Int(viewModel.maxDailyLoss))%",
                        slider: $viewModel.maxDailyLoss,
                        range: 1...50
                    )
                    riskParameterRow(
                        label: "أقصى صفقات مفتوحة",
                        value: "\(viewModel.maxOpenPositions)",
                        sliderProxy: $viewModel.maxOpenPositionsDouble,
                        range: 1...20
                    )
                    riskParameterRow(
                        label: "المخاطرة لكل صفقة",
                        value: "\(Int(viewModel.riskPerTrade))%",
                        slider: $viewModel.riskPerTrade,
                        range: 1...10
                    )
                }
            }
        }
    }

    private func riskParameterRow(
        label: String,
        value: String,
        slider: Binding<Double>? = nil,
        sliderProxy: Binding<Double>? = nil,
        range: ClosedRange<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: RouaSpacing.xs) {
            HStack {
                Text(label)
                    .rouaFont(.footnote, color: .rouaTextSecondary)
                Spacer()
                Text(value)
                    .rouaFont(.footnoteBold, color: .rouaPrimary)
                    .monospacedDigit()
            }

            if let slider {
                Slider(value: slider, in: range, step: 1)
                    .tint(.rouaPrimary)
            } else if let sliderProxy {
                Slider(value: sliderProxy, in: range, step: 1)
                    .tint(.rouaPrimary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }

    private var openPositionsSection: some View {
        VStack(spacing: RouaSpacing.sm) {
            SectionHeader(title: "الصفقات المفتوحة")

            ForEach(viewModel.openPositions) { position in
                PositionRow(
                    symbol: position.symbol,
                    side: position.isLong ? .long : .short,
                    quantity: String(format: "%.4f", position.quantity),
                    entryPrice: String(format: "%.2f", position.entryPrice),
                    currentPrice: String(format: "%.2f", position.currentPrice ?? position.entryPrice),
                    pnl: position.unrealizedPnl,
                    pnlPct: position.unrealizedPnlPct ?? 0
                )
            }
        }
    }

    private var performanceSection: some View {
        VStack(spacing: RouaSpacing.sm) {
            SectionHeader(title: "مقاييس الأداء")

            if let metrics = viewModel.performanceMetrics {
                GlassCard {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: RouaSpacing.lg) {
                        StatMini(label: "إجمالي الصفقات", value: "\(metrics.totalTrades)")
                        StatMini(label: "نسبة الفوز", value: metrics.formattedWinRate)
                        StatMini(
                            label: "الربح/الخسارة",
                            value: metrics.formattedTotalPnl,
                            change: metrics.totalPnl
                        )
                        if let sharpe = metrics.sharpeRatio {
                            StatMini(label: "نسبة شارب", value: String(format: "%.2f", sharpe))
                        }
                        if let drawdown = metrics.formattedMaxDrawdown {
                            StatMini(label: "أقصى تراجع", value: drawdown)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Add Credential Sheet

struct AddCredentialSheet: View {

    @ObservedObject var viewModel: PortfolioViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var exchange = ""
    @State private var label = ""
    @State private var apiKey = ""
    @State private var apiSecret = ""
    @State private var passphrase = ""
    @State private var isTestnet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rouaBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: RouaSpacing.lg) {
                        // Exchange
                        VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                            Text("التبادل")
                                .rouaFont(.footnote, color: .rouaTextSecondary)
                            TextField("مثال: Binance", text: $exchange)
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

                        // Label
                        VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                            Text("التسمية")
                                .rouaFont(.footnote, color: .rouaTextSecondary)
                            TextField("مثال: حسابي الرئيسي", text: $label)
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

                        // API Key
                        VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                            Text("مفتاح API")
                                .rouaFont(.footnote, color: .rouaTextSecondary)
                            SecureField("أدخل مفتاح API", text: $apiKey)
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

                        // API Secret
                        VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                            Text("سر API")
                                .rouaFont(.footnote, color: .rouaTextSecondary)
                            SecureField("أدخل سر API", text: $apiSecret)
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

                        // Passphrase (optional)
                        VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                            Text("عبارة المرور (اختياري)")
                                .rouaFont(.footnote, color: .rouaTextSecondary)
                            SecureField("أدخل عبارة المرور", text: $passphrase)
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

                        // Testnet toggle
                        HStack {
                            Text("حساب تجريبي (Testnet)")
                                .rouaFont(.subheadline, color: .rouaTextPrimary)
                            Spacer()
                            Toggle("", isOn: $isTestnet)
                                .tint(.rouaPrimary)
                                .labelsHidden()
                        }
                        .padding(RouaSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius)
                                .fill(Color.rouaSurfaceLight)
                        )

                        // Add button
                        RouaButton(
                            "إضافة بيانات الاعتماد",
                            variant: .primary,
                            icon: "plus",
                            isLoading: viewModel.isAddingCredential,
                            isDisabled: exchange.isEmpty || apiKey.isEmpty || apiSecret.isEmpty
                        ) {
                            viewModel.addCredential(
                                exchange: exchange,
                                label: label.isEmpty ? exchange : label,
                                apiKey: apiKey,
                                apiSecret: apiSecret,
                                passphrase: passphrase.isEmpty ? nil : passphrase,
                                testnet: isTestnet
                            ) {
                                dismiss()
                            }
                        }
                    }
                    .padding(.horizontal, RouaSpacing.screenPadding)
                    .padding(.vertical, RouaSpacing.lg)
                }
            }
            .navigationTitle("إضافة بيانات اعتماد")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") { dismiss() }
                        .rouaFont(.subheadline, color: .rouaTextSecondary)
                }
            }
        }
    }
}

// MARK: - Helper

private func formatNumber(_ value: Double) -> String {
    if value >= 1_000_000 {
        return String(format: "%.2fM", value / 1_000_000)
    } else if value >= 1_000 {
        return String(format: "%.2fK", value / 1_000)
    } else {
        return String(format: "%.2f", value)
    }
}

// MARK: - Asset Color Extension

extension AssetBalance {
    /// Deterministic color for allocation chart.
    var allocationColor: Color {
        let colors: [Color] = [
            .rouaPrimary, .rouaAccent, .rouaProfit,
            .rouaWarning, .rouaInfo, .rouaSecondary,
            .rouaLoss, .rouaNeutral, Color(hex: "FF6B6B"),
        ]
        let hash = asset.hashValue
        let index = abs(hash) % colors.count
        return colors[index]
    }
}

// MARK: - Portfolio View Model

@MainActor
final class PortfolioViewModel: ObservableObject {

    @Published var balances: Balances?
    @Published var credentials: [Credential] = []
    @Published var agentState: AgentState?
    @Published var openPositions: [Position] = []
    @Published var performanceMetrics: PerformanceMetrics?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAgentToggling = false
    @Published var isAddingCredential = false
    @Published var selectedStrategy: AgentStrategy = .auto
    @Published var maxPositionSize: Double = 10
    @Published var maxDailyLoss: Double = 5
    @Published var maxOpenPositions: Int = 5
    @Published var maxOpenPositionsDouble: Double = 5
    @Published var riskPerTrade: Double = 2
    @Published var agentActionPending: AgentAction?

    enum AgentAction {
        case start(strategy: AgentStrategy)
        case stop

        var message: String {
            switch self {
            case .start: return "هل تريد تشغيل وكيل التداول؟"
            case .stop:  return "هل تريد إيقاف وكيل التداول؟"
            }
        }
    }

    func refresh() async {
        isLoading = true
        // TODO: Call API service
        try? await Task.sleep(nanoseconds: 800_000_000)
        isLoading = false
    }

    func deleteCredential(id: String) {
        withAnimation {
            credentials.removeAll { $0.id == id }
        }
        // TODO: Call API service
    }

    func testCredential(id: String) {
        // TODO: Call API service to test connectivity
    }

    func addCredential(
        exchange: String,
        label: String,
        apiKey: String,
        apiSecret: String,
        passphrase: String?,
        testnet: Bool,
        onSuccess: @escaping () -> Void
    ) {
        isAddingCredential = true
        // TODO: Call API service
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.isAddingCredential = false
            onSuccess()
        }
    }

    func confirmAgentAction(_ action: AgentAction) {
        isAgentToggling = true
        // TODO: Call API service
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.isAgentToggling = false
            switch action {
            case .start:
                self?.agentState = AgentState(
                    isActive: true,
                    strategy: self?.selectedStrategy.rawValue,
                    startTime: ISO8601DateFormatter().string(from: Date()),
                    totalTrades: 0,
                    winRate: 0,
                    totalPnl: 0,
                    currentPositions: 0,
                    settings: nil
                )
            case .stop:
                self?.agentState = AgentState(
                    isActive: false,
                    strategy: nil,
                    startTime: nil,
                    totalTrades: nil,
                    winRate: nil,
                    totalPnl: nil,
                    currentPositions: nil,
                    settings: nil
                )
            }
        }
    }
}

// MARK: - Preview

#Preview("Portfolio") {
    PortfolioView()
}
