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
            totalValue: acc.totalValue ?? 0,
            totalPnl: (acc.totalRealizedPnl ?? 0) + (acc.totalUnrealizedPnl ?? 0),
            dailyPnl: acc.totalUnrealizedPnl ?? 0,
            positions: acc.positions,
            unrealizedPnl: acc.totalUnrealizedPnl,
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

        do {
            let account: AccountOverview = try await api.request("/trading/account")
            self.accountOverview = account
            self.positions = account.positions ?? []
            self.isAuthDataAvailable = true
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
        } catch {
            print("[Dashboard] Trade history unavailable: \(error.localizedDescription)")
        }
    }

    func retry() async {
        await loadDashboard()
    }
}
