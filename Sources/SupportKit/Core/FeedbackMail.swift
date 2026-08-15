import Foundation

struct FeedbackMail: Equatable {
    let recipient: String
    let subject: String
    let body: String

    init(app: SupportAppInfo, locale: Locale = .current) {
        recipient = SupportConstants.feedbackEmail
        subject = "[\(app.name) \(app.version)] "
            + String(localized: "User Feedback", bundle: .module, locale: locale)
        body = """
        \(String(localized: "Please describe the issue or suggestion:", bundle: .module, locale: locale))



        ----------------------------
        \(String(localized: "App Version:", bundle: .module, locale: locale)) \(app.version) (\(app.build))
        \(String(localized: "System Version:", bundle: .module, locale: locale)) \(app.systemVersion)
        \(String(localized: "Device Model:", bundle: .module, locale: locale)) \(app.hardwareModel)
        \(String(localized: "Language/Region:", bundle: .module, locale: locale)) \(app.localeIdentifier)
        """
    }

    var mailtoURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = recipient
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body),
        ]
        return components.url
    }
}
