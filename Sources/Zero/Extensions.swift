import Path
import SwiftCLI

extension Array where Element == Entry {
    var paths: [Path] {
        map { $0.path }
    }
}

extension Path: ConvertibleFromString {
    public init?(input: String) {
        self = Path(input) ?? Path.cwd.join(input)
    }
}

extension Workspace: ConvertibleFromString {
    public init?(input: String) {
        self = input.split(separator: ".").map(String.init)
    }
}
