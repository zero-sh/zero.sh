import Foundation
import SwiftCLI

extension Task {
    /// Run an executable synchronously and capture its output.
    ///
    /// - executable: Name or path of executable to run.
    /// - arguments: Arguments to pass to executable.
    /// - directory: Directory to run in (defaults to current working directory).
    /// - tee: Stream to redirect output as it's being written (analogous to
    ///        `tee` command). Defaults to nil.
    /// - env: Environment for the spawned process. Defaults to
    ///        `ProcessInfo.processInfo.environment`.
    ///
    /// - Returns: `CaptureResult` value containing body of standard output and
    ///            error.
    /// - Throws: `CaptureError` if command fails
    static func capture(
        _ executable: String,
        arguments: [String],
        directory: String? = nil,
        tee: WritableStream? = nil,
        env: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> CaptureResult {
        let stdoutCapture = CaptureStream()
        let stderrCapture = CaptureStream()
        let task = Task(
            executable: executable,
            arguments: arguments,
            directory: directory,
            stdout: tee.flatMap { stream in SplitStream(stream, stdoutCapture) } ?? stdoutCapture,
            stderr: stderrCapture
        )
        task.env = env

        let exitCode = task.runSync()
        let result = CaptureResult(stdout: stdoutCapture, stderr: stderrCapture)
        guard exitCode == 0 else {
            throw CaptureError(exitStatus: exitCode, captured: result)
        }
        return result
    }
}
