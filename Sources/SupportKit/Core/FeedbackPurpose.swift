import Foundation

enum FeedbackPurpose: String, CaseIterable, Identifiable {
    case featureSuggestion
    case problemReport

    var id: String { rawValue }

    var action: SupportAction {
        switch self {
        case .featureSuggestion: .featureSuggestion
        case .problemReport: .problemFeedback
        }
    }

    var suggestedSystemImage: String {
        switch self {
        case .featureSuggestion: "lightbulb"
        case .problemReport: "exclamationmark.bubble"
        }
    }

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
