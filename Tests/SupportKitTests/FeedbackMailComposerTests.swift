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

    @Test("Completion dismisses only the provided mail composer")
    func completionDismissesMailComposerBeforeFallback() {
        var didOfferFallback = false
        let coordinator = FeedbackMailComposer.Coordinator {
            didOfferFallback = true
        }
        let controller = MailComposerDismissSpy()

        coordinator.finish(
            controller: controller,
            result: .failed,
            error: nil
        )

        #expect(controller.dismissCallCount == 1)
        #expect(!didOfferFallback)

        controller.completeDismissal()

        #expect(didOfferFallback)
    }
}

@MainActor
private final class MailComposerDismissSpy: MailComposerDismissing {
    private(set) var dismissCallCount = 0
    private var completion: (() -> Void)?

    func dismiss(animated flag: Bool, completion: (() -> Void)?) {
        dismissCallCount += 1
        self.completion = completion
    }

    func completeDismissal() {
        completion?()
    }
}
