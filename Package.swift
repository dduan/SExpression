// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "SExpression",
    products: [.library(name: "SExpression", targets: ["SExpression"])],
    targets: [
        .target(name: "SExpression", dependencies: []),
        .testTarget(name: "SExpressionTests", dependencies: ["SExpression"]),
    ]
)
