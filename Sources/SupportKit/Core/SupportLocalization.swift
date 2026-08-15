import Foundation

enum SupportLocalization {
    static func string(
        _ key: String,
        locale: Locale = .current
    ) -> String {
        if locale.language.languageCode?.identifier == "en" {
            return key
        }

        let localizations = Bundle.module.localizations
        let preferred = Bundle.preferredLocalizations(
            from: localizations,
            forPreferences: [locale.identifier]
        )

        if let localization = preferred.first,
           let path = Bundle.module.path(forResource: localization, ofType: "lproj"),
           let localizedBundle = Bundle(path: path) {
            return localizedBundle.localizedString(forKey: key, value: key, table: nil)
        }

        return Bundle.module.localizedString(forKey: key, value: key, table: nil)
    }
}
