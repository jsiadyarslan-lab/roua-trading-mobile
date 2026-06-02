// =============================================================================
// NotificationsView.swift — Roua Trading · Notifications
// =============================================================================
// In-app notification center with grouping, swipe actions, and type-based theming.
// Uses RouaColors, RouaTypography, RouaSpacing, and RouaComponents.
// Supports RTL layout, accessibility, pull-to-refresh, and smooth animations.
// =============================================================================

import SwiftUI

// MARK: - Notification Date Group

enum NotificationDateGroup: String, CaseIterable {
    case today     = "اليوم"
    case yesterday = "أمس"
    case earlier   = "سابق"

    var iconName: String {
        switch self {
        case .today:     return "sun.max"
        case .yesterday: return "moon"
        case .earlier:   return "clock"
        }
    }
}

// MARK: - Notification Type Color

extension NotificationType {

    /// Theme color for each notification category.
    var themeColor: Color {
        switch self {
        case .trade:  return .rouaProfit       // green
        case .signal: return .rouaInfo          // blue/cyan
        case .ai:     return .rouaSecondary     // purple
        case .risk:   return .rouaLoss          // red
        case .system: return .rouaNeutral       // gray
        case .news:   return .rouaWarning       // orange
        }
    }

    /// Light background color for each notification category.
    var themeBgColor: Color {
        themeColor.opacity(0.12)
    }

    /// Accessibility description for the type.
    var accessibilityDescription: String {
        switch self {
        case .trade:  return "صفقة"
        case .signal: return "إشارة"
        case .ai:     return "ذكاء اصطناعي"
        case .risk:   return "مخاطر"
        case .system: return "نظام"
        case .news:   return "أخبار"
        }
    }
}

// MARK: - Notifications View

struct NotificationsView: View {

    @StateObject private var viewModel = NotificationsViewModel()
    @State private var isRefreshing = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rouaBackground.ignoresSafeArea()

                if viewModel.notifications.isEmpty && !viewModel.isLoading {
                    emptyState
                } else {
                    notificationList
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: RouaSpacing.sm) {
                        Text("الإشعارات")
                            .rouaFont(.headline, color: .rouaTextPrimary)

                        if viewModel.unreadCount > 0 {
                            unreadBadge
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.hasUnread {
                        Button {
                            viewModel.markAllRead()
                        } label: {
                            Text("تحديد الكل كمقروء")
                                .rouaFont(.captionBold, color: .rouaPrimary)
                        }
                        .accessibilityLabel("تحديد جميع الإشعارات كمقروءة")
                    }
                }
            }
            .overlay {
                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    LoadingView(message: "جاري تحميل الإشعارات...")
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }

    // MARK: - Unread Badge

    private var unreadBadge: some View {
        Text("\(viewModel.unreadCount)")
            .rouaFont(.captionBold, color: .white)
            .padding(.horizontal, RouaSpacing.sm)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(Color.rouaLoss)
            )
            .accessibilityLabel("\(viewModel.unreadCount) إشعارات غير مقروءة")
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            icon: "bell.slash",
            title: "لا توجد إشعارات",
            description: "ستظهر هنا الإشعارات المتعلقة بالصفقات والإشارات والتنبيهات"
        )
    }

    // MARK: - Notification List

    private var notificationList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: RouaSpacing.md, pinnedViews: [.sectionHeaders]) {
                ForEach(NotificationDateGroup.allCases, id: \.self) { group in
                    let groupNotifications = viewModel.notifications(for: group)
                    if !groupNotifications.isEmpty {
                        Section {
                            ForEach(groupNotifications) { notification in
                                notificationRow(notification)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            withAnimation(.easeOut(duration: RouaSpacing.animationFast)) {
                                                viewModel.deleteNotification(id: notification.id)
                                            }
                                        } label: {
                                            Label("حذف", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .leading) {
                                        if !notification.isRead {
                                            Button {
                                                withAnimation(.easeOut(duration: RouaSpacing.animationFast)) {
                                                    viewModel.markRead(id: notification.id)
                                                }
                                            } label: {
                                                Label("مقروء", systemImage: "checkmark")
                                            }
                                            .tint(.rouaPrimary)
                                        }
                                    }
                            }
                        } header: {
                            sectionHeader(group)
                        }
                    }
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
            .padding(.vertical, RouaSpacing.md)
            // Bottom safe area for tab bar
            .padding(.bottom, RouaSpacing.tabBarHeight + RouaSpacing.lg)
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ group: NotificationDateGroup) -> some View {
        HStack(spacing: RouaSpacing.xs) {
            Image(systemName: group.iconName)
                .font(.system(size: RouaSpacing.iconSmall))
                .foregroundStyle(.rouaTextTertiary)
            Text(group.rawValue)
                .rouaFont(.footnoteBold, color: .rouaTextTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, RouaSpacing.xs)
    }

    // MARK: - Notification Row

    private func notificationRow(_ notification: RouaNotification) -> some View {
        Button {
            handleNotificationTap(notification)
        } label: {
            HStack(spacing: RouaSpacing.md) {
                // Type icon
                notificationTypeIcon(notification.type)

                // Content
                VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                    HStack(spacing: RouaSpacing.xs) {
                        // Unread dot
                        if !notification.isRead {
                            Circle()
                                .fill(Color.rouaPrimary)
                                .frame(width: 8, height: 8)
                        }

                        Text(notification.title)
                            .rouaFont(.subheadlineBold, color: .rouaTextPrimary)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Text(notification.message)
                        .rouaFont(.footnote, color: .rouaTextSecondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: RouaSpacing.md) {
                        // Type badge
                        Text(notification.type.accessibilityDescription)
                            .rouaFont(.micro, color: notification.type.themeColor)
                            .padding(.horizontal, RouaSpacing.xs)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(notification.type.themeBgColor)
                            )

                        // Time
                        Text(notification.timeAgo)
                            .rouaFont(.micro, color: .rouaTextTertiary)
                    }
                }
            }
            .padding(RouaSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                    .fill(notification.isRead ? Color.rouaSurface : Color.rouaSurfaceLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                    .stroke(
                        notification.isRead ? Color.rouaGlassBorder : notification.type.themeColor.opacity(0.3),
                        lineWidth: notification.isRead ? 0.5 : 1
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(notification.type.accessibilityDescription): \(notification.title). \(notification.message)" +
            (notification.isRead ? "" : "، غير مقروء")
        )
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Type Icon

    private func notificationTypeIcon(_ type: NotificationType) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius)
                .fill(type.themeBgColor)
                .frame(width: 44, height: 44)

            Image(systemName: type.iconName)
                .font(.system(size: RouaSpacing.iconMedium))
                .foregroundStyle(type.themeColor)
        }
    }

    // MARK: - Navigation Handler

    private func handleNotificationTap(_ notification: RouaNotification) {
        // Mark as read
        if !notification.isRead {
            withAnimation(.easeOut(duration: RouaSpacing.animationFast)) {
                viewModel.markRead(id: notification.id)
            }
        }

        // Navigate based on type and action URL
        switch notification.type {
        case .trade:
            // TODO: Navigate to positions/trade detail
            break
        case .signal:
            // TODO: Navigate to signal detail
            break
        case .ai:
            // TODO: Navigate to AI brief
            break
        case .risk:
            // TODO: Navigate to risk dashboard
            break
        case .system:
            // TODO: Navigate to relevant settings
            break
        case .news:
            // TODO: Navigate to news detail
            break
        }
    }
}

// MARK: - Notifications View Model

@MainActor
final class NotificationsViewModel: ObservableObject {

    @Published var notifications: [RouaNotification] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Computed

    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    var hasUnread: Bool {
        notifications.contains { !$0.isRead }
    }

    /// Returns notifications grouped by date category.
    func notifications(for group: NotificationDateGroup) -> [RouaNotification] {
        // In production, parse `createdAt` with ISO8601DateFormatter
        // and group by calendar day. For now, return all notifications
        // in the "today" group as a placeholder.
        switch group {
        case .today:
            return Array(notifications.prefix(min(notifications.count, 5)))
        case .yesterday:
            let start = min(5, notifications.count)
            let end = min(10, notifications.count)
            if start >= end { return [] }
            return Array(notifications[start..<end])
        case .earlier:
            let start = min(10, notifications.count)
            if start >= notifications.count { return [] }
            return Array(notifications[start...])
        }
    }

    // MARK: - Actions

    func refresh() async {
        isLoading = true
        // TODO: Call API service
        try? await Task.sleep(nanoseconds: 800_000_000)
        isLoading = false
    }

    func markRead(id: String) {
        if let index = notifications.firstIndex(where: { $0.id == id }) {
            let existing = notifications[index]
            notifications[index] = RouaNotification(
                id: existing.id,
                type: existing.type,
                title: existing.title,
                message: existing.message,
                data: existing.data,
                isRead: true,
                createdAt: existing.createdAt,
                actionUrl: existing.actionUrl
            )
        }
        // TODO: Call API service to sync read state
    }

    func markAllRead() {
        for i in notifications.indices where !notifications[i].isRead {
            let existing = notifications[i]
            notifications[i] = RouaNotification(
                id: existing.id,
                type: existing.type,
                title: existing.title,
                message: existing.message,
                data: existing.data,
                isRead: true,
                createdAt: existing.createdAt,
                actionUrl: existing.actionUrl
            )
        }
        // TODO: Call API service
    }

    func deleteNotification(id: String) {
        notifications.removeAll { $0.id == id }
        // TODO: Call API service
    }
}

// MARK: - Preview

#Preview("Notifications") {
    NotificationsView()
        .environmentObject({
            let vm = NotificationsViewModel()
            // Sample data for preview
            vm.notifications = [
                RouaNotification(
                    id: "1",
                    type: .trade,
                    title: "تم تنفيذ صفقة شراء",
                    message: "تم شراء 0.5 BTC/USDT بسعر 67,250.00",
                    data: nil,
                    isRead: false,
                    createdAt: "منذ 5 دقائق",
                    actionUrl: "/positions/1"
                ),
                RouaNotification(
                    id: "2",
                    type: .signal,
                    title: "إشارة تداول جديدة",
                    message: "ETH/USDT - شري قوي بثقة 85%",
                    data: nil,
                    isRead: false,
                    createdAt: "منذ 15 دقيقة",
                    actionUrl: "/signals/2"
                ),
                RouaNotification(
                    id: "3",
                    type: .ai,
                    title: "تحليل AI متاح",
                    message: "تم إنشاء تحليل ذكي لـ SOL/USDT",
                    data: nil,
                    isRead: true,
                    createdAt: "منذ ساعة",
                    actionUrl: "/ai/briefs/3"
                ),
                RouaNotification(
                    id: "4",
                    type: .risk,
                    title: "تنبيه مخاطر",
                    message: "استخدام الهامش تجاوز 80% من المحفظة",
                    data: nil,
                    isRead: false,
                    createdAt: "منذ ساعتين",
                    actionUrl: nil
                ),
                RouaNotification(
                    id: "5",
                    type: .system,
                    title: "تحديث النظام",
                    message: "تم تحديث النظام بنجاح إلى الإصدار 2.1",
                    data: nil,
                    isRead: true,
                    createdAt: "أمس",
                    actionUrl: nil
                ),
                RouaNotification(
                    id: "6",
                    type: .news,
                    title: "خبر سريع",
                    message: "البنك المركزي يرفع أسعار الفائدة 0.25%",
                    data: nil,
                    isRead: true,
                    createdAt: "أمس",
                    actionUrl: "/news/6"
                ),
            ]
            return vm
        }())
}
