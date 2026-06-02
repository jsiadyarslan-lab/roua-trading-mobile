// =============================================================================
// OrderSheet.swift — Roua Trading · Order Placement Sheet
// =============================================================================
// Half-sheet (medium detent) for placing buy/sell orders.
// Includes: side toggle, order type, quantity, price, SL/TP,
// credential selector, order summary, and confirmation.
//
// RTL-aware (Arabic). Haptic feedback on confirmation.
// Uses: TradingViewModel, RouaComponents, RouaColors, RouaTypography
// =============================================================================

import SwiftUI

// MARK: - Order Sheet

/// Sheet for placing a new buy or sell order.
///
/// Presented as a half-sheet (`.medium` detent).
/// Pre-selects the order side based on which floating button was tapped.
struct OrderSheet: View {

    // MARK: - Properties

    @ObservedObject var viewModel: TradingViewModel
    let initialSide: OrderSide

    // MARK: - State

    @State private var side: OrderSide = .buy
    @State private var orderType: OrderType = .market
    @State private var quantityText: String = ""
    @State private var priceText: String = ""
    @State private var stopLossText: String = ""
    @State private var takeProfitText: String = ""
    @State private var selectedCredentialId: String?
    @State private var showSuccess: Bool = false
    @State private var showAdvanced: Bool = false

    @Environment(\.dismiss) private var dismiss

    // MARK: - Computed

    /// Parsed quantity value.
    private var quantity: Double {
        Double(quantityText) ?? 0
    }

    /// Parsed limit price.
    private var price: Double? {
        let val = Double(priceText)
        return (val ?? 0) > 0 ? val : nil
    }

    /// Parsed stop loss.
    private var stopLoss: Double? {
        let val = Double(stopLossText)
        return (val ?? 0) > 0 ? val : nil
    }

    /// Parsed take profit.
    private var takeProfit: Double? {
        let val = Double(takeProfitText)
        return (val ?? 0) > 0 ? val : nil
    }

    /// Current price from the quote.
    private var currentPrice: Double {
        viewModel.currentQuote?.price ?? 0
    }

    /// Estimated total (quantity × execution price).
    private var estimatedTotal: Double {
        let execPrice = orderType == .limit ? (price ?? currentPrice) : currentPrice
        return quantity * execPrice
    }

    /// Estimated trading fee (0.1% taker fee).
    private var estimatedFee: Double {
        estimatedTotal * 0.001
    }

    /// Whether the form is valid for submission.
    private var isValid: Bool {
        quantity > 0
        && selectedCredentialId != nil
        && (orderType == .market || (price ?? 0) > 0)
    }

    // MARK: - Initialization

    init(viewModel: TradingViewModel, initialSide: OrderSide = .buy) {
        self.viewModel = viewModel
        self.initialSide = initialSide
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: RouaSpacing.lg) {
                    // Symbol display
                    symbolHeader

                    // BUY / SELL toggle
                    sideToggle

                    // Order type selector
                    orderTypeSelector

                    // Quantity input
                    quantityInput

                    // Price input (limit orders)
                    if orderType == .limit {
                        priceInput
                    }

                    // Advanced section toggle
                    advancedToggle

                    // SL / TP inputs
                    if showAdvanced {
                        stopLossInput
                        takeProfitInput
                    }

                    // Credential selector
                    credentialSelector

                    // Order summary
                    orderSummary

                    // Confirm button
                    confirmButton

                    // Error display
                    if let error = viewModel.errorMessage {
                        orderError(message: error)
                    }
                }
                .padding(.horizontal, RouaSpacing.screenPadding)
                .padding(.top, RouaSpacing.md)
                .padding(.bottom, RouaSpacing.xxxl)
            }
            .background(Color.rouaBackground)
            .navigationTitle("طلب جديد")  // New Order
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.rouaTextTertiary)
                    }
                    .accessibilityLabel("Close")
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .overlay {
                if showSuccess {
                    successOverlay
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.rouaBackground)
        .onAppear {
            side = initialSide
            selectedCredentialId = viewModel.credentials.first?.id
        }
    }

    // MARK: - Symbol Header

    private var symbolHeader: some View {
        HStack {
            Text(String(viewModel.currentSymbol.prefix(2)))
                .rouaFont(.calloutBold, color: .rouaTextPrimary)
                .frame(width: 40, height: 40)
                .background(Color.rouaSurfaceLight)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.currentSymbol)
                    .rouaFont(.title3, color: .rouaTextPrimary)
                if let quote = viewModel.currentQuote {
                    Text(quote.price.asPrice())
                        .rouaFont(.monoSmall, color: .rouaTextSecondary)
                        .monospacedDigit()
                }
            }

            Spacer()

            if viewModel.currentQuote != nil {
                PulsingDot(status: .active, size: 6)
            }
        }
        .padding(RouaSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                .fill(Color.rouaSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                .stroke(Color.rouaGlassBorder, lineWidth: 1)
        )
    }

    // MARK: - Side Toggle

    private var sideToggle: some View {
        HStack(spacing: 0) {
            // Buy button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    side = .buy
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Text("شراء")  // Buy
                    .rouaFont(.calloutBold, color: side == .buy ? .white : .rouaTextTertiary)
                    .frame(maxWidth: .infinity)
                    .frame(height: RouaSpacing.buttonHeightSmall)
                    .background(
                        RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                            .fill(side == .buy ? Color.rouaProfit : Color.rouaSurfaceLight)
                    )
            }
            .accessibilityLabel("Buy order")
            .accessibilityAddTraits(side == .buy ? .isSelected : [])

            Spacer()
                .frame(width: RouaSpacing.sm)

            // Sell button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    side = .sell
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Text("بيع")  // Sell
                    .rouaFont(.calloutBold, color: side == .sell ? .white : .rouaTextTertiary)
                    .frame(maxWidth: .infinity)
                    .frame(height: RouaSpacing.buttonHeightSmall)
                    .background(
                        RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                            .fill(side == .sell ? Color.rouaLoss : Color.rouaSurfaceLight)
                    )
            }
            .accessibilityLabel("Sell order")
            .accessibilityAddTraits(side == .sell ? .isSelected : [])
        }
    }

    // MARK: - Order Type Selector

    private var orderTypeSelector: some View {
        VStack(alignment: .leading, spacing: RouaSpacing.sm) {
            Text("نوع الطلب")  // Order Type
                .rouaFont(.subheadlineBold, color: .rouaTextSecondary)

            HStack(spacing: 0) {
                ForEach([OrderType.market, .limit], id: \.self) { type in
                    Button {
                        withAnimation(.easeInOut(duration: RouaSpacing.animationFast)) {
                            orderType = type
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Text(type.displayName)
                            .rouaFont(
                                .footnoteBold,
                                color: orderType == type ? .rouaPrimary : .rouaTextTertiary
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, RouaSpacing.sm)
                            .background(
                                Capsule()
                                    .fill(orderType == type ? Color.rouaPrimary.opacity(0.15) : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(orderType == type ? .isSelected : [])
                }
            }
            .padding(RouaSpacing.xs)
            .background(
                Capsule()
                    .fill(Color.rouaSurfaceLight)
            )
        }
    }

    // MARK: - Quantity Input

    private var quantityInput: some View {
        VStack(alignment: .leading, spacing: RouaSpacing.sm) {
            Text("الكمية")  // Quantity
                .rouaFont(.subheadlineBold, color: .rouaTextSecondary)

            HStack(spacing: RouaSpacing.sm) {
                // Minus button
                Button {
                    let current = quantity
                    let step = stepSize(for: currentPrice)
                    let newQty = max(0, current - step)
                    quantityText = formatQuantity(newQty)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.rouaTextSecondary)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.rouaSurfaceLight))
                }
                .accessibilityLabel("Decrease quantity")

                // Text field
                TextField("0.00", text: $quantityText)
                    .rouaFont(.mono, color: .rouaTextPrimary)
                    .monospacedDigit()
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, RouaSpacing.sm)
                    .frame(height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                            .fill(Color.rouaSurfaceLight)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                            .stroke(Color.rouaGlassBorder, lineWidth: 1)
                    )
                    .accessibilityLabel("Quantity")

                // Plus button
                Button {
                    let current = quantity
                    let step = stepSize(for: currentPrice)
                    let newQty = current + step
                    quantityText = formatQuantity(newQty)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.rouaTextSecondary)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.rouaSurfaceLight))
                }
                .accessibilityLabel("Increase quantity")

                // Percentage buttons
                ForEach([25, 50, 100], id: \.self) { pct in
                    Button {
                        // TODO: Calculate based on available balance from selected credential
                        quantityText = formatQuantity(Double(pct) / 100.0)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Text("\(pct)%")
                            .rouaFont(.captionBold, color: .rouaPrimary)
                            .padding(.horizontal, RouaSpacing.sm)
                            .padding(.vertical, RouaSpacing.xs)
                            .background(
                                Capsule()
                                    .fill(Color.rouaPrimary.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Price Input

    private var priceInput: some View {
        VStack(alignment: .leading, spacing: RouaSpacing.sm) {
            Text("سعر الحد")  // Limit Price
                .rouaFont(.subheadlineBold, color: .rouaTextSecondary)

            HStack(spacing: RouaSpacing.sm) {
                TextField(
                    currentPrice.asPrice(),
                    text: $priceText
                )
                .rouaFont(.mono, color: .rouaTextPrimary)
                .monospacedDigit()
                .keyboardType(.decimalPad)
                .padding(.horizontal, RouaSpacing.md)
                .frame(height: RouaSpacing.buttonHeightSmall)
                .background(
                    RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                        .fill(Color.rouaSurfaceLight)
                    )
                .overlay(
                    RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                        .stroke(Color.rouaGlassBorder, lineWidth: 1)
                )
                .accessibilityLabel("Limit price")

                // Fill current price button
                Button {
                    priceText = String(format: "%.2f", currentPrice)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Text("السعر")  // Price
                        .rouaFont(.captionBold, color: .rouaPrimary)
                        .padding(.horizontal, RouaSpacing.sm)
                        .padding(.vertical, RouaSpacing.xs)
                        .background(
                            Capsule()
                                .fill(Color.rouaPrimary.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Use current price")
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Advanced Toggle

    private var advancedToggle: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showAdvanced.toggle()
            }
        } label: {
            HStack {
                Text("وقف الخسارة / جني الأرباح")  // Stop Loss / Take Profit
                    .rouaFont(.subheadline, color: .rouaTextSecondary)
                Spacer()
                Image(systemName: showAdvanced ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.rouaTextTertiary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Toggle stop loss and take profit")
        .accessibilityValue(showAdvanced ? "Expanded" : "Collapsed")
    }

    // MARK: - Stop Loss Input

    private var stopLossInput: some View {
        VStack(alignment: .leading, spacing: RouaSpacing.sm) {
            Text("وقف الخسارة (اختياري)")  // Stop Loss (optional)
                .rouaFont(.subheadline, color: .rouaTextSecondary)

            TextField("0.00", text: $stopLossText)
                .rouaFont(.mono, color: .rouaTextPrimary)
                .monospacedDigit()
                .keyboardType(.decimalPad)
                .padding(.horizontal, RouaSpacing.md)
                .frame(height: RouaSpacing.buttonHeightSmall)
                .background(
                    RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                        .fill(Color.rouaLossBg)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                        .stroke(Color.rouaLoss.opacity(0.2), lineWidth: 1)
                )
                .accessibilityLabel("Stop loss price")
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Take Profit Input

    private var takeProfitInput: some View {
        VStack(alignment: .leading, spacing: RouaSpacing.sm) {
            Text("جني الأرباح (اختياري)")  // Take Profit (optional)
                .rouaFont(.subheadline, color: .rouaTextSecondary)

            TextField("0.00", text: $takeProfitText)
                .rouaFont(.mono, color: .rouaTextPrimary)
                .monospacedDigit()
                .keyboardType(.decimalPad)
                .padding(.horizontal, RouaSpacing.md)
                .frame(height: RouaSpacing.buttonHeightSmall)
                .background(
                    RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                        .fill(Color.rouaProfitBg)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                        .stroke(Color.rouaProfit.opacity(0.2), lineWidth: 1)
                )
                .accessibilityLabel("Take profit price")
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Credential Selector

    private var credentialSelector: some View {
        VStack(alignment: .leading, spacing: RouaSpacing.sm) {
            Text("حساب التداول")  // Trading Account
                .rouaFont(.subheadlineBold, color: .rouaTextSecondary)

            Menu {
                ForEach(viewModel.credentials) { credential in
                    Button {
                        selectedCredentialId = credential.id
                    } label: {
                        HStack {
                            Text(credential.displayLabel)
                            if credential.testnet {
                                Text("Testnet")
                                    .font(.caption)
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedCredentialLabel)
                        .rouaFont(.callout, color: .rouaTextPrimary)
                        .lineLimit(1)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.rouaTextTertiary)
                }
                .padding(.horizontal, RouaSpacing.md)
                .frame(height: RouaSpacing.buttonHeight)
                .background(
                    RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                        .fill(Color.rouaSurfaceLight)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                        .stroke(Color.rouaGlassBorder, lineWidth: 1)
                )
            }
            .accessibilityLabel("Select trading account")
        }
    }

    /// Display label for the currently selected credential.
    private var selectedCredentialLabel: String {
        guard let id = selectedCredentialId,
              let credential = viewModel.credentials.first(where: { $0.id == id }) else {
            return "اختر حساباً"  // Select account
        }
        return credential.displayLabel
    }

    // MARK: - Order Summary

    private var orderSummary: some View {
        GlassCard {
            VStack(spacing: RouaSpacing.sm) {
                summaryRow(
                    label: "الإجمالي المقدّر",  // Estimated Total
                    value: estimatedTotal.asCurrency()
                )
                summaryRow(
                    label: "الرسوم المقدّرة",  // Estimated Fees
                    value: estimatedFee.asCurrency()
                )

                Divider()
                    .background(Color.rouaBorder)

                summaryRow(
                    label: "الصافي",  // Net
                    value: (estimatedTotal + estimatedFee).asCurrency(),
                    valueColor: side == .buy ? .rouaLoss : .rouaProfit
                )
            }
        }
    }

    private func summaryRow(label: String, value: String, valueColor: Color = .rouaTextPrimary) -> some View {
        HStack {
            Text(label)
                .rouaFont(.subheadline, color: .rouaTextSecondary)
            Spacer()
            Text(value)
                .rouaFont(.calloutBold, color: valueColor)
                .monospacedDigit()
        }
    }

    // MARK: - Confirm Button

    private var confirmButton: some View {
        RouaButton(
            "تأكيد الطلب",  // Confirm Order
            variant: side == .buy ? .primary : .danger,
            size: .large,
            icon: side == .buy ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill",
            iconPosition: .leading,
            isLoading: viewModel.isPlacingOrder,
            isDisabled: !isValid
        ) {
            placeOrder()
        }
        .background(
            side == .buy ? Color.rouaGradientProfit : Color.rouaGradientLoss
        )
        .clipShape(RoundedRectangle(cornerRadius: RouaSpacing.buttonCornerRadius, style: .continuous))
    }

    // MARK: - Error Display

    private func orderError(message: String) -> some View {
        HStack(spacing: RouaSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.rouaLoss)
            Text(message)
                .rouaFont(.footnote, color: .rouaTextPrimary)
                .lineLimit(2)
            Spacer()
        }
        .padding(RouaSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: RouaSpacing.smallCornerRadius, style: .continuous)
                .fill(Color.rouaLossBg)
        )
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            Color.rouaBackground.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: RouaSpacing.lg) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.rouaProfit)

                Text("تم تنفيذ الطلب")  // Order executed
                    .rouaFont(.title3, color: .rouaTextPrimary)

                Text("\(side.displayName) \(quantityText) \(viewModel.currentSymbol)")
                    .rouaFont(.callout, color: .rouaTextSecondary)
            }
            .padding(RouaSpacing.xxxl)
        }
        .transition(.opacity)
        .onAppear {
            // Auto-dismiss after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                dismiss()
            }
        }
    }

    // MARK: - Actions

    private func placeOrder() {
        guard let credentialId = selectedCredentialId else { return }

        let request = OrderRequest(
            exchangeCredentialId: credentialId,
            symbol: viewModel.currentSymbol,
            side: side,
            type: orderType,
            quantity: quantity,
            price: orderType == .limit ? price : nil,
            stopLoss: stopLoss,
            takeProfit: takeProfit,
            idempotencyKey: nil,
            clientOrderId: nil,
            signalId: nil
        )

        Task {
            await viewModel.placeOrder(request)

            if viewModel.errorMessage == nil {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showSuccess = true
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    // MARK: - Helpers

    /// Determines the quantity step size based on the current price.
    private func stepSize(for price: Double) -> Double {
        switch price {
        case ..<1:       return 100
        case ..<10:      return 10
        case ..<100:     return 1
        case ..<1000:    return 0.1
        case ..<10000:   return 0.01
        case ..<100000:  return 0.001
        default:         return 0.0001
        }
    }

    /// Formats a quantity for display in the text field.
    private func formatQuantity(_ value: Double) -> String {
        if value == floor(value) && value < 10000 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.4f", value)
    }
}

// =============================================================================
// MARK: - Preview
// =============================================================================

#Preview("OrderSheet - Buy") {
    OrderSheet(
        viewModel: TradingViewModel(),
        initialSide: .buy
    )
}

#Preview("OrderSheet - Sell") {
    OrderSheet(
        viewModel: TradingViewModel(),
        initialSide: .sell
    )
}
