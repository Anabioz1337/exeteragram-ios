load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_bundle")
load("//build-system/bazel-utils:plist_fragment.bzl", "plist_fragment")

plist_fragment(
    name = "ExteraAIBundleInfoPlist",
    extension = "plist",
    template =
    """
    <key>CFBundleIdentifier</key>
    <string>extera.ExteraAI</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleName</key>
    <string>ExteraAIBundle</string>
    """
)

apple_resource_bundle(
    name = "ExteraAIBundle",
    infoplists = [
        ":ExteraAIBundleInfoPlist",
    ],
    resources = glob([
        "Resources/**/*.lproj/*",
    ]),
)

swift_library(
    name = "exteraAICore",
    module_name = "exteraAICore",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    data = [
        ":ExteraAIBundle",
    ],
    deps = [
        "//submodules/AccountContext",
        "//submodules/Display",
        "//submodules/ExteraSpeech",
        "//submodules/ItemListUI",
        "//submodules/ItemListPeerActionItem",
        "//submodules/PresentationDataUtils",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/TelegramPresentationData",
        "//submodules/AlertUI:AlertUI",
    ],
    visibility = [
        "//visibility:public",
    ],
)
