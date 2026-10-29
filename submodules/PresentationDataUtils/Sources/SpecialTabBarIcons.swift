import Foundation
import UIKit

public func useSpecialTabBarIcons() -> Bool {
    return (Date(timeIntervalSince1970: 1608800400)...Date(timeIntervalSince1970: 1609545600)).contains(Date())
}

/// extera «другие иконки вкладок»: системный глиф вместо стандартного ассета.
/// Возвращает nil, если символ недоступен в этой версии ОС — вызывающий код тогда держит стандартную иконку.
public func exteraAlternateTabIcon(_ systemName: String) -> UIImage? {
    return UIImage(systemName: systemName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 24.0))?.withRenderingMode(.alwaysTemplate)
}
