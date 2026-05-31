import SwiftUI

struct SettingsView: View {
    @ObservedObject private var authService = AuthService.shared
    @AppStorage("appLanguage") private var appLanguage = "ar"
    @State private var biometricEnabled = true
    @State private var pushEnabled = true
    @State private var showLogout = false

    private let languages = [
        ("ar", "العربية", "🇸🇦"),
        ("en", "English", "🇬🇧"),
        ("fr", "Français", "🇫🇷"),
        ("tr", "Türkçe", "🇹🇷"),
        ("es", "Español", "🇪🇸"),
        ("de", "Deutsch", "🇩🇪"),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaTheme.Spacing.lg) {
                Text("الإعدادات")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(RouaTheme.Colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Profile Card
                GlassCard {
                    HStack(spacing: RouaTheme.Spacing.lg) {
                        ZStack {
                            Circle().fill(RouaTheme.Colors.accentGradient).frame(width: 56, height: 56)
                            Image(systemName: "person.fill").font(.system(size: 24)).foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authService.currentUser?.displayName ?? "المتداول").font(.system(size: 16, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary)
                            Text(authService.currentUser?.email ?? "").font(.system(size: 12)).foregroundStyle(RouaTheme.Colors.textSecondary)
                            if let tier = authService.currentUser?.tier {
                                Text(tier).font(.system(size: 10, weight: .medium)).foregroundStyle(RouaTheme.Colors.accent).padding(.horizontal, 6).padding(.vertical, 2).background(RouaTheme.Colors.accent.opacity(0.1)).clipShape(Capsule())
                            }
                        }
                    }
                }

                // Language Selector
                GlassCard {
                    VStack(alignment: .leading, spacing: RouaTheme.Spacing.md) {
                        Text("اللغة").font(.system(size: 14, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                            ForEach(languages, id: \.0) { lang in
                                Button {
                                    appLanguage = lang.0
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(lang.2).font(.system(size: 16))
                                        Text(lang.1).font(.system(size: 11, weight: appLanguage == lang.0 ? .bold : .medium))
                                    }
                                    .foregroundStyle(appLanguage == lang.0 ? .white : RouaTheme.Colors.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(appLanguage == lang.0 ? RouaTheme.Colors.accent : RouaTheme.Colors.surfaceElevated)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                            }
                        }
                    }
                }

                // Settings Toggles
                GlassCard {
                    VStack(spacing: RouaTheme.Spacing.md) {
                        Toggle(isOn: $biometricEnabled) {
                            Text("الفتح البيومتري").font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textPrimary)
                        }.tint(RouaTheme.Colors.accent)
                        Toggle(isOn: $pushEnabled) {
                            Text("الإشعارات").font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textPrimary)
                        }.tint(RouaTheme.Colors.accent)
                    }
                }

                // App Info
                GlassCard {
                    VStack(spacing: RouaTheme.Spacing.sm) {
                        HStack { Text("الإصدار").font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textSecondary); Spacer(); Text("3.0.0").font(.system(size: 14, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textPrimary) }
                        HStack { Text("البناء").font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textSecondary); Spacer(); Text("Phase 2").font(.system(size: 14, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textPrimary) }
                    }
                }

                TradingButton(title: "تسجيل الخروج", style: .danger, isLoading: false) { showLogout = true }
                    .alert("تسجيل الخروج", isPresented: $showLogout) {
                        Button("تسجيل الخروج", role: .destructive) { Task { await authService.logout() } }
                        Button("إلغاء", role: .cancel) {}
                    } message: { Text("هل أنت متأكد من تسجيل الخروج؟") }
            }
            .padding(RouaTheme.Spacing.lg)
        }
        .background(RouaTheme.Colors.background)
        .navigationTitle("الإعدادات")
    }
}
