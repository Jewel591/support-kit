import Foundation

enum SupportCopy {
    static var fiveStarRating: String {
        fiveStarRating(locale: .current)
    }

    static func fiveStarRating(locale: Locale) -> String {
        SupportLocalization.string("Give Us a 5-Star Rating", locale: locale)
    }

    static var chooseFeedbackChannel: String {
        String(localized: "Choose a Feedback Channel", bundle: .module)
    }

    static var appStorePublicReview: String {
        String(localized: "Post Publicly on the App Store", bundle: .module)
    }

    static var emailFeedback: String {
        String(localized: "Send Feedback by Email", bundle: .module)
    }

    static var feedbackChannelExplanation: String {
        String(
            localized: "App Store reviews are public. Email is best for details and device diagnostics.",
            bundle: .module
        )
    }

    static var cancel: String {
        String(localized: "Cancel", bundle: .module)
    }
}
