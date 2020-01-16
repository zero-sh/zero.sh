import Foundation
import SwiftCLI

let cli = CLI(
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
cli.goAndExit()
