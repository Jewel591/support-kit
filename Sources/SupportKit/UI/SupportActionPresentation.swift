import SwiftUI

struct SupportNotice: Identifiable {
    struct PrimaryAction {
        let title: String
        let handler: @MainActor () -> Void
    }

    let id = UUID()
    let title: String
    let message: String
    var primaryAction: PrimaryAction?
}

enum SupportPresentedSheet: Identifiable {
    case mail(
        mail: FeedbackMail,
        failureNotice: SupportNotice,
        sentNotice: @MainActor () -> SupportNotice?
    )
    case share(URL)

    var id: String {
        switch self {
        case .mail: "mail"
        case .share: "share"
        }
    }
}

@MainActor
struct SupportActionPresenter {
    private let sheetHandler: @MainActor (SupportPresentedSheet) -> Void
    private let noticeHandler: @MainActor (SupportNotice) -> Void

    init(
        sheetHandler: @escaping @MainActor (SupportPresentedSheet) -> Void,
        noticeHandler: @escaping @MainActor (SupportNotice) -> Void
    ) {
        self.sheetHandler = sheetHandler
        self.noticeHandler = noticeHandler
    }

    func present(_ sheet: SupportPresentedSheet) {
        sheetHandler(sheet)
    }

    func present(_ notice: SupportNotice) {
        noticeHandler(notice)
    }
}

/// Owns presentation state for exactly one rendered support control.
///
/// A custom style may emit several root rows into a `Form`. Keeping state here ensures only the
/// tapped package-owned control installs an active presenter instead of broadcasting one binding
/// through every row produced by the style.
@MainActor
struct SupportActionPresentationHost<Content: View>: View {
    let handler: (@MainActor (SupportActionPresenter) -> Void)?
    let content: Content

    @State private var presentedSheet: SupportPresentedSheet?
    @State private var notice: SupportNotice?
    @State private var pendingNotice: SupportNotice?

    var body: some View {
        ZStack {
            if let handler {
                Button {
                    handler(presenter)
                } label: {
                    content
                }
                .buttonStyle(.plain)
            } else {
                content
            }
        }
        .sheet(item: $presentedSheet, onDismiss: handleSheetDismissal) { sheet in
            switch sheet {
            case let .mail(mail, failureNotice, sentNotice):
                FeedbackMailComposer(
                    mail: mail,
                    onFailure: { pendingNotice = failureNotice },
                    onSent: { pendingNotice = sentNotice() }
                )
            case let .share(appStoreURL):
                SupportActivityView(items: [appStoreURL])
            }
        }
        .alert(item: $notice) { notice in
            alert(for: notice)
        }
    }

    private var presenter: SupportActionPresenter {
        SupportActionPresenter(
            sheetHandler: { presentedSheet = $0 },
            noticeHandler: { notice = $0 }
        )
    }

    private func handleSheetDismissal() {
        guard let pendingNotice else { return }
        self.pendingNotice = nil
        notice = pendingNotice
    }

    private func alert(for notice: SupportNotice) -> Alert {
        let title = Text(notice.title)
        let message = Text(notice.message)
        let ok = Text(String(localized: "OK", bundle: .module))

        guard let primaryAction = notice.primaryAction else {
            return Alert(title: title, message: message, dismissButton: .default(ok))
        }

        return Alert(
            title: title,
            message: message,
            primaryButton: .default(Text(primaryAction.title), action: primaryAction.handler),
            secondaryButton: .cancel(ok)
        )
    }
}
