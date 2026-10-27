load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "ExteraSearchToolkit",
    module_name = "ExteraSearchToolkit",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//submodules/TelegramUIPreferences:TelegramUIPreferences",
    ],
    visibility = [
        "//visibility:public",
    ],
)
