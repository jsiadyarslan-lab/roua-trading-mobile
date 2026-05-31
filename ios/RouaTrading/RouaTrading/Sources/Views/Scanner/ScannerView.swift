import SwiftUI

struct ScannerView: View {
    @StateObject private var vm = ScannerViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaTheme.Spacing.lg) {
                // Error Banner
                if let error = vm.errorMessage {
                    ErrorBanner(message: error) { Task { await vm.retry() } }
                }

                Text("ماسح السوق").font(.system(size: 22, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)

                if vm.isLoading && vm.results.isEmpty {
                    ForEach(0..<5, id: \.self) { _ in
                        GlassCard { ShimmerView() }
                    }
                } else if vm.results.isEmpty {
                    GlassCard {
                        VStack(spacing: RouaTheme.Spacing.sm) {
                            Image(systemName: "magnifyingglass").font(.system(size: 28)).foregroundStyle(RouaTheme.Colors.textTertiary)
                            Text("لا توجد نتائج مسح").font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textSecondary)
                        }.frame(maxWidth: .infinity).padding(.vertical, RouaTheme.Spacing.xl)
                    }
                } else {
                    ForEach(vm.results) { r in
                        GlassCard {
                            VStack(spacing: RouaTheme.Spacing.sm) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 6) {
                                            Text(r.symbol).font(.system(size: 14, weight: .medium)).foregroundStyle(RouaTheme.Colors.textPrimary)
                                            if let dir = r.direction {
                                                Text(dir == "BUY" ? "شراء" : dir == "SELL" ? "بيع" : "محايد")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundStyle(dir == "BUY" ? RouaTheme.Colors.profit : dir == "SELL" ? RouaTheme.Colors.loss : RouaTheme.Colors.textTertiary)
                                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                                    .background(dir == "BUY" ? RouaTheme.Colors.profitBackground : dir == "SELL" ? RouaTheme.Colors.lossBackground : RouaTheme.Colors.surfaceElevated)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                        if let n = r.name { Text(n).font(.system(size: 12)).foregroundStyle(RouaTheme.Colors.textTertiary).lineLimit(1) }
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        if let price = r.price { Text(String(format: "%.2f", price)).font(.system(size: 13, weight: .semibold, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textPrimary) }
                                        if let pct = r.changePercent { ChangeBadge(value: pct) }
                                    }
                                }

                                // Technical indicators row
                                if r.rsi != nil || r.technicalScore != nil || r.confidence != nil {
                                    HStack(spacing: RouaTheme.Spacing.md) {
                                        if let rsi = r.rsi { StatMini(title: "RSI", value: String(format: "%.1f", rsi)) }
                                        if let score = r.technicalScore { StatMini(title: "نقاط", value: "\(score)") }
                                        if let conf = r.confidence { StatMini(title: "ثقة", value: "\(conf)%") }
                                    }
                                }

                                // Arabic reasons
                                if let reasons = r.reasonsAr, !reasons.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 4) {
                                            ForEach(reasons, id: \.self) { reason in
                                                Text(reason).font(.system(size: 9)).foregroundStyle(RouaTheme.Colors.textSecondary)
                                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                                    .background(RouaTheme.Colors.surfaceElevated)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }.padding(RouaTheme.Spacing.lg)
        }.background(RouaTheme.Colors.background).task { await vm.runScan() }.refreshable { await vm.runScan() }
        .navigationTitle("الماسح")
    }
}
