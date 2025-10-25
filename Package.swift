// swift-tools-version:5.9

import Foundation
import PackageDescription

var globalSwiftSettings: [PackageDescription.SwiftSetting] = []
globalSwiftSettings.append(.unsafeFlags(["-Xfrontend", "-strict-concurrency=complete"]))

let FFIbinaryTarget: PackageDescription.Target = .binaryTarget(
    name: "automergeFFI",
    path: "./bin/automergeFFI.xcframework.zip"
)

let package = Package(
    name: "Automerge",
    platforms: [.iOS(.v13), .macOS(.v10_15), .visionOS(.v1)],
    products: [
        .library(name: "Automerge", targets: ["Automerge", "AutomergeUtilities"]),
    ],
    targets: [
        FFIbinaryTarget,
        .target(
            name: "AutomergeUniffi",
            dependencies: [
                // On Apple platforms, this links the core Rust library through XCFramework.
                // On other platforms (such as WASM), end users will need to build the library
                // themselves and link it through the "swift build -Xlinker path/to/libuniffi_automerge.a"
                // for example: cargo build --manifest-path rust/Cargo.toml --target wasm32-wasip1 --release
                .target(name: "automergeFFI", condition: .when(platforms: [
                    .iOS, .macOS, .macCatalyst, .tvOS, .watchOS, .visionOS,
                ])),
                // The dependency on _CAutomergeUniffi gives the WebAssembly linker a place to link in
                // the automergeFFI target when the XCFramework binary target isn't available.
                .target(name: "_CAutomergeUniffi", condition: .when(platforms: [.wasi, .linux, .windows])),
            ],
            path: "./AutomergeUniffi"
        ),
        .systemLibrary(name: "_CAutomergeUniffi"),
        .target(
            name: "Automerge",
            dependencies: ["AutomergeUniffi"],
            swiftSettings: globalSwiftSettings
        ),
        .target(
            name: "AutomergeUtilities",
            dependencies: ["Automerge"],
            swiftSettings: globalSwiftSettings
        ),
        .testTarget(
            name: "AutomergeTests",
            dependencies: ["Automerge", "AutomergeUtilities"],
            exclude: ["Fixtures"]
        ),
    ]
)
