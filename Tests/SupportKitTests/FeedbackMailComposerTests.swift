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

    @Test("Failure is recorded before dismissing only the provided mail composer")
    func failurePrecedesMailComposerDismissal() {
        var events: [String] = []
        let coordinator = FeedbackMailComposer.Coordinator {
            events.append("fallback")
        }
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
