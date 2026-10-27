import Foundation
import SwiftSignalKit
import Display
import PresentationDataUtils
import AccountContext

// Flags whose changes only take effect the next time the app launches (they are read
// once at startup) present this notice after being changed.
public func exteraPresentRestartRequired(sharedContext: SharedAccountContext) {
    let presentationData = sharedContext.currentPresentationData.with { $0 }
    let strings = exteraStrings(presentationData: presentationData)
    let alert = textAlertController(
        sharedContext: sharedContext,
        title: strings.restartRequired,
        text: strings.restartRequiredText,
        actions: [
            TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {})
        ]
    )
    sharedContext.presentGlobalController(alert, nil)
}
