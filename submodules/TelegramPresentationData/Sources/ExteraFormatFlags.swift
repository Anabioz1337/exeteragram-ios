import Foundation
import SwiftSignalKit

private let numericRoundingDisabledValue = Atomic(value: false)
private let timeWithSecondsValue = Atomic(value: false)

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
