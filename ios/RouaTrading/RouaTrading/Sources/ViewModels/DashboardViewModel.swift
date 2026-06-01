import Foundation

// MARK: - Dashboard ViewModel — Loads public + auth data
@MainActor
class DashboardViewModel: ObservableObject {
    @Published var accountOverview: AccountOverview?
    @Published var positions: [Position] = []
    @Published var trades: [Trade] = []
    @Published var topQuotes: [Quote] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var isAuthDataAvailable = false

    private let api = APIClient.shared

    // Popular symbols to show on dashboard
    private let popularSymbols = ["BTC/USDT", "ETH/USDT", "SOL/USDT", "XRP/USDT", "BNB/USDT", "XAU/USDT"]

    // Computed portfolio summary from account overview
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

    func loadDashboard() async {
        isLoading = true
        errorMessage = nil

        // Always load public market data first (no auth needed)
        await loadPublicMarketData()

        // Then try authenticated endpoints
        await loadAuthData()

        self.isLoading = false
    }

    // MARK: - Public Data (always works, no auth needed)
    private func loadPublicMarketData() async {
        // Load quotes for popular symbols
        var loadedQuotes: [Quote] = []
        for symbol in popularSymbols.prefix(6) {
            do {
                let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
                let quoteResponse: QuoteResponse = try await api.request("/exchange/quote/\(encoded)")
                if let quote = quoteResponse.data {
                    loadedQuotes.append(quote)
                }
            } catch {
                print("[Dashboard] Quote load error for \(symbol): \(error.localizedDescription)")
            }
        }
        self.topQuotes = loadedQuotes

        // Load scanner overview for market sentiment
        // (This is public data — no auth needed)
    }

    // MARK: - Auth Data (requires login)
    private func loadAuthData() async {
        // Check if we have a session token
        guard APIClient.shared.sessionToken != nil else {
            print("[Dashboard] No session token — skipping auth data")
            self.isAuthDataAvailable = false
            return
        }

        // Use v2/portfolio endpoint (v1 /trading/account is broken — 503)
        do {
            let account: AccountOverview = try await api.request("/trading/v2/portfolio")
            self.accountOverview = account
            self.positions = account.effectivePositions
            self.isAuthDataAvailable = true
            print("[Dashboard] ✅ Portfolio loaded: value=\(account.effectiveTotalValue), positions=\(account.effectivePositions.count)")
        } catch {
            if let apiError = error as? APIError, case .unauthorized = apiError {
                self.errorMessage = "يرجى تسجيل الدخول لعرض بيانات حسابك"
                self.showError = true
                self.isAuthDataAvailable = false
            } else {
                print("[Dashboard] Account data unavailable: \(error.localizedDescription)")
                self.isAuthDataAvailable = false
            }
        }

        do {
            let historyResponse: TradeHistoryResponse = try await api.request("/trading/history")
            self.trades = historyResponse.trades ?? []
            print("[Dashboard] ✅ Loaded \(self.trades.count) trade history items")
        } catch {
            print("[Dashboard] Trade history unavailable: \(error.localizedDescription)")
        }
    }

    func retry() async {
        await loadDashboard()
    }
}
