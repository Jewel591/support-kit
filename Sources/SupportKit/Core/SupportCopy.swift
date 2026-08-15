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

    static var appStoreReview: String {
        appStoreReview(locale: .current)
    }

    static func appStoreReview(locale: Locale) -> String {
        SupportLocalization.string("Leave a Review on the App Store", locale: locale)
    }

    static var emailFeedback: String {
        String(localized: "Send Feedback by Email", bundle: .module)
    }

    static var feedbackChannelExplanation: String {
        feedbackChannelExplanation(locale: .current)
    }

    static func feedbackChannelExplanation(locale: Locale) -> String {
        SupportLocalization.string(
            "We regularly read and respond to App Store reviews.",
            locale: locale
        )
    }

    static var cancel: String {
        String(localized: "Cancel", bundle: .module)
    }
}
