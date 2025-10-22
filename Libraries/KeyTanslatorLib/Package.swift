// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SangamKeyTranslator",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .watchOS(.v8),
        .tvOS(.v15)
    ],
    products: [
        .library(
            name: "SangamKeyTranslator",
            targets: ["SangamKeyTranslator"]
        ),
    ],
    targets: [
        .target(
            name: "CAnjalKeyTranslator",
            path: ".",
            sources: [
                "src/tamil/AnjalKeyMap.c",
                "src/tamil/KeyTranslatorTamil.c",
                "src/indic/IndicNotesIMEngine.c",
                "src/indic/IndicDevanagariKeymap.c",
                "src/indic/IndicMalayalamKeymap.c",
                "src/indic/IndicKannadaKeymap.c",
                "src/indic/IndicTamilAnjalKeymap.c",
                "src/indic/IndicTeluguKeymap.c",
                "src/indic/IndicGurmukhiKeymap.c"
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include"),
                .define("TARGET_OS_MAC", .when(platforms: [.macOS])),
                .define("TARGET_OS_IOS", .when(platforms: [.iOS])),
            ]
        ),
        .target(
            name: "SangamKeyTranslator",
            dependencies: ["CAnjalKeyTranslator"],
            path: "swift/Sources/SangamKeyTranslator"
        ),
    ]
)
