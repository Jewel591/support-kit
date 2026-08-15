import Testing
@testable import SupportKit

@Suite("Support style API")
struct SupportStyleAPITests {
    @Test("Problem feedback retains the original feedback identity")
    func problemFeedbackCompatibility() {
        #expect(SupportAction.problemFeedback == .emailFeedback)
        #expect(FeedbackPurpose.problemReport.action == .emailFeedback)
        #expect(FeedbackPurpose.featureSuggestion.action == .featureSuggestion)
        #expect(FeedbackPurpose.featureSuggestion.action != .emailFeedback)
    }

    @Test("Style metadata accepts future package tokens")
    func extensibleTokens() {
        let action = SupportAction(rawValue: "futureAction")
        let accessory = SupportAccessory(identifier: "futureAccessory")

        #expect(action.rawValue == "futureAction")
        #expect(accessory.identifier == "futureAccessory")
        #expect(accessory.valueText == nil)
    }
}
