import Foundation

enum FeedbackPurpose: String, Identifiable {
    case featureSuggestion
    case problemReport

    var id: String { rawValue }

    func title(locale: Locale = .current) -> String {
        switch self {
        case .featureSuggestion:
            SupportLocalization.string("Feature Suggestions", locale: locale)
        case .problemReport:
            SupportLocalization.string("Problem Feedback", locale: locale)
        }
    }

    func emailPrompt(locale: Locale = .current) -> String {
        switch self {
        case .featureSuggestion:
            SupportLocalization.string(
                "Tell us what you would like to see:",
                locale: locale
            )
        case .problemReport:
            SupportLocalization.string(
                "Describe the problem you encountered:",
                locale: locale
            )
        }
    }
}
