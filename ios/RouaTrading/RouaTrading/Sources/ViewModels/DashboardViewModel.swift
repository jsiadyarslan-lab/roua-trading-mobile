import Foundation

// MARK: - Dashboard ViewModel — Loads public + auth data + council + scanner + news
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

    // New data sources
    @Published var councilBriefs: [TradingBriefItem] = []
    @Published var scannerSignals: [ScanResult] = []
    @Published var newsArticles: [NewsArticle] = []

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

        // Load all data in parallel
        async let publicTask: () = loadPublicMarketData()
        async let authTask: () = loadAuthData()
        async let briefsTask: () = loadCouncilBriefs()
        async let scannerTask: () = loadScannerSignals()
        async let newsTask: () = loadNews()

        await publicTask
        await authTask
        await briefsTask
        await scannerTask
        await newsTask

        self.isLoading = false
    }

    // MARK: - Public Data (always works, no auth needed)
    private func loadPublicMarketData() async {
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
    }

    // MARK: - Auth Data (requires login)
    private func loadAuthData() async {
        guard APIClient.shared.sessionToken != nil else {
            print("[Dashboard] No session token — skipping auth data")
            self.isAuthDataAvailable = false
            return
        }

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
        } catch {
            print("[Dashboard] Trade history unavailable: \(error.localizedDescription)")
        }
    }

    // MARK: - Council Briefs (آخر التوصيات)
    private func loadCouncilBriefs() async {
        do {
            // GET /api/strategic-council/briefs → { success: true, data: { active: [...], count: N } }
            let response: CouncilBriefsWrapper = try await api.request("/strategic-council/briefs")
            let briefs = response.data?.active ?? []
            self.councilBriefs = Array(briefs.prefix(3))
            print("[Dashboard] ✅ Loaded \(councilBriefs.count) council briefs (total active: \(briefs.count))")
        } catch {
            print("[Dashboard] Council briefs unavailable: \(error.localizedDescription)")
            self.councilBriefs = []
        }
    }

    // MARK: - Scanner Signals (آخر الإشارات)
    private func loadScannerSignals() async {
        do {
            // GET /api/scanner/scan → { success, items: [...], meta } (no ?limit= param)
            let response: ScannerScanResponse = try await api.request("/scanner/scan")
            let allItems = response.items ?? []
            self.scannerSignals = Array(allItems.prefix(3))
            print("[Dashboard] ✅ Loaded \(scannerSignals.count) scanner signals (total: \(allItems.count))")
        } catch {
            print("[Dashboard] Scanner signals unavailable: \(error.localizedDescription)")
            self.scannerSignals = []
        }
    }

    // MARK: - News (آخر الأخبار)
    private func loadNews() async {
        do {
            // GET /api/news/latest?limit=5 → { success: true, data: [...], count: N }
            let response: NewsListResponse = try await api.request("/news/latest?limit=5")
            self.newsArticles = response.data ?? []
            print("[Dashboard] ✅ Loaded \(newsArticles.count) news articles")
        } catch {
            print("[Dashboard] News unavailable: \(error.localizedDescription)")
            self.newsArticles = []
        }
    }

    func retry() async {
        await loadDashboard()
    }
}

// MARK: - Trading Brief Item (for council briefs display)
// Backend returns: { id, pair, direction, entryPrice, stopLoss, takeProfit, confidence, timeframe, issuedAt, expiresAt, isActive, strictRules, reviewStatus, analysisSummary }
struct TradingBriefItem: Codable, Identifiable {
    let id: String
    let pair: String
    let direction: String?
    let entryPrice: Double?
    let stopLoss: Double?
    let takeProfit: Double?
    let confidence: Double?
    let timeframe: String?
    let isActive: Bool?
    let issuedAt: String?
    let expiresAt: String?
    let reviewStatus: String?
    let analysisSummary: String?

    // Compat alias
    var createdAt: String? { issuedAt }
}

// MARK: - API Response types for new endpoints

// GET /api/strategic-council/briefs → { success: true, data: { active: [...], count: N } }
struct CouncilBriefsWrapper: Codable {
    let success: Bool?
    let data: CouncilBriefsData?
}

struct CouncilBriefsData: Codable {
    let active: [TradingBriefItem]?
    let count: Int?
}

// GET /api/news/latest → { success: true, data: [...], count: N }
struct NewsListResponse: Codable {
    let success: Bool?
    let data: [NewsArticle]?
    let count: Int?
}
