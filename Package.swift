// swift-tools-version:5.1
import PackageDescription

let package = Package(name: "Zero")
package.platforms = [
    .macOS(.v10_13),
]
package.products = [
    .executable(name: "zero", targets: ["main"]),
]
package.dependencies = [
    .package(url: "https://github.com/mxcl/Path.swift.git", .upToNextMajor(from: "1.2.0")),
    .package(url: "https://github.com/onevcat/Rainbow.git", .upToNextMajor(from: "3.2.0")),
    .package(url: "https://github.com/jakeheis/SwiftCLI.git", .upToNextMajor(from: "6.0.2")),
]
package.targets = [
    .target(name: "Zero", dependencies: ["Path", "Rainbow", "SwiftCLI"]),
    .target(name: "main", dependencies: ["Zero"]),
    .target(name: "generate-completions", dependencies: ["Zero"]),
]
