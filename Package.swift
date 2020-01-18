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
    .package(url: "https://github.com/mxcl/Path.swift.git", .upToNextMajor(from: "0.16.3")),
    .package(url: "https://github.com/onevcat/Rainbow.git", .upToNextMajor(from: "3.1.5")),
    .package(url: "https://github.com/msanders/SwiftCLI.git", .branch("6.0.1-zero.sh")),
]
package.targets = [
    .target(name: "Zero", dependencies: ["Path", "Rainbow", "SwiftCLI"]),
    .target(name: "main", dependencies: ["Zero"]),
    .target(name: "generate-completions", dependencies: ["Zero"]),
]
