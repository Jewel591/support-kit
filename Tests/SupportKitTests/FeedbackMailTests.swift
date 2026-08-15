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
}
