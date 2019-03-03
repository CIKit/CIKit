// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CIKit",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "CIKit",
            targets: ["CIKit"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/ProcedureKit/ProcedureKit", .branch("development"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "CIKit",
            dependencies: [
                "ProcedureKit",
                "ProcedureKitMac",
                "ProcedureKitNetwork"
            ]),
        .testTarget(
            name: "CIKitTests",
            dependencies: [
                "CIKit",
                "ProcedureKit",
                "ProcedureKitMac",
                "ProcedureKitNetwork",
                "TestingProcedureKit"

            ]),
    ]
)
