import Foundation
import MessageUI
import Testing
@testable import SupportKit

@MainActor
@Suite("Feedback mail result handling")
struct FeedbackMailComposerTests {
    @Test("Failed mail offers the fallback contact path")
    func failedResult() {
        #expect(
            FeedbackMailComposer.Coordinator.shouldOfferFallback(
                result: .failed,
                error: nil
            )
        )
    }

    @Test("Framework error offers the fallback contact path")
    func frameworkError() {
        #expect(
            FeedbackMailComposer.Coordinator.shouldOfferFallback(
                result: .cancelled,
                error: CocoaError(.fileWriteUnknown)
            )
        )
    }

    @Test("Successful or user-cancelled mail does not show a failure")
    func nonFailureResults() {
        #expect(
            !FeedbackMailComposer.Coordinator.shouldOfferFallback(
                result: .sent,
                error: nil
            )
        )
        #expect(
            !FeedbackMailComposer.Coordinator.shouldOfferFallback(
                result: .cancelled,
                error: nil
            )
        )
    }

    @Test("Only sent mail triggers the success callback")
    func sentResult() {
        var sentCount = 0
        var failureCount = 0
        let coordinator = FeedbackMailComposer.Coordinator(
            onFailure: { failureCount += 1 },
            onSent: { sentCount += 1 }
        )
        let controller = MailComposerDismissSpy {}

        for result in [
            MFMailComposeResult.cancelled,
            .saved,
            .failed,
            .sent,
        ] {
            coordinator.finish(controller: controller, result: result, error: nil)
        }

        #expect(sentCount == 1)
        #expect(failureCount == 1)
    }

    @Test("Failure is recorded before dismissing only the provided mail composer")
    func failurePrecedesMailComposerDismissal() {
        var events: [String] = []
        let coordinator = FeedbackMailComposer.Coordinator(
            onFailure: { events.append("fallback") },
            onSent: { events.append("sent") }
        )
        let controller = MailComposerDismissSpy {
            events.append("dismiss")
        }

        coordinator.finish(
            controller: controller,
            result: .failed,
            error: nil
        )

        #expect(controller.dismissCallCount == 1)
        #expect(events == ["fallback", "dismiss"])
    }
}

@MainActor
private final class MailComposerDismissSpy: MailComposerDismissing {
    private let onDismiss: () -> Void
    private(set) var dismissCallCount = 0

    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    func dismiss(animated flag: Bool, completion: (() -> Void)?) {
        dismissCallCount += 1
        onDismiss()
        completion?()
    }
}
