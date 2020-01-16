import Foundation
import Rainbow
import SwiftCLI

enum TTY {
    static func error(_ msg: String) -> String {
        String(format: "%@: %@", "Error".applyingCodes(Color.red), msg)
    }

    static func success(_ msg: String) -> String {
        String(format: "%@ %@", "Success!".applyingCodes(Color.green, Style.underline), msg)
    }

    static func progress(_ msg: String) -> String {
        String(
            format: "%@ %@",
            "==>".applyingCodes(Color.blue, Style.bold),
            msg.applyingCodes(Style.bold)
        )
    }

    static func command(_ msg: String) -> String {
        String(format: "%@ %@", "==>".applyingCodes(Color.yellow, Style.bold), msg)
    }

    static func bold(_ msg: String) -> String {
        msg.applyingCodes(Color.yellow, Style.bold)
    }
}

extension Input {
    /// Prompts for a confirmation, i.e. a yes/no question.
    ///
    /// - Parameter prompt: Prompt to be printed before accepting input.
    /// - Parameter defaultValue: Whether to default to true or false for empty
    ///                           input. Invalid input aside from empty strings
    ///                           is always refused until corrected.
    /// - Returns: A boolean matching input.
    static func confirm(prompt: String, defaultValue: Bool = false) -> Bool {
        let suffix = defaultValue ? " [Y/n]: " : " [y/N]: "
        return readBool(
            prompt: prompt + suffix,
            defaultValue: defaultValue,
            errorResponse: { _, _ in
                Term.stderr <<< TTY.error("Invalid input.")
            }
        )
    }
}
