// swift-tools-version: 5.9

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

for target in package.targets {
  target.swiftSettings = target.swiftSettings ?? []
  target.swiftSettings!.append(contentsOf: [
    .enableExperimentalFeature("StrictConcurrency")
  ])
}

#if !os(Windows)
  // DocC needs to be ported to Windows
  // https://github.com/thebrowsercompany/swift-build/issues/39
  package.dependencies.append(
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
  )
#endif
