import UIKit

public enum ExteraInlineResultsUI {
    public static let panelHeight: CGFloat = 38.0
    public static let pillStackHeight: CGFloat = 34.0

    public static var weatherPageUrl: URL {
        return URL(string: "https://open-meteo.com")!
    }

    public static func cryptoPageUrl(coinId: String) -> URL {
        return URL(string: "https://www.coingecko.com/en/coins/\(coinId)")!
    }
}
