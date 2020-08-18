import Foundation
import SwiftCLI

public enum Zero {
    public static let cli: CLI = {
        let cli = CLI(
            name: "zero",
            version: "0.5.0",
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
        cli.globalOptions.append(verboseFlag)
        cli.helpMessageGenerator = ZeroHelpMessageGenerator()
        return cli
    }()
}

struct ZeroHelpMessageGenerator: HelpMessageGenerator {
    func writeErrorLine(for message: String, to out: WritableStream) {
        out <<< TTY.errorMessage(message)
    }
}

extension Command {
    var verbose: Bool {
        verboseFlag.value
    }
}

private let verboseFlag = Flag(
    "-v",
    "--verbose",
    description: "Enable verbose output for zero and subcommands."
)
