import SwiftUI
import UIKit

@MainActor
public struct SupportView<Style: SupportStyle>: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.supportFeedbackEventHandler) private var feedbackEventHandler

    private let style: Style
    private let actions: [SupportAction]?
    private let feedbackDiagnostics: String?
    private let appInfo: SupportAppInfo
    private let host: SupportHost?

    public init(style: Style) {
        self.init(actions: nil, style: style)
    }

    /// Creates a support surface containing the requested actions in the requested order.
    ///
    /// Unsupported actions and actions unavailable for the current host are omitted. Duplicate
    /// actions use their first occurrence. The host owns which surface receives each action;
    /// SupportKit continues to own the behavior of every item it supplies.
    /// 当前错误的技术诊断只附加到问题反馈邮件；不得包含账号、凭据或用户业务内容。
    public init(actions: [SupportAction], feedbackDiagnostics: String? = nil, style: Style) {
        self.init(actions: Optional(actions), feedbackDiagnostics: feedbackDiagnostics, style: style)
    }

    private init(actions: [SupportAction]?, feedbackDiagnostics: String? = nil, style: Style) {
        self.actions = actions
        self.feedbackDiagnostics = feedbackDiagnostics
        self.style = style
        appInfo = .current
        host = SupportHostCatalog.currentHost
    }

    public var body: some View {
        style.makeBody(configuration: presentedConfiguration)
    }

    private var presentedConfiguration: SupportStyleConfiguration {
        guard let actions else { return configuration }
        return configuration.selecting(actions)
    }

    private var configuration: SupportStyleConfiguration {
        let localized: (String.LocalizationValue) -> String = {
            String(localized: $0, bundle: .module)
        }

        let feedbackItems = FeedbackPurpose.allCases.map { purpose in
            item(
                id: purpose.action,
                title: purpose.title(),
                symbol: purpose.suggestedSystemImage,
                accessory: .disclosure,
                handler: { presentation in
                    enterFeedback(for: purpose, presentation: presentation)
                }
            )
        }

        var groups = [
            SupportStyleConfiguration.Group(
                id: "contact",
                title: localized("Contact Us"),
                items: feedbackItems
            ),
            SupportStyleConfiguration.Group(
                id: "follow",
                title: localized("Follow Us"),
                items: [
                    item(
                        id: .copyWeChatID,
                        title: localized("Copy WeChat ID"),
                        symbol: "doc.on.doc",
                        icon: Image("WeChatIcon", bundle: .module)
                            .renderingMode(.original)
                            .resizable(),
                        accessory: .copy,
                        handler: copyWeChatID
                    ),
                    item(
                        id: .xiaohongshu,
                        title: localized("Xiaohongshu"),
                        symbol: "heart",
                        icon: Image("XiaohongshuIcon", bundle: .module)
                            .renderingMode(.original)
                            .resizable(),
                        accessory: .externalLink,
                        handler: { _ in openXiaohongshu() }
                    ),
                    // The official website is being rebuilt and is not public yet.
                    // Restore this item when the new site launches.
                    // item(
                    //     id: .officialWebsite,
                    //     title: localized("Official Website"),
                    //     symbol: "globe",
                    //     accessory: .externalLink,
                    //     handler: { open(SupportConstants.studioWebsite) }
                    // ),
                ]
            ),
        ]

        if let host, let appStoreURL = host.appStoreURL {
            groups.append(
                SupportStyleConfiguration.Group(
                    id: "support",
                    title: localized("Support This App"),
                    items: [
                        item(
                            id: .rateApp,
                            title: SupportCopy.fiveStarRating,
                            symbol: "star",
                            accessory: .externalLink,
                            handler: { _ in open(host.reviewURL) }
                        ),
                        item(
                            id: .shareApp,
                            title: localized("Share This App"),
                            symbol: "square.and.arrow.up",
                            accessory: .share,
                            handler: { presentation in
                                presentation.present(.share(appStoreURL))
                            }
                        ),
                    ]
                )
            )
        }

        groups.append(
            SupportStyleConfiguration.Group(
                id: "about",
                title: localized("About"),
                items: [
                    item(
                        id: .privacyPolicy,
                        title: localized("Privacy Policy"),
                        symbol: "hand.raised",
                        accessory: .externalLink,
                        handler: { _ in open(SupportConstants.privacyPolicy) }
                    ),
                    item(
                        id: .termsOfUse,
                        title: localized("Terms of Use"),
                        symbol: "doc.text",
                        accessory: .externalLink,
                        handler: { _ in open(SupportConstants.termsOfUse) }
                    ),
                    item(
                        id: .version,
                        title: localized("Version"),
                        symbol: "info.circle",
                        accessory: .value("\(appInfo.version) (\(appInfo.build))"),
                        handler: nil
                    ),
                ]
            )
        )

        return SupportStyleConfiguration(
            navigationTitle: localized("Support"),
            groups: groups
        )
    }

    private func item(
        id: SupportAction,
        title: String,
        symbol: String,
        icon: Image? = nil,
        accessory: SupportAccessory,
        handler: (@MainActor (SupportActionPresenter) -> Void)?
    ) -> SupportStyleConfiguration.Item {
        SupportStyleConfiguration.Item(
            id: id,
            title: title,
            suggestedIcon: icon ?? Image(systemName: symbol),
            suggestedSystemImage: symbol,
            accessory: accessory,
            handler: handler
        )
    }

    private func enterFeedback(
        for purpose: FeedbackPurpose,
        presentation: SupportActionPresenter
    ) {
        switch purpose.entryRoute {
        case .email:
            presentEmail(for: purpose, presentation: presentation)
        }
    }

    /// 一律交给用户的默认邮件 App 发送：发送过程、报错与发件箱都在用户眼前，
    /// 不再使用 App 内邮件编辑器——它的「已发送」只代表进入发件箱，发不出去时用户毫无察觉。
    private func presentEmail(
        for purpose: FeedbackPurpose,
        presentation: SupportActionPresenter
    ) {
        let mail = feedbackMail(for: purpose)
        let kind = SupportFeedbackEvent.Kind(purpose)
        guard let url = mail.mailtoURL else {
            handOff(mail, kind: kind, accepted: false, presentation: presentation)
            return
        }
        openURL(url) { accepted in
            Task { @MainActor in
                handOff(mail, kind: kind, accepted: accepted, presentation: presentation)
            }
        }
    }

    private func handOff(
        _ mail: FeedbackMail,
        kind: SupportFeedbackEvent.Kind,
        accepted: Bool,
        presentation: SupportActionPresenter
    ) {
        feedbackEventHandler?(
            SupportFeedbackEvent(
                feedbackID: mail.feedbackID.rawValue,
                kind: kind,
                outcome: accepted ? .mailAppOpened : .mailAppUnavailable
            )
        )
        if !accepted {
            presentation.present(Self.emailUnavailableNotice())
        }
    }

    func feedbackMail(for purpose: FeedbackPurpose) -> FeedbackMail {
        FeedbackMail(app: appInfo, purpose: purpose, diagnostics: feedbackDiagnostics)
    }

    static func emailUnavailableNotice() -> SupportNotice {
        SupportNotice(
            title: String(localized: "Email Unavailable", bundle: .module),
            message: String(
                localized: "Contact us at support@weisenjoy.com.",
                bundle: .module
            ),
            primaryAction: SupportNotice.PrimaryAction(
                title: String(localized: "Copy Email Address", bundle: .module)
            ) {
                UIPasteboard.general.string = SupportConstants.feedbackEmail
            }
        )
    }

    private func copyWeChatID(presentation: SupportActionPresenter) {
        UIPasteboard.general.string = SupportConstants.weChatID
        presentation.present(
            SupportNotice(
                title: String(localized: "WeChat ID Copied", bundle: .module),
                message: SupportCopy.weChatIDCopiedMessage(appName: appInfo.name)
            )
        )
    }

    private func openXiaohongshu() {
        guard let appURL = SupportConstants.xiaohongshuApp else {
            open(SupportConstants.xiaohongshuWeb)
            return
        }
        openURL(appURL) { accepted in
            Task { @MainActor in
                if !accepted {
                    open(SupportConstants.xiaohongshuWeb)
                }
            }
        }
    }

    private func open(_ url: URL?) {
        guard let url else { return }
        openURL(url)
    }
}

public extension SupportView where Style == SystemSupportStyle {
    init() {
        self.init(actions: nil, style: SystemSupportStyle())
    }

    init(actions: [SupportAction], feedbackDiagnostics: String? = nil) {
        self.init(actions: actions, feedbackDiagnostics: feedbackDiagnostics, style: SystemSupportStyle())
    }
}
