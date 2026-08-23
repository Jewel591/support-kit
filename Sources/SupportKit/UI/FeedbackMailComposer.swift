import MessageUI
import SwiftUI

@MainActor
protocol MailComposerDismissing: AnyObject {
    func dismiss(animated flag: Bool, completion: (() -> Void)?)
}

extension MFMailComposeViewController: MailComposerDismissing {}

@MainActor
struct FeedbackMailComposer: UIViewControllerRepresentable {
    let mail: FeedbackMail
    let onFailure: @MainActor () -> Void

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients([mail.recipient])
        controller.setSubject(mail.subject)
        controller.setMessageBody(mail.body, isHTML: false)
        return controller
    }

    func updateUIViewController(
        _ uiViewController: MFMailComposeViewController,
        context: Context
    ) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFailure: onFailure)
    }

    @MainActor
    final class Coordinator: NSObject, @preconcurrency MFMailComposeViewControllerDelegate {
        private let onFailure: @MainActor () -> Void

        init(onFailure: @escaping @MainActor () -> Void) {
            self.onFailure = onFailure
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            finish(controller: controller, result: result, error: error)
        }

        func finish(
            controller: any MailComposerDismissing,
            result: MFMailComposeResult,
            error: Error?
        ) {
            let shouldOfferFallback = Self.shouldOfferFallback(
                result: result,
                error: error
            )
            controller.dismiss(animated: true) { [onFailure] in
                if shouldOfferFallback {
                    onFailure()
                }
            }
        }

        static func shouldOfferFallback(
            result: MFMailComposeResult,
            error: Error?
        ) -> Bool {
            result == .failed || error != nil
        }
    }
}
