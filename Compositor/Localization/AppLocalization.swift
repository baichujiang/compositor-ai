import Foundation

/// UI language is independent of document data and stored enum values.
nonisolated enum AppLocalization {
    static let preferenceKey = "ui.interfaceLanguage"
    static let supportedLanguages = ["zh-Hans", "en"]
    static let activeLanguage = language(in: UserDefaults.standard)
    static var locale: Locale { Locale(identifier: activeLanguage) }
    private static let bundles: [String: Bundle] = Dictionary(uniqueKeysWithValues: supportedLanguages.compactMap { language in
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"), let bundle = Bundle(path: path) else { return nil }
        return (language, bundle)
    })

    static func language(in defaults: UserDefaults) -> String {
        let saved = defaults.string(forKey: preferenceKey) ?? "zh-Hans"
        return supportedLanguages.contains(saved) ? saved : "zh-Hans"
    }

    /// Set the app's language before its views and system menus are created.
    static func prepare() {
        UserDefaults.standard.set(activeLanguage == "en" ? ["en"] : [activeLanguage, "en"], forKey: "AppleLanguages")
    }

    static func choose(_ language: String) {
        guard supportedLanguages.contains(language) else { return }
        UserDefaults.standard.set(language, forKey: preferenceKey)
        // Active views retain their launch language; reopening applies the preference.
        UserDefaults.standard.set(language == "en" ? ["en"] : [language, "en"], forKey: "AppleLanguages")
    }

    static func text(_ key: String, language: String = activeLanguage) -> String {
        guard let bundle = bundles[language] else { return key }
        return bundle.localizedString(forKey: key, value: key, table: "Localizable")
    }
}

/// Dynamic UI labels and AppKit controls don't use SwiftUI's literal localization.
nonisolated func L(_ key: String) -> String { AppLocalization.text(key) }

nonisolated func LF(_ key: String, _ arguments: CVarArg...) -> String {
    String(format: L(key), locale: Locale.current, arguments: arguments)
}
