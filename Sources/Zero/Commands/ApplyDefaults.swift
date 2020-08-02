import Foundation
import Path
import SwiftCLI

final class ApplyDefaultsCommand: Command {
    let name: String = "apply-defaults"
    let shortDescription: String = "Apply user defaults for a workplace"
    @Param var workspace: Workspace?
    @Key("-d", "--directory") var configDirectory: Path?

    func execute() throws {
        let runner = try ZeroRunner(
            configDirectory: self.configDirectory,
            workspace: self.workspace ?? [],
            verbose: self.verbose
        )
        try runner.workspaceDirectories.forEach(runner.applyDefaults)
    }
}

extension ZeroRunner {
    /// Runs `apply-user-defaults` for the defaults file in the given directory.
    func applyDefaults(directory: Path) throws {
        guard directory.join("defaults.yaml").exists else {
            return
        }

        Term.stdout <<< TTY.progressMessage("Applying defaults...")

        // Close any open System Preferences panes, to prevent them from
        // overriding settings we’re about to change.
        try Self.runTask("osascript", "-e", "quit app \"System Preferences\"")

        let verboseFlags: [String] = self.verbose ? ["--verbose"] : []
        try Self.runTask(
            "apply-user-defaults",
            arguments: ["./defaults.yaml"] + verboseFlags,
            at: directory
        )
    }
}
