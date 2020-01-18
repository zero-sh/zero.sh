import Foundation
import Path
import SwiftCLI

final class RunScriptsCommand: Command {
    let name: String = "run-scripts"
    let shortDescription: String = "Run before & after scripts for a workplace"
    @Param var workspace: Workspace?
    @Key("-d", "--directory") var configDirectory: Path?

    func execute() throws {
        let runner = try ZeroRunner(configDirectory: configDirectory, workspace: workspace ?? [])
        try runner.workspaceDirectories.forEach { directory in
            try runner.runScripts(directory: directory, suffix: .before)
            try runner.runScripts(directory: directory, suffix: .after)
        }
    }
}

enum ZeroScriptSuffix: String {
    case before
    case after
}

extension ZeroRunner {
    /// Run scripts in the given directory, contained in `run/{suffix}`.
    func runScripts(directory: Path, suffix: ZeroScriptSuffix) throws {
        Term.stdout <<< TTY.progressMessage("Running scripts in run/\(suffix.rawValue)")
        let scriptDirectory = directory.join("run").join(suffix.rawValue)
        let scripts: [Path] = !scriptDirectory.exists ? [] : try scriptDirectory.ls().paths.sorted()
        guard !scripts.isEmpty else {
            Term.stdout <<< "No scripts found."
            return
        }

        for script in scripts {
            try runTask("./\(script.basename())", at: scriptDirectory)
        }
    }
}
