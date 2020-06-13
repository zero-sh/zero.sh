import CoreFoundation
import Darwin
import Foundation
import Path
import SwiftCLI

struct SpawnError: ProcessError {
    let exitStatus: Int32
    let message: String?
}

extension SpawnError {
    init(exitStatus: Int32) {
        self = .init(exitStatus: exitStatus, message: "")
    }
}

/// Run executable via `posix_spawn`. Workaround for issue where `Process`
/// doesn't accept input for sudo commands.
///
/// See:
///   - https://github.com/zero-sh/zero.sh/issues/10
///   - https://forums.swift.org/t/34357/3
///   - https://gist.github.com/dduan/d4e967f3fc2801d3736b726cd34446bc
extension Task {
    static func spawn(_ executable: String, arguments: [String] = []) throws -> Int32 {
        guard let absolutePath = Path(executable), absolutePath.exists else {
            throw SpawnError(exitStatus: 127, message: "\(executable): No such file or directory")
        }
        guard absolutePath.isExecutable else {
            throw SpawnError(exitStatus: 126, message: "\(executable): Permission denied")
        }

        var exitStatus: Int32 = 0
        try withCStrings(arguments) { cArgs in
            let envs = ProcessInfo().environment.map { key, value in "\(key)=\(value)" }
            try withCStrings(envs) { cEnvs in
                var pid: pid_t = 0
                let spawnStatus = posix_spawn(&pid, executable, nil, nil, cArgs, cEnvs)
                if spawnStatus != 0, errno == ENOENT {
                    throw SpawnError(
                        exitStatus: 125,
                        message: "The file '\(executable)' is marked as an executable but could " +
                            "not be read by the operating system."
                    )
                }

                guard spawnStatus == 0, waitpid(pid, &exitStatus, 0) != -1 else {
                    throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: [:])
                }
            }
        }

        return WIFSIGNALED(exitStatus) ? WTERMSIG(exitStatus) : WEXITSTATUS(exitStatus)
    }
}

private func withCStrings(
    _ strings: [String],
    scoped: ([UnsafeMutablePointer<CChar>?]) throws -> Void
) rethrows {
    let cStrings = strings.map { strdup($0) }
    try scoped(cStrings + [nil])
    cStrings.forEach { free($0) }
}

private func _WSTATUS(_ status: Int32) -> Int32 {
    status & 0x7F
}

private func WIFSIGNALED(_ status: Int32) -> Bool {
    (_WSTATUS(status) != 0) && (_WSTATUS(status) != 0x7F)
}

private func WEXITSTATUS(_ status: Int32) -> Int32 {
    (status >> 8) & 0xFF
}

private func WTERMSIG(_ status: Int32) -> Int32 {
    status & 0x7F
}
