import Foundation

public enum L10n {
    nonisolated public static let bundle: Bundle = {
        #if SWIFT_PACKAGE
        Bundle.module
        #else
        Bundle.main
        #endif
    }()

    nonisolated public static func t(_ key: String) -> String {
        String(localized: String.LocalizationValue(stringLiteral: key), bundle: bundle)
    }

    nonisolated public static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: t(key), locale: .current, arguments: arguments)
    }
}
