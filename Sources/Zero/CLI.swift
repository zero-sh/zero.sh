import Foundation
import SwiftCLI

public enum Zero {
    public static let cli: CLI = {
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
        cli.helpMessageGenerator = ZeroHelpMessageGenerator()
        return cli
    }()
}

struct ZeroHelpMessageGenerator: HelpMessageGenerator {
    func writeErrorLine(for message: String, to out: WritableStream) {
        out <<< TTY.errorMessage(message)
    }
}
