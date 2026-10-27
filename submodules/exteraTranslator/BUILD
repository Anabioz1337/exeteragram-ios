load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_bundle")
load("//build-system/bazel-utils:plist_fragment.bzl", "plist_fragment")

plist_fragment(
    name = "ExteraTranslatorBundleInfoPlist",
    extension = "plist",
    template =
    """
    <key>CFBundleIdentifier</key>
    <string>extera.ExteraTranslator</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleName</key>
    <string>ExteraTranslatorBundle</string>
    """
)

apple_resource_bundle(
    name = "ExteraTranslatorBundle",
    infoplists = [
        ":ExteraTranslatorBundleInfoPlist",
    ],
    resources = glob([
        "Resources/**/*.lproj/*",
    ]),
)

swift_library(
    name = "ExteraTranslator",
    module_name = "ExteraTranslator",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    data = [
        ":ExteraTranslatorBundle",
    ],
    deps = [
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/TelegramCore:TelegramCore",
    ],
    visibility = [
        "//visibility:public",
    ],
)
