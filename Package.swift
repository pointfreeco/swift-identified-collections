// swift-tools-version:5.6

import PackageDescription

let package = Package(
  name: "swift-identified-collections",
  products: [
    .library(
      name: "IdentifiedCollections",
      targets: ["IdentifiedCollections"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-collections", from: "1.0.2"),
    .package(url: "https://github.com/apple/swift-collections-benchmark", from: "0.0.2"),
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "IdentifiedCollections",
      dependencies: [
        .product(name: "OrderedCollections", package: "swift-collections")
      ]
    ),
    .testTarget(
      name: "IdentifiedCollectionsTests",
      dependencies: ["IdentifiedCollections"]
    ),
    .executableTarget(
      name: "swift-identified-collections-benchmark",
      dependencies: [
        "IdentifiedCollections",
        .product(name: "CollectionsBenchmark", package: "swift-collections-benchmark"),
      ]
    ),
  ]
)
