import Foundation
import SwiftCLI

final class UpdateCommand: Command {
    let name: String = "update"
    let shortDescription: String = "Check for system and application updates"

    func execute() throws {
        try ZeroRunner.update(verbose: self.verbose)
    }
}

extension ZeroRunner {
    /// Check and apply all system and application updates via
    /// `softwareupdate`, `brew` and `mas`.
    static func update(verbose: Bool) throws {
        try systemUpdate(verbose: verbose)
        try brewUpdate(verbose: verbose)
        try appStoreUpdate()
    }
}

private extension ZeroRunner {
    /// Check and apply system updates via `softwareupdate` CLI.
    static func systemUpdate(verbose: Bool) throws {
        Term.stdout <<< TTY.progressMessage("Checking for system updates...")

        let verboseFlags: [String] = verbose ? ["--verbose"] : []
        let result = try Task.capture(
            "/usr/sbin/softwareupdate",
            arguments: ["--list"] + verboseFlags,
            tee: Term.stdout,

            // `NSUnbufferedIO` forces output of `softwareupdate` to be
            // unbuffered so it's printed as it's being run, rather than when
            // it completes.
            //
            // See https://stackoverflow.com/a/59557241/12638282.
            env: ProcessInfo.processInfo.environment.merging([
                "NSUnbufferedIO": "YES",
            ], uniquingKeysWith: { _, new in new })
        )

        let updateNeedle = "Software Update found the following new or updated software:"
        guard result.stdout.contains(updateNeedle) else {
            Term.stdout <<< "No updates found."
            return
        }

        let prompt = "Install system updates? This will restart your machine if necessary."
        if Input.confirm(prompt: prompt, defaultValue: true) {
            let exitStatus = try Task.spawn("/usr/bin/sudo", arguments: [
                "--",
                "/usr/sbin/softwareupdate",
                "--install",
                "--all",
                "--restart",
            ] + verboseFlags)
            guard exitStatus == 0 else {
                throw SpawnError(exitStatus: exitStatus)
            }
            exit(0)
        } else {
            Term.stderr <<< "Aborting."
            exit(1)
        }
    }

    /// Check and apply brew and brew cask updates.
    static func brewUpdate(verbose: Bool) throws {
        let verboseFlags: [String] = verbose ? ["--verbose"] : []
        try Task.run("brew", arguments: ["update"] + verboseFlags)
        try Task.run("brew", arguments: ["upgrade"] + verboseFlags)
        try Task.run("brew", arguments: ["cask", "upgrade"] + verboseFlags)
    }

    /// Check and apply app store updates.
    static func appStoreUpdate() throws {
        Term.stdout <<< TTY.progressMessage("Upgrading apps from the App Store...")
        try Task.run("mas", "upgrade")
    }
}
