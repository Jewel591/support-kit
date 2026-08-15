import MessageUI
import SwiftUI

@MainActor
struct FeedbackMailComposer: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

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
        Coordinator(dismiss: dismiss, onFailure: onFailure)
    }

    @MainActor
    final class Coordinator: NSObject, @preconcurrency MFMailComposeViewControllerDelegate {
        private let dismiss: DismissAction
        private let onFailure: @MainActor () -> Void

        init(
            dismiss: DismissAction,
            onFailure: @escaping @MainActor () -> Void
        ) {
            self.dismiss = dismiss
            self.onFailure = onFailure
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            dismiss()
            if Self.shouldOfferFallback(result: result, error: error) {
                onFailure()
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
