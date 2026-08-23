import Foundation
import Testing
@testable import SupportKit

struct FeedbackPurposeTests {
    @Test("Feedback skips channel choice when App Store review is unavailable")
    func feedbackEntryRouteMatchesAvailableChannels() {
        #expect(!FeedbackPurpose.shouldChooseChannel(reviewURL: nil))
        #expect(
            FeedbackPurpose.shouldChooseChannel(
                reviewURL: URL(string: "https://apps.apple.com/app/id123?action=write-review")
            )
        )
    }
}
