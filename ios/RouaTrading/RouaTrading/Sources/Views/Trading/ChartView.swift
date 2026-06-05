// =============================================================================
// ChartView.swift — Roua Trading · LightweightCharts v4 Wrapper
// =============================================================================
// UIViewRepresentable wrapper for TradingView LightweightCharts library.
// Renders a candlestick series with volume histogram overlay.
// Dark theme, crosshair, time/price scales, and live candle updates.
//
// Up candle: #00C853 (green)  Down candle: #FF1744 (red)
// Volume bars: same colors at reduced opacity.
//
// Supports:
//   - Full setData on initial load
//   - Incremental update() for live candles (avoids full redraw)
//   - Horizontal line price annotations (for entry/SL/TP levels)
//   - fitContent on initial load only (not on every update)
//
// IMPORTANT: This file is written for LightweightChartsIOS v4.0.0 API.
// Key v4 differences from v3:
//   - ChartDelegate protocol (not ChartViewDelegate)
//   - MouseEventParams for crosshair (not CrosshairMovedParameters)
//   - HandleScrollOptions is an enum with .options(Options) case
//   - handleScale uses TogglableOptions<HandleScaleOptions>
//   - GridOptions uses verticalLines/horizontalLines (not vertLines/horizLines)
//   - CrosshairLineOptions width is LineWidth enum (not Int)
//   - PriceScaleApi.applyOptions takes PriceScaleOptions
//   - priceScale() returns non-optional PriceScaleApi
//   - Swift init args must match exact parameter order from the library
//   - Struct arrays use != (not !== which only works with classes)
// =============================================================================

import SwiftUI
import LightweightCharts

// MARK: - Volume Data Point

/// Data point for the volume histogram overlay on the chart.
struct VolumeDataPoint: Equatable {
    let time: Int
    let value: Double
    let color: Color

    static func == (lhs: VolumeDataPoint, rhs: VolumeDataPoint) -> Bool {
        lhs.time == rhs.time && lhs.value == rhs.value
    }
}

// MARK: - Chart View

/// SwiftUI wrapper for TradingView LightweightCharts v4.
///
/// Usage:
/// ```swift
/// ChartView(
///     candles: viewModel.candles,
///     volumeData: viewModel.volumeData,
///     liveCandle: viewModel.liveCandle,
///     onCrosshairMove: { time, price in ... }
/// )
/// ```
struct ChartView: UIViewRepresentable {

    /// Historical candle data for the candlestick series.
    let candles: [CandleData]

    /// Volume data for the histogram overlay.
    /// Derived from candles if not provided explicitly.
    var volumeData: [VolumeDataPoint] = []

    /// Optional live (partial) candle from WebSocket — updated in real time.
    var liveCandle: CandleData? = nil

    /// Callback when the user moves the crosshair.
    let onCrosshairMove: ((TimeInterval, Double?) -> Void)?

    /// Optional price level annotations (entry, SL, TP).
    var priceLineAnnotations: [PriceLineAnnotation] = []

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> ChartViewWrapper {
        let wrapper = ChartViewWrapper()
        wrapper.setupChart(delegate: context.coordinator)
        return wrapper
    }

    func updateUIView(_ wrapper: ChartViewWrapper, context: Context) {
        // Update candle data (use != for structs, !== only works with classes)
        if candles != context.coordinator.previousCandles {
            wrapper.setCandleData(candles)
            context.coordinator.previousCandles = candles
            context.coordinator.hasInitializedData = true
        }

        // Update volume data
        if volumeData != context.coordinator.previousVolumeData {
            wrapper.setVolumeData(volumeData)
            context.coordinator.previousVolumeData = volumeData
        }

        // Update live candle (incremental)
        if let liveCandle = liveCandle {
            wrapper.updateLiveCandle(liveCandle)
        }

        // Update price line annotations
        if priceLineAnnotations != context.coordinator.previousAnnotations {
            wrapper.setPriceLineAnnotations(priceLineAnnotations)
            context.coordinator.previousAnnotations = priceLineAnnotations
        }
    }

    func makeCoordinator() -> ChartCoordinator {
        ChartCoordinator(onCrosshairMove: onCrosshairMove)
    }
}

// MARK: - Price Line Annotation

/// A horizontal price line drawn on the chart (e.g., entry, stop-loss, take-profit).
struct PriceLineAnnotation: Identifiable, Equatable {
    let id: String
    let price: Double
    let color: Color
    let label: String
    let lineStyle: LineStyle = .dashed

    /// Convert to LightweightCharts PriceLineOptions.
    /// v4: lineWidth is LineWidth enum, color is ChartColor (not String).
    func toPriceLineOptions() -> PriceLineOptions {
        PriceLineOptions(
            price: price,
            color: ChartColor(rawValue: color.toHex()),
            lineWidth: .one,
            lineStyle: lineStyle,
            axisLabelVisible: true,
            title: label
        )
    }
}

// MARK: - Chart Coordinator

/// Coordinator for crosshair move callbacks.
/// v4: Uses ChartDelegate protocol (not ChartViewDelegate).
/// v4: Uses MouseEventParams (not CrosshairMovedParameters).
class ChartCoordinator: NSObject, ChartDelegate {

    let onCrosshairMove: ((TimeInterval, Double?) -> Void)?

    var previousCandles: [CandleData]?
    var previousVolumeData: [VolumeDataPoint]
    var previousAnnotations: [PriceLineAnnotation] = []
    var hasInitializedData: Bool = false

    init(onCrosshairMove: ((TimeInterval, Double?) -> Void)?) {
        self.onCrosshairMove = onCrosshairMove
        self.previousVolumeData = []
    }

    // v4: ChartDelegate requires both didCrosshairMove and didClick
    func didCrosshairMove(onChart chart: ChartApi, parameters: MouseEventParams) {
        guard let eventTime = parameters.time else { return }
        switch eventTime {
        case .utc(let timestamp):
            onCrosshairMove?(timestamp, nil)
        default:
            break
        }
    }

    func didClick(onChart chart: ChartApi, parameters: MouseEventParams) {
        // No action needed on click
    }
}

// MARK: - Chart View Wrapper

/// UIKit wrapper that owns the LightweightCharts instance and its series.
///
/// Manages:
/// - Chart widget creation with dark theme
/// - CandlestickSeries (main price data)
/// - HistogramSeries (volume overlay at bottom)
/// - Incremental updates via `update()` for live candles
/// - Full `setData()` for historical data
/// - `fitContent()` on initial load only
class ChartViewWrapper: UIView {

    // MARK: - Properties

    private var chart: LightweightCharts?
    private var candlestickSeries: CandlestickSeries?
    private var volumeSeries: HistogramSeries?
    private var priceLineSources: [PriceLine] = []
    private var hasFittedContent: Bool = false

    // MARK: - Setup

    /// Creates the chart widget with dark theme and configures all series.
    /// v4: setupChart takes ChartDelegate (not ChartViewDelegate).
    func setupChart(delegate: ChartDelegate?) {
        backgroundColor = UIColor.clear

        // ChartOptions init parameter order: width, height, watermark, layout,
        // leftPriceScale, rightPriceScale, overlayPriceScales, timeScale,
        // crosshair, grid, localization, handleScroll, handleScale, ...
        let options = ChartOptions(
            layout: LayoutOptions(
                background: .solid(color: ChartColor(rawValue: "rgba(0, 0, 0, 0)")),
                textColor: "rgba(255, 255, 255, 0.4)",
                fontSize: 11,
                fontFamily: "SF Mono"
            ),
            rightPriceScale: PriceScaleOptions(
                scaleMargins: PriceScaleMargins(
                    top: 0.1,
                    bottom: 0.25
                ),
                borderColor: "rgba(255, 255, 255, 0.08)",
                entireTextOnly: true
            ),
            timeScale: TimeScaleOptions(
                rightOffset: 5,
                barSpacing: 8,
                minBarSpacing: 2,
                fixLeftEdge: false,
                fixRightEdge: false,
                borderColor: "rgba(255, 255, 255, 0.08)",
                timeVisible: true,
                secondsVisible: false
            ),
            crosshair: CrosshairOptions(
                mode: .normal,
                vertLine: CrosshairLineOptions(
                    color: "rgba(108, 92, 231, 0.5)",
                    width: .one,
                    style: .dashed,
                    labelBackgroundColor: "rgba(108, 92, 231, 0.9)"
                ),
                horzLine: CrosshairLineOptions(
                    color: "rgba(108, 92, 231, 0.5)",
                    width: .one,
                    style: .dashed,
                    labelBackgroundColor: "rgba(108, 92, 231, 0.9)"
                )
            ),
            grid: GridOptions(
                verticalLines: GridLineOptions(
                    color: "rgba(255, 255, 255, 0.03)"
                ),
                horizontalLines: GridLineOptions(
                    color: "rgba(255, 255, 255, 0.03)"
                )
            ),
            localization: LocalizationOptions(
                dateFormat: "yyyy-MM-dd"
            ),
            handleScroll: .options(HandleScrollOptions.Options(
                mouseWheel: true,
                pressedMouseMove: true,
                horzTouchDrag: true,
                vertTouchDrag: false
            )),
            handleScale: .options(HandleScaleOptions(
                mouseWheel: true,
                pinch: true,
                axisPressedMouseMove: .options(AxisPressedMouseMoveOptions(
                    time: true,
                    price: true
                ))
            ))
        )

        let chartView = LightweightCharts(options: options)
        chartView.delegate = delegate

        // ── Candlestick Series ──
        // CandlestickSeriesOptions init order: lastValueVisible, title, priceScaleId,
        // visible, priceLineVisible, ..., upColor, downColor, ..., wickUpColor, wickDownColor
        let candleOptions = CandlestickSeriesOptions(
            upColor: "#00C853",
            downColor: "#FF1744",
            borderUpColor: "#00C853",
            borderDownColor: "#FF1744",
            wickUpColor: "#00C853",
            wickDownColor: "#FF1744"
        )
        let candleSeries = chartView.addCandlestickSeries(options: candleOptions)
        self.candlestickSeries = candleSeries

        // ── Volume Histogram Series ──
        // HistogramSeriesOptions init order: lastValueVisible, title, priceScaleId,
        // visible, priceLineVisible, ..., priceFormat, ..., color, base
        let volumeOptions = HistogramSeriesOptions(
            lastValueVisible: false,
            priceScaleId: "overlay",
            priceFormat: .builtIn(BuiltInPriceFormat(type: .volume, precision: nil, minMove: nil))
        )
        let volumeSeriesView = chartView.addHistogramSeries(options: volumeOptions)

        // Configure volume price scale (bottom 20%)
        // v4: priceScale() returns non-optional PriceScaleApi
        // v4: applyOptions takes PriceScaleOptions (not OverlayPriceScaleOptions)
        chartView.priceScale(
            priceScaleId: "overlay"
        ).applyOptions(options: PriceScaleOptions(
            scaleMargins: PriceScaleMargins(
                top: 0.8,
                bottom: 0.0
            )
        ))

        self.volumeSeries = volumeSeriesView
        self.chart = chartView

        // Layout
        addSubview(chartView)
        chartView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chartView.topAnchor.constraint(equalTo: topAnchor),
            chartView.leadingAnchor.constraint(equalTo: leadingAnchor),
            chartView.trailingAnchor.constraint(equalTo: trailingAnchor),
            chartView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Data Methods

    /// Sets the full historical candle data. Called on initial load or timeframe change.
    /// v4: Time.utc(timestamp:) expects Double, CandleData.time is Int → cast required.
    func setCandleData(_ candles: [CandleData]) {
        guard let series = candlestickSeries else { return }

        let data = candles.map { candle -> CandlestickData in
            CandlestickData(
                time: .utc(timestamp: Double(candle.time)),
                open: candle.open,
                high: candle.high,
                low: candle.low,
                close: candle.close
            )
        }

        series.setData(data: data)

        // Fit content only on initial load
        if !hasFittedContent {
            chart?.timeScale().fitContent()
            hasFittedContent = true
        }
    }

    /// Sets the full volume histogram data.
    /// v4: HistogramData.color is ChartColor? (not String), created via ChartColor(rawValue:).
    func setVolumeData(_ volumeData: [VolumeDataPoint]) {
        guard let series = volumeSeries else { return }

        let data = volumeData.map { point -> HistogramData in
            HistogramData(
                time: .utc(timestamp: Double(point.time)),
                value: point.value,
                color: ChartColor(rawValue: point.color.toVolumeHex())
            )
        }

        series.setData(data: data)
    }

    /// Updates the live (current) candle incrementally instead of full setData.
    /// v4: Time.utc(timestamp:) expects Double, color uses ChartColor(rawValue:).
    func updateLiveCandle(_ candle: CandleData) {
        guard let series = candlestickSeries else { return }

        let data = CandlestickData(
            time: .utc(timestamp: Double(candle.time)),
            open: candle.open,
            high: candle.high,
            low: candle.low,
            close: candle.close
        )

        series.update(bar: data)

        // Also update volume
        let volumePoint = HistogramData(
            time: .utc(timestamp: Double(candle.time)),
            value: candle.volume,
            color: ChartColor(rawValue: candle.isBullish ? Color.rouaProfit.toVolumeHex() : Color.rouaLoss.toVolumeHex())
        )
        volumeSeries?.update(bar: volumePoint)
    }

    /// Adds or updates horizontal price line annotations.
    /// v4: Uses series.createPriceLine(options:) and series.removePriceLine(line:).
    func setPriceLineAnnotations(_ annotations: [PriceLineAnnotation]) {
        guard let series = candlestickSeries else { return }

        // Remove existing price lines
        for source in priceLineSources {
            series.removePriceLine(line: source)
        }
        priceLineSources.removeAll()

        // Add new price lines
        for annotation in annotations {
            let options = annotation.toPriceLineOptions()
            let source = series.createPriceLine(options: options)
            priceLineSources.append(source)
        }
    }

    /// Resets the fitted content flag (e.g., on symbol change).
    func resetFitState() {
        hasFittedContent = false
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        chart?.frame = bounds
    }
}

// MARK: - Color Extensions for Chart

extension Color {

    /// Converts a SwiftUI Color to a hex string suitable for LightweightCharts.
    /// Falls back to a reasonable default if the conversion fails.
    func toHex() -> String {
        // Use known colors directly
        if self == .rouaProfit {
            return "#00C853"
        } else if self == .rouaLoss {
            return "#FF1744"
        } else if self == .rouaPrimary {
            return "#6C5CE7"
        } else if self == .rouaWarning {
            return "#FFB800"
        } else if self == .rouaNeutral {
            return "#78909C"
        }

        // Fallback: use UIColor description
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        let ri = Int(r * 255)
        let gi = Int(g * 255)
        let bi = Int(b * 255)

        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }

    /// Converts a Color to a volume bar hex with ~40% opacity for subtlety.
    func toVolumeHex() -> String {
        let hex = toHex()
        // Add alpha component for volume (40% opacity → 66 in hex)
        return hex + "66"
    }
}

// =============================================================================
// MARK: - Preview
// =============================================================================

#Preview("ChartView") {
    let mockCandles: [CandleData] = {
        var result: [CandleData] = []
        let now = Int(Date().timeIntervalSince1970)
        var price = 67500.0
        for i in 0..<100 {
            let time = now - (100 - i) * 3600
            let change = Double.random(in: -200...200)
            let open = price
            let close = open + change
            let high = max(open, close) + abs(Double.random(in: 0...100))
            let low = min(open, close) - abs(Double.random(in: 0...100))
            result.append(CandleData(time: time, open: open, high: high, low: low, close: close, volume: Double.random(in: 50...5000)))
            price = close
        }
        return result
    }()

    ChartView(
        candles: mockCandles,
        volumeData: mockCandles.map { VolumeDataPoint(time: $0.time, value: $0.volume, color: $0.isBullish ? .rouaProfit : .rouaLoss) },
        liveCandle: nil,
        onCrosshairMove: nil
    )
    .frame(height: 300)
    .background(Color.rouaBackground)
}
