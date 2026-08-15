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
        let id = UUID()
        let title: String
        let message: String
    }

    @Environment(\.openURL) private var openURL

    private let style: Style
    private let appInfo: SupportAppInfo
    private let host: SupportHost?

    @State private var presentedSheet: PresentedSheet?
    @State private var notice: Notice?

    public init(style: Style) {
        self.style = style
        appInfo = .current
        host = SupportHostCatalog.currentHost
    }

    public var body: some View {
        style.makeBody(configuration: configuration)
            .sheet(item: $presentedSheet) { sheet in
                switch sheet {
                case .mail:
                    FeedbackMailComposer(
                        mail: FeedbackMail(app: appInfo),
                        onFailure: showEmailFallback
                    )
                case .share:
                    if let appStoreURL = host?.appStoreURL {
                        SupportActivityView(items: [appStoreURL])
                    }
                }
            }
            .alert(item: $notice) { notice in
                Alert(
                    title: Text(notice.title),
                    message: Text(notice.message),
                    dismissButton: .default(Text(String(localized: "OK", bundle: .module)))
                )
            }
    }

    private var configuration: SupportStyleConfiguration {
        let localized: (String.LocalizationValue) -> String = {
            String(localized: $0, bundle: .module)
        }

        var groups = [
            SupportStyleConfiguration.Group(
                id: "contact",
                title: localized("Contact Us"),
                items: [
                    item(
                        id: .emailFeedback,
                        title: localized("Email Feedback"),
                        symbol: "envelope",
                        accessory: .externalLink,
                        perform: presentEmail
                    ),
                    item(
                        id: .copyWeChatID,
                        title: localized("Copy WeChat ID"),
                        symbol: "doc.on.doc",
                        accessory: .copy,
                        perform: copyWeChatID
                    ),
                ]
            ),
            SupportStyleConfiguration.Group(
                id: "follow",
                title: localized("Follow Us"),
                items: [
                    item(
                        id: .xiaohongshu,
                        title: localized("Xiaohongshu"),
                        symbol: "heart",
                        accessory: .externalLink,
                        perform: openXiaohongshu
                    ),
                    item(
                        id: .officialWebsite,
                        title: localized("Official Website"),
                        symbol: "globe",
                        accessory: .externalLink,
                        perform: { open(SupportConstants.studioWebsite) }
                    ),
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
                            title: localized("Rate This App"),
                            symbol: "star",
                            accessory: .externalLink,
                            perform: { open(host.reviewURL) }
                        ),
                        item(
                            id: .shareApp,
                            title: localized("Share This App"),
                            symbol: "square.and.arrow.up",
                            accessory: .share,
                            perform: { presentedSheet = .share }
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
                        perform: { open(SupportConstants.privacyPolicy) }
                    ),
                    item(
                        id: .termsOfUse,
                        title: localized("Terms of Use"),
                        symbol: "doc.text",
                        accessory: .externalLink,
                        perform: { open(SupportConstants.termsOfUse) }
                    ),
                    item(
                        id: .version,
                        title: localized("Version"),
                        symbol: "info.circle",
                        accessory: .value("\(appInfo.version) (\(appInfo.build))"),
                        perform: nil
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
        accessory: SupportAccessory,
        perform: (@MainActor () -> Void)?
    ) -> SupportStyleConfiguration.Item {
        SupportStyleConfiguration.Item(
            id: id,
            title: title,
            suggestedSystemImage: symbol,
            accessory: accessory,
            perform: perform
        )
    }

    private func presentEmail() {
        if MFMailComposeViewController.canSendMail() {
            presentedSheet = .mail
            return
        }
        guard let url = FeedbackMail(app: appInfo).mailtoURL else {
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
        self.init(style: SystemSupportStyle())
    }
}
