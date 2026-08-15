import Foundation

struct FeedbackMail: Equatable {
    let recipient: String
    let subject: String
    let body: String

    init(app: SupportAppInfo) {
        recipient = SupportConstants.feedbackEmail
        subject = "[\(app.name) \(app.version)] "
            + String(localized: "User Feedback", bundle: .module)
        body = """
        \(String(localized: "Please describe the issue or suggestion:", bundle: .module))



        ----------------------------
        App Version: \(app.version) (\(app.build))
        System Version: \(app.systemVersion)
        Device Model: \(app.hardwareModel)
        Language/Region: \(app.localeIdentifier)
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
