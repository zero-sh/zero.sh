import Foundation
import Path

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
