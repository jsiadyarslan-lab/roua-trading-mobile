import SwiftUI
import UIKit

// MARK: - Color Extensions

extension Color {
    /// Creates a `Color` from a 6-character hex string (e.g., "FF5733").
    ///
    /// - Parameter hex: A 6-character hex string, optionally prefixed with "#".
    /// - Parameter opacity: An optional opacity value (0.0–1.0). Defaults to 1.0.
    init(hex: String, opacity: Double = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        // Handle 8-char hex (includes alpha)
        var alpha: Double = opacity
        if hexSanitized.count == 8 {
            let alphaHex = String(hexSanitized.suffix(2))
            alpha = Double(UInt8(alphaHex, radix: 16) ?? 255) / 255.0
            hexSanitized = String(hexSanitized.prefix(6))
        }

        guard hexSanitized.count == 6 else {
            self = .clear
            return
        }

        var rgbValue: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgbValue)

        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, opacity: alpha)
    }

    /// Creates a `Color` from individual RGB values (0–255).
    init(r: Int, g: Int, b: Int, opacity: Double = 1.0) {
        self.init(
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: opacity
        )
    }

    /// Returns a lighter version of the color.
    func lighter(by amount: Double = 0.2) -> Color {
        UIColor(self).lighter(by: amount).toColor()
    }

    /// Returns a darker version of the color.
    func darker(by amount: Double = 0.2) -> Color {
        UIColor(self).darker(by: amount).toColor()
    }
}

// MARK: - UIColor Extensions

extension UIColor {
    /// Returns a lighter version of the color.
    func lighter(by amount: Double = 0.2) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(
            red: min(r + amount, 1.0),
            green: min(g + amount, 1.0),
            blue: min(b + amount, 1.0),
            alpha: a
        )
    }

    /// Returns a darker version of the color.
    func darker(by amount: Double = 0.2) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(
            red: max(r - amount, 0.0),
            green: max(g - amount, 0.0),
            blue: max(b - amount, 0.0),
            alpha: a
        )
    }

    /// Converts a `UIColor` to a SwiftUI `Color`.
    func toColor() -> Color {
        Color(self)
    }
}

// MARK: - Double Extensions

extension Double {
    /// Formats the value as a currency string.
    ///
    /// - Parameter currencyCode: ISO 4217 currency code (default: "USD").
    /// - Returns: A formatted string (e.g., "$1,234.56").
    func asCurrency(currencyCode: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? String(format: "%.2f", self)
    }

    /// Formats the value as a compact currency (e.g., "$1.2K", "$3.4M").
    func asCompactCurrency(currencyCode: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1

        switch abs(self) {
        case 1_000_000_000...:
            return formatter.string(from: NSNumber(value: self / 1_000_000_000))! + "B"
        case 1_000_000...:
            return formatter.string(from: NSNumber(value: self / 1_000_000))! + "M"
        case 1_000...:
            return formatter.string(from: NSNumber(value: self / 1_000))! + "K"
        default:
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            return formatter.string(from: NSNumber(value: self)) ?? String(format: "%.2f", self)
        }
    }

    /// Formats the value as a percentage string.
    ///
    /// - Parameter decimals: Number of decimal places (default: 2).
    /// - Returns: A formatted string (e.g., "+5.23%").
    func asPercentage(decimals: Int = 2) -> String {
        let sign = self >= 0 ? "+" : ""
        return String(format: "\(sign)%.\(decimals)f%%", self)
    }

    /// Formats the value as a compact number (e.g., "1.2K", "3.4M").
    func asCompact() -> String {
        switch abs(self) {
        case 1_000_000_000...:
            return String(format: "%.1fB", self / 1_000_000_000)
        case 1_000_000...:
            return String(format: "%.1fM", self / 1_000_000)
        case 1_000...:
            return String(format: "%.1fK", self / 1_000)
        default:
            if self == floor(self) {
                return String(format: "%.0f", self)
            }
            return String(format: "%.2f", self)
        }
    }

    /// Formats as a price string with appropriate decimal places.
    ///
    /// Automatically determines precision based on the value magnitude:
    /// - < $1: 6 decimal places
    /// - < $10: 4 decimal places
    /// - < $1000: 2 decimal places
    /// - >= $1000: 2 decimal places with comma separator
    func asPrice() -> String {
        switch abs(self) {
        case 0:
            return "0.00"
        case ..<1:
            return String(format: "%.6f", self)
        case ..<10:
            return String(format: "%.4f", self)
        case ..<1000:
            return String(format: "%.2f", self)
        default:
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            return formatter.string(from: NSNumber(value: self)) ?? String(format: "%.2f", self)
        }
    }

    /// Clamps the value within the given range.
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Date Extensions

extension Date {
    /// A shared ISO 8601 formatter with fractional seconds.
    private static let iso8601Full: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// A shared ISO 8601 formatter without fractional seconds.
    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// Parses an ISO 8601 date string, trying with and without fractional seconds.
    static func fromISO8601(_ string: String) -> Date? {
        iso8601Full.date(from: string) ?? iso8601.date(from: string)
    }

    /// Formats the date as a short time string (e.g., "2:30 PM").
    var shortTimeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// Formats the date as a short date string (e.g., "1/15/25").
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// Formats the date as a medium date + short time (e.g., "Jan 15, 2025 at 2:30 PM").
    var mediumDateTimeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// Returns a relative time string (e.g., "2m ago", "5h ago", "Yesterday").
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Whether the date is today.
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Whether the date is yesterday.
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// The start of the day.
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// The end of the day.
    var endOfDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-1)
    }
}

// MARK: - String Extensions

extension String {
    /// Whether the string is not empty (convenience for `!isEmpty`).
    var isNotEmpty: Bool { !isEmpty }

    /// Returns a localized version of the string using the default table.
    var localized: String {
        NSLocalizedString(self, comment: self)
    }

    /// Returns a localized version with a custom table and bundle.
    func localized(in table: String, bundle: Bundle = .main) -> String {
        NSLocalizedString(self, tableName: table, bundle: bundle, comment: self)
    }

    /// Returns `true` if the string is a valid email format.
    var isValidEmail: Bool {
        let regex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return range(of: regex, options: .regularExpression) != nil
    }

    /// Converts a string to a `Double`, returning `nil` on failure.
    var doubleValue: Double? {
        Double(self)
    }

    /// Truncates the string to the given length, appending an ellipsis if needed.
    func truncated(to length: Int, addEllipsis: Bool = true) -> String {
        if count <= length { return self }
        let truncated = prefix(length)
        return addEllipsis ? truncated + "…" : String(truncated)
    }

    /// Strips HTML tags from the string.
    var strippingHTML: String {
        replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression,
            range: nil
        )
    }
}

// MARK: - View Extensions

extension View {
    /// Applies a conditional modifier.
    ///
    /// ```swift
    /// Text("Hello")
    ///     .if(isHighlighted) { view in
    ///         view.foregroundColor(.yellow)
    ///     }
    /// ```
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Applies a modifier based on an optional value.
    @ViewBuilder
    func `ifLet`<Value, Content: View>(_ value: Value?, transform: (Self, Value) -> Content) -> some View {
        if let value {
            transform(self, value)
        } else {
            self
        }
    }

    /// Applies a corner radius to specific corners.
    ///
    /// - Parameters:
    ///   - radius: The corner radius.
    ///   - corners: Which corners to round.
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }

    /// Hides the view conditionally.
    @ViewBuilder
    func hidden(_ isHidden: Bool) -> some View {
        if isHidden {
            self.hidden()
        } else {
            self
        }
    }

    /// Adds a horizontal padding and a maximum width for readability on iPad.
    func readablePadding() -> some View {
        padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 48 : 16)
    }
}

// MARK: - Rounded Corner Shape

/// A shape that rounds specific corners.
private struct RoundedCornerShape: Shape {
    let radius: CGFloat
    let corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let topLeft = corners.contains(.topLeft) ? radius : 0
        let topRight = corners.contains(.topRight) ? radius : 0
        let bottomLeft = corners.contains(.bottomLeft) ? radius : 0
        let bottomRight = corners.contains(.bottomRight) ? radius : 0

        let w = rect.size.width
        let h = rect.size.height

        path.move(to: CGPoint(x: topLeft, y: 0))
        path.addLine(to: CGPoint(x: w - topRight, y: 0))
        if topRight > 0 {
            path.addArc(
                center: CGPoint(x: w - topRight, y: topRight),
                radius: topRight,
                startAngle: .degrees(-90),
                endAngle: .degrees(0),
                clockwise: false
            )
        }
        path.addLine(to: CGPoint(x: w, y: h - bottomRight))
        if bottomRight > 0 {
            path.addArc(
                center: CGPoint(x: w - bottomRight, y: h - bottomRight),
                radius: bottomRight,
                startAngle: .degrees(0),
                endAngle: .degrees(90),
                clockwise: false
            )
        }
        path.addLine(to: CGPoint(x: bottomLeft, y: h))
        if bottomLeft > 0 {
            path.addArc(
                center: CGPoint(x: bottomLeft, y: h - bottomLeft),
                radius: bottomLeft,
                startAngle: .degrees(90),
                endAngle: .degrees(180),
                clockwise: false
            )
        }
        path.addLine(to: CGPoint(x: 0, y: topLeft))
        if topLeft > 0 {
            path.addArc(
                center: CGPoint(x: topLeft, y: topLeft),
                radius: topLeft,
                startAngle: .degrees(180),
                endAngle: .degrees(270),
                clockwise: false
            )
        }

        return path
    }
}

// MARK: - UIScreen Extensions

extension UIScreen {
    /// The safe area insets for the main screen.
    static var safeAreaInsets: UIEdgeInsets {
        let scene = UIApplication.shared.connectedScenes
            .first as? UIWindowScene
        return scene?.windows.first?.safeAreaInsets ?? .zero
    }

    /// The safe area top inset.
    static var safeAreaTop: CGFloat {
        safeAreaInsets.top
    }

    /// The safe area bottom inset.
    static var safeAreaBottom: CGFloat {
        safeAreaInsets.bottom
    }
}

// MARK: - Encodable Extensions

extension Encodable {
    /// Encodes the value to a JSON dictionary.
    var asDictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    /// Encodes the value to a JSON string.
    var asJSONString: String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - Collection Extensions

extension Collection {
    /// Returns the element at the given index if it exists, otherwise `nil`.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
