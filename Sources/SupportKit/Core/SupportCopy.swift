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
        feedbackChannelExplanation(locale: .current)
    }

    static func feedbackChannelExplanation(locale: Locale) -> String {
        SupportLocalization.string(
            "We regularly read and respond to App Store reviews. Email is best for details and device diagnostics.",
            locale: locale
        )
    }

    static var cancel: String {
        String(localized: "Cancel", bundle: .module)
    }
}
