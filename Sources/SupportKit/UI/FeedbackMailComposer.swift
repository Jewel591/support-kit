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
    let onSent: @MainActor () -> Void

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
        Coordinator(onFailure: onFailure, onSent: onSent)
    }

    @MainActor
    final class Coordinator: NSObject, @preconcurrency MFMailComposeViewControllerDelegate {
        private let onFailure: @MainActor () -> Void
        private let onSent: @MainActor () -> Void

        init(
            onFailure: @escaping @MainActor () -> Void,
            onSent: @escaping @MainActor () -> Void
        ) {
            self.onFailure = onFailure
            self.onSent = onSent
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
            if result == .sent {
                onSent()
            } else if Self.shouldOfferFallback(result: result, error: error) {
                onFailure()
            }
            controller.dismiss(animated: true, completion: nil)
        }

        static func shouldOfferFallback(
            result: MFMailComposeResult,
            error: Error?
        ) -> Bool {
            result == .failed || error != nil
        }
    }
}
