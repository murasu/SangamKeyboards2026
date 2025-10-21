// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "ContextAwareEditor",
    platforms: [
        .macOS(.v12),  // macOS Monterey
        .iOS(.v15)     // iOS 15
    ],
    products: [
        // Shared core library
        .library(
            name: "EditorCore",
            targets: ["EditorCore"]
        ),
        // Platform-specific UI library
        .library(
            name: "EditorUI",
            targets: ["EditorUI"]
        ),
    ],
    dependencies: [
        // Add your C library packages here
        // .package(path: "../CAnjalKeyTranslator"),
        // .package(path: "../PredictorWrapper"),
    ],
    targets: [
        // MARK: - Core Logic (Platform Agnostic)
        .target(
            name: "EditorCore",
            dependencies: [
                // "CAnjalKeyTranslator",
                // "PredictorWrapper",
            ],
            path: "Sources/EditorCore"
        ),
        
        // MARK: - UI Layer (Conditional Compilation)
        .target(
            name: "EditorUI",
            dependencies: ["EditorCore"],
            path: "Sources/EditorUI"
        ),
        
        // MARK: - macOS App Target
        .executableTarget(
            name: "EditorApp-macOS",
            dependencies: ["EditorUI"],
            path: "Sources/Apps/macOS",
            resources: [
                .process("Resources")
            ]
        ),
        
        // MARK: - iOS App Target (Phase 2)
        // .executableTarget(
        //     name: "EditorApp-iOS",
        //     dependencies: ["EditorUI"],
        //     path: "Sources/Apps/iOS"
        // ),
        
        // MARK: - Tests
        //.testTarget(
        //    name: "EditorCoreTests",
        //    dependencies: ["EditorCore"],
        //    path: "Tests/EditorCoreTests"
        //),
    ]
)
