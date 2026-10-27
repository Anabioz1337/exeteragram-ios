load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_bundle")
load("//build-system/bazel-utils:plist_fragment.bzl", "plist_fragment")

plist_fragment(
    name = "ExteraProfileBundleInfoPlist",
    extension = "plist",
    template =
    """
    <key>CFBundleIdentifier</key>
    <string>extera.ExteraProfile</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleName</key>
    <string>ExteraProfileBundle</string>
    """
)

apple_resource_bundle(
    name = "ExteraProfileBundle",
    infoplists = [
        ":ExteraProfileBundleInfoPlist",
    ],
    resources = glob([
        "Resources/**/*.lproj/*",
    ]),
)

swift_library(
    name = "ExteraProfile",
    module_name = "ExteraProfile",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    data = [
        ":ExteraProfileBundle",
    ],
    deps = [
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/Postbox:Postbox",
        "//submodules/TelegramCore:TelegramCore",
    ],
    visibility = [
        "//visibility:public",
    ],
)
