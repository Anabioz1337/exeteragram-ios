load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "ExteraSpeechUI",
    module_name = "ExteraSpeechUI",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//submodules/AccountContext:AccountContext",
        "//submodules/Display:Display",
        "//submodules/Media/ConvertOpusToAAC:ConvertOpusToAAC",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/TelegramPresentationData:TelegramPresentationData",
        "//submodules/TelegramUIPreferences:TelegramUIPreferences",
        "//submodules/ExteraSpeech:ExteraSpeech",
    ],
    visibility = [
        "//visibility:public",
    ],
)
