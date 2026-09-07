import Foundation

enum SupportCopy {
    static var fiveStarRating: String {
        fiveStarRating(locale: .current)
    }

    static func fiveStarRating(locale: Locale) -> String {
        SupportLocalization.string("Give Us a 5-Star Rating", locale: locale)
    }

    /// Alert body shown after the WeChat ID lands on the pasteboard. The second line asks the
    /// user to mention which app they came from, because one WeChat account serves every app
    /// in the studio catalog and the friend request itself carries no such context.
    static func weChatIDCopiedMessage(appName: String, locale: Locale = .current) -> String {
        let hint = SupportLocalization.string(
            "Please mention %@ when adding.",
            locale: locale
        )
        return SupportConstants.weChatID + "\n" + String(format: hint, appName)
    }
}
