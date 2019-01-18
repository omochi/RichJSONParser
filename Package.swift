// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RichJSONParser",
    products: [
        .library(name: "RichJSONParser", targets: ["RichJSONParser"]),
    ],
    dependencies: [
        .package(url: "https://github.com/omochi/OrderedDictionary.git", .upToNextMajor(from: "1.0.0")),
    ],
    targets: [
        .target( name: "RichJSONParser", dependencies: ["OrderedDictionary"]),
        .testTarget(name: "RichJSONParserTests", dependencies: ["RichJSONParser"]),
    ]
)
