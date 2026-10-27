load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load(
    "@build_bazel_rules_apple//apple:resources.bzl",
    "apple_resource_bundle",
)
load("//build-system/bazel-utils:plist_fragment.bzl",
    "plist_fragment",
)

filegroup(
    name = "ExteraPreferencesUIResources",
    srcs = glob([
        "Resources/**/*",
    ], exclude = ["Resources/**/.*"]),
    visibility = ["//visibility:public"],
)

plist_fragment(
    name = "ExteraPreferencesUIBundleInfoPlist",
    extension = "plist",
    template =
    """
    <key>CFBundleIdentifier</key>
    <string>org.telegram.exteraPreferencesUI</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleName</key>
    <string>exteraPreferencesUI</string>
    """
)

apple_resource_bundle(
    name = "ExteraPreferencesUIBundle",
    infoplists = [
        ":ExteraPreferencesUIBundleInfoPlist",
    ],
    resources = [
        ":ExteraPreferencesUIResources",
    ],
    visibility = ["//visibility:public"],
)

swift_library(
    name = "exteraPreferencesUI",
    module_name = "exteraPreferencesUI",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    data = [
        ":ExteraPreferencesUIBundle",
    ],
    deps = [
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/AsyncDisplayKit:AsyncDisplayKit",
        "//submodules/Display:Display",
        "//submodules/LegacyComponents:LegacyComponents",
        "//submodules/LegacyMediaPickerUI:LegacyMediaPickerUI",
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/TelegramPresentationData:TelegramPresentationData",
        "//submodules/ItemListUI:ItemListUI",
        "//submodules/AccountContext:AccountContext",
        "//submodules/AlertUI:AlertUI",
        "//submodules/UndoUI:UndoUI",
        "//submodules/PresentationDataUtils:PresentationDataUtils",
        "//submodules/exteraSettingsCore:exteraSettingsCore",
    ],
    visibility = [
        "//visibility:public",
    ],
)
