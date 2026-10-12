import Foundation

/// 用户点击功能建议或问题反馈后，邮件交接的结果。
///
/// SupportKit 不依赖统计 SDK，由宿主通过 `onSupportFeedbackEvent(_:)` 接收并上报。
/// `mailAppOpened` 只表示已跳转到用户的邮件 App，不代表邮件已发出或已送达；
/// 送达需由收件端按 `feedbackID` 对账。
public struct SupportFeedbackEvent: Equatable, Sendable {
    public enum Kind: String, Sendable, CaseIterable {
        case featureSuggestion = "feature_suggestion"
        case problemReport = "problem_report"
    }

    public enum Outcome: String, Sendable, CaseIterable {
        /// 系统接受了 `mailto` 链接，用户已被带到邮件 App。
        case mailAppOpened = "mail_app_opened"
        /// 设备上没有能处理 `mailto` 的邮件 App，已改为展示反馈邮箱地址。
        case mailAppUnavailable = "mail_app_unavailable"
    }

    /// 与邮件标题、正文中的编号一致，格式为 `FB-` 加 8 位大写字母数字。
    public let feedbackID: String
    public let kind: Kind
    public let outcome: Outcome

    public init(feedbackID: String, kind: Kind, outcome: Outcome) {
        self.feedbackID = feedbackID
        self.kind = kind
        self.outcome = outcome
    }
}

extension SupportFeedbackEvent.Kind {
    init(_ purpose: FeedbackPurpose) {
        switch purpose {
        case .featureSuggestion: self = .featureSuggestion
        case .problemReport: self = .problemReport
        }
    }
}
