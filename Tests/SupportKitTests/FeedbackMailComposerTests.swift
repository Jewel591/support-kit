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
}
