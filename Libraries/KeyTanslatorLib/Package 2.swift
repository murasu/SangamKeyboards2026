// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AnjalKeyTranslator",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .watchOS(.v6),
        .tvOS(.v13)
    ],
    products: [
        .library(
            name: "AnjalKeyTranslator",
            targets: ["AnjalKeyTranslator", "CAnjalKeyTranslator"]
        ),
    ],
    targets: [
        .target(
            name: "CAnjalKeyTranslator",
            path: "src",
            sources: [
                "tamil/AnjalKeyMap.c",
                "tamil/KeyTranslatorTamil.c",
                "indic/IndicNotesIMEngine.c",
                "indic/IndicDevanagariKeymap.c",
                "indic/IndicMalayalamKeymap.c",
                "indic/IndicKannadaKeymap.c",
                "indic/IndicTeluguKeymap.c",
                "indic/IndicGurmukhiKeymap.c",
                "indic/IndicTamilAnjalKeymap.c"
            ],
            publicHeadersPath: "../include"
        ),
        .target(
            name: "AnjalKeyTranslator",
            dependencies: ["CAnjalKeyTranslator"],
            path: "Sources/AnjalKeyTranslator"
        ),
        .testTarget(
            name: "AnjalKeyTranslatorTests",
            dependencies: ["AnjalKeyTranslator"],
            path: "Tests/AnjalKeyTranslatorTests"
        ),
    ]
)