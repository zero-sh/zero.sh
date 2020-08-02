import Foundation
import Path
import SwiftCLI

final class BundleCommand: Command {
    let name: String = "bundle"
    let shortDescription: String = "Run brew bundle on a workspace"
    @Param var workspace: Workspace?
    @Key("-d", "--directory") var configDirectory: Path?

    func execute() throws {
        let runner = try ZeroRunner(
            configDirectory: self.configDirectory,
            workspace: self.workspace ?? [],
            verbose: self.verbose
        )
        try runner.workspaceDirectories.forEach(runner.bundle)
    }
}

extension ZeroRunner {
    /// Run `brew bundle` in the given directory, if Brewfile exists.
    func bundle(directory: Path) throws {
        if !directory.join("Brewfile").exists {
            Term.stdout <<< "No Brewfile found."
        } else {
            let verboseFlags: [String] = self.verbose ? ["--verbose"] : []
            try Self.runTask("brew", arguments: ["bundle"] + verboseFlags, at: directory)
        }
    }
}
