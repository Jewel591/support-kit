import Foundation

/// 反馈编号：写进邮件标题与正文，并随 `SupportFeedbackEvent` 交给宿主上报。
/// 系统不报告 `mailto` 邮件是否真正发出，收件端按编号与上报事件对账，才能得到送达率。
/// 编号随机生成，不含用户、设备或账号标识。
struct FeedbackID: Equatable, Sendable, CustomStringConvertible {
    static let prefix = "FB-"
    static let length = 8
    /// Crockford Base32：去掉 I、L、O、U，用户手抄或转述时不易混淆。
    static let alphabet = Array("0123456789ABCDEFGHJKMNPQRSTVWXYZ")

    let rawValue: String

    var description: String { rawValue }

    static func random() -> FeedbackID {
        var generator = SystemRandomNumberGenerator()
        return random(using: &generator)
    }

    static func random<Generator: RandomNumberGenerator>(using generator: inout Generator) -> FeedbackID {
        let code = (0..<length).map { _ in alphabet.randomElement(using: &generator)! }
        return FeedbackID(rawValue: prefix + String(code))
    }
}
