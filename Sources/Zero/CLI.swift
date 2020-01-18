import Foundation
import SwiftCLI

public enum Zero {
    public static let cli: CLI = .init(
        name: "zero",
        version: "0.2.0-beta",
        description: "Radically simple personal bootstrapping tool for macOS.",
        commands: [
          SetupCommand(),
          UpdateCommand(),
          BundleCommand(),
          ApplyDefaultsCommand(),
          ApplySymlinksCommand(),
          RunScriptsCommand(),
        ]
    )
}
