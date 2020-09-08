import Foundation
import SwiftCLI

final class UpdateCommand: Command {
    let name: String = "update"
    let shortDescription: String = "Check for system and application updates"

    @Flag("-a", "--all", description: "Update all casks, including those with auto-update enabled.")
    var updateAll: Bool

    func execute() throws {
        try ZeroRunner.update(verbose: self.verbose, updateAll: self.updateAll)
    }
}

extension ZeroRunner {
    /// Check and apply all system and application updates via
    /// `softwareupdate`, `brew` and `mas`.
    static func update(verbose: Bool, updateAll: Bool) throws {
        try systemUpdate(verbose: verbose)
        try brewUpdate(verbose: verbose, updateAll: updateAll)
        try appStoreUpdate()
    }
}

private extension ZeroRunner {
    /// Check and apply system updates via `softwareupdate` CLI.
    static func systemUpdate(verbose: Bool) throws {
        Term.stdout <<< TTY.progressMessage("Checking for system updates...")

        let verboseFlags: [String] = verbose ? ["--verbose"] : []
        let result = try ZeroRunner.captureTask(
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
            Term.stdout <<< "No new software available."
            return
        }

        let prompt = "Install system updates? This will restart your machine if necessary."
        if Input.confirm(prompt: prompt, defaultValue: true) {
            try ZeroRunner.spawnTask("/usr/bin/sudo", arguments: [
                "--",
                "/usr/sbin/softwareupdate",
                "--install",
                "--all",
                "--restart",
            ] + verboseFlags)
            exit(0)
        } else {
            Term.stderr <<< "Aborting."
            exit(1)
        }
    }

    /// Check and apply brew and brew cask updates.
    static func brewUpdate(verbose: Bool, updateAll: Bool) throws {
        let verboseFlags: [String] = verbose ? ["--verbose"] : []
        try ZeroRunner.runTask("brew", arguments: ["update"] + verboseFlags)
        try ZeroRunner.spawnTask("brew", arguments: ["upgrade"] + verboseFlags)

        if updateAll {
            try ZeroRunner.spawnShell(
                "brew cask outdated --greedy --verbose | " +
                    "grep -Fv '(latest)' | " +
                    "awk '{print $1}' | " +
                    "xargs brew cask reinstall"
            )
        }
    }

    /// Check and apply app store updates.
    static func appStoreUpdate() throws {
        Term.stdout <<< TTY.progressMessage("Upgrading apps from the App Store...")
        try ZeroRunner.runTask("mas", "upgrade")
    }
}
