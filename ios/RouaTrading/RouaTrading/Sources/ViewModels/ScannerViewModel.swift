import Foundation

// MARK: - Scanner ViewModel
@MainActor
class ScannerViewModel: ObservableObject {
    @Published var results: [ScanResult] = []
    @Published var heatmapData: [HeatmapItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let api = APIClient.shared

    func runScan() async {
        isLoading = true
        errorMessage = nil

        do {
            // Scanner scan returns { items: [...], meta: {...} }
            let scanResponse: ScannerScanResponse = try await api.request("/scanner/scan")
            self.results = scanResponse.items ?? []

            // Heatmap returns raw array from NestJS (or { success, data: [...] } from web proxy)
            let heatmapItems: [HeatmapItem] = try await api.request("/scanner/heatmap")
            self.heatmapData = heatmapItems

            self.isLoading = false
        } catch {
            self.isLoading = false
            self.errorMessage = "فشل مسح السوق: \(error.localizedDescription)"
            self.showError = true
            print("[Scanner] Error: \(error)")
        }
    }

    func retry() async {
        await runScan()
    }
}
