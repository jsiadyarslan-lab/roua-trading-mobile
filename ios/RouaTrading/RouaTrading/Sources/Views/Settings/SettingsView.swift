// =============================================================================
// SettingsView.swift — Roua Trading · Settings
// =============================================================================
// Profile, Security, Notifications, Trading, and About sections.
// Uses RouaColors, RouaTypography, RouaSpacing, and RouaComponents.
// Supports RTL layout, accessibility, and smooth animations.
// =============================================================================

import SwiftUI

// MARK: - Settings View

struct SettingsView: View {

    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var showSignOutConfirmation = false
    @State private var showSignOutAllConfirmation = false
    @State private var showChangePasskey = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rouaBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: RouaSpacing.xxl) {
                        // Profile Section
                        profileSection

                        // Security Section
                        securitySection

                        // Notifications Section
                        notificationsSection

                        // Trading Section
                        tradingSection

                        // Language Section
                        languageSection

                        // About Section
                        aboutSection

                        // Logout
                        logoutButton
                    }
                    .padding(.horizontal, RouaSpacing.screenPadding)
                    .padding(.vertical, RouaSpacing.lg)
                    // Bottom safe area for tab bar
                    .padding(.bottom, RouaSpacing.tabBarHeight + RouaSpacing.lg)
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
        }
    }
}

// MARK: - Profile Section

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

// MARK: - Security Section

extension SettingsView {

    private var securitySection: some View {
        VStack(spacing: RouaSpacing.md) {
            SectionHeader(title: "الأمان")

            // Active Sessions
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

            // Biometric & Passkey
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

                    // Change passkey
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

// MARK: - Notifications Section

extension SettingsView {

    private var notificationsSection: some View {
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
                                Text("\(viewModel.minConfidence)%")
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

// MARK: - Language Section

extension SettingsView {

    private var languageSection: some View {
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
    }
}

// MARK: - Trading Section

extension SettingsView {

    private var tradingSection: some View {
        VStack(spacing: RouaSpacing.md) {
            SectionHeader(title: "التداول")

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

                    // Confirm before trading
                    settingsToggleRow(
                        icon: "checkmark.shield",
                        iconColor: .rouaProfit,
                        title: "تأكيد قبل التداول",
                        isOn: $viewModel.confirmBeforeTrading
                    )

                    Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                    // Risk limits
                    settingsNavigationRow(
                        icon: "shield.lefthalf.filled",
                        iconColor: .rouaWarning,
                        title: "حدود المخاطر",
                        value: viewModel.riskLimitsSummary
                    ) {
                        // TODO: Show risk limits detail
                    }
                }
            }
        }
    }
}

// MARK: - About Section

extension SettingsView {

    private var aboutSection: some View {
        VStack(spacing: RouaSpacing.md) {
            SectionHeader(title: "حول")

            GlassCard {
                VStack(spacing: 0) {
                    // App version
                    settingsInfoRow(
                        icon: "info.circle",
                        iconColor: .rouaNeutral,
                        title: "إصدار التطبيق",
                        value: viewModel.appVersion
                    )

                    Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                    // Terms of Service
                    settingsLinkRow(
                        icon: "doc.text",
                        iconColor: .rouaPrimary,
                        title: "شروط الخدمة"
                    ) {
                        // TODO: Open terms URL
                    }

                    Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                    // Privacy Policy
                    settingsLinkRow(
                        icon: "hand.raised",
                        iconColor: .rouaAccent,
                        title: "سياسة الخصوصية"
                    ) {
                        // TODO: Open privacy URL
                    }

                    Divider().background(Color.rouaGlassBorder).padding(.vertical, RouaSpacing.sm)

                    // Support
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

// MARK: - Logout Button

extension SettingsView {

    private var logoutButton: some View {
        RouaButton(
            "تسجيل الخروج",
            variant: .danger,
            size: .large,
            icon: "rectangle.portrait.and.arrow.right"
        ) {
            showSignOutConfirmation = true
        }
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

// MARK: - Preview

#Preview("Settings") {
    SettingsView()
}
