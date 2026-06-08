// =============================================================================
// AIHubView.swift — Roua Trading · AI Hub Main View
// =============================================================================
// Central hub for all AI features matching the web AI Hub page:
// محادثة (Chat)    | المجلس (Council) | المنفذ (Executor) |
// الإشارات (Signals) | المدرب (Coach)  | النماذج (Models)
//
// NEW: Asset selector header, AI model status indicators, chat interface,
// market sentiment gauge, glassmorphism tab bar.
// Uses AIViewModel. Glassmorphism styling throughout. RTL Arabic labels.
// =============================================================================

import SwiftUI

// MARK: - AI Chat Message Model

/// Simple message model for the AI Hub chat interface.
struct AIChatMessage: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date

    static func == (lhs: AIChatMessage, rhs: AIChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - AI Model Status Model

/// Status indicator for a single AI/LLM model provider.
struct AIModelStatus: Identifiable {
    let id: String
    let name: String
    let isOnline: Bool
    let color: Color
}

// MARK: - AI Hub Tab

enum AIHubTab: String, CaseIterable, Identifiable {
    case chat     = "محادثة"
    case council  = "المجلس"
    case executor = "المنفذ"
    case signals  = "الإشارات"
    case coach    = "المدرب"
    case models   = "النماذج"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .chat:     return "bubble.left.and.bubble.right"
        case .council:  return "brain.head.profile"
        case .executor: return "bolt.horizontal.icloud"
        case .signals:  return "signal"
        case .coach:    return "graduationcap"
        case .models:   return "cpu"
        }
    }
}

// MARK: - AI Hub View

struct AIHubView: View {

    // MARK: - Dependencies

    @StateObject private var viewModel = AIViewModel()

    // MARK: - State

    @State private var selectedTab: AIHubTab = .chat
    @State private var chatMessages: [AIChatMessage] = []
    @State private var chatInput: String = ""
    @State private var isAITyping: Bool = false
    @FocusState private var isChatFocused: Bool
    @State private var selectedSymbol: String = "BTC/USDT"
    @State private var livePrice: Double = 67234.50
    @State private var priceChange: Double = 1245.30
    @State private var priceChangePct: Double = 1.89

    // MARK: - AI Model Statuses (Mock Data)

    private let aiModels: [AIModelStatus] = [
        AIModelStatus(id: "gemini",     name: "Gemini",     isOnline: true,  color: Color(hex: "4285F4")),
        AIModelStatus(id: "groq",       name: "Groq",       isOnline: true,  color: Color(hex: "F55036")),
        AIModelStatus(id: "glm4",       name: "GLM-4",      isOnline: true,  color: Color(hex: "6C5CE7")),
        AIModelStatus(id: "hf",         name: "HuggingFace",isOnline: false, color: Color(hex: "FFD21E")),
        AIModelStatus(id: "openrouter", name: "OpenRouter", isOnline: true,  color: Color(hex: "00D4FF")),
        AIModelStatus(id: "ollama",     name: "Ollama",     isOnline: false, color: Color(hex: "A29BFE")),
        AIModelStatus(id: "bedrock",    name: "Bedrock",    isOnline: true,  color: Color(hex: "FF9900"))
    ]

    // MARK: - Quick Prompts

    private let quickPrompts: [(String, String)] = [
        ("تحليل السوق",    "chart.bar.fill"),
        ("توصية ذكية",     "sparkles"),
        ("تحليل المشاعر",  "heart.text.square"),
        ("مؤشرات فنية",    "waveform.path"),
        ("مخاطر المحفظة",  "shield.checkered"),
        ("استراتيجية تداول","chess"),
    ]

    // MARK: - Sentiment

    private var sentimentScore: Double { 0.72 }  // 0…1, >0.5 = bullish
    private var sentimentLabel: String { sentimentScore > 0.5 ? "صعودي" : "هبوطي" }
    private var sentimentColor: Color { sentimentScore > 0.5 ? .rouaProfit : .rouaLoss }

    // MARK: - Technical Indicators (Mock)

    private let rsiValue: Double = 58.4
    private let emaValue: String = "فوق EMA-20"
    private let direction: String = "صعودي"
    private let signalClass: String = "شراء قوي"

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Asset selector header
                assetHeader

                // AI model status row
                modelStatusRow

                // Tab bar
                tabBar

                // Content
                Group {
                    switch selectedTab {
                    case .chat:
                        chatView
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
            .task {
                viewModel.loadAll()
                loadWelcomeMessage()
            }
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

    // MARK: - Asset Selector Header

    private var assetHeader: some View {
        HStack(spacing: RouaSpacing.md) {
            // Symbol selector dropdown
            Menu {
                ForEach(["BTC/USDT", "ETH/USDT", "SOL/USDT", "XRP/USDT", "DOGE/USDT"], id: \.self) { symbol in
                    Button(action: {
                        withAnimation(.easeInOut(duration: RouaSpacing.animationFast)) {
                            selectedSymbol = symbol
                        }
                    }) {
                        HStack {
                            Text(symbol)
                                .rouaFont(.calloutBold, color: .rouaTextPrimary)
                            if symbol == selectedSymbol {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.rouaPrimary)
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: RouaSpacing.xs) {
                    Image(systemName: "bitcoinsign.circle.fill")
                        .font(.system(size: RouaSpacing.iconMedium))
                        .foregroundStyle(.rouaGold)
                    Text(selectedSymbol)
                        .rouaFont(.calloutBold, color: .rouaTextPrimary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.rouaTextTertiary)
                }
                .padding(.horizontal, RouaSpacing.md)
                .padding(.vertical, RouaSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                        .fill(Color.rouaSurfaceLight)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                        .stroke(Color.rouaGlassBorder, lineWidth: 0.5)
                )
            }
            .accessibilityLabel("اختيار الأصل")
            .accessibilityValue(selectedSymbol)

            Spacer()

            // Live price
            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(formatPrice(livePrice))")
                    .rouaFont(.title3, color: .rouaTextPrimary)
                    .monospacedDigit()
                ChangeBadge(value: priceChange, percentage: priceChangePct)
            }
        }
        .padding(.horizontal, RouaSpacing.screenPadding)
        .padding(.vertical, RouaSpacing.sm)
        .background(
            Color.rouaNavGlass
                .background(.ultraThinMaterial)
        )
    }

    // MARK: - AI Model Status Row

    private var modelStatusRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RouaSpacing.sm) {
                ForEach(aiModels) { model in
                    HStack(spacing: RouaSpacing.xs) {
                        PulsingDot(
                            status: model.isOnline ? .active : .inactive,
                            size: 6
                        )
                        Text(model.name)
                            .rouaFont(.caption, color: model.isOnline ? model.color : .rouaTextTertiary)
                    }
                    .padding(.horizontal, RouaSpacing.sm)
                    .padding(.vertical, RouaSpacing.xs)
                    .background(
                        Capsule()
                            .fill(model.isOnline ? model.color.opacity(0.1) : Color.rouaSurfaceLight.opacity(0.5))
                    )
                    .overlay(
                        Capsule()
                            .stroke(model.isOnline ? model.color.opacity(0.25) : Color.rouaGlassBorder, lineWidth: 0.5)
                    )
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
        }
        .padding(.vertical, RouaSpacing.xs)
        .background(Color.rouaSurface.opacity(0.3))
    }

    // MARK: - Tab Bar (Glassmorphism)

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
                            Group {
                                if selectedTab == tab {
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [.rouaPrimary, .rouaPurple],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                } else {
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                        .opacity(0.5)
                                }
                            }
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    selectedTab == tab
                                        ? Color.rouaPurple.opacity(0.5)
                                        : Color.rouaGlassBorder,
                                    lineWidth: selectedTab == tab ? 1 : 0.5
                                )
                        )
                        .shadow(
                            color: selectedTab == tab ? .rouaPrimary.opacity(0.3) : .clear,
                            radius: selectedTab == tab ? 8 : 0
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
        .background(
            ZStack {
                Color.rouaNavGlass
                    .background(.ultraThinMaterial)
            }
        )
    }

    // MARK: - Chat View (Primary)

    private var chatView: some View {
        VStack(spacing: 0) {
            // Market sentiment + technical indicators strip
            sentimentStrip

            // Messages area
            chatMessagesList

            // Quick prompts
            quickPromptsBar

            // Input bar
            chatInputBar
        }
    }

    // MARK: - Sentiment Strip

    private var sentimentStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RouaSpacing.md) {
                // Sentiment gauge
                sentimentGauge

                Divider()
                    .frame(height: 36)
                    .background(Color.rouaGlassBorder)

                // Technical indicators
                techIndicator(label: "RSI", value: String(format: "%.1f", rsiValue), color: rsiColor)
                techIndicator(label: "EMA", value: emaValue, color: .rouaCyan)
                techIndicator(label: "الاتجاه", value: direction, color: sentimentColor)
                techIndicator(label: "الإشارة", value: signalClass, color: .rouaProfit)
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
        }
        .padding(.vertical, RouaSpacing.sm)
        .background(Color.rouaSurface.opacity(0.3))
    }

    private var sentimentGauge: some View {
        HStack(spacing: RouaSpacing.xs) {
            // Mini arc gauge
            ZStack {
                Circle()
                    .stroke(Color.rouaSurfaceLight, lineWidth: 3)
                    .frame(width: 32, height: 32)
                Circle()
                    .trim(from: 0, to: sentimentScore)
                    .stroke(
                        AngularGradient(
                            colors: [.rouaLoss, .rouaWarning, .rouaProfit],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))
                Text("\(Int(sentimentScore * 100))")
                    .rouaFont(.micro, color: sentimentColor)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("المشاعر")
                    .rouaFont(.micro, color: .rouaTextTertiary)
                Text(sentimentLabel)
                    .rouaFont(.captionBold, color: sentimentColor)
            }
        }
        .padding(.horizontal, RouaSpacing.sm)
        .padding(.vertical, RouaSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                .fill(sentimentColor.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                .stroke(sentimentColor.opacity(0.2), lineWidth: 0.5)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("مشاعر السوق: \(sentimentLabel), نسبة \(Int(sentimentScore * 100)) بالمئة")
    }

    @ViewBuilder
    private func techIndicator(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(label)
                .rouaFont(.micro, color: .rouaTextTertiary)
            Text(value)
                .rouaFont(.captionBold, color: color)
                .lineLimit(1)
        }
        .padding(.horizontal, RouaSpacing.sm)
        .padding(.vertical, RouaSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                .fill(color.opacity(0.06))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }

    private var rsiColor: Color {
        switch rsiValue {
        case ..<30:  return .rouaLoss      // Oversold
        case 30..<70: return .rouaTextSecondary // Neutral
        default:     return .rouaProfit     // Overbought
        }
    }

    // MARK: - Chat Messages List

    private var chatMessagesList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: RouaSpacing.md) {
                    ForEach(chatMessages) { message in
                        chatBubble(message: message)
                            .id(message.id.uuidString)
                    }

                    // Typing indicator
                    if isAITyping {
                        HStack {
                            AITypingIndicator()
                            Spacer()
                        }
                        .padding(.horizontal, RouaSpacing.screenPadding)
                        .id("aiTyping")
                    }
                }
                .padding(.vertical, RouaSpacing.md)
            }
            .onChange(of: chatMessages.count) { _, _ in
                withAnimation {
                    proxy.scrollTo(
                        isAITyping ? "aiTyping" : chatMessages.last?.id.uuidString,
                        anchor: .bottom
                    )
                }
            }
            .onChange(of: isAITyping) { _, typing in
                if typing {
                    withAnimation {
                        proxy.scrollTo("aiTyping", anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Chat Bubble

    @ViewBuilder
    private func chatBubble(message: AIChatMessage) -> some View {
        HStack {
            if message.isUser { Spacer(minLength: RouaSpacing.xxxl) }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: RouaSpacing.xs) {
                // AI label for non-user messages
                if !message.isUser {
                    HStack(spacing: RouaSpacing.xs) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                            .foregroundStyle(.rouaPurple)
                        Text("المساعد الذكي")
                            .rouaFont(.micro, color: .rouaPurple)
                    }
                }

                Text(message.content)
                    .rouaFont(.subheadline, color: message.isUser ? .white : .rouaTextPrimary)
                    .padding(.horizontal, RouaSpacing.md)
                    .padding(.vertical, RouaSpacing.sm)
                    .background(
                        Group {
                            if message.isUser {
                                RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.rouaPrimary, Color.rouaPurple.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .opacity(0.6)
                                    RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                                        .fill(Color.rouaGlass)
                                }
                            }
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                            .stroke(
                                message.isUser ? Color.rouaPurple.opacity(0.3) : Color.rouaGlassBorder,
                                lineWidth: 0.5
                            )
                    )
                    .shadow(
                        color: message.isUser ? .rouaPrimary.opacity(0.15) : .clear,
                        radius: 8,
                        x: 0, y: 2
                    )

                // Timestamp
                Text(message.timestamp, style: .time)
                    .rouaFont(.micro, color: .rouaTextTertiary)
            }
            .padding(.horizontal, RouaSpacing.screenPadding)

            if !message.isUser { Spacer(minLength: RouaSpacing.xxxl) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(message.isUser ? "أنت" : "المساعد"): \(message.content)")
    }

    // MARK: - Quick Prompts Bar

    private var quickPromptsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RouaSpacing.sm) {
                ForEach(quickPrompts, id: \.0) { prompt in
                    Button {
                        sendChatMessage(prompt.0)
                    } label: {
                        HStack(spacing: RouaSpacing.xs) {
                            Image(systemName: prompt.1)
                                .font(.system(size: RouaSpacing.iconSmall))
                            Text(prompt.0)
                                .rouaFont(.captionBold)
                        }
                        .foregroundStyle(.rouaPurple)
                        .padding(.horizontal, RouaSpacing.md)
                        .padding(.vertical, RouaSpacing.sm)
                        .background(
                            Capsule()
                                .fill(Color.rouaPurple.opacity(0.1))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.rouaPurple.opacity(0.25), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(prompt.0)
                }
            }
            .padding(.horizontal, RouaSpacing.screenPadding)
        }
        .padding(.vertical, RouaSpacing.sm)
        .background(Color.rouaSurface.opacity(0.4))
    }

    // MARK: - Chat Input Bar

    private var chatInputBar: some View {
        HStack(spacing: RouaSpacing.sm) {
            // Smart Recommendation Button
            Button {
                sendChatMessage("أعطني توصية ذكية لـ \(selectedSymbol)")
            } label: {
                Image(systemName: "sparkle")
                    .font(.system(size: RouaSpacing.iconMedium))
                    .foregroundStyle(.rouaPurple)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.rouaPurple.opacity(0.12))
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.rouaPurple.opacity(0.25), lineWidth: 0.5)
                    )
            }
            .accessibilityLabel("توصية ذكية")

            // Text input
            TextField("اسأل المساعد الذكي…", text: $chatInput)
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
                .focused($isChatFocused)
                .onSubmit { sendChatMessage() }

            // Comprehensive Analysis Button
            Button {
                sendChatMessage("تحليل شامل لـ \(selectedSymbol)")
            } label: {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: RouaSpacing.iconMedium))
                    .foregroundStyle(.rouaCyan)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.rouaCyan.opacity(0.12))
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.rouaCyan.opacity(0.25), lineWidth: 0.5)
                    )
            }
            .accessibilityLabel("تحليل شامل")

            // Send button
            Button {
                sendChatMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        chatInput.trimmingCharacters(in: .whitespaces).isEmpty
                            ? .rouaTextDisabled
                            : .rouaPrimary
                    )
            }
            .disabled(chatInput.trimmingCharacters(in: .whitespaces).isEmpty)
            .accessibilityLabel("إرسال")
        }
        .padding(.horizontal, RouaSpacing.screenPadding)
        .padding(.vertical, RouaSpacing.sm)
        .background(
            ZStack {
                Color.rouaNavGlass
                    .background(.ultraThinMaterial)
            }
        )
    }

    // MARK: - Actions

    private func sendChatMessage(_ override: String? = nil) {
        let text = (override ?? chatInput).trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        let userMsg = AIChatMessage(
            content: text,
            isUser: true,
            timestamp: Date()
        )
        withAnimation {
            chatMessages.append(userMsg)
        }
        chatInput = ""
        isChatFocused = false

        // Simulate AI response
        isAITyping = true
        Task {
            // Try real API first
            viewModel.sendCoachMessage(text)

            // Wait for the response or timeout
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s

            let responseText: String
            if let latestAdvice = viewModel.coachAdvice.first {
                responseText = latestAdvice.advice
            } else {
                // Fallback generated response based on the prompt
                responseText = generateFallbackResponse(for: text)
            }

            let aiMsg = AIChatMessage(
                content: responseText,
                isUser: false,
                timestamp: Date()
            )
            withAnimation {
                chatMessages.append(aiMsg)
                isAITyping = false
            }
        }
    }

    private func generateFallbackResponse(for question: String) -> String {
        if question.contains("توصية") || question.contains("ذكية") {
            return "بناءً على تحليل النماذج المتعددة، يظهر \(selectedSymbol) إشارة صعودية بقوة ثقة ٧٢٪. نقطة الدخول المقترحة $\(formatPrice(livePrice)) مع وقف خسارة عند $\(formatPrice(livePrice * 0.97)). تأكد من إدارة المخاطر بشكل مناسب."
        } else if question.contains("تحليل") || question.contains("شامل") {
            return "تحليل شامل لـ \(selectedSymbol):\n• RSI: \(String(format: "%.1f", rsiValue)) — \(rsiValue > 70 ? "ذروة شراء" : rsiValue < 30 ? "ذروة بيع" : "محايد")\n• EMA: \(emaValue)\n• الاتجاه: \(direction)\n• المشاعر: \(sentimentLabel) بنسبة \(Int(sentimentScore * 100))٪\n\nالإجماع بين النماذج يشير إلى إشارة \(signalClass). يُنصح بالحذر مع إدارة المخاطر."
        } else if question.contains("مشاعر") || question.contains("المشاعر") {
            return "مؤشر المشاعر الحالي لـ \(selectedSymbol): \(sentimentLabel) بنسبة \(Int(sentimentScore * 100))٪. الضغط الشرائي يتفوق حالياً مع إجماع \(viewModel.consensusResult != nil ? "مؤكد من المجلس" : "إيجابي من النماذج")."
        } else if question.contains("مؤشر") || question.contains("فني") {
            return "المؤشرات الفنية لـ \(selectedSymbol):\n• RSI(14): \(String(format: "%.1f", rsiValue))\n• EMA-20: السعر \(emaValue)\n• MACD: إشارة صعودية\n• Bollinger: ضمن النطاق\nالاتجاه العام: \(direction)"
        } else if question.contains("مخاطر") || question.contains("محفظة") {
            return "تقييم المخاطر:\n• التعرض الحالي: متوسط\n• تنويع المحفظة: مقبول\n• نسبة المخاطرة للمكافأة: 1:2.3\n• وقف الخسارة الموصى به: 2٪ لكل صفقة\n\nيُنصح بتقليل حجم الصفقات في ظل تقلبات السوق الحالية."
        } else if question.contains("استراتيجي") {
            return "استراتيجية مقترحة لـ \(selectedSymbol):\n1. دخول تدريجي عند المستويات الحالية\n2. وقف خسارة عند \(String(format: "%.0f", livePrice * 0.97))\n3. جني أرباح جزئي عند \(String(format: "%.0f", livePrice * 1.03))\n4. هدف ثانوي عند \(String(format: "%.0f", livePrice * 1.05))\n\nإجماع النماذج: \(signalClass) بثقة ٧٢٪"
        } else {
            return "شكراً لسؤالك! بناءً على بيانات \(selectedSymbol) الحالية، المشاعر السوقية \(sentimentLabel) مع إجماع النماذج يشير إلى \(signalClass). يمكنك سؤالي عن تحليل أعمق أو توصيات محددة."
        }
    }

    private func loadWelcomeMessage() {
        let welcome = AIChatMessage(
            content: "مرحباً! أنا المساعد الذكي لرواعة. يمكنني تحليل السوق، تقديم توصيات، ومراجعة إجماع نماذج الذكاء الاصطناعي لـ \(selectedSymbol). كيف يمكنني مساعدتك؟",
            isUser: false,
            timestamp: Date()
        )
        chatMessages.append(welcome)
    }

    // MARK: - Formatting

    private func formatPrice(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.2f", value)
        } else if value >= 1 {
            return String(format: "%.4f", value)
        } else {
            return String(format: "%.6f", value)
        }
    }
}

// MARK: - AI Typing Indicator

private struct AITypingIndicator: View {

    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: RouaSpacing.sm) {
            // AI avatar
            Image(systemName: "sparkles")
                .font(.system(size: RouaSpacing.iconSmall))
                .foregroundStyle(.rouaPurple)

            // Bouncing dots
            HStack(spacing: RouaSpacing.xs) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.rouaPurple)
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
                    .fill(.ultraThinMaterial)
                    .opacity(0.6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                    .fill(Color.rouaGlass)
            )
            .overlay(
                RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                    .stroke(Color.rouaGlassBorder, lineWidth: 0.5)
            )

            Spacer()
        }
        .onAppear { isAnimating = true }
        .accessibilityLabel("المساعد الذكي يكتب")
    }
}

// MARK: - Preview

#Preview("AIHubView") {
    AIHubView()
}
