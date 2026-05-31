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
    @Published var selectedTimeframe = "1h"

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

        // Load public market data first (no auth needed)
        async let quoteTask: () = loadQuote()
        async let candlesTask: () = loadHistoricalCandles()

        // Then try authenticated endpoints (may fail if not logged in)
        await quoteTask
        await candlesTask

        // Try authenticated data — don't fail the whole screen if these error
        await loadAccountData()

        self.isLoading = false
    }

    func loadQuote() async {
        do {
            let quoteResponse: QuoteResponse = try await api.request("/exchange/quote/\(symbol)")
            self.currentQuote = quoteResponse.data
        } catch {
            print("[Trading] Quote load error: \(error)")
        }
    }

    func loadAccountData() async {
        do {
            // Load positions (requires auth — may return empty or 401)
            let positions: [Position] = try await api.request("/trading/positions")
            self.positions = positions

            // Load account overview
            let account: AccountOverview = try await api.request("/trading/account")
            self.accountOverview = account
        } catch {
            // Auth required — not an error if user not logged in
            print("[Trading] Account data unavailable (auth required): \(error.localizedDescription)")
        }
    }

    func loadHistoricalCandles() async {
        do {
            // Normalize timeframe for API: "1D" -> "1d", "1W" -> "1w"
            let apiInterval = selectedTimeframe.lowercased()
            let response: CandleHistoryResponse = try await api.request("/exchange/history/\(symbol)?interval=\(apiInterval)&limit=500")
            let candles = response.data ?? []
            print("[Trading] Loaded \(candles.count) historical candles for \(symbol) @ \(apiInterval)")
            self.historicalCandles = candles
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
