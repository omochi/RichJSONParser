// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RichJSONParser",
    products: [
        .library(name: "RichJSONParser", targets: ["RichJSONParser"]),
    ],
    dependencies: [
    ],
    targets: [
        .target( name: "RichJSONParser", dependencies: []),
        .testTarget(name: "RichJSONParserTests", dependencies: ["RichJSONParser"]),
    ]
)
