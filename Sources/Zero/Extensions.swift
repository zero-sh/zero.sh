import Foundation
import Path
import SwiftCLI

/// XDG Base Directory namespace.
/// https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
struct XDGBaseDirectory {
    var configHome: Path {
        guard let input = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"] else {
            return Path.home.join(".config")
        }
        return Path(input) ?? Path.cwd.join(input)
    }

    fileprivate init() {}
}

extension Path {
    static let XDG: XDGBaseDirectory = .init()
}

extension Path: ConvertibleFromString {
    /// Instantiate path from the given string. Unless given an absolute path,
    /// assumes a relative path within current working directory.
    public init?(input: String) {
        self = Path(input) ?? Path.cwd.join(input)
    }
}

extension Workspace: ConvertibleFromString {
    /// Instantiate a workspace from the given string with "." as a delimiter,
    /// e.g. "home.laptop" will become `["home", "laptop"]`.
    public init?(input: String) {
        self = input.split(separator: ".").map(String.init)
    }
}
