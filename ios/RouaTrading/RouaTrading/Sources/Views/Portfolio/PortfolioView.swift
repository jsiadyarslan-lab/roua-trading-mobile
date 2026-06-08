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

// MARK: - Agent Action (local to view)

/// Represents a pending agent action that requires user confirmation.
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

// MARK: - Portfolio View

struct PortfolioView: View {

    @StateObject private var viewModel = PortfolioViewModel()
    @State private var selectedTab: PortfolioTab = .balances
    @State private var showAddCredential = false
    @State private var showAgentConfirmation = false

    // Local state previously on inline ViewModel
    @State private var selectedStrategy: AgentStrategy = .auto
    @State private var maxPositionSize: Double = 10
    @State private var maxDailyLoss: Double = 5
    @State private var maxOpenPositions: Int = 5
    @State private var maxOpenPositionsDouble: Double = 5
    @State private var riskPerTrade: Double = 2
    @State private var agentActionPending: AgentAction?
    @State private var isAgentToggling = false

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
            .task {
                viewModel.loadAll()
            }
            .refreshable {
                viewModel.loadAll()
            }
            .overlay {
                // Only show full-screen loading on first load when ALL data is empty.
                // Once any data arrives, hide the overlay so the user can see what loaded.
                if viewModel.isLoading
                    && viewModel.portfolioSummary == nil
                    && viewModel.credentials.isEmpty
                    && viewModel.agentState == nil {
                    LoadingView(message: "جاري التحميل...")
                }
            }
            .alert(
                "تأكيد",
                isPresented: $showAgentConfirmation,
                presenting: agentActionPending
            ) { action in
                Button("إلغاء", role: .cancel) {}
                Button("تأكيد") {
                    confirmAgentAction(action)
                }
            } message: { action in
                Text(action.message)
            }
            .sheet(isPresented: $showAddCredential) {
                AddCredentialSheet(isPresented: $showAddCredential)
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

    // MARK: - Agent Action Handler

    private func confirmAgentAction(_ action: AgentAction) {
        isAgentToggling = true
        switch action {
        case .start(let strategy):
            let request = AgentStartRequest(
                strategy: strategy,
                credentialId: nil,
                symbols: nil,
                maxPositionSizePercent: maxPositionSize,
                maxDailyLossPercent: maxDailyLoss,
                maxOpenPositions: maxOpenPositions,
                riskPerTradePercent: riskPerTrade,
                strategyParams: nil
            )
            Task {
                await viewModel.startAgent(request)
                isAgentToggling = false
            }
        case .stop:
            Task {
                await viewModel.stopAgent()
                isAgentToggling = false
            }
        }
    }
}

// MARK: - Balances Tab

extension PortfolioView {

    private var balancesTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaSpacing.lg) {
                if let summary = viewModel.portfolioSummary {
                    // Total Balance Card
                    totalBalanceCard(summary)

                    // Open Positions (if any)
                    if !summary.positions.isEmpty {
                        positionsSection(summary)
                    }

                    // Risk & Metrics
                    portfolioMetricsSection(summary)
                } else if viewModel.isLoading {
                    balancesShimmer
                } else if let error = viewModel.errorMessage {
                    ErrorBanner(message: error, onRetry: { viewModel.loadAll() }) {
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

    private func totalBalanceCard(_ summary: PortfolioSummary) -> some View {
        GlassCard(glow: .rouaPrimary) {
            VStack(alignment: .leading, spacing: RouaSpacing.md) {
                Text("إجمالي الرصيد")
                    .rouaFont(.subheadline, color: .rouaTextSecondary)

                Text("$\(formatNumber(summary.totalBalance))")
                    .rouaFont(.largeTitle, color: .rouaTextPrimary)
                    .monospacedDigit()

                HStack(spacing: RouaSpacing.lg) {
                    ChangeBadge(
                        value: summary.dailyPnL,
                        percentage: summary.dailyPnLPercent
                    )

                    StatMini(
                        label: "غير محقق",
                        value: "$\(formatNumber(summary.unrealizedPnl))"
                    )

                    StatMini(
                        label: "الصفقات",
                        value: "\(summary.openPositionsCount)"
                    )
                }
            }
        }
        .padding(.horizontal, RouaSpacing.screenPadding)
    }

    private func positionsSection(_ summary: PortfolioSummary) -> some View {
        VStack(spacing: RouaSpacing.sm) {
            SectionHeader(title: "الصفقات المفتوحة")

            ForEach(summary.positions) { position in
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
        .padding(.horizontal, RouaSpacing.screenPadding)
    }

    private func portfolioMetricsSection(_ summary: PortfolioSummary) -> some View {
        VStack(spacing: RouaSpacing.sm) {
            SectionHeader(title: "مقاييس المحفظة")

            GlassCard {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: RouaSpacing.lg) {
                    StatMini(
                        label: "التعرض الإجمالي",
                        value: "$\(formatNumber(summary.totalExposure))"
                    )
                    StatMini(
                        label: "الهامش المستخدم",
                        value: "$\(formatNumber(summary.marginUsed))"
                    )
                    if let available = summary.availableBalance {
                        StatMini(
                            label: "الرصيد المتاح",
                            value: "$\(formatNumber(available))"
                        )
                    }
                    if let totalPnl = summary.totalPnl {
                        StatMini(
                            label: "إجمالي الربح/الخسارة",
                            value: "$\(formatNumber(totalPnl))",
                            change: totalPnl
                        )
                    }
                    StatMini(
                        label: "أقصى تراجع",
                        value: String(format: "%.1f%%", summary.maxDrawdownPercent)
                    )
                    if let marginAvail = summary.marginAvailable {
                        StatMini(
                            label: "الهامش المتاح",
                            value: "$\(formatNumber(marginAvail))"
                        )
                    }
                }
            }
        }
        .padding(.horizontal, RouaSpacing.screenPadding)
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
                                    deleteCredential(id: credential.id)
                                } label: {
                                    Label("حذف", systemImage: "trash")
                                }

                                Button {
                                    testCredential(id: credential.id)
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

    // MARK: - Credential Actions via APIClient

    private func deleteCredential(id: String) {
        withAnimation {
            viewModel.credentials.removeAll { $0.id == id }
        }
        Task {
            do {
                let _: Data = try await APIClient.shared.requestRaw(.portfolioDeleteCredential(id: id))
            } catch {
                viewModel.errorMessage = error.localizedDescription
            }
        }
    }

    private func testCredential(id: String) {
        Task {
            do {
                let _: Data = try await APIClient.shared.requestRaw(.portfolioTestConnectivity)
            } catch {
                viewModel.errorMessage = error.localizedDescription
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
                if !viewModel.agentPositions.isEmpty {
                    openPositionsSection
                }

                // Performance Metrics
                if viewModel.performance != nil {
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
                    isLoading: isAgentToggling
                ) {
                    agentActionPending = viewModel.agentState?.isActive == true
                        ? .stop
                        : .start(strategy: selectedStrategy)
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
                        selectedStrategy = strategy
                    } label: {
                        HStack(spacing: RouaSpacing.xs) {
                            if selectedStrategy == strategy {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            Text(strategy.displayName)
                                .rouaFont(selectedStrategy == strategy ? .footnoteBold : .footnote)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, RouaSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                                .fill(selectedStrategy == strategy
                                      ? Color.rouaPrimary.opacity(0.2)
                                      : Color.rouaSurfaceLight)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                                .stroke(selectedStrategy == strategy
                                        ? Color.rouaPrimary
                                        : Color.rouaGlassBorder,
                                        lineWidth: selectedStrategy == strategy ? 1.5 : 0.5)
                        )
                        .foregroundStyle(selectedStrategy == strategy
                                         ? .rouaPrimary
                                         : .rouaTextSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(strategy.displayName)
                    .accessibilityAddTraits(selectedStrategy == strategy ? .isSelected : [])
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
                        value: "\(Int(maxPositionSize))%",
                        slider: $maxPositionSize,
                        range: 1...100
                    )
                    riskParameterRow(
                        label: "أقصى خسارة يومية",
                        value: "\(Int(maxDailyLoss))%",
                        slider: $maxDailyLoss,
                        range: 1...50
                    )
                    riskParameterRow(
                        label: "أقصى صفقات مفتوحة",
                        value: "\(maxOpenPositions)",
                        sliderProxy: $maxOpenPositionsDouble,
                        range: 1...20
                    )
                    riskParameterRow(
                        label: "المخاطرة لكل صفقة",
                        value: "\(Int(riskPerTrade))%",
                        slider: $riskPerTrade,
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
                    .onChange(of: slider.wrappedValue) { _, newValue in
                        if sliderProxy != nil {
                            maxOpenPositions = Int(newValue)
                        }
                    }
            } else if let sliderProxy {
                Slider(value: sliderProxy, in: range, step: 1)
                    .tint(.rouaPrimary)
                    .onChange(of: sliderProxy.wrappedValue) { _, newValue in
                        maxOpenPositions = Int(newValue)
                    }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }

    private var openPositionsSection: some View {
        VStack(spacing: RouaSpacing.sm) {
            SectionHeader(title: "الصفقات المفتوحة")

            ForEach(viewModel.agentPositions) { position in
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

            if let metrics = viewModel.performance {
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

    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss

    @State private var exchange = ""
    @State private var label = ""
    @State private var apiKey = ""
    @State private var apiSecret = ""
    @State private var passphrase = ""
    @State private var isTestnet = false
    @State private var isSubmitting = false

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
                            isLoading: isSubmitting,
                            isDisabled: exchange.isEmpty || apiKey.isEmpty || apiSecret.isEmpty
                        ) {
                            addCredential()
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

    private func addCredential() {
        isSubmitting = true
        let request = CreateCredentialRequest(
            exchange: exchange,
            label: label.isEmpty ? exchange : label,
            apiKey: apiKey,
            apiSecret: apiSecret,
            passphrase: passphrase.isEmpty ? nil : passphrase,
            testnet: isTestnet ? true : nil,
            keyType: nil
        )
        Task {
            do {
                let _: Data = try await APIClient.shared.requestRaw(
                    .portfolioCreateCredential,
                    body: request
                )
                isSubmitting = false
                dismiss()
            } catch {
                isSubmitting = false
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

// MARK: - Preview

#Preview("Portfolio") {
    PortfolioView()
}
