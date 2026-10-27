import Foundation

public enum ExteraResultFormatter {
    private static let groupingFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 8
        return formatter
    }()

    private static let plainFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.maximumFractionDigits = 8
        return formatter
    }()

    private static func trimmedPlain(_ value: Double) -> String {
        let rounded = (value * 1e12).rounded() / 1e12
        if rounded.rounded() == rounded && abs(rounded) < 1e15 {
            let integerFormatter = NumberFormatter()
            integerFormatter.numberStyle = .none
            integerFormatter.maximumFractionDigits = 0
            return integerFormatter.string(from: NSNumber(value: rounded)) ?? String(Int64(rounded))
        }
        let rendered = plainFormatter.string(from: NSNumber(value: rounded)) ?? "\(rounded)"
        return rendered.replacingOccurrences(of: ",", with: ".")
    }

    public static func format(_ value: Double, groupDigits: Bool) -> String {
        guard value.isFinite else {
            return ""
        }
        if groupDigits {
            return groupingFormatter.string(from: NSNumber(value: value)) ?? trimmedPlain(value)
        }
        return trimmedPlain(value)
    }

    public static func compactPrice(_ value: Double) -> String {
        switch abs(value) {
        case 1_000_000_000...:
            return String(format: "%.0f", value / 1_000_000_000.0) + "B"
        case 1_000_000...:
            return String(format: "%.1f", value / 1_000_000.0) + "M"
        case 100_000...:
            return String(format: "%.0f", value / 1_000.0) + "K"
        default:
            if abs(value) >= 1000.0 {
                return String(format: "%.0f", value)
            }
            if abs(value) >= 10.0 {
                return String(format: "%.2f", value)
            }
            if abs(value) >= 1.0 {
                return String(format: "%.3f", value)
            }
            return String(format: "%.4f", value)
        }
    }
}
