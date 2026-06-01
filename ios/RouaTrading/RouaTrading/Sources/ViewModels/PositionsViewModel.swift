import Foundation

// MARK: - Positions ViewModel — بيانات الصفقات المفتوحة والمغلقة
@MainActor
class PositionsViewModel: ObservableObject {
    @Published var positions: [Position] = []
    @Published var closedTrades: [Trade] = []
    @Published var accountOverview: AccountOverview?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedPeriod: Period = .all

    private let api = APIClient.shared

    // MARK: - Period Filter
    enum Period: String, CaseIterable {
        case all = "الكل"
        case day = "يوم"
        case week = "أسبوع"
        case month = "شهر"
        case year = "سنوي"

        var title: String { rawValue }
    }

    // Computed: filtered trades based on selected period
    var filteredTrades: [Trade] {
        guard selectedPeriod != .all else { return closedTrades }
        let now = Date()
        let calendar = Calendar.current
        return closedTrades.filter { trade in
            guard let closeTime = trade.closeTime, closeTime > 0 else { return false }
            let tradeDate = Date(timeIntervalSince1970: Double(closeTime) / 1000)
            switch selectedPeriod {
            case .day: return calendar.isDateInToday(tradeDate)
            case .week: return calendar.isDate(tradeDate, equalTo: now, toGranularity: .weekOfYear)
            case .month: return calendar.isDate(tradeDate, equalTo: now, toGranularity: .month)
            case .year: return calendar.isDate(tradeDate, equalTo: now, toGranularity: .year)
            case .all: return true
            }
        }
    }

    // Account detail computed values
    var availableBalance: Double {
        let total = accountOverview?.effectiveTotalValue ?? 0
        let margin = usedMargin
        return max(0, total - margin)
    }

    var usedMargin: Double {
        accountOverview?.effectiveUsedMargin ?? 0
    }

    var marginRatio: Double {
        let total = accountOverview?.effectiveTotalValue ?? 0
        guard total > 0 else { return 0 }
        return (usedMargin / total) * 100
    }

    // MARK: - Load Data
    func loadData() async {
        isLoading = true
        errorMessage = nil

        guard APIClient.shared.sessionToken != nil else {
            isLoading = false
            return
        }

        // Load positions and portfolio in parallel
        async let positionsTask: () = loadPositions()
        async let portfolioTask: () = loadPortfolio()
        async let historyTask: () = loadTradeHistory()

        await positionsTask
        await portfolioTask
        await historyTask

        isLoading = false
    }

    private func loadPositions() async {
        do {
            let positions: [Position] = try await api.request("/trading/v2/positions")
            self.positions = positions.filter { $0.status == "OPEN" }
            print("[Positions] ✅ Loaded \(self.positions.count) open positions")
        } catch {
            print("[Positions] Positions unavailable: \(error.localizedDescription)")
        }
    }

    private func loadPortfolio() async {
        do {
            let account: AccountOverview = try await api.request("/trading/v2/portfolio")
            self.accountOverview = account
            print("[Positions] ✅ Portfolio loaded")
        } catch {
            print("[Positions] Portfolio unavailable: \(error.localizedDescription)")
        }
    }

    private func loadTradeHistory() async {
        do {
            let response: TradeHistoryResponse = try await api.request("/trading/history")
            self.closedTrades = response.trades ?? []
            print("[Positions] ✅ Loaded \(self.closedTrades.count) closed trades")
        } catch {
            print("[Positions] Trade history unavailable: \(error.localizedDescription)")
        }
    }

    func retry() async {
        await loadData()
    }
}
