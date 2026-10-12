import SwiftUI

extension EnvironmentValues {
    @Entry var supportFeedbackEventHandler: (@MainActor (SupportFeedbackEvent) -> Void)?
}

public extension View {
    /// 接收本视图内 SupportKit 反馈入口的邮件交接结果，供宿主上报到自己的统计系统。
    func onSupportFeedbackEvent(
        _ handler: @escaping @MainActor (SupportFeedbackEvent) -> Void
    ) -> some View {
        environment(\.supportFeedbackEventHandler, handler)
    }
}
