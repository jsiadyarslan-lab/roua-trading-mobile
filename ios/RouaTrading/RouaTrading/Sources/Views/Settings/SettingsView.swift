// =============================================================================
// SettingsView.swift — Roua Trading · Settings
// =============================================================================
// Tab-based settings with 8 sections matching the web design:
// Account, Subscription, Trading, Notifications, AI, Appearance, Security, Data.
// Uses RouaColors, RouaTypography, RouaSpacing, and RouaComponents.
// Supports RTL layout, accessibility, and smooth animations.
// =============================================================================

import SwiftUI

// MARK: - Settings Tab Enum

/// Tabs matching the web Settings page navigation.
enum SettingsTab: String, CaseIterable, Identifiable {
    case account
    case subscription
    case trading
    case notifications
    case ai
    case appearance
    case security
    case data

    var id: String { rawValue }

    /// Arabic label displayed in the tab bar.
    var label: String {
        switch self {
        case .account:       return "الحساب"
        case .subscription:  return "الاشتراك"
        case .trading:       return "التداول"
        case .notifications: return "الإشعارات"
        case .ai:            return "الذكاء"
        case .appearance:    return "المظهر"
        case .security:      return "الأمان"
        case .data:          return "البيانات"
        }
    }

    /// SF Symbol icon for each tab.
    var icon: String {
        switch self {
        case .account:       return "person.crop.circle"
        case .subscription:  return "crown.fill"
        case .trading:       return "chart.line.uptrend.xyaxis"
        case .notifications: return "bell.fill"
        case .ai:            return "brain"
        case .appearance:    return "paintbrush.fill"
        case .security:      return "shield.lefthalf.filled"
        case .data:          return "externaldrive.fill"
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {

    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var selectedTab: SettingsTab = .account
    @State private var showSignOutConfirmation = false
    @State private var showSignOutAllConfirmation = false
    @State private var showDeleteAccountConfirmation = false
    @State private var showChangePasskey = false

    // AI tab state
    @AppStorage("settings_ai_temperature") private var aiTemperature: Double = 0.7
    @AppStorage("settings_ai_max_tokens") private var aiMaxTokens: Int = 2048

    // Appearance tab state
    @AppStorage("settings_compact_mode") private var compactMode: Bool = false

    // Data tab state
    @AppStorage("settings_hide_balances") private var hideBalances: Bool = false
    @AppStorage("settings_share_usage_data") private var shareUsageData: Bool = true
    @AppStorage("settings_analytics_enabled") private var analyticsEnabled: Bool = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rouaBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Tab bar
                    tabBar

                    // Tab content
                    ScrollView(showsIndicators: false) {
                        tabContent
                            .padding(.horizontal, RouaSpacing.screenPadding)
                            .padding(.vertical, RouaSpacing.lg)
                            .padding(.bottom, RouaSpacing.tabBarHeight + RouaSpacing.lg)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                viewModel.loadAll()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("الإعدادات")
                        .rouaFont(.headline, color: .rouaTextPrimary)
                }
            }
            .alert("تسجيل الخروج", isPresented: $showSignOutConfirmation) {
                Button("إلغاء", role: .cancel) {}
                Button("تسجيل الخروج", role: .destructive) {
                    viewModel.signOut()
                }
            } message: {
                Text("هل أنت متأكد من تسجيل الخروج؟")
            }
            .alert("تسجيل الخروج من جميع الأجهزة", isPresented: $showSignOutAllConfirmation) {
                Button("إلغاء", role: .cancel) {}
                Button("تسجيل الخروج", role: .destructive) {
                    viewModel.signOutAllDevices()
                }
            } message: {
                Text("سيتم تسجيل الخروج من جميع الأجهزة والأجهزة الأخرى. هل أنت متأكد؟")
            }
            .alert("حذف الحساب", isPresented: $showDeleteAccountConfirmation) {
                Button("إلغاء", role: .cancel) {}
                Button("حذف", role: .destructive) {
                    // TODO: Delete account API call
                }
            } message: {
                Text("سيتم حذف حسابك نهائيًا وجميع البيانات المرتبطة به. هذا الإجراء لا يمكن التراجع عنه.")
            }
        }
    }
}

// MARK: - Tab Bar

extension SettingsView {

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RouaSpacing.sm) {
                ForEach(SettingsTab.allCases) { tab in
                    tabPill(tab)
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
            .padding(.vertical, RouaSpacing.sm)
        }
        .background(Color.rouaBackground2)
    }

    private func tabPill(_ tab: SettingsTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selectedTab = tab
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: RouaSpacing.xs) {
                Image(systemName: tab.icon)
                    .font(.system(size: RouaSpacing.iconSmall))
                Text(tab.label)
                    .rouaFont(.footnoteBold)
            }
            .padding(.horizontal, RouaSpacing.md)
            .padding(.vertical, RouaSpacing.sm)
            .background(
                Capsule()
                    .fill(selectedTab == tab ? Color.rouaPrimary : Color.rouaGlassStrong)
            )
            .overlay(
                Capsule()
                    .stroke(selectedTab == tab ? Color.clear : Color.rouaGlassBorder, lineWidth: 1)
            )
            .foregroundStyle(selectedTab == tab ? .white : .rouaTextSecondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
    }
}

// MARK: - Tab Content Router

extension SettingsView {

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .account:       accountTab
        case .subscription:  subscriptionTab
        case .trading:       tradingTab
        case .notifications: notificationsTab
        case .ai:            aiTab
        case .appearance:    appearanceTab
        case .security:      securityTab
        case .data:          dataTab
        }
    }
}

// MARK: - Account Tab

extension SettingsView {

    private var accountTab: some View {
        VStack(spacing: RouaSpacing.xxl) {
            // Profile card
            profileSection

            // API Keys
            VStack(spacing: RouaSpacing.md) {
                SectionHeader(title: "مفاتيح API")

                GlassCard {
                    VStack(spacing: 0) {
                        settingsNavigationRow(
                            icon: "key.fill",
                            iconColor: .rouaAccent,
                            title: "مفاتيح API",
                            value: "إدارة المفاتيح"
                        ) {
                            // TODO: Navigate to API keys
                        }

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        settingsLinkRow(
                            icon: "plus.circle",
                            iconColor: .rouaProfit,
                            title: "إضافة مفتاح جديد"
                        ) {
                            // TODO: Add API key flow
                        }
                    }
                }
            }

            // Account info
            VStack(spacing: RouaSpacing.md) {
                SectionHeader(title: "معلومات الحساب")

                GlassCard {
                    VStack(spacing: 0) {
                        settingsInfoRow(
                            icon: "number",
                            iconColor: .rouaNeutral,
                            title: "معرّف المستخدم",
                            value: viewModel.user?.id.prefix(8).appending("…") ?? "—"
                        )

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        settingsInfoRow(
                            icon: "crown.fill",
                            iconColor: .rouaGold,
                            title: "مستوى الاشتراك",
                            value: viewModel.user?.tier.displayName ?? "Free"
                        )

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        settingsInfoRow(
                            icon: "antenna.radiowaves.left.and.right",
                            iconColor: .rouaProfit,
                            title: "حالة الجلسة",
                            value: viewModel.sessions.isEmpty ? "غير نشط" : "نشط"
                        )
                    }
                }
            }

            // Danger zone
            VStack(spacing: RouaSpacing.md) {
                SectionHeader(title: "المنطقة الخطرة")

                RouaButton(
                    "تسجيل الخروج",
                    variant: .danger,
                    size: .large,
                    icon: "rectangle.portrait.and.arrow.right"
                ) {
                    showSignOutConfirmation = true
                }

                RouaButton(
                    "حذف الحساب",
                    variant: .ghost,
                    size: .medium,
                    icon: "trash"
                ) {
                    showDeleteAccountConfirmation = true
                }
                .foregroundStyle(.rouaLoss)
            }
        }
    }
}

// MARK: - Subscription Tab

extension SettingsView {

    private var subscriptionTab: some View {
        VStack(spacing: RouaSpacing.xxl) {
            // Current plan
            VStack(spacing: RouaSpacing.md) {
                SectionHeader(title: "خطة الاشتراك")

                GlassCard(glow: .rouaGold) {
                    HStack(spacing: RouaSpacing.md) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: RouaSpacing.iconXL))
                            .foregroundStyle(.rouaGold)

                        VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                            Text("خطتك الحالية")
                                .rouaFont(.footnote, color: .rouaTextSecondary)
                            Text(viewModel.user?.tier.displayName ?? "Free")
                                .rouaFont(.title3, color: .rouaGold)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            // Plan comparison
            VStack(spacing: RouaSpacing.md) {
                SectionHeader(title: "مقارنة الخطط")

                VStack(spacing: RouaSpacing.md) {
                    planCard(
                        title: "FREE",
                        price: "مجاني",
                        color: .rouaTextSecondary,
                        features: [
                            "5 إشارات يوميًا",
                            "ماسح أساسي",
                            "بيانات مباشرة متأخرة"
                        ],
                        isCurrent: viewModel.user?.tier == .free
                    )

                    planCard(
                        title: "PRO",
                        price: "$29/شهر",
                        color: .rouaPrimary,
                        features: [
                            "إشارات غير محدودة",
                            "ماسح متقدم",
                            "بيانات مباشرة فورية",
                            "تنبيهات AI",
                            "حدود مخاطر مخصصة"
                        ],
                        isCurrent: viewModel.user?.tier == .pro
                    )

                    planCard(
                        title: "PREMIUM",
                        price: "$79/شهر",
                        color: .rouaGold,
                        features: [
                            "كل مزايا Pro",
                            "تنفيذ تلقائي للإشارات",
                            "نماذج AI متقدمة",
                            "أولوية الدعم",
                            "تقارير متقدمة"
                        ],
                        isCurrent: false
                    )

                    planCard(
                        title: "INSTITUTIONAL",
                        price: "مخصص",
                        color: .rouaAccent,
                        features: [
                            "كل مزايا Premium",
                            "API غير محدود",
                            "مدير حساب مخصص",
                            "SLA مخصص",
                            "تكامل مؤسسي"
                        ],
                        isCurrent: viewModel.user?.tier == .institutional
                    )
                }
            }

            // Upgrade prompt
            if viewModel.user?.tier == .free {
                GlassCard {
                    VStack(spacing: RouaSpacing.md) {
                        Image(systemName: "sparkles")
                            .font(.system(size: RouaSpacing.iconHero))
                            .foregroundStyle(.rouaGold)

                        Text("ارتقِ بخطة التداول الخاصة بك")
                            .rouaFont(.headline, color: .rouaTextPrimary)
                            .multilineTextAlignment(.center)

                        Text("احصل على إشارات غير محدودة، وتنبيهات AI، وأدوات متقدمة مع خطة Pro.")
                            .rouaFont(.subheadline, color: .rouaTextSecondary)
                            .multilineTextAlignment(.center)

                        RouaButton("ترقية الآن", variant: .primary, icon: "arrow.up.circle") {
                            // TODO: Navigate to subscription upgrade
                        }
                    }
                }
            }
        }
    }

    private func planCard(
        title: String,
        price: String,
        color: Color,
        features: [String],
        isCurrent: Bool
    ) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: RouaSpacing.md) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                        Text(title)
                            .rouaFont(.calloutBold, color: color)
                        Text(price)
                            .rouaFont(.footnote, color: .rouaTextSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if isCurrent {
                        Badge(text: "الحالي", variant: .success)
                    }
                }

                // Features
                VStack(alignment: .leading, spacing: RouaSpacing.sm) {
                    ForEach(features, id: \.self) { feature in
                        HStack(spacing: RouaSpacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: RouaSpacing.iconSmall))
                                .foregroundStyle(.rouaProfit)
                            Text(feature)
                                .rouaFont(.footnote, color: .rouaTextSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Trading Tab

extension SettingsView {

    private var tradingTab: some View {
        VStack(spacing: RouaSpacing.xxl) {
            // Active account & order settings
            VStack(spacing: RouaSpacing.md) {
                SectionHeader(title: "إعدادات التداول")

                GlassCard {
                    VStack(spacing: 0) {
                        // Default exchange credential
                        settingsNavigationRow(
                            icon: "building.columns",
                            iconColor: .rouaPrimary,
                            title: "بيانات الاعتماد الافتراضية",
                            value: viewModel.defaultCredentialLabel
                        ) {
                            // TODO: Show credential picker
                        }

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        // Default order type
                        settingsNavigationRow(
                            icon: "doc.text",
                            iconColor: .rouaAccent,
                            title: "نوع الأمر الافتراضي",
                            value: viewModel.defaultOrderType.displayName
                        ) {
                            // TODO: Show order type picker
                        }

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        // Chart type
                        settingsNavigationRow(
                            icon: "chart.bar",
                            iconColor: .rouaCyan,
                            title: "نوع الرسم البياني",
                            value: "شموع يابانية"
                        ) {
                            // TODO: Show chart type picker
                        }

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        // Timeframe
                        settingsNavigationRow(
                            icon: "clock",
                            iconColor: .rouaWarning,
                            title: "الإطار الزمني",
                            value: "15 دقيقة"
                        ) {
                            // TODO: Show timeframe picker
                        }

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        // Confirm before trading
                        settingsToggleRow(
                            icon: "checkmark.shield",
                            iconColor: .rouaProfit,
                            title: "تأكيد قبل التداول",
                            isOn: $viewModel.confirmBeforeTrading
                        )

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        // Auto stop-loss
                        settingsToggleRow(
                            icon: "hand.raised.fill",
                            iconColor: .rouaLoss,
                            title: "وقف خسارة تلقائي",
                            subtitle: "تعيين SL تلقائيًا عند فتح صفقة",
                            isOn: .constant(true)
                        )

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        // Trailing stop
                        settingsToggleRow(
                            icon: "arrow.triangle.2.circlepath",
                            iconColor: .rouaInfo,
                            title: "وقف متحرك",
                            isOn: .constant(false)
                        )
                    }
                }
            }

            // Risk management
            VStack(spacing: RouaSpacing.md) {
                SectionHeader(title: "إدارة المخاطر")

                GlassCard {
                    VStack(spacing: 0) {
                        // Risk limits
                        settingsNavigationRow(
                            icon: "shield.lefthalf.filled",
                            iconColor: .rouaWarning,
                            title: "حدود المخاطر",
                            value: viewModel.riskLimitsSummary
                        ) {
                            // TODO: Show risk limits detail
                        }

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        // Stop-loss default
                        settingsNavigationRow(
                            icon: "hand.thumbsdown.fill",
                            iconColor: .rouaLoss,
                            title: "وقف الخسارة الافتراضي",
                            value: "2%"
                        ) {
                            // TODO: Show SL picker
                        }

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        // Take-profit default
                        settingsNavigationRow(
                            icon: "hand.thumbsup.fill",
                            iconColor: .rouaProfit,
                            title: "جني الأرباح الافتراضي",
                            value: "5%"
                        ) {
                            // TODO: Show TP picker
                        }

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        // Risk per trade
                        settingsNavigationRow(
                            icon: "percent",
                            iconColor: .rouaWarning,
                            title: "المخاطرة لكل صفقة",
                            value: "1%"
                        ) {
                            // TODO: Show risk per trade picker
                        }

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        // Max daily loss
                        settingsNavigationRow(
                            icon: "exclamationmark.octagon.fill",
                            iconColor: .rouaLoss,
                            title: "أقصى خسارة يومية",
                            value: "5%"
                        ) {
                            // TODO: Show max daily loss picker
                        }

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        // Max open positions
                        settingsNavigationRow(
                            icon: "square.stack.3d.up.fill",
                            iconColor: .rouaPrimary,
                            title: "أقصى عدد صفقات مفتوحة",
                            value: "5"
                        ) {
                            // TODO: Show max positions picker
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Notifications Tab

extension SettingsView {

    private var notificationsTab: some View {
        VStack(spacing: RouaSpacing.xxl) {
            VStack(spacing: RouaSpacing.md) {
                SectionHeader(title: "الإشعارات")

                GlassCard {
                    VStack(spacing: 0) {
                        // Push notifications
                        settingsToggleRow(
                            icon: "bell.fill",
                            iconColor: .rouaPrimary,
                            title: "الإشعارات الفورية",
                            isOn: $viewModel.pushNotificationsEnabled
                        )

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        // Signal alerts
                        settingsToggleRow(
                            icon: "antenna.radiowaves.left.and.right",
                            iconColor: .rouaInfo,
                            title: "تنبيهات الإشارات",
                            isOn: $viewModel.signalAlertsEnabled
                        )

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        // Trade alerts
                        settingsToggleRow(
                            icon: "arrow.left.arrow.right",
                            iconColor: .rouaProfit,
                            title: "تنبيهات الصفقات",
                            isOn: $viewModel.tradeAlertsEnabled
                        )

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        // AI alerts
                        settingsToggleRow(
                            icon: "brain",
                            iconColor: .rouaSecondary,
                            title: "تنبيهات الذكاء الاصطناعي",
                            isOn: $viewModel.aiAlertsEnabled
                        )

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        // Scanner alerts
                        settingsToggleRow(
                            icon: "magnifyingglass",
                            iconColor: .rouaAccent,
                            title: "تنبيهات الماسح",
                            isOn: $viewModel.scannerAlertsEnabled
                        )

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        // Risk alerts
                        settingsToggleRow(
                            icon: "exclamationmark.triangle.fill",
                            iconColor: .rouaWarning,
                            title: "تنبيهات المخاطر",
                            isOn: $viewModel.riskAlertsEnabled
                        )

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        // Auto-execute signals
                        settingsToggleRow(
                            icon: "bolt.fill",
                            iconColor: .rouaProfit,
                            title: "تنفيذ الإشارات تلقائيًا",
                            subtitle: "تنفيذ الصفقات تلقائيًا عند تلقي إشارات",
                            isOn: $viewModel.autoExecuteEnabled
                        )

                        if viewModel.autoExecuteEnabled {
                            Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                            // Min confidence slider
                            VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                                HStack {
                                    Text("الحد الأدنى للثقة")
                                        .rouaFont(.footnote, color: .rouaTextSecondary)
                                    Spacer()
                                    Text("\(Int(viewModel.minConfidence))%")
                                        .rouaFont(.footnoteBold, color: .rouaPrimary)
                                        .monospacedDigit()
                                }

                                Slider(value: $viewModel.minConfidence, in: 50...100, step: 5)
                                    .tint(.rouaPrimary)
                            }
                            .padding(.horizontal, RouaSpacing.md)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - AI Tab

extension SettingsView {

    private var aiTab: some View {
        VStack(spacing: RouaSpacing.xxl) {
            // AI model preferences
            VStack(spacing: RouaSpacing.md) {
                SectionHeader(title: "تفضيلات نموذج AI")

                GlassCard {
                    VStack(spacing: 0) {
                        // Default AI model
                        settingsNavigationRow(
                            icon: "cpu",
                            iconColor: .rouaPurple,
                            title: "النموذج الافتراضي",
                            value: "GPT-4o"
                        ) {
                            // TODO: Show AI model picker
                        }

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        // Analysis depth
                        settingsNavigationRow(
                            icon: "waveform.path",
                            iconColor: .rouaCyan,
                            title: "عمق التحليل",
                            value: "متقدم"
                        ) {
                            // TODO: Show analysis depth picker
                        }
                    }
                }
            }

            // AI parameters
            VStack(spacing: RouaSpacing.md) {
                SectionHeader(title: "معاملات AI")

                GlassCard {
                    VStack(spacing: RouaSpacing.lg) {
                        // Temperature
                        VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                            HStack {
                                Image(systemName: "thermometer.medium")
                                    .font(.system(size: RouaSpacing.iconMedium))
                                    .foregroundStyle(.rouaWarning)
                                    .frame(width: 32, height: 32)
                                    .background(Color.rouaWarning.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius))

                                Text("درجة الحرارة")
                                    .rouaFont(.subheadline, color: .rouaTextPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text(String(format: "%.1f", aiTemperature))
                                    .rouaFont(.footnoteBold, color: .rouaWarning)
                                    .monospacedDigit()
                            }

                            Slider(value: $aiTemperature, in: 0...2, step: 0.1)
                                .tint(.rouaWarning)

                            HStack {
                                Text("دقيق")
                                    .rouaFont(.caption, color: .rouaTextTertiary)
                                Spacer()
                                Text("إبداعي")
                                    .rouaFont(.caption, color: .rouaTextTertiary)
                            }
                        }

                        Divider().background(Color.rouaGlassBorder)

                        // Max tokens
                        VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                            HStack {
                                Image(systemName: "text.bubble.fill")
                                    .font(.system(size: RouaSpacing.iconMedium))
                                    .foregroundStyle(.rouaPrimary)
                                    .frame(width: 32, height: 32)
                                    .background(Color.rouaPrimary.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius))

                                Text("الحد الأقصى للرموز")
                                    .rouaFont(.subheadline, color: .rouaTextPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("\(Int(aiMaxTokens))")
                                    .rouaFont(.footnoteBold, color: .rouaPrimary)
                                    .monospacedDigit()
                            }

                            Slider(value: Binding(
                                get: { Double(aiMaxTokens) },
                                set: { aiMaxTokens = Int($0) }
                            ), in: 256...4096, step: 256)
                                .tint(.rouaPrimary)

                            HStack {
                                Text("مختصر")
                                    .rouaFont(.caption, color: .rouaTextTertiary)
                                Spacer()
                                Text("مفصّل")
                                    .rouaFont(.caption, color: .rouaTextTertiary)
                            }
                        }
                    }
                }
            }

            // AI capabilities
            VStack(spacing: RouaSpacing.md) {
                SectionHeader(title: "قدرات AI")

                GlassCard {
                    VStack(spacing: 0) {
                        settingsToggleRow(
                            icon: "text.badge.star",
                            iconColor: .rouaGold,
                            title: "تحليل المشاعر",
                            isOn: .constant(true)
                        )

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        settingsToggleRow(
                            icon: "chart.xyaxis.line",
                            iconColor: .rouaProfit,
                            title: "التحليل الفني AI",
                            isOn: .constant(true)
                        )

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        settingsToggleRow(
                            icon: "newspaper",
                            iconColor: .rouaAccent,
                            title: "تحليل الأخبار",
                            isOn: .constant(true)
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Appearance Tab

extension SettingsView {

    private var appearanceTab: some View {
        VStack(spacing: RouaSpacing.xxl) {
            // Theme selector
            VStack(spacing: RouaSpacing.md) {
                SectionHeader(title: "المظهر")

                GlassCard {
                    VStack(spacing: 0) {
                        // Theme
                        HStack(spacing: RouaSpacing.md) {
                            Image(systemName: "moon.stars.fill")
                                .font(.system(size: RouaSpacing.iconMedium))
                                .foregroundStyle(.rouaPrimary)
                                .frame(width: 32, height: 32)
                                .background(Color.rouaPrimary.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius))

                            Text("السمة")
                                .rouaFont(.subheadline, color: .rouaTextPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text("داكن")
                                .rouaFont(.footnote, color: .rouaTextTertiary)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("السمة: داكن")

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        // Compact mode
                        settingsToggleRow(
                            icon: "rectangle.compress.vertical",
                            iconColor: .rouaAccent,
                            title: "الوضع المضغوط",
                            subtitle: "تقليل المسافات لعرض المزيد من المحتوى",
                            isOn: $compactMode
                        )
                    }
                }
            }

            // Language
            VStack(spacing: RouaSpacing.md) {
                SectionHeader(title: languageManager.isArabic ? "اللغة" : "Language")

                GlassCard {
                    VStack(spacing: 0) {
                        // Language picker
                        ForEach(AppLanguage.allCases) { lang in
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    languageManager.setLanguage(lang)
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                HStack(spacing: RouaSpacing.md) {
                                    Image(systemName: lang == .arabic ? "text.alignright" : "text.alignleft")
                                        .font(.system(size: RouaSpacing.iconMedium))
                                        .foregroundStyle(lang == .arabic ? .rouaPrimary : .rouaAccent)
                                        .frame(width: 32, height: 32)
                                        .background((lang == .arabic ? Color.rouaPrimary : Color.rouaAccent).opacity(0.15))
                                        .clipShape(RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius))

                                    Text(lang.nativeName)
                                        .rouaFont(.subheadline, color: .rouaTextPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    if languageManager.currentLanguage == lang {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: RouaSpacing.iconMedium))
                                            .foregroundStyle(.rouaPrimary)
                                    }
                                }
                                .contentShape(Rectangle())
                                .padding(.vertical, RouaSpacing.xs)
                            }
                            .buttonStyle(.plain)

                            if lang != AppLanguage.allCases.last {
                                Divider().background(Color.rouaGlassBorder)
                            }
                        }
                    }
                }
            }

            // About (app version)
            VStack(spacing: RouaSpacing.md) {
                SectionHeader(title: "حول")

                GlassCard {
                    VStack(spacing: 0) {
                        settingsInfoRow(
                            icon: "info.circle",
                            iconColor: .rouaNeutral,
                            title: "إصدار التطبيق",
                            value: viewModel.appVersion
                        )

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        settingsLinkRow(
                            icon: "doc.text",
                            iconColor: .rouaPrimary,
                            title: "شروط الخدمة"
                        ) {
                            // TODO: Open terms URL
                        }

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        settingsLinkRow(
                            icon: "hand.raised",
                            iconColor: .rouaAccent,
                            title: "سياسة الخصوصية"
                        ) {
                            // TODO: Open privacy URL
                        }

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        settingsLinkRow(
                            icon: "questionmark.circle",
                            iconColor: .rouaProfit,
                            title: "الدعم والاتصال"
                        ) {
                            // TODO: Open support
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Security Tab

extension SettingsView {

    private var securityTab: some View {
        VStack(spacing: RouaSpacing.xxl) {
            // Active Sessions
            VStack(spacing: RouaSpacing.md) {
                SectionHeader(title: "الجلسات النشطة")

                GlassCard {
                    VStack(alignment: .leading, spacing: RouaSpacing.md) {
                        HStack {
                            Text("الجلسات النشطة")
                                .rouaFont(.calloutBold, color: .rouaTextPrimary)
                            Spacer()
                            Text("\(viewModel.sessions.count)")
                                .rouaFont(.calloutBold, color: .rouaPrimary)
                        }

                        if viewModel.sessions.isEmpty {
                            Text("لا توجد جلسات نشطة")
                                .rouaFont(.footnote, color: .rouaTextTertiary)
                        } else {
                            ForEach(viewModel.sessions) { session in
                                sessionRow(session)
                            }
                        }

                        // Sign out all devices
                        RouaButton(
                            "تسجيل الخروج من جميع الأجهزة",
                            variant: .secondary,
                            size: .small,
                            icon: "rectangle.portrait.and.arrow.right"
                        ) {
                            showSignOutAllConfirmation = true
                        }
                    }
                }
            }

            // Authentication
            VStack(spacing: RouaSpacing.md) {
                SectionHeader(title: "المصادقة")

                GlassCard {
                    VStack(spacing: 0) {
                        // Biometric auth toggle
                        settingsToggleRow(
                            icon: viewModel.biometricIcon,
                            iconColor: .rouaProfit,
                            title: "المصادقة البيومترية",
                            subtitle: viewModel.biometricLabel,
                            isOn: $viewModel.biometricEnabled
                        )

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        // Passkey
                        Button {
                            showChangePasskey = true
                        } label: {
                            HStack(spacing: RouaSpacing.md) {
                                Image(systemName: "key.fill")
                                    .font(.system(size: RouaSpacing.iconMedium))
                                    .foregroundStyle(.rouaAccent)
                                    .frame(width: 32, height: 32)
                                    .background(Color.rouaAccent.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius))

                                Text("تغيير مفتاح المرور")
                                    .rouaFont(.subheadline, color: .rouaTextPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Image(systemName: "chevron.left")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.rouaTextTertiary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("تغيير مفتاح المرور")

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        // Two-factor authentication
                        settingsNavigationRow(
                            icon: "lock.shield.fill",
                            iconColor: .rouaWarning,
                            title: "المصادقة الثنائية",
                            value: "غير مفعّلة"
                        ) {
                            // TODO: Navigate to 2FA setup
                        }
                    }
                }
            }
        }
    }

    private func sessionRow(_ session: AuthSession) -> some View {
        HStack(spacing: RouaSpacing.md) {
            // Device icon
            Image(systemName: session.isMobile ? "iphone" : "desktopcomputer")
                .font(.system(size: RouaSpacing.iconMedium))
                .foregroundStyle(.rouaTextSecondary)
                .frame(width: 32, height: 32)
                .background(Color.rouaSurfaceLight)
                .clipShape(RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius))

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(session.deviceLabel)
                    .rouaFont(.footnoteBold, color: .rouaTextPrimary)
                    .lineLimit(1)

                HStack(spacing: RouaSpacing.sm) {
                    if let ip = session.ipAddress {
                        Text(ip)
                            .rouaFont(.micro, color: .rouaTextTertiary)
                    }
                    Text(session.lastActive)
                        .rouaFont(.micro, color: .rouaTextTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Revoke button
            Button {
                withAnimation {
                    viewModel.revokeSession(id: session.id)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: RouaSpacing.iconMedium))
                    .foregroundStyle(.rouaLoss)
            }
            .accessibilityLabel("إلغاء الجلسة")
        }
        .padding(.vertical, RouaSpacing.xs)
    }
}

// MARK: - Data Tab

extension SettingsView {

    private var dataTab: some View {
        VStack(spacing: RouaSpacing.xxl) {
            // Export data
            VStack(spacing: RouaSpacing.md) {
                SectionHeader(title: "تصدير البيانات")

                GlassCard {
                    VStack(spacing: 0) {
                        settingsNavigationRow(
                            icon: "square.and.arrow.up",
                            iconColor: .rouaPrimary,
                            title: "تصدير بيانات التداول",
                            value: "CSV"
                        ) {
                            // TODO: Export trade data
                        }

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        settingsNavigationRow(
                            icon: "doc.richtext",
                            iconColor: .rouaAccent,
                            title: "تصدير سجل الإشارات",
                            value: "JSON"
                        ) {
                            // TODO: Export signal history
                        }

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        settingsNavigationRow(
                            icon: "chart.pie",
                            iconColor: .rouaProfit,
                            title: "تقرير الأداء",
                            value: "PDF"
                        ) {
                            // TODO: Export performance report
                        }
                    }
                }
            }

            // Storage
            VStack(spacing: RouaSpacing.md) {
                SectionHeader(title: "التخزين")

                GlassCard {
                    VStack(spacing: 0) {
                        settingsInfoRow(
                            icon: "internaldrive",
                            iconColor: .rouaNeutral,
                            title: "مساحة التخزين المستخدمة",
                            value: "23.4 ميجابايت"
                        )

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        settingsLinkRow(
                            icon: "trash.circle",
                            iconColor: .rouaLoss,
                            title: "مسح ذاكرة التخزين المؤقت"
                        ) {
                            // TODO: Clear cache
                        }
                    }
                }
            }

            // Privacy
            VStack(spacing: RouaSpacing.md) {
                SectionHeader(title: "الخصوصية")

                GlassCard {
                    VStack(spacing: 0) {
                        settingsToggleRow(
                            icon: "eye.slash.fill",
                            iconColor: .rouaPrimary,
                            title: "إخفاء الأرصدة",
                            subtitle: "إخفاء قيم الأرصدة في الواجهة",
                            isOn: $hideBalances
                        )

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        settingsToggleRow(
                            icon: "chart.bar.doc.horizontal",
                            iconColor: .rouaAccent,
                            title: "مشاركة بيانات الاستخدام",
                            subtitle: "المساعدة في تحسين التطبيق",
                            isOn: $shareUsageData
                        )

                        Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                        settingsToggleRow(
                            icon: "dot.radiowaves.left.and.right",
                            iconColor: .rouaWarning,
                            title: "التحليلات",
                            subtitle: "السماح بجمع بيانات التحليلات",
                            isOn: $analyticsEnabled
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Profile Section (shared with Account tab)

extension SettingsView {

    private var profileSection: some View {
        VStack(spacing: RouaSpacing.md) {
            SectionHeader(title: "الملف الشخصي")

            GlassCard {
                HStack(spacing: RouaSpacing.md) {
                    // Avatar
                    AvatarView(
                        imageURL: viewModel.user?.avatarUrl,
                        initials: viewModel.user?.initials ?? "؟",
                        size: .large
                    )

                    // Info
                    VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                        Text(viewModel.user?.displayName ?? "مستخدم")
                            .rouaFont(.headline, color: .rouaTextPrimary)
                            .lineLimit(1)

                        Text(viewModel.user?.email ?? "")
                            .rouaFont(.footnote, color: .rouaTextSecondary)
                            .lineLimit(1)

                        // Tier badge
                        tierBadge
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Edit button
                    Button {
                        // TODO: Navigate to edit profile
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: RouaSpacing.iconMedium))
                            .foregroundStyle(.rouaPrimary)
                            .frame(width: 36, height: 36)
                            .background(Color.rouaPrimary.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("تعديل الملف الشخصي")
                }
            }
        }
    }

    private var tierBadge: some View {
        let tier: UserTier = viewModel.user?.tier ?? .free
        return Badge(
            text: tier.displayName,
            variant: tier == .institutional ? .warning : tier == .pro ? .info : .neutral
        )
    }
}

// MARK: - Shared Row Components

extension SettingsView {

    private func settingsToggleRow(
        icon: String,
        iconColor: Color = .rouaPrimary,
        title: String,
        subtitle: String? = nil,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: RouaSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: RouaSpacing.iconMedium))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .rouaFont(.subheadline, color: .rouaTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let subtitle {
                    Text(subtitle)
                        .rouaFont(.caption, color: .rouaTextTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Toggle("", isOn: isOn)
                .tint(.rouaPrimary)
                .labelsHidden()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(isOn.wrappedValue ? "مفعّل" : "معطّل")")
        .accessibilityAddTraits(.isButton)
    }

    private func settingsNavigationRow(
        icon: String,
        iconColor: Color = .rouaPrimary,
        title: String,
        value: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: RouaSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: RouaSpacing.iconMedium))
                    .foregroundStyle(iconColor)
                    .frame(width: 32, height: 32)
                    .background(iconColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .rouaFont(.subheadline, color: .rouaTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(value)
                        .rouaFont(.caption, color: .rouaTextTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.rouaTextTertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title): \(value)")
    }

    private func settingsInfoRow(
        icon: String,
        iconColor: Color = .rouaPrimary,
        title: String,
        value: String
    ) -> some View {
        HStack(spacing: RouaSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: RouaSpacing.iconMedium))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius))

            Text(title)
                .rouaFont(.subheadline, color: .rouaTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(value)
                .rouaFont(.footnote, color: .rouaTextTertiary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }

    private func settingsLinkRow(
        icon: String,
        iconColor: Color = .rouaPrimary,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: RouaSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: RouaSpacing.iconMedium))
                    .foregroundStyle(iconColor)
                    .frame(width: 32, height: 32)
                    .background(iconColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius))

                Text(title)
                    .rouaFont(.subheadline, color: .rouaPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "arrow.up.left")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.rouaTextTertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

// MARK: - Local UI State
// All @AppStorage and @State properties are declared on the main SettingsView struct
// to ensure proper SwiftUI binding support.

// MARK: - Preview

#Preview("Settings") {
    SettingsView()
}
