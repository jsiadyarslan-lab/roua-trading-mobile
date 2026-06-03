// =============================================================================
// AIHubView.swift — Roua Trading · AI Hub Main View
// =============================================================================
// Central hub for all AI features with horizontal tab scroll:
// المجلس (Council) | المنفذ (Executor) | الإشارات (Signals) |
// المدرب (Coach)   | النماذج (Models)
// Uses AIViewModel. Glassmorphism styling throughout.
// =============================================================================

import SwiftUI

// MARK: - AI Hub Tab

enum AIHubTab: String, CaseIterable, Identifiable {
    case council  = "المجلس"
    case executor = "المنفذ"
    case signals  = "الإشارات"
    case coach    = "المدرب"
    case models   = "النماذج"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .council:  return "brain.head.profile"
        case .executor: return "bolt.horizontal.icloud"
        case .signals:  return "signal"
        case .coach:    return "graduationcap"
        case .models:   return "cpu"
        }
    }
}

struct AIHubView: View {

    // MARK: - Dependencies

    @StateObject private var viewModel = AIViewModel()

    // MARK: - State

    @State private var selectedTab: AIHubTab = .council

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab bar
                tabBar

                // Content
                Group {
                    switch selectedTab {
                    case .council:
                        AICouncilView(viewModel: viewModel)
                    case .executor:
                        SmartExecutorView(viewModel: viewModel)
                    case .signals:
                        SignalsView(viewModel: viewModel)
                    case .coach:
                        AICoachView(viewModel: viewModel)
                    case .models:
                        AIModelsView(viewModel: viewModel)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
            }
            .background(Color.rouaBackground)
            .navigationTitle("المركز الذكي")
            .navigationBarTitleDisplayMode(.inline)
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

    // MARK: - Tab Bar

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RouaSpacing.sm) {
                ForEach(AIHubTab.allCases) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: RouaSpacing.animationFast)) {
                            selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: RouaSpacing.xs) {
                            Image(systemName: tab.icon)
                                .font(.system(size: RouaSpacing.iconSmall))
                            Text(tab.rawValue)
                                .rouaFont(.subheadlineBold)
                        }
                        .foregroundStyle(selectedTab == tab ? .white : .rouaTextSecondary)
                        .padding(.horizontal, RouaSpacing.lg)
                        .padding(.vertical, RouaSpacing.sm)
                        .background(
                            Capsule().fill(
                                selectedTab == tab
                                    ? Color.rouaGradientPrimary
                                    : Color.rouaSurfaceLight
                            )
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    selectedTab == tab ? Color.clear : Color.rouaGlassBorder,
                                    lineWidth: 0.5
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tab.rawValue)
                    .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
        }
        .padding(.vertical, RouaSpacing.sm)
        .background(Color.rouaSurface.opacity(0.5))
    }
}

// MARK: - Preview

#Preview("AIHubView") {
    AIHubView()
}
