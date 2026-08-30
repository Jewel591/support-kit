import Foundation
import Testing
@testable import SupportKit

@Suite("Feedback follow-up preference")
struct FeedbackFollowUpPreferenceTests {
    @Test("Prompt remains eligible until the user follows Xiaohongshu")
    func followChoiceSuppressesFuturePrompts() throws {
        let suiteName = "SupportKitTests.FeedbackFollowUpPreference.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let preference = FeedbackFollowUpPreference(defaults: defaults)

        #expect(preference.shouldPrompt)

        preference.markFollowed()

        #expect(!preference.shouldPrompt)
        #expect(!FeedbackFollowUpPreference(defaults: defaults).shouldPrompt)
    }
}
