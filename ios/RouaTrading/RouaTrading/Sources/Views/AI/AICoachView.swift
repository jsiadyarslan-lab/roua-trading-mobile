// =============================================================================
// AICoachView.swift — Roua Trading · AI Coach Chat Interface
// =============================================================================
// Chat-style interface with previous advice, quick action buttons,
// text input with send, and coach responses in styled bubbles.
// Uses AIViewModel for /coach/ask and /coach/performance.
// =============================================================================

import SwiftUI

struct AICoachView: View {

    // MARK: - Dependencies

    @ObservedObject var viewModel: AIViewModel

    // MARK: - State

    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool
    @State private var autoScroll = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Messages area
            messagesList

            // Quick action buttons
            quickActions

            // Input bar
            inputBar
        }
        .background(Color.rouaBackground)
    }

    // MARK: - Messages List

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: RouaSpacing.md) {
                    // Welcome message
                    if viewModel.coachMessages.isEmpty {
                        coachBubble(
                            text: "مرحباً! أنا مدربك الذكي. اسألني عن تداولك أو اطلب تحليل الأداء.",
                            isUser: false
                        )
                        .id("welcome")
                    }

                    // Previous advice
                    ForEach(viewModel.coachAdvice) { advice in
                        adviceBubble(advice: advice)
                    }

                    // Chat messages
                    ForEach(viewModel.coachMessages) { message in
                        coachBubble(
                            text: message.text,
                            isUser: message.isUser,
                            timestamp: message.timestamp
                        )
                        .id(message.id)
                    }

                    // Loading indicator
                    if viewModel.isCoachThinking {
                        HStack(spacing: RouaSpacing.sm) {
                            TypingIndicator()
                            Spacer()
                        }
                        .padding(.horizontal, RouaSpacing.screenPadding)
                        .id("typing")
                    }
                }
                .padding(.vertical, RouaSpacing.md)
            }
            .onChange(of: viewModel.coachMessages.count) { _, _ in
                withAnimation {
                    proxy.scrollTo(
                        viewModel.isCoachThinking ? "typing" : viewModel.coachMessages.last?.id,
                        anchor: .bottom
                    )
                }
            }
            .onChange(of: viewModel.isCoachThinking) { _, isThinking in
                if isThinking {
                    withAnimation {
                        proxy.scrollTo("typing", anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Quick Action Buttons

    private var quickActions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RouaSpacing.sm) {
                QuickActionButton(
                    title: "تحليل الأداء",
                    icon: "chart.bar",
                    action: {
                        sendMessage("تحليل الأداء")
                        Task { await viewModel.loadCoachPerformance() }
                    }
                )

                QuickActionButton(
                    title: "نصيحة تداول",
                    icon: "lightbulb",
                    action: {
                        sendMessage("أعطني نصيحة تداول")
                    }
                )

                QuickActionButton(
                    title: "تحليل المخاطر",
                    icon: "shield",
                    action: {
                        sendMessage("حلل مخاطر محفظتي")
                    }
                )

                QuickActionButton(
                    title: "استراتيجية",
                    icon: "chess",
                    action: {
                        sendMessage("اقترح استراتيجية تداول")
                    }
                )
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
        }
        .padding(.vertical, RouaSpacing.sm)
        .background(Color.rouaSurface.opacity(0.5))
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: RouaSpacing.sm) {
            TextField("اسأل المدرب…", text: $messageText)
                .rouaFont(.callout, color: .rouaTextPrimary)
                .padding(.horizontal, RouaSpacing.md)
                .padding(.vertical, RouaSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: RouaSpacing.buttonCornerRadius, style: .continuous)
                        .fill(Color.rouaSurfaceLight)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: RouaSpacing.buttonCornerRadius, style: .continuous)
                        .stroke(Color.rouaGlassBorder, lineWidth: 0.5)
                )
                .focused($isInputFocused)
                .onSubmit { sendMessage() }

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        messageText.trimmingCharacters(in: .whitespaces).isEmpty
                            ? .rouaTextDisabled
                            : .rouaPrimary
                    )
            }
            .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, RouaSpacing.screenPadding)
        .padding(.vertical, RouaSpacing.sm)
        .background(Color.rouaSurface.opacity(0.5))
    }

    // MARK: - Message Bubbles

    @ViewBuilder
    private func coachBubble(
        text: String,
        isUser: Bool,
        timestamp: String? = nil
    ) -> some View {
        HStack {
            if isUser { Spacer(minLength: RouaSpacing.xxxl) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: RouaSpacing.xs) {
                Text(text)
                    .rouaFont(.subheadline, color: isUser ? .white : .rouaTextPrimary)
                    .padding(.horizontal, RouaSpacing.md)
                    .padding(.vertical, RouaSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                            .fill(isUser ? Color.rouaPrimary : Color.rouaGlassStrong)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                            .stroke(Color.rouaGlassBorder, lineWidth: 0.5)
                    )
                    .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)

                if let timestamp {
                    Text(timestamp)
                        .rouaFont(.micro, color: .rouaTextTertiary)
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)

            if !isUser { Spacer(minLength: RouaSpacing.xxxl) }
        }
    }

    @ViewBuilder
    private func adviceBubble(advice: CoachAdvice) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: RouaSpacing.sm) {
                // Type badge
                HStack(spacing: RouaSpacing.xs) {
                    Image(systemName: adviceIcon(for: advice.type))
                        .font(.system(size: RouaSpacing.iconSmall))
                        .foregroundStyle(.rouaAccent)
                    Text(advice.type)
                        .rouaFont(.captionBold, color: .rouaAccent)
                    Spacer()
                    if let confidence = advice.confidencePct {
                        Text(confidence)
                            .rouaFont(.caption, color: .rouaTextTertiary)
                    }
                }

                Text(advice.advice)
                    .rouaFont(.subheadline, color: .rouaTextPrimary)

                // Action items
                if let items = advice.actionItems, !items.isEmpty {
                    VStack(alignment: .leading, spacing: RouaSpacing.xs) {
                        ForEach(items, id: \.self) { item in
                            HStack(spacing: RouaSpacing.xs) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: RouaSpacing.iconSmall))
                                    .foregroundStyle(.rouaProfit)
                                Text(item)
                                    .rouaFont(.footnote, color: .rouaTextSecondary)
                            }
                        }
                    }
                }

                // Performance metrics
                if let metrics = advice.performanceMetrics, !metrics.isEmpty {
                    Divider()
                        .background(Color.rouaGlassBorder)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: RouaSpacing.md) {
                            ForEach(Array(metrics.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                                VStack(spacing: 2) {
                                    Text(key)
                                        .rouaFont(.micro, color: .rouaTextTertiary)
                                    Text(String(format: "%.1f", value))
                                        .rouaFont(.footnoteBold, color: .rouaPrimary)
                                        .monospacedDigit()
                                }
                            }
                        }
                    }
                }

                Text(advice.createdAt)
                    .rouaFont(.micro, color: .rouaTextTertiary)
            }
            .padding(RouaSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                    .fill(Color.rouaGlassStrong)
            )
            .overlay(
                RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                    .stroke(Color.rouaGlassBorder, lineWidth: 0.5)
            )
            .padding(.horizontal, RouaSpacing.screenPadding)

            Spacer(minLength: RouaSpacing.xxxl)
        }
    }

    // MARK: - Actions

    private func sendMessage(_ override: String? = nil) {
        let text = (override ?? messageText).trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        viewModel.sendCoachMessage(text)
        messageText = ""
        isInputFocused = false
    }

    private func adviceIcon(for type: String) -> String {
        switch type.lowercased() {
        case "performance": return "chart.bar"
        case "risk":        return "shield"
        case "strategy":    return "chess"
        case "signal":      return "signal"
        default:            return "lightbulb"
        }
    }
}

// MARK: - Quick Action Button

private struct QuickActionButton: View {

    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: RouaSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: RouaSpacing.iconSmall))
                Text(title)
                    .rouaFont(.captionBold)
            }
            .foregroundStyle(.rouaPrimary)
            .padding(.horizontal, RouaSpacing.md)
            .padding(.vertical, RouaSpacing.sm)
            .background(
                Capsule().fill(Color.rouaPrimary.opacity(0.15))
            )
            .overlay(
                Capsule().stroke(Color.rouaPrimary.opacity(0.3), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

// MARK: - Typing Indicator

private struct TypingIndicator: View {

    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: RouaSpacing.xs) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.rouaPrimary)
                    .frame(width: 8, height: 8)
                    .offset(y: isAnimating ? -4 : 4)
                    .animation(
                        .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                        value: isAnimating
                    )
            }
        }
        .padding(.horizontal, RouaSpacing.md)
        .padding(.vertical, RouaSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                .fill(Color.rouaGlassStrong)
        )
        .overlay(
            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                .stroke(Color.rouaGlassBorder, lineWidth: 0.5)
        )
        .onAppear { isAnimating = true }
        .accessibilityLabel("Coach is typing")
    }
}

// MARK: - Coach Message Model

/// Simple message model for the coach chat interface.
struct CoachMessage: Identifiable, Equatable {
    let id = UUID().uuidString
    let text: String
    let isUser: Bool
    let timestamp: String

    static func == (lhs: CoachMessage, rhs: CoachMessage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Preview

#Preview("AICoachView") {
    AICoachView(viewModel: AIViewModel())
}
