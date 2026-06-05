// =============================================================================
// TabBarView.swift — Roua Trading · Custom Tab Bar
// =============================================================================
// Five-tab custom tab bar with glassmorphism design, glow effects on the
// selected tab, badge indicators, and smooth tab-switching animations.
// Each tab wraps its content in its own NavigationStack.
//
// Tabs:
//   0 — الرئيسية    (Home)      · house.fill
//   1 — الأسواق     (Markets)   · chart.line.uptrend.xyaxis
//   2 — الذكاء      (AI Hub)    · brain.head.profile.fill
//   3 — المحفظة     (Portfolio) · wallet.pass.fill
//   4 — الإعدادات   (Settings)  · gearshape.fill
// =============================================================================

import SwiftUI

// MARK: - Tab Definition

enum RouaTab: Int, CaseIterable, Identifiable {
    case home = 0
    case markets = 1
    case aiHub = 2
    case portfolio = 3
    case settings = 4

    var id: Int { rawValue }

    /// Arabic label displayed under the icon.
    var label: String {
        switch self {
        case .home:      return "الرئيسية"
        case .markets:   return "الأسواق"
        case .aiHub:     return "الذكاء"
        case .portfolio: return "المحفظة"
        case .settings:  return "الإعدادات"
        }
    }

    /// SF Symbol name for the icon.
    var iconName: String {
        switch self {
        case .home:      return "house.fill"
        case .markets:   return "chart.line.uptrend.xyaxis"
        case .aiHub:     return "brain.head.profile.fill"
        case .portfolio: return "wallet.pass.fill"
        case .settings:  return "gearshape.fill"
        }
    }
}

// MARK: - Tab Bar View

struct TabBarView: View {

    @State private var selectedTab: RouaTab = .home

    // Real-time data from SocketManager
    @ObservedObject var socketManager: SocketManager

    // Badge counts — driven by real-time events and view models.
    @State private var activeSignalCount: Int = 0
    @State private var unreadNotificationCount: Int = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // ── Tab Content ──
            Group {
                switch selectedTab {
                case .home:
                    HomeView()

                case .markets:
                    MarketsView()

                case .aiHub:
                    AIHubView()

                case .portfolio:
                    PortfolioView()

                case .settings:
                    SettingsView()
                }
            }
            .padding(.bottom, RouaSpacing.tabBarHeight)

            // ── Custom Tab Bar ──
            tabBarOverlay
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            setupSocketEvents()
        }
        .onReceive(socketManager.$isNotificationsActive) { _ in
            // Connection status changed
        }
    }

    // MARK: - Socket Event Handler

    private func setupSocketEvents() {
        socketManager.onEvent = { event in
            switch event {
            case .unreadCount(let count):
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    unreadNotificationCount = count
                }
            case .autoExecuteSignal:
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    activeSignalCount += 1
                }
            case .notification:
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    unreadNotificationCount += 1
                }
            default:
                break
            }
        }
    }

    // MARK: - Tab Bar Overlay

    private var tabBarOverlay: some View {
        VStack(spacing: 0) {
            // Top separator line
            Rectangle()
                .fill(Color.rouaGlassBorder)
                .frame(height: 0.5)

            HStack(spacing: 0) {
                ForEach(RouaTab.allCases) { tab in
                    tabItem(for: tab)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, RouaSpacing.sm)
            .padding(.bottom, RouaSpacing.sm)
            .background(
                // Glassmorphism background
                tabBarBackground
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("شريط التنقل")
    }

    // MARK: - Tab Bar Background

    private var tabBarBackground: some View {
        ZStack {
            // Blur material
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.7)

            // Tinted overlay
            Rectangle()
                .fill(Color.rouaGlass)

            // Subtle top-edge gradient
            VStack {
                LinearGradient(
                    colors: [
                        Color.rouaPrimary.opacity(0.08),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
                .frame(height: 1)
                Spacer()
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Single Tab Item

    @ViewBuilder
    private func tabItem(for tab: RouaTab) -> some View {
        let isSelected = selectedTab == tab

        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedTab = tab
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: RouaSpacing.xs) {
                ZStack(alignment: .topTrailing) {
                    // Icon
                    Image(systemName: tab.iconName)
                        .font(.system(size: RouaSpacing.iconLarge, weight: isSelected ? .semibold : .regular))
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(isSelected ? .rouaPrimary : .rouaTextTertiary)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .animation(
                            .spring(response: 0.3, dampingFraction: 0.6),
                            value: isSelected
                        )

                    // Glow effect behind icon when selected
                    if isSelected {
                        Circle()
                            .fill(Color.rouaPrimary.opacity(0.25))
                            .frame(width: 36, height: 36)
                            .blur(radius: 12)
                            .offset(y: -2)
                    }

                    // Badge
                    badge(for: tab)
                }
                .frame(height: RouaSpacing.iconLarge + 4)

                // Label
                Text(tab.label)
                    .rouaFont(isSelected ? .captionBold : .caption, color: isSelected ? .rouaPrimary : .rouaTextTertiary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Badge

    @ViewBuilder
    private func badge(for tab: RouaTab) -> some View {
        let count: Int = {
            switch tab {
            case .aiHub:    return activeSignalCount
            case .settings: return unreadNotificationCount
            default:        return 0
            }
        }()

        if count > 0 {
            ZStack {
                Circle()
                    .fill(Color.rouaLoss)
                    .frame(width: 18, height: 18)

                Text(count > 99 ? "99+" : "\(count)")
                    .rouaFont(.micro, color: .white)
                    .monospacedDigit()
            }
            .offset(x: 10, y: -6)
            .accessibilityLabel("\(count) إشعارات جديدة")
            .transition(.scale.combined(with: .opacity))
        }
    }
}

// MARK: - Preview

#Preview("TabBarView") {
    TabBarView(socketManager: SocketManager())
        .preferredColorScheme(.dark)
}
