import SwiftUI

// MARK: - Tab Bar View — 6 tabs
struct TabBarView: View {
    @State private var selectedTab = 1 // Default to Chart tab
    @AppStorage("appLanguage") private var appLanguage = "ar"

    private let tabs: [(String, String)] = [
        ("الرئيسية", "square.grid.2x2"),      // 0 - Home
        ("الشارت", "chart.line.uptrend.xyaxis"), // 1 - Chart
        ("الذكاء", "brain"),                  // 2 - AI
        ("الماسح", "magnifyingglass"),         // 3 - Scanner
        ("الوكيل", "robot"),                  // 4 - Agent
        ("الإعدادات", "gearshape"),            // 5 - Settings
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case 0: NavigationStack { DashboardView() }
                case 1: NavigationStack { ChartPageView() }
                case 2: NavigationStack { AIHubView() }
                case 3: NavigationStack { ScannerView() }
                case 4: NavigationStack { AgentView() }
                case 5: NavigationStack { SettingsView() }
                default: EmptyView()
                }
            }.padding(.bottom, 72)

            // Tab Bar
            VStack(spacing: 0) {
                Divider().background(RouaTheme.Colors.border)
                HStack(spacing: 0) {
                    ForEach(0..<6, id: \.self) { i in
                        tabItem(i)
                    }
                }
                .padding(.horizontal, RouaTheme.Spacing.xs)
                .padding(.top, RouaTheme.Spacing.sm)
                .padding(.bottom, RouaTheme.Spacing.lg)
                .background(RouaTheme.Colors.surface.opacity(0.95))
                .background(.ultraThinMaterial)
            }
        }
        .background(RouaTheme.Colors.background)
    }

    private func tabItem(_ index: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = index }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tabs[index].1)
                    .font(.system(size: 18))
                    .foregroundStyle(selectedTab == index ? RouaTheme.Colors.accent : RouaTheme.Colors.textTertiary)
                Text(tabs[index].0)
                    .font(.system(size: 9, weight: selectedTab == index ? .bold : .medium))
                    .foregroundStyle(selectedTab == index ? RouaTheme.Colors.accent : RouaTheme.Colors.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
