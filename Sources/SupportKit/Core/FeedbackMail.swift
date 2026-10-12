import Foundation

struct FeedbackMail: Equatable {
    let recipient: String
    let subject: String
    let body: String
    let feedbackID: FeedbackID

    init(
        app: SupportAppInfo,
        purpose: FeedbackPurpose = .problemReport,
        diagnostics: String? = nil,
        feedbackID: FeedbackID = .random(),
        locale: Locale = .current
    ) {
        self.feedbackID = feedbackID
        recipient = SupportConstants.feedbackEmail
        subject = "[\(app.name) \(app.version)] "
            + purpose.title(locale: locale)
            + " \(feedbackID)"
        let template = """
        \(Self.deliveryNotice(locale: locale))

        \(purpose.emailPrompt(locale: locale))



        ----------------------------
        \(SupportLocalization.string("Feedback ID:", locale: locale)) \(feedbackID)
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

    /// 邮件交给用户的邮件 App 后，App 无法得知是否真正发出；support@ 的自动回复是用户唯一的送达确认。
    static func deliveryNotice(locale: Locale = .current) -> String {
        SupportLocalization.string(
            "After you send this email, we'll reply automatically to confirm we received it. If no confirmation arrives within a few minutes, it may not have been sent. Check the Outbox in your mail app.",
            locale: locale
        )
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
