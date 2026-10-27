import Foundation
import UIKit
import TelegramPresentationData

final class ExteraBrandingBundleAnchor: NSObject {
}

private let stringsBundle: Bundle? = Bundle(for: ExteraBrandingBundleAnchor.self).path(forResource: "ExteraBrandingBundle", ofType: "bundle").flatMap { Bundle(path: $0) }

public func exteraBrandingString(_ key: String) -> String {
    return stringsBundle?.localizedString(forKey: key, value: key, table: nil) ?? key
}

public func exteraBrandingAppIconTitle(identifier: String) -> String {
    return exteraBrandingString("extera_AppIcon.\(identifier)")
}

public let exteraBrandingVersionSuffix = "extera"

public let exteraAlternateAppIcons: [PresentationAppIcon] = [
    PresentationAppIcon(name: "ExteraGoogle", imageName: "ExteraGoogle"),
    PresentationAppIcon(name: "ExteraOsu", imageName: "ExteraOsu"),
    PresentationAppIcon(name: "ExteraAurora", imageName: "ExteraAurora"),
    PresentationAppIcon(name: "ExteraAmethyst", imageName: "ExteraAmethyst"),
    PresentationAppIcon(name: "ExteraSunset", imageName: "ExteraSunset"),
    PresentationAppIcon(name: "ExteraHuman", imageName: "ExteraHuman"),
    PresentationAppIcon(name: "ExteraJellyfish", imageName: "ExteraJellyfish"),
    PresentationAppIcon(name: "ExteraSpace", imageName: "ExteraSpace"),
    PresentationAppIcon(name: "ExteraCyberpunk", imageName: "ExteraCyberpunk"),
    PresentationAppIcon(name: "ExteraNasa", imageName: "ExteraNasa"),
    PresentationAppIcon(name: "ExteraXp", imageName: "ExteraXp"),
    PresentationAppIcon(name: "ExteraPsychosis", imageName: "ExteraPsychosis"),
    PresentationAppIcon(name: "ExteraFish", imageName: "ExteraFish"),
    PresentationAppIcon(name: "ExteraIceAge", imageName: "ExteraIceAge"),
    PresentationAppIcon(name: "ExteraNyanCat", imageName: "ExteraNyanCat"),
    PresentationAppIcon(name: "ExteraFlappy", imageName: "ExteraFlappy"),
    PresentationAppIcon(name: "ExteraInvincible", imageName: "ExteraInvincible"),
    PresentationAppIcon(name: "ExteraSponge", imageName: "ExteraSponge"),
    PresentationAppIcon(name: "ExteraHamster", imageName: "ExteraHamster"),
    PresentationAppIcon(name: "ExteraFrog", imageName: "ExteraFrog"),
    PresentationAppIcon(name: "ExteraGuitar", imageName: "ExteraGuitar"),
    PresentationAppIcon(name: "ExteraCandy", imageName: "ExteraCandy"),
    PresentationAppIcon(name: "ExteraAvatar", imageName: "ExteraAvatar"),
    PresentationAppIcon(name: "ExteraEchpochmak", imageName: "ExteraEchpochmak"),
    PresentationAppIcon(name: "ExteraMole", imageName: "ExteraMole"),
    PresentationAppIcon(name: "ExteraEditor", imageName: "ExteraEditor"),
    PresentationAppIcon(name: "ExteraOrbit", imageName: "ExteraOrbit"),
    PresentationAppIcon(name: "ExteraMonet", imageName: "ExteraMonet"),
    PresentationAppIcon(name: "ExteraWinter", imageName: "ExteraWinter"),
    PresentationAppIcon(name: "ExteraSus", imageName: "ExteraSus"),
]

public enum ExteraBrandingLinks {
    public static let website = URL(string: "https://exteragram.app")!
    public static let sourceCode = URL(string: "https://github.com/exteraGram/exteraGram")!
    public static let officialChannel = URL(string: "https://t.me/exteraReleases")!
    public static let support = URL(string: "https://t.me/exteraOwner")!
}
