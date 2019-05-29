// swift-tools-version:5.0

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
