import Foundation
import Path
import SwiftCLI

final class BundleCommand: Command {
    let name: String = "bundle"
    let shortDescription: String = "Run brew bundle on a workspace"
    @Param var workspace: Workspace?
    @Key("-d", "--directory") var configDirectory: Path?
    
    @Flag("-r","--rm", description: "Remove bottles that are not in the Brewfile.")
    var removeNotPresent: Bool
    
    func execute() throws {
        let runner = try ZeroRunner(
            configDirectory: self.configDirectory,
            workspace: self.workspace ?? [],
            verbose: self.verbose,
            removeNotPresent: self.removeNotPresent
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
            let removeNotPresentFlags: [String] = self.removeNotPresent ? ["--cleanup", "--zap"] : []
            try Self.runTask("brew", arguments: ["bundle"] + verboseFlags + removeNotPresentFlags, at: directory)
        }
    }
}
