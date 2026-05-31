import Foundation

// MARK: - Trading ViewModel
@MainActor
class TradingViewModel: ObservableObject {
    @Published var symbol = "BTC/USDT"
    @Published var currentQuote: Quote?
    @Published var positions: [Position] = []
    @Published var accountOverview: AccountOverview?
    @Published var orderSide = "BUY"
    @Published var orderType = "MARKET"
    @Published var quantity = ""
    @Published var stopLoss = ""
    @Published var takeProfit = ""
    @Published var isPlacingOrder = false
    @Published var orderSuccess: V2PlaceOrderResponse?
    @Published var orderError: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var historicalCandles: [CandleData] = []

    private let api = APIClient.shared

    // Computed helpers
    var portfolioSummary: PortfolioSummary? {
        guard let acc = accountOverview else { return nil }
        return PortfolioSummary(
            totalValue: acc.totalValue ?? 0,
            totalPnl: (acc.totalRealizedPnl ?? 0) + (acc.totalUnrealizedPnl ?? 0),
            dailyPnl: acc.totalUnrealizedPnl ?? 0,
            positions: acc.positions,
            unrealizedPnl: acc.totalUnrealizedPnl,
            realizedPnl: acc.totalRealizedPnl
        )
    }

    func loadTradingData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load quote — response is { success, data: Quote }
            let quoteResponse: QuoteResponse = try await api.request("/exchange/quote/\(symbol)")
            self.currentQuote = quoteResponse.data

            // Load positions (raw array)
            let positions: [Position] = try await api.request("/trading/positions")
            self.positions = positions

            // Load account overview
            let account: AccountOverview = try await api.request("/trading/account")
            self.accountOverview = account

            // Load historical candles for chart
            await loadHistoricalCandles()

            self.isLoading = false
        } catch {
            self.isLoading = false
            self.errorMessage = "فشل تحميل بيانات التداول: \(error.localizedDescription)"
            self.showError = true
            print("[Trading] Load error: \(error)")
        }
    }

    func loadHistoricalCandles() async {
        do {
            let response: CandleHistoryResponse = try await api.request("/exchange/history/\(symbol)?interval=1h&limit=500")
            self.historicalCandles = response.data ?? []
        } catch {
            print("[Trading] Failed to load historical candles: \(error.localizedDescription)")
            // Don't fail the whole screen — chart will be empty
        }
    }

    func placeOrder(credentialId: String) async {
        guard let qty = Double(quantity), qty > 0 else {
            orderError = "الكمية غير صالحة"
            return
        }

        isPlacingOrder = true
        orderError = nil

        let request = PlaceOrderRequest(
            exchangeCredentialId: credentialId,
            symbol: symbol,
            side: orderSide,
            type: orderType,
            quantity: qty,
            price: nil,
            stopLoss: Double(stopLoss),
            takeProfit: Double(takeProfit),
            idempotencyKey: UUID().uuidString,
            clientOrderId: nil
        )

        do {
            let response: V2PlaceOrderResponse = try await api.request("/trading/orders", method: "POST", body: request)
            self.orderSuccess = response
            self.isPlacingOrder = false
            self.quantity = ""
            self.stopLoss = ""
            self.takeProfit = ""
            await loadTradingData()
        } catch {
            self.orderError = "فشل تقديم الطلب: \(error.localizedDescription)"
            self.isPlacingOrder = false
            print("[Trading] Order error: \(error)")
        }
    }

    func retry() async {
        await loadTradingData()
    }
}
