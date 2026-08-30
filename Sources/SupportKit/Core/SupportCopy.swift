import Foundation

enum SupportCopy {
    static var fiveStarRating: String {
        fiveStarRating(locale: .current)
    }

    static func fiveStarRating(locale: Locale) -> String {
        SupportLocalization.string("Give Us a 5-Star Rating", locale: locale)
    }

    static var emailFeedback: String {
        String(localized: "Send Feedback by Email", bundle: .module)
    }

    static var cancel: String {
        String(localized: "Cancel", bundle: .module)
    }
}
