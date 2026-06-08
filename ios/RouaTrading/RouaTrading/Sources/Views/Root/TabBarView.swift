// =============================================================================
// TabBarView.swift — Roua Trading · Custom Tab Bar (m2-shell)
// =============================================================================
// Five-tab custom tab bar matching web's m2-shell bottom navigation:
//   - Gradient active indicator line (cyan → green) ABOVE the active tab
//   - Glassmorphism background with blur
//   - Center tab (Scanner) elevated as a FAB
//   - Badge indicators for real-time counts
//   - Smooth tab-switching animations with haptic feedback
//
// Tabs (matching web m2-shell):
//   0 — الشارت     (Chart)     · chart.xyaxis.line       → HomeView
//   1 — الصفاقات   (Positions) · arrow.left.arrow.right   → TradingView
//   2 — السكانر    (Scanner)   · magnifyingglass          → MarketsView (center FAB)
//   3 — AI          (AI)        · brain.head.profile       → AIHubView
//   4 — المزيد     (More)      · ellipsis                 → SettingsView
// =============================================================================

import SwiftUI

// MARK: - Tab Definition

enum RouaTab: Int, CaseIterable, Identifiable {
    case chart = 0
    case positions = 1
    case scanner = 2
    case ai = 3
    case more = 4

    var id: Int { rawValue }

    /// Arabic label displayed under the icon (matches web m2-shell).
    var label: String {
        switch self {
        case .chart:    return "الشارت"
        case .positions: return "الصفقات"
        case .scanner:  return "السكانر"
        case .ai:       return "AI"
        case .more:     return "المزيد"
        }
    }

    /// SF Symbol name for the icon.
    var iconName: String {
        switch self {
        case .chart:    return "chart.xyaxis.line"
        case .positions: return "arrow.left.arrow.right"
        case .scanner:  return "magnifyingglass"
        case .ai:       return "brain.head.profile"
        case .more:     return "ellipsis"
        }
    }

    /// Whether this tab is the center FAB-style tab.
    var isCenter: Bool {
        self == .scanner
    }
}

// MARK: - Tab Bar View

struct TabBarView: View {

    @State private var selectedTab: RouaTab = .chart

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
                case .chart:
                    HomeView()

                case .positions:
                    TradingView()

                case .scanner:
                    MarketsView()

                case .ai:
                    AIHubView()

                case .more:
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

            // Subtle top-edge gradient (cyan tint matching indicator)
            VStack {
                LinearGradient(
                    colors: [
                        Color.rouaAccent.opacity(0.06),
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
                // ── Gradient indicator line above active tab ──
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [Color.rouaAccent, Color.rouaSuccess],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 2.5)
                        .clipShape(Capsule())
                    } else {
                        Color.clear
                            .frame(height: 2.5)
                    }
                }
                .animation(
                    .spring(response: 0.3, dampingFraction: 0.6),
                    value: isSelected
                )

                // ── Icon + Badge ──
                ZStack(alignment: .topTrailing) {
                    if tab.isCenter {
                        // ── Center FAB-style tab ──
                        ZStack {
                            // Glow behind FAB
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.rouaAccent.opacity(0.3), Color.rouaSuccess.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 52, height: 52)
                                .blur(radius: 14)
                                .offset(y: 2)

                            // FAB circle background
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.rouaAccent, Color.rouaSuccess],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 46, height: 46)
                                .overlay(
                                    Circle()
                                        .stroke(Color.rouaGlassBorder, lineWidth: 0.5)
                                )
                                .shadow(color: Color.rouaAccent.opacity(0.35), radius: 10, y: 4)

                            // Icon inside FAB
                            Image(systemName: tab.iconName)
                                .font(.system(size: RouaSpacing.iconLarge, weight: .semibold))
                                .symbolRenderingMode(.monochrome)
                                .foregroundStyle(Color.rouaBackground)
                        }
                        .offset(y: -12)
                    } else {
                        // ── Regular tab icon ──
                        Image(systemName: tab.iconName)
                            .font(.system(size: RouaSpacing.iconLarge, weight: isSelected ? .semibold : .regular))
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(isSelected ? .rouaTextPrimary : .rouaTextTertiary)
                            .scaleEffect(isSelected ? 1.1 : 1.0)
                            .animation(
                                .spring(response: 0.3, dampingFraction: 0.6),
                                value: isSelected
                            )
                    }

                    // Badge
                    badge(for: tab)
                }
                .frame(height: tab.isCenter ? 52 : RouaSpacing.iconLarge + 4)

                // Label
                Text(tab.label)
                    .rouaFont(
                        isSelected ? .captionBold : .caption,
                        color: isSelected ? .rouaTextPrimary : .rouaTextTertiary
                    )
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
            case .positions: return activeSignalCount
            case .more:      return unreadNotificationCount
            default:         return 0
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
