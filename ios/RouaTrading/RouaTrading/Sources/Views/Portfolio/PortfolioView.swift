import SwiftUI

struct PortfolioView: View {
    @StateObject private var vm = PortfolioViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RouaTheme.Spacing.lg) {
                // Error Banner
                if let error = vm.errorMessage {
                    ErrorBanner(message: error) { Task { await vm.retry() } }
                }

                // Total Portfolio Value
                GlassCard {
                    VStack(spacing: RouaTheme.Spacing.md) {
                        Text("إجمالي قيمة المحفظة").font(.system(size: 12, weight: .medium)).foregroundStyle(RouaTheme.Colors.textTertiary).frame(maxWidth: .infinity, alignment: .leading)
                        if vm.isLoading && vm.totalValue == 0 {
                            ShimmerView()
                        } else {
                            Text(String(format: "$%.2f", vm.totalValue)).font(.system(size: 28, weight: .bold, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textPrimary)
                        }
                    }
                }

                // Exchange Balances
                if !vm.balances.isEmpty {
                    Text("أرصدة البورصات").font(.system(size: 16, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(vm.balances) { balance in
                        GlassCard {
                            VStack(spacing: RouaTheme.Spacing.md) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(balance.label ?? balance.exchange ?? "بورصة").font(.system(size: 14, weight: .medium)).foregroundStyle(RouaTheme.Colors.textPrimary)
                                        Text((balance.exchange ?? "").uppercased()).font(.system(size: 10)).foregroundStyle(RouaTheme.Colors.textTertiary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        if let equity = balance.equity {
                                            Text(String(format: "$%.2f", equity)).font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textPrimary)
                                        }
                                        if let available = balance.available {
                                            Text("متاح: \(String(format: "$%.2f", available))").font(.system(size: 10, design: .monospaced)).foregroundStyle(RouaTheme.Colors.textTertiary)
                                        }
                                    }
                                    if balance.isTestnet == true {
                                        Text("تجريبي").font(.system(size: 10, weight: .medium)).foregroundStyle(RouaTheme.Colors.warning).padding(.horizontal, 8).padding(.vertical, 3).background(RouaTheme.Colors.warningBackground).clipShape(Capsule())
                                    }
                                }

                                // Show error if balance fetch failed
                                if let error = balance.error {
                                    Text(error).font(.system(size: 11)).foregroundStyle(RouaTheme.Colors.loss).frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                }

                // Exchange Credentials
                if vm.isLoading && vm.credentials.isEmpty {
                    ForEach(0..<2, id: \.self) { _ in
                        GlassCard { ShimmerView() }
                    }
                } else if vm.credentials.isEmpty && vm.balances.isEmpty {
                    GlassCard {
                        VStack(spacing: RouaTheme.Spacing.sm) {
                            Image(systemName: "wallet.pass").font(.system(size: 28)).foregroundStyle(RouaTheme.Colors.textTertiary)
                            Text("لا توجد حسابات مربوطة").font(.system(size: 14)).foregroundStyle(RouaTheme.Colors.textSecondary)
                        }.frame(maxWidth: .infinity).padding(.vertical, RouaTheme.Spacing.xl)
                    }
                } else if !vm.credentials.isEmpty {
                    Text("حسابات التداول").font(.system(size: 16, weight: .semibold)).foregroundStyle(RouaTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)

                    GlassCard {
                        VStack(spacing: RouaTheme.Spacing.md) {
                            ForEach(vm.credentials) { cred in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(cred.label).font(.system(size: 14, weight: .medium)).foregroundStyle(RouaTheme.Colors.textPrimary)
                                        Text(cred.exchange.uppercased()).font(.system(size: 10)).foregroundStyle(RouaTheme.Colors.textTertiary)
                                    }
                                    Spacer()
                                    if cred.testnet {
                                        Text("تجريبي").font(.system(size: 10, weight: .medium)).foregroundStyle(RouaTheme.Colors.warning).padding(.horizontal, 8).padding(.vertical, 3).background(RouaTheme.Colors.warningBackground).clipShape(Capsule())
                                    }
                                    Circle().fill(cred.isValid ?? false ? RouaTheme.Colors.profit : RouaTheme.Colors.loss).frame(width: 8, height: 8)
                                }.padding(.vertical, 4)
                            }
                        }
                    }
                }
            }.padding(RouaTheme.Spacing.lg)
        }.background(RouaTheme.Colors.background).task { await vm.loadData() }
        .refreshable { await vm.loadData() }
        .navigationTitle("المحفظة")
    }
}
