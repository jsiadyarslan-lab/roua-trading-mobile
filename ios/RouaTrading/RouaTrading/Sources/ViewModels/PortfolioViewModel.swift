import Foundation

// MARK: - Portfolio ViewModel
@MainActor
class PortfolioViewModel: ObservableObject {
    @Published var credentials: [ExchangeCredential] = []
    @Published var totalValue: Double = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let api = APIClient.shared

    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Credentials returns { success: true, data: [...] }
            let response: CredentialsResponse = try await api.request("/portfolio/credentials")
            self.credentials = response.data ?? []
        } catch {
            self.errorMessage = "فشل تحميل المحفظة: \(error.localizedDescription)"
            self.showError = true
            print("[Portfolio] Error: \(error)")
        }

        // Also load account overview for total portfolio value
        do {
            let account: AccountOverview = try await api.request("/trading/account")
            self.totalValue = account.totalValue ?? 0
        } catch {
            // Account data may require auth — don't fail
            print("[Portfolio] Account data unavailable: \(error.localizedDescription)")
        }

        self.isLoading = false
    }

    func retry() async {
        await loadData()
    }
}
