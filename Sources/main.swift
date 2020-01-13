import Foundation
import Path // mxcl/Path.swift == 1.0.0-alpha.3
import Rainbow // onevcat/Rainbow ~> 3.0.0

// MARK: - CLI

final class CLI {
    enum UsageError: LocalizedError {
        case invalidFlag(_ flag: String)
        case invalidArgumentCount
        case invalidWorkspaceFormat
        case missingWorkspaceParameter
        case workspaceIsParent
        case invalidWorkspaceDirectory(Path)

        public var errorDescription: String? {
            switch self {
            case let .invalidFlag(flag):
                return "Unknown flag: \(flag)."
            case .invalidArgumentCount:
                return "Invalid number of arguments."
            case .invalidWorkspaceFormat:
                return "Invalid workspace name."
            case .missingWorkspaceParameter:
                return "Missing required parameter 'workspace'."
            case .workspaceIsParent:
                return "Cannot setup parent of a workspace."
            case let .invalidWorkspaceDirectory(directoryPath):
                return "Not a directory: \(directoryPath)."
            }
        }
    }

    enum AppError: LocalizedError {
        case reachability
        case abortedXcodeInstall
        case invalidScriptDirectory(_ directoryPath: Path)
        case shell(
            arguments: [String],
            terminationStatus: Int32
        )

        public var errorDescription: String? {
            switch self {
            case .reachability:
                return "You are not connected to the Internet. Please connect to continue."
            case .abortedXcodeInstall:
                return "Aborted Xcode Command Line Tools installation."
            case let .invalidScriptDirectory(directoryPath):
                return "Not a directory: \(directoryPath.abbreviatingWithTilde)."
            case let .shell(arguments, status):
                return "Command \(arguments) returned non-zero exit status \(status)."
            }
        }
    }

    let configPath: Path
    let workspaces: [String]
    init(arguments: [String]) throws {
        var parsedArguments: ArraySlice<String> = arguments[1...]
        let idx = parsedArguments.partition { !$0.hasPrefix("-") }
        let remainingArgs: ArraySlice<String> = parsedArguments[idx ..< parsedArguments.endIndex]
        guard remainingArgs.count == 1 || remainingArgs.count == 2 else {
            throw CLI.UsageError.invalidArgumentCount
        }
        if let flag = parsedArguments[parsedArguments.startIndex ..< idx].first {
            throw CLI.UsageError.invalidFlag(flag)
        }

        let firstArg = remainingArgs[remainingArgs.startIndex]
        configPath = Path(firstArg) ?? Path.cwd.join(firstArg)
        workspaces = remainingArgs.count == 1 ? [] : remainingArgs[remainingArgs.startIndex + 1]
            .split(separator: ".")
            .map(String.init) ?? []
    }

    private func run(
        command _: String = "/usr/bin/env",
        _ args: String...,
        at currentWorkingDirectory: Path? = nil
    ) throws {
        putcommand(args.joined(separator: " "))

        let status = try runCommand(args, at: currentWorkingDirectory ?? configPath)
        guard status == 0 else {
            throw CLI.AppError.shell(arguments: args, terminationStatus: status)
        }
    }

    private func pipe(
        _ args: String...,
        printOutput: Bool = false,
        environment: [String: String] = [:]
    ) throws -> String {
        putcommand(args.joined(separator: " "))

        let output = try commandOutput(
            args,
            environment: environment,
            printOutput: printOutput
        )
        guard output.terminationStatus == 0 else {
            throw CLI.AppError.shell(
                arguments: args,
                terminationStatus: output.terminationStatus
            )
        }

        return String(data: output.outputData, encoding: .utf8) ?? ""
    }

    func validateWorkspace() throws {
        if workspaces.isEmpty, configPath.join("workspaces").exists {
            throw CLI.UsageError.missingWorkspaceParameter
        }

        var cwd: Path = configPath
        let lastIndex = workspaces.endIndex - 1
        for (idx, workspace) in workspaces.enumerated() {
            let workspaceDirectory = cwd.join("workspaces").join(workspace)
            if !workspaceDirectory.isDirectory {
                throw CLI.UsageError.invalidWorkspaceDirectory(workspaceDirectory)
            }

            cwd = workspaceDirectory
            if idx == lastIndex, cwd.join("workspaces").isDirectory {
                throw CLI.UsageError.workspaceIsParent
            }
        }
    }

    func update() throws {
        try checkReachability()
        try systemUpdate()
        try brewUpdate()
        try appStoreUpdate()
    }

    func setupWorkspaces() throws {
        guard !workspaces.isEmpty, workspaces != ["."] else {
            try setup(directory: configPath)
            return
        }

        var cwd: Path = configPath
        let lastIndex = workspaces.endIndex - 1
        for (idx, workspace) in workspaces.enumerated() {
            if idx == lastIndex {
                try setup(directory: cwd)
            } else {
                let workspaceDirectory = cwd.join("workspaces").join(workspace)
                let sharedDirectory = workspaceDirectory.join("shared")
                if sharedDirectory.isDirectory {
                    try setup(directory: sharedDirectory)
                }

                cwd = workspaceDirectory
            }
        }
    }

    private func checkReachability() throws {
        guard try runCommand(["curl", "www.apple.com"]) == 0 else {
            throw CLI.AppError.reachability
        }
    }

    private func systemUpdate() throws {
        putprogress("Checking for system updates...")

        // `NSUnbufferedIO` forces output of `softwareupdate` to be unbuffered so
        // it's printed as it's being run, rather than when it completes.
        //
        // See https://stackoverflow.com/a/59557241
        let updateOutput = try pipe("softwareupdate", "--list", printOutput: true, environment: [
            "NSUnbufferedIO": "YES",
        ])

        let updateNeedle = "Software Update found the following new or updated software:"
        if updateOutput.contains(updateNeedle) {
            let prompt = "Install system updates? This will restart your machine if necessary."
            if TTY.confirm(prompt) {
                try run("sudo", "softwareupdate", "--install", "--all", "--restart")
                exit(0)
            } else {
                fputs("Aborting.\n", stderr)
                exit(1)
            }
        }
    }

    private func brewUpdate() throws {
        try run("brew", "update")
        try run("brew", "upgrade")
        try run("brew", "cask", "upgrade")
    }

    private func appStoreUpdate() throws {
        putprogress("Upgrading apps from the App Store...")

        if Path.which("mas") == nil {
            try run("brew", "install", "mas")
        }
        try run("mas", "upgrade")
    }

    private func setup(directory: Path) throws {
        if directory != configPath {
            putbold("Setting up \(directory.relative(to: configPath)).")
        }
        try brewBundle(directory: directory)
        try runScripts(directory: directory, suffix: "before")
        try applyDefaults(directory: directory)
        try applySymlinks(directory: directory)
        try runScripts(directory: directory, suffix: "after")
    }

    private func brewBundle(directory: Path) throws {
        if !directory.join("Brewfile").exists {
            print("No Brewfile found.")
        } else {
            try run("brew", "bundle", "--no-lock")
        }
    }

    private func runScripts(directory: Path, suffix: String) throws {
        putprogress("Running scripts in run/\(suffix)")
        let scriptDirectory = directory.join("run").join(suffix)
        let scripts: [Path] = !scriptDirectory.exists ? [] : scriptDirectory.ls().sorted()
        guard !scripts.isEmpty else {
            print("No scripts found.")
            return
        }

        for script in scripts {
            try run(command: "/bin/sh", "./\(script.basename())", at: scriptDirectory)
        }
    }

    private func applyDefaults(directory: Path) throws {
        guard directory.join("defaults.yml").exists else {
            return
        }

        putprogress("Applying defaults...")
        if Path.which("apply-user-defaults") == nil {
            try run("brew", "install", "zero-sh/tap/apply-user-defaults")
        }

        // Close any open System Preferences panes, to prevent them from
        // overriding settings we’re about to change.
        try run("osascript", "-e", "'quit app \"System Preferences\"'")

        try run("apply-user-defaults", "./defaults", at: directory)
    }

    private func applySymlinks(directory: Path) throws {
        let symlinkDirectory = directory.join("symlinks")
        let symlinks: [Path] = !symlinkDirectory.exists ? [] : symlinkDirectory.ls()
        putprogress("Applying symlinks...")

        if Path.which("stow") == nil {
            try run("brew", "install", "stow")
        }

        for link in symlinks {
            try run(
                "stow",
                link.basename(),
                "--target",
                Path.home.string,
                "--dotfiles",
                "--verbose=1",
                at: symlinkDirectory
            )
        }

        puts("Applied symlinks.")
    }
}

// MARK: - Shell

struct ShellOutput {
    let terminationStatus: Int32
    let outputData: Data
    let errorData: Data
}

func commandOutput(
    command launchPath: String = "/usr/bin/env",
    _ args: [String],
    at currentDirectoryPath: Path? = nil,
    environment: [String: String] = [:],
    printOutput: Bool = false,
    printErrorOutput: Bool = true
) throws -> ShellOutput {
    let task = Process()
    let outputPipe = Pipe()
    let errorPipe = Pipe()
    task.arguments = args
    task.launchPath = launchPath
    task.standardError = errorPipe
    task.standardOutput = outputPipe
    if !environment.isEmpty {
        task.environment = ProcessInfo.processInfo.environment.merging(environment) { _, new in
            new
        }
    }
    if let url = currentDirectoryPath?.url {
        task.currentDirectoryURL = url
    }

    // Avoid race condition when printing to stdout at the same time as the
    // piped process.
    let outputQueue = DispatchQueue(label: "zero-sh-shell-output-queue")
    var outputData: Data = .init()
    var errorData: Data = .init()

    outputPipe.fileHandleForReading.readabilityHandler = { pipe in
        let data = pipe.availableData
        outputData.append(data)

        if printOutput {
            outputQueue.async {
                FileHandle.standardOutput.write(data)
            }
        }
    }

    errorPipe.fileHandleForReading.readabilityHandler = { pipe in
        let data = pipe.availableData
        errorData.append(data)

        if printErrorOutput {
            outputQueue.async {
                FileHandle.standardOutput.write(data)
            }
        }
    }

    try task.run()
    task.waitUntilExit()

    outputPipe.fileHandleForReading.readabilityHandler = nil
    errorPipe.fileHandleForReading.readabilityHandler = nil

    // Ensure all output has been processed before returning.
    return try outputQueue.sync {
        return .init(
            terminationStatus: task.terminationStatus,
            outputData: outputData,
            errorData: errorData
        )
    }
}

@discardableResult
func runCommand(
    command launchPath: String = "/usr/bin/env",
    _ args: [String],
    at currentDirectoryPath: Path? = nil
) throws -> Int32 {
    let task = Process()
    task.arguments = args
    task.launchPath = launchPath
    if let url = currentDirectoryPath?.url {
        task.currentDirectoryURL = url
    }
    try task.run()
    task.waitUntilExit()
    return task.terminationStatus
}

// MARK: - TTY

enum TTY {
    static func confirm(_ prompt: String, defaultValue: Bool = false) -> Bool {
        let suffix: String = defaultValue ? "[Y/n]" : "[y/N]"
        repeat {
            fputs(String(format: "%@ %@ ", prompt, suffix), stdout)
            guard let line = readLine() else {
                print()
                fputs("Aborting.\n", stderr)
                exit(1)
            }

            switch line.lowercased() {
            case "yes", "y":
                return true
            case "no", "n":
                return false
            case "":
                return defaultValue
            default:
                puterr("Invalid input.")
                continue
            }
        } while true
    }
}

func puterr(_ msg: String) {
    fputs(
        String(format: "%@: %@\n", "Error".applyingCodes(Color.red), msg),
        stderr
    )
}

func puts(_ msg: String) {
    print(String(
        format: "%@ %@",
        "Success!".applyingCodes(Color.green, Style.underline),
        msg
    ))
}

func putprogress(_ msg: String) {
    print(String(
        format: "%@ %@",
        "==>".applyingCodes(Color.blue, Style.bold),
        msg.applyingCodes(Style.bold)
    ))
}

func putcommand(_ msg: String) {
    print(String(format: "%@ %@", "==>".bold.yellow, msg))
}

func putbold(_ msg: String) {
    print(msg.applyingCodes(Color.yellow, Style.bold))
}

// MARK: - Extensions

extension Path {
    var abbreviatingWithTilde: String {
        string.replacingOccurrences(
            of: Path.home.string,
            with: "~",
            options: .anchored,
            range: nil
        )
    }

    static func which(_ cmd: String) -> Path? {
        PATH.first { prefix in
            let path = prefix.join(cmd)
            return path.isExecutable
        }
    }

    private static var PATH: [Path] {
        guard let PATH = ProcessInfo.processInfo.environment["PATH"] else {
            return []
        }
        return PATH.split(separator: ":").map { entry in
            entry.first == "/" ? Path.root.join(entry) : Path.cwd.join(entry)
        }
    }
}

// MARK: -

func main(_ cli: CLI) throws {
    try cli.validateWorkspace()
    try cli.update()
    try cli.setupWorkspaces()
}

do {
    try main(try CLI(arguments: CommandLine.arguments))
} catch let error as CLI.UsageError {
    puterr("\(error.localizedDescription)")
    exit(2)
} catch {
    if let error = error as? CLI.AppError, case let .shell(_, statusCode) = error {
        puterr("\(error.localizedDescription)")
        exit(statusCode)
    }

    let error = error as NSError
    let statusCode: Int = {
        if error.domain == NSPOSIXErrorDomain {
            return error.code
        } else if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError,
            underlyingError.domain == NSPOSIXErrorDomain {
            return underlyingError.code
        } else {
            return 1
        }
    }()

    puterr("\(error.localizedDescription)")
    exit(Int32(statusCode))
}
