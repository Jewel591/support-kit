import MessageUI
import SwiftUI
import UIKit

@MainActor
public struct SupportView<Style: SupportStyle>: View {
    private enum PresentedSheet: String, Identifiable {
        case mail
        case share

        var id: String { rawValue }
    }

    private struct Notice: Identifiable {
        enum Action {
            case followXiaohongshu
        }

        let id = UUID()
        let title: String
        let message: String
        var action: Action? = nil
    }

    @Environment(\.openURL) private var openURL

    private let style: Style
    private let actions: [SupportAction]?
    private let appInfo: SupportAppInfo
    private let host: SupportHost?
    private let feedbackFollowUpPreference = FeedbackFollowUpPreference()

    @State private var presentedSheet: PresentedSheet?
    @State private var notice: Notice?
    @State private var pendingMailFailure = false
    @State private var pendingMailSent = false
    @State private var mailPurpose = FeedbackPurpose.problemReport

    public init(style: Style) {
        self.init(actions: nil, style: style)
    }

    /// Creates a support surface containing the requested actions in the requested order.
    ///
    /// Unsupported actions and actions unavailable for the current host are omitted. Duplicate
    /// actions use their first occurrence. The host owns which surface receives each action;
    /// SupportKit continues to own the behavior of every item it supplies.
    public init(actions: [SupportAction], style: Style) {
        self.init(actions: Optional(actions), style: style)
    }

    private init(actions: [SupportAction]?, style: Style) {
        self.actions = actions
        self.style = style
        appInfo = .current
        host = SupportHostCatalog.currentHost
    }

    public var body: some View {
        style.makeBody(configuration: presentedConfiguration)
            .sheet(item: $presentedSheet, onDismiss: handleSheetDismissal) { sheet in
                switch sheet {
                case .mail:
                    FeedbackMailComposer(
                        mail: FeedbackMail(app: appInfo, purpose: mailPurpose),
                        onFailure: { pendingMailFailure = true },
                        onSent: { pendingMailSent = true }
                    )
                case .share:
                    if let appStoreURL = host?.appStoreURL {
                        SupportActivityView(items: [appStoreURL])
                    }
                }
            }
            .alert(item: $notice) { notice in
                alert(for: notice)
            }
    }

    private var presentedConfiguration: SupportStyleConfiguration {
        guard let actions else { return configuration }
        return configuration.selecting(actions)
    }

    private func handleSheetDismissal() {
        if pendingMailFailure {
            pendingMailFailure = false
            showEmailFallback()
        } else if pendingMailSent {
            pendingMailSent = false
            showFeedbackFollowUpIfNeeded()
        }
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
                handler: { enterFeedback(for: purpose) }
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
                        handler: openXiaohongshu
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

        if let host, host.appStoreURL != nil {
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
                            handler: { open(host.reviewURL) }
                        ),
                        item(
                            id: .shareApp,
                            title: localized("Share This App"),
                            symbol: "square.and.arrow.up",
                            accessory: .share,
                            handler: { presentedSheet = .share }
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
                        handler: { open(SupportConstants.privacyPolicy) }
                    ),
                    item(
                        id: .termsOfUse,
                        title: localized("Terms of Use"),
                        symbol: "doc.text",
                        accessory: .externalLink,
                        handler: { open(SupportConstants.termsOfUse) }
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
        handler: (@MainActor () -> Void)?
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

    private func enterFeedback(for purpose: FeedbackPurpose) {
        switch purpose.entryRoute {
        case .email:
            presentEmail(for: purpose)
        }
    }

    private func presentEmail(for purpose: FeedbackPurpose) {
        mailPurpose = purpose
        if MFMailComposeViewController.canSendMail() {
            presentedSheet = .mail
            return
        }
        guard let url = FeedbackMail(app: appInfo, purpose: purpose).mailtoURL else {
            showEmailFallback()
            return
        }
        openURL(url) { accepted in
            Task { @MainActor in
                if !accepted {
                    showEmailFallback()
                }
            }
        }
    }

    private func showEmailFallback() {
        notice = Notice(
            title: String(localized: "Email Unavailable", bundle: .module),
            message: String(
                localized: "Contact us at support@weisenjoy.com.",
                bundle: .module
            )
        )
    }

    private func showFeedbackFollowUpIfNeeded() {
        guard feedbackFollowUpPreference.shouldPrompt else { return }
        notice = Notice(
            title: String(localized: "Thanks for your feedback", bundle: .module),
            message: String(
                localized: "We will get back to you soon. Follow us on Xiaohongshu to see fixes and updates first.",
                bundle: .module
            ),
            action: .followXiaohongshu
        )
    }

    private func alert(for notice: Notice) -> Alert {
        let title = Text(notice.title)
        let message = Text(notice.message)
        let ok = Text(String(localized: "OK", bundle: .module))

        switch notice.action {
        case .followXiaohongshu:
            return Alert(
                title: title,
                message: message,
                primaryButton: .default(
                    Text(String(localized: "Xiaohongshu", bundle: .module))
                ) {
                    feedbackFollowUpPreference.markFollowed()
                    openXiaohongshu()
                },
                secondaryButton: .cancel(ok)
            )
        case nil:
            return Alert(title: title, message: message, dismissButton: .default(ok))
        }
    }

    private func copyWeChatID() {
        UIPasteboard.general.string = SupportConstants.weChatID
        notice = Notice(
            title: String(localized: "WeChat ID Copied", bundle: .module),
            message: SupportConstants.weChatID
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

    init(actions: [SupportAction]) {
        self.init(actions: actions, style: SystemSupportStyle())
    }
}
