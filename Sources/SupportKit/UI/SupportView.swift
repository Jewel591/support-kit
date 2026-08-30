import MessageUI
import SwiftUI
import UIKit

@MainActor
public struct SupportView<Style: SupportStyle>: View {
    @Environment(\.openURL) private var openURL

    private let style: Style
    private let actions: [SupportAction]?
    private let appInfo: SupportAppInfo
    private let host: SupportHost?
    private let feedbackFollowUpPreference = FeedbackFollowUpPreference()

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

    private func presentEmail(
        for purpose: FeedbackPurpose,
        presentation: SupportActionPresenter
    ) {
        let mail = FeedbackMail(app: appInfo, purpose: purpose)
        if MFMailComposeViewController.canSendMail() {
            presentation.present(
                .mail(
                    mail: mail,
                    failureNotice: emailFallbackNotice(),
                    sentNotice: feedbackFollowUpNotice
                )
            )
            return
        }
        guard let url = mail.mailtoURL else {
            presentation.present(emailFallbackNotice())
            return
        }
        openURL(url) { accepted in
            Task { @MainActor in
                if !accepted {
                    presentation.present(emailFallbackNotice())
                }
            }
        }
    }

    private func emailFallbackNotice() -> SupportNotice {
        SupportNotice(
            title: String(localized: "Email Unavailable", bundle: .module),
            message: String(
                localized: "Contact us at support@weisenjoy.com.",
                bundle: .module
            )
        )
    }

    private func feedbackFollowUpNotice() -> SupportNotice? {
        guard feedbackFollowUpPreference.shouldPrompt else { return nil }
        return SupportNotice(
            title: String(localized: "Thanks for your feedback", bundle: .module),
            message: String(
                localized: "We will get back to you soon. Follow us on Xiaohongshu to see fixes and updates first.",
                bundle: .module
            ),
            primaryAction: SupportNotice.PrimaryAction(
                title: String(localized: "Xiaohongshu", bundle: .module)
            ) {
                feedbackFollowUpPreference.markFollowed()
                openXiaohongshu()
            }
        )
    }

    private func copyWeChatID(presentation: SupportActionPresenter) {
        UIPasteboard.general.string = SupportConstants.weChatID
        presentation.present(
            SupportNotice(
                title: String(localized: "WeChat ID Copied", bundle: .module),
                message: SupportConstants.weChatID
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

    init(actions: [SupportAction]) {
        self.init(actions: actions, style: SystemSupportStyle())
    }
}
