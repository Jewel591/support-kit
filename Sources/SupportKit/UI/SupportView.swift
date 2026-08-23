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
    private let placement: SupportPlacement?
    private let appInfo: SupportAppInfo
    private let host: SupportHost?

    @State private var presentedSheet: PresentedSheet?
    @State private var notice: Notice?
    @State private var pendingMailFailure = false
    @State private var selectedFeedbackPurpose: FeedbackPurpose?
    @State private var mailPurpose = FeedbackPurpose.problemReport
    @State private var queuedMailPurpose: FeedbackPurpose?

    @available(
        *,
        deprecated,
        message: "Render explicit .primary and .secondary SupportView placements."
    )
    public init(style: Style) {
        self.init(placement: nil, style: style)
    }

    public init(placement: SupportPlacement, style: Style) {
        self.init(placement: Optional(placement), style: style)
    }

    private init(placement: SupportPlacement?, style: Style) {
        self.placement = placement
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
                        onFailure: { pendingMailFailure = true }
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
            .confirmationDialog(
                SupportCopy.chooseFeedbackChannel,
                isPresented: isChoosingFeedbackChannel,
                titleVisibility: .visible,
                presenting: selectedFeedbackPurpose
            ) { purpose in
                if let reviewURL = host?.reviewURL {
                    Button(SupportCopy.appStoreReview) {
                        open(reviewURL)
                    }
                }
                Button(SupportCopy.emailFeedback) {
                    queuedMailPurpose = purpose
                }
                Button(SupportCopy.cancel, role: .cancel) {}
            } message: { _ in
                Text(SupportCopy.feedbackChannelExplanation)
            }
    }

    private var presentedConfiguration: SupportStyleConfiguration {
        guard let placement else { return configuration }
        return configuration.filtered(to: placement)
    }

    private func handleSheetDismissal() {
        guard pendingMailFailure else { return }
        pendingMailFailure = false
        showEmailFallback()
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
                perform: { beginFeedback(for: purpose) }
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
                        perform: copyWeChatID
                    ),
                    item(
                        id: .xiaohongshu,
                        title: localized("Xiaohongshu"),
                        symbol: "heart",
                        icon: Image("XiaohongshuIcon", bundle: .module)
                            .renderingMode(.original)
                            .resizable(),
                        accessory: .externalLink,
                        perform: openXiaohongshu
                    ),
                    // The official website is being rebuilt and is not public yet.
                    // Restore this item when the new site launches.
                    // item(
                    //     id: .officialWebsite,
                    //     title: localized("Official Website"),
                    //     symbol: "globe",
                    //     accessory: .externalLink,
                    //     perform: { open(SupportConstants.studioWebsite) }
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
        icon: Image? = nil,
        accessory: SupportAccessory,
        perform: (@MainActor () -> Void)?
    ) -> SupportStyleConfiguration.Item {
        SupportStyleConfiguration.Item(
            id: id,
            title: title,
            suggestedIcon: icon ?? Image(systemName: symbol),
            suggestedSystemImage: symbol,
            recommendedPlacement: id.recommendedPlacement,
            accessory: accessory,
            perform: perform
        )
    }

    private var isChoosingFeedbackChannel: Binding<Bool> {
        Binding(
            get: { selectedFeedbackPurpose != nil },
            set: { isPresented in
                if !isPresented {
                    selectedFeedbackPurpose = nil
                    guard let purpose = queuedMailPurpose else { return }
                    queuedMailPurpose = nil
                    Task { @MainActor in
                        await Task.yield()
                        presentEmail(for: purpose)
                    }
                }
            }
        )
    }

    private func beginFeedback(for purpose: FeedbackPurpose) {
        guard FeedbackPurpose.shouldChooseChannel(reviewURL: host?.reviewURL) else {
            presentEmail(for: purpose)
            return
        }
        selectedFeedbackPurpose = purpose
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
    @available(
        *,
        deprecated,
        message: "Render explicit .primary and .secondary SupportView placements."
    )
    init() {
        self.init(placement: nil, style: SystemSupportStyle())
    }

    init(placement: SupportPlacement) {
        self.init(placement: placement, style: SystemSupportStyle())
    }
}
