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
            totalValue: acc.effectiveTotalValue,
            totalPnl: (acc.totalRealizedPnl ?? 0) + acc.effectiveUnrealizedPnl,
            dailyPnl: acc.dailyPnL ?? acc.effectiveUnrealizedPnl,
            positions: acc.positions,
            unrealizedPnl: acc.effectiveUnrealizedPnl,
            realizedPnl: acc.totalRealizedPnl
        )
    }

    func loadTradingData() async {
        isLoading = true
        errorMessage = nil

        // Load public market data first (no auth needed)
        async let quoteTask: () = loadQuote()
        async let candlesTask: () = loadHistoricalCandles()

        await quoteTask
        await candlesTask

        // Then try authenticated endpoints
        await loadAccountData()

        self.isLoading = false
    }

    // URL-encode symbol for path segments (BTC/USDT → BTC%2FUSDT)
    private var encodedSymbol: String {
        symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
    }

    // Convert UI timeframe to API interval
    // UI: "1m", "5m", "15m", "1h", "4h", "1D", "1W"
    // Backend CCXT: "1m", "5m", "15m", "1h", "4h", "1d", "1w", "1day"
    private var apiInterval: String {
        let tf = selectedTimeframe.lowercased()
        // CCXT uses "1d" not "1D", "1w" not "1W"
        return tf
    }

    func loadQuote() async {
        do {
            let quoteResponse: QuoteResponse = try await api.request("/exchange/quote/\(encodedSymbol)")
            self.currentQuote = quoteResponse.data
            print("[Trading] Quote loaded: \(symbol) = \(currentQuote?.lastPrice ?? 0)")
        } catch {
            print("[Trading] Quote load error: \(error.localizedDescription)")
        }
    }

    func loadAccountData() async {
        guard APIClient.shared.sessionToken != nil else {
            print("[Trading] No session token — skipping account data")
            return
        }

        // Use v2 endpoints (v1 /trading/positions is broken — 503 due to briefId)
        do {
            let positions: [Position] = try await api.request("/trading/v2/positions")
            self.positions = positions
            print("[Trading] ✅ Loaded \(positions.count) positions")
        } catch {
            print("[Trading] Positions unavailable: \(error.localizedDescription)")
        }

        do {
            let account: AccountOverview = try await api.request("/trading/v2/portfolio")
            self.accountOverview = account
            print("[Trading] ✅ Portfolio loaded")
        } catch {
            print("[Trading] Account data unavailable: \(error.localizedDescription)")
        }
    }

    func loadHistoricalCandles() async {
        do {
            let response: CandleHistoryResponse = try await api.request("/exchange/history/\(encodedSymbol)?interval=\(apiInterval)&limit=500")
            let candles = response.data ?? []
            print("[Trading] Loaded \(candles.count) historical candles for \(symbol) @ \(apiInterval)")
            self.historicalCandles = candles
        } catch {
            print("[Trading] Failed to load historical candles: \(error.localizedDescription)")
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
            let response: V2PlaceOrderResponse = try await api.request("/trading/v2/orders", method: "POST", body: request)
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
