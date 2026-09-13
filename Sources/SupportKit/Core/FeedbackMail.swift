import Foundation

struct FeedbackMail: Equatable {
    let recipient: String
    let subject: String
    let body: String

    init(
        app: SupportAppInfo,
        purpose: FeedbackPurpose = .problemReport,
        diagnostics: String? = nil,
        locale: Locale = .current
    ) {
        recipient = SupportConstants.feedbackEmail
        subject = "[\(app.name) \(app.version)] "
            + purpose.title(locale: locale)
        let template = """
        \(purpose.emailPrompt(locale: locale))



        ----------------------------
        \(SupportLocalization.string("App Version:", locale: locale)) \(app.version) (\(app.build))
        \(SupportLocalization.string("System Version:", locale: locale)) \(app.systemVersion)
        \(SupportLocalization.string("Device Model:", locale: locale)) \(app.hardwareModel)
        \(SupportLocalization.string("Language/Region:", locale: locale)) \(app.localeIdentifier)
        """
        if purpose == .problemReport,
           let diagnostics = diagnostics?.trimmingCharacters(in: .whitespacesAndNewlines),
           !diagnostics.isEmpty {
            body = template + "\n\n" + diagnostics
        } else {
            body = template
        }
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
