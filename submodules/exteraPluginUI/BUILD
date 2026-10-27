load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_bundle")
load("//build-system/bazel-utils:plist_fragment.bzl", "plist_fragment")

plist_fragment(
    name = "ExteraPluginUIBundleInfoPlist",
    extension = "plist",
    template =
    """
    <key>CFBundleIdentifier</key>
    <string>extera.ExteraPluginUI</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleName</key>
    <string>ExteraPluginUIBundle</string>
    """
)

apple_resource_bundle(
    name = "ExteraPluginUIBundle",
    infoplists = [
        ":ExteraPluginUIBundleInfoPlist",
    ],
    resources = glob([
        "Resources/**/*.lproj/*",
    ]),
)

swift_library(
    name = "ExteraPluginUI",
    module_name = "ExteraPluginUI",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    data = [
        ":ExteraPluginUIBundle",
    ],
    deps = [
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
    ],
    visibility = [
        "//visibility:public",
    ],
)
