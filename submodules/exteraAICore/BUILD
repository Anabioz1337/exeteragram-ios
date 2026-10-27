load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "exteraAICore",
    module_name = "exteraAICore",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//submodules/AccountContext",
        "//submodules/Display",
        "//submodules/ItemListUI",
        "//submodules/ItemListPeerActionItem",
        "//submodules/PresentationDataUtils",
        "//submodules/SwiftSignalKit",
        "//submodules/TelegramPresentationData",
    ],
    visibility = [
        "//visibility:public",
    ],
)
