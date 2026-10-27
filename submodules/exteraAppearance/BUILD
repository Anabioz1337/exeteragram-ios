load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_bundle")
load("//build-system/bazel-utils:plist_fragment.bzl", "plist_fragment")

plist_fragment(
    name = "ExteraAppearanceBundleInfoPlist",
    extension = "plist",
    template =
    """
    <key>CFBundleIdentifier</key>
    <string>extera.ExteraAppearance</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleName</key>
    <string>ExteraAppearanceBundle</string>
    """
)

apple_resource_bundle(
    name = "ExteraAppearanceBundle",
    infoplists = [
        ":ExteraAppearanceBundleInfoPlist",
    ],
    resources = glob([
        "Resources/**/*.lproj/*",
    ]),
)

swift_library(
    name = "exteraAppearance",
    module_name = "exteraAppearance",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    data = [
        ":ExteraAppearanceBundle",
    ],
    deps = [
        "//submodules/AsyncDisplayKit",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
    ],
    visibility = [
        "//visibility:public",
    ],
)
