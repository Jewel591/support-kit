import Foundation
import Testing
@testable import SupportKit

@Suite("Feedback email")
struct FeedbackMailTests {
    private let app = SupportAppInfo(
        name: "Example",
        version: "2.3",
        build: "45",
        systemVersion: "iOS 27.0",
        hardwareModel: "iPhone18,1",
        localeIdentifier: "en_US"
    )
    private let id = FeedbackID(rawValue: "FB-7K3M9QX2")

    @Test("Feedback template uses the canonical public address and diagnostics")
    func canonicalTemplate() {
        let mail = FeedbackMail(app: app)

        #expect(mail.recipient == "support@weisenjoy.com")
        #expect(mail.subject.contains("[Example 2.3]"))
        #expect(mail.body.contains("2.3 (45)"))
        #expect(mail.body.contains("iOS 27.0"))
        #expect(mail.body.contains("iPhone18,1"))
        #expect(mail.body.contains("en_US"))
    }

    @Test("Feedback template excludes account identity fields")
    func excludesUserIdentity() {
        let body = FeedbackMail(app: app).body.lowercased()

        #expect(!body.contains("user id"))
        #expect(!body.contains("用户 id"))
        #expect(!body.contains("账号邮箱"))
    }

    @Test("Feedback diagnostics use the selected locale")
    func localizedDiagnostics() {
        let body = FeedbackMail(
            app: app,
            locale: Locale(identifier: "zh-Hans")
        ).body

        #expect(body.contains("App 版本："))
        #expect(body.contains("系统版本："))
        #expect(body.contains("设备型号："))
        #expect(body.contains("语言/地区："))
        #expect(!body.contains("System Version:"))
    }

    @Test("Feature suggestions and problem reports use distinct localized templates")
    func purposeSpecificTemplates() {
        let feature = FeedbackMail(
            app: app,
            purpose: .featureSuggestion,
            locale: Locale(identifier: "zh-Hans")
        )
        let problem = FeedbackMail(
            app: app,
            purpose: .problemReport,
            locale: Locale(identifier: "zh-Hans")
        )

        #expect(feature.subject.contains("功能建议"))
        #expect(feature.body.contains("请告诉我们你希望新增什么功能："))
        #expect(problem.subject.contains("问题反馈"))
        #expect(problem.body.contains("请描述你遇到的问题："))
        #expect(feature.subject != problem.subject)
        #expect(feature.body != problem.body)
    }

    @Test("Mailto fallback preserves recipient, subject, and body")
    func mailtoFallback() {
        let mail = FeedbackMail(app: app)
        let components = mail.mailtoURL.flatMap {
            URLComponents(url: $0, resolvingAgainstBaseURL: false)
        }

        #expect(components?.scheme == "mailto")
        #expect(components?.path == "support@weisenjoy.com")
        #expect(components?.queryItems?.first(where: { $0.name == "subject" })?.value == mail.subject)
        #expect(components?.queryItems?.first(where: { $0.name == "body" })?.value == mail.body)
    }

    @Test("#21: Problem feedback carries the current failure into both mail routes")
    func currentFailureDiagnostics() {
        let diagnostics = "reason: containerUnavailable\nerror: SQLite 13 & I/O\n设备刚解锁"
        let mail = FeedbackMail(app: app, diagnostics: diagnostics)
        #expect(mail.body.contains(diagnostics))
        #expect(mail.body.components(separatedBy: diagnostics).count == 2)
        #expect(mail.body.contains("2.3 (45)"))
        let components = mail.mailtoURL.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        #expect(components?.queryItems?.first(where: { $0.name == "body" })?.value == mail.body)
    }

    @Test("#21: Blank diagnostics and feature suggestions preserve their normal templates")
    func diagnosticsStayScopedToProblems() {
        #expect(FeedbackMail(app: app, diagnostics: " \n ", feedbackID: id) == FeedbackMail(app: app, feedbackID: id))
        let feature = FeedbackMail(app: app, purpose: .featureSuggestion, feedbackID: id)
        #expect(
            FeedbackMail(app: app, purpose: .featureSuggestion, diagnostics: "failure details", feedbackID: id)
                == feature
        )
    }

    @MainActor
    @Test("#21: The public support surface forwards diagnostics only to problem feedback")
    func surfaceForwardsDiagnostics() {
        let diagnostics = "reason: containerUnavailable\nerror: SQLite 13"
        let view = SupportView(actions: [.problemFeedback, .featureSuggestion], feedbackDiagnostics: diagnostics)
        #expect(view.feedbackMail(for: .problemReport).body.contains(diagnostics))
        #expect(!view.feedbackMail(for: .featureSuggestion).body.contains(diagnostics))
        let normal = SupportView(actions: [.problemFeedback])
        #expect(!normal.feedbackMail(for: .problemReport).body.contains(diagnostics))
    }

    @Test("#24: Subject and body carry the feedback ID used for delivery reconciliation")
    func feedbackIDInSubjectAndBody() {
        let mail = FeedbackMail(app: app, feedbackID: id)

        #expect(mail.subject.hasSuffix(" FB-7K3M9QX2"))
        #expect(mail.body.contains("Feedback ID: FB-7K3M9QX2"))
        let components = mail.mailtoURL.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        #expect(components?.queryItems?.first(where: { $0.name == "subject" })?.value?.contains("FB-7K3M9QX2") == true)
    }

    @Test("#24: Body opens with the auto-reply delivery notice in the selected locale")
    func deliveryNoticeLeadsBody() {
        let english = FeedbackMail(app: app, feedbackID: id)
        #expect(english.body.hasPrefix("After you send this email, we'll reply automatically"))
        #expect(english.body.contains("Outbox"))

        let chinese = FeedbackMail(app: app, feedbackID: id, locale: Locale(identifier: "zh-Hans"))
        #expect(chinese.body.hasPrefix("发送后，我们收到会自动回复一封确认邮件。"))
        #expect(chinese.body.contains("「发件箱」"))
        #expect(chinese.body.contains("反馈编号： FB-7K3M9QX2"))
        #expect(!chinese.body.contains("Outbox"))
    }

    @Test("#24: Each mail gets a fresh feedback ID")
    func defaultIDIsRandom() {
        #expect(FeedbackMail(app: app).feedbackID != FeedbackMail(app: app).feedbackID)
    }
}

@Suite("Feedback ID")
struct FeedbackIDTests {
    @Test("Random IDs use the FB- prefix and eight unambiguous Crockford characters")
    func format() {
        let allowed = Set("0123456789ABCDEFGHJKMNPQRSTVWXYZ")
        for _ in 0..<500 {
            let raw = FeedbackID.random().rawValue
            #expect(raw.hasPrefix("FB-"))
            let code = raw.dropFirst(3)
            #expect(code.count == 8)
            #expect(code.allSatisfy(allowed.contains))
        }
        #expect(FeedbackID.alphabet.count == 32)
        #expect(!FeedbackID.alphabet.contains { "ILOU".contains($0) })
    }
}

@Suite("Support feedback event")
struct SupportFeedbackEventTests {
    @Test("Raw values are the stable analytics contract")
    func rawValues() {
        #expect(SupportFeedbackEvent.Kind.featureSuggestion.rawValue == "feature_suggestion")
        #expect(SupportFeedbackEvent.Kind.problemReport.rawValue == "problem_report")
        #expect(SupportFeedbackEvent.Outcome.mailAppOpened.rawValue == "mail_app_opened")
        #expect(SupportFeedbackEvent.Outcome.mailAppUnavailable.rawValue == "mail_app_unavailable")
    }

    @Test("Feedback purpose maps to the event kind")
    func kindMapping() {
        #expect(SupportFeedbackEvent.Kind(.featureSuggestion) == .featureSuggestion)
        #expect(SupportFeedbackEvent.Kind(.problemReport) == .problemReport)
    }

    @MainActor
    @Test("Unavailable notice offers to copy the support address")
    func unavailableNoticeCopiesAddress() {
        let notice = SupportView<SystemSupportStyle>.emailUnavailableNotice()
        #expect(notice.title == "Email Unavailable")
        #expect(notice.message.contains("support@weisenjoy.com"))
        #expect(notice.primaryAction?.title == "Copy Email Address")
    }
}
