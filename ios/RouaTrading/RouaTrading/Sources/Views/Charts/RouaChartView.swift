import SwiftUI
import LightweightCharts

// MARK: - Real TradingView Candlestick Chart
struct RouaChartView: View {
    let candles: [CandleData]
    let liveCandle: CandleData?
    let onTimeframeChange: (String) -> Void
    let selectedTimeframe: String

    private let timeframes = ["1m", "5m", "15m", "1h", "4h", "1d"]

    var body: some View {
        VStack(spacing: 0) {
            // Timeframe selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: RouaTheme.Spacing.sm) {
                    ForEach(timeframes, id: \.self) { tf in
                        Button { onTimeframeChange(tf) } label: {
                            Text(tf).font(.system(size: 11, weight: selectedTimeframe == tf ? .bold : .medium))
                                .foregroundStyle(selectedTimeframe == tf ? .white : RouaTheme.Colors.textSecondary)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(selectedTimeframe == tf ? RouaTheme.Colors.accent : RouaTheme.Colors.surfaceElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }.padding(.horizontal, RouaTheme.Spacing.lg).padding(.vertical, RouaTheme.Spacing.sm)
            }

            // Chart
            if candles.isEmpty {
                ZStack {
                    RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md).fill(RouaTheme.Colors.surface)
                    VStack(spacing: RouaTheme.Spacing.sm) {
                        ProgressView().tint(RouaTheme.Colors.accent)
                        Text("جاري تحميل بيانات الشارت...").font(.system(size: 12)).foregroundStyle(RouaTheme.Colors.textSecondary)
                    }
                }.frame(height: 300)
            } else {
                CandlestickChartWrapper(
                    candles: candles,
                    liveCandle: liveCandle
                )
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: RouaTheme.CornerRadius.md))
            }
        }
    }
}

// MARK: - UIViewRepresentable wrapper for LightweightCharts
struct CandlestickChartWrapper: UIViewRepresentable {
    let candles: [CandleData]
    let liveCandle: CandleData?

    func makeCoordinator() -> ChartCoordinator {
        ChartCoordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        context.coordinator.setupChart(in: container)
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.updateData(candles: candles, liveCandle: liveCandle)
    }
}

// MARK: - Chart Coordinator
class ChartCoordinator {
    private var chart: LightweightCharts?
    private var candlestickSeries: CandlestickSeries?
    private var volumeSeries: HistogramSeries?

    func setupChart(in container: UIView) {
        let options = ChartOptions(
            layout: LayoutOptions(
                background: .solid(color: "#0A0E17"),   // RouaTheme.Colors.background
                textColor: "#94A3B8"                     // textSecondary
            ),
            rightPriceScale: VisiblePriceScaleOptions(
                borderColor: "#1E293B"                    // border
            ),
            timeScale: TimeScaleOptions(
                borderColor: "#1E293B",
                timeVisible: true,
                secondsVisible: false
            ),
            crosshair: CrosshairOptions(mode: .normal),
            grid: GridOptions(
                verticalLines: GridLineOptions(color: "rgba(30, 41, 59, 0.5)"),
                horizontalLines: GridLineOptions(color: "rgba(30, 41, 59, 0.5)")
            )
        )

        let chart = LightweightCharts(options: options)
        container.addSubview(chart)
        chart.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chart.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            chart.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            chart.topAnchor.constraint(equalTo: container.topAnchor),
            chart.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        // Candlestick series with Roua colors
        let candleOptions = CandlestickSeriesOptions(
            upColor: "#00C853",          // profit green
            downColor: "#FF1744",        // loss red
            borderUpColor: "#00C853",
            borderDownColor: "#FF1744",
            wickUpColor: "#00C853",
            wickDownColor: "#FF1744"
        )
        let series = chart.addCandlestickSeries(options: candleOptions)
        self.candlestickSeries = series

        // Volume histogram — use separate price scale for volume overlay
        let volumeOptions = HistogramSeriesOptions(
            priceLineVisible: false,
            color: "rgba(59, 130, 246, 0.3)"  // accent with alpha
        )
        let volSeries = chart.addHistogramSeries(options: volumeOptions)
        self.volumeSeries = volSeries

        self.chart = chart
    }

    /// Convert timestamp (seconds) to LightweightCharts Time
    private func timeFromTimestamp(_ timestamp: TimeInterval) -> Time {
        // If timestamp is in milliseconds (from Binance WS), convert to seconds
        let seconds = timestamp > 1_000_000_000_000 ? timestamp / 1000.0 : timestamp
        return .utc(timestamp: seconds)
    }

    func updateData(candles: [CandleData], liveCandle: CandleData?) {
        var candlestickData: [CandlestickData] = []
        var volumeData: [HistogramData] = []

        for candle in candles {
            let time = timeFromTimestamp(candle.resolvedTime)
            let item = CandlestickData(
                time: time,
                open: candle.open,
                high: candle.high,
                low: candle.low,
                close: candle.close
            )
            candlestickData.append(item)

            let volItem = HistogramData(
                time: time,
                value: candle.volume,
                color: candle.close >= candle.open ? "rgba(0, 200, 83, 0.2)" : "rgba(255, 23, 68, 0.2)"
            )
            volumeData.append(volItem)
        }

        // Add live candle if available
        if let live = liveCandle {
            let time = timeFromTimestamp(live.resolvedTime)
            let liveItem = CandlestickData(
                time: time,
                open: live.open,
                high: live.high,
                low: live.low,
                close: live.close
            )
            candlestickData.append(liveItem)
        }

        candlestickSeries?.setData(data: candlestickData)
        volumeSeries?.setData(data: volumeData)

        chart?.timeScale().fitContent()
    }
}
