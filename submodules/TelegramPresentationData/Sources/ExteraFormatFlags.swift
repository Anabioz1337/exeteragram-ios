import Foundation
import SwiftSignalKit

private let numericRoundingDisabledValue = Atomic(false)
private let timeWithSecondsValue = Atomic(false)

public func numericCountRoundingDisabled() -> Bool {
    return numericRoundingDisabledValue.with { $0 }
}

public func presentationTimeWithSeconds() -> Bool {
    return timeWithSecondsValue.with { $0 }
}

public func applyExteraFormatFlags(numericRoundingDisabled: Bool, timeWithSeconds: Bool) {
    let _ = numericRoundingDisabledValue.swap(numericRoundingDisabled)
    let _ = timeWithSecondsValue.swap(timeWithSeconds)
}
