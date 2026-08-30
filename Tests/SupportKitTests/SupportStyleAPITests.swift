import SwiftUI
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

    @Test("Every feedback purpose enters the email flow directly")
    func feedbackPurposesEnterEmailDirectly() {
        #expect(FeedbackPurpose.allCases.allSatisfy { $0.entryRoute == .email })
    }

    @Test("Feedback purposes expose the preferred settings symbols")
    func feedbackPurposeSymbols() {
        #expect(FeedbackPurpose.featureSuggestion.suggestedSystemImage == "sparkles")
        #expect(FeedbackPurpose.problemReport.suggestedSystemImage == "exclamationmark.bubble")
    }

    @Test("Style metadata accepts future package tokens")
    func extensibleTokens() {
        let action = SupportAction(rawValue: "futureAction")
        let accessory = SupportAccessory(identifier: "futureAccessory")

        #expect(action.rawValue == "futureAction")
        #expect(accessory.identifier == "futureAccessory")
        #expect(accessory.valueText == nil)
    }

    @MainActor
    @Test("Action selection follows host order, ignores duplicates, and removes empty groups")
    func actionSelection() {
        let configuration = SupportStyleConfiguration(
            navigationTitle: "Support",
            groups: [
                .init(
                    id: "contact",
                    title: "Contact Us",
                    items: [
                        item(id: .featureSuggestion),
                        item(id: .problemFeedback),
                    ]
                ),
                .init(
                    id: "about",
                    title: "About",
                    items: [
                        item(id: .privacyPolicy),
                        item(id: .version, handler: nil),
                    ]
                ),
            ]
        )

        let selected = configuration.selecting([
            .privacyPolicy,
            .featureSuggestion,
            .privacyPolicy,
            SupportAction(rawValue: "futureAction"),
            .version,
        ])

        #expect(selected.items.map(\.id) == [.privacyPolicy, .featureSuggestion, .version])
        #expect(selected.groups.map(\.id) == ["about", "contact"])
        #expect(selected.groups[0].items.map(\.id) == [.privacyPolicy, .version])
        #expect(selected.groups[1].items.map(\.id) == [.featureSuggestion])
        #expect(selected.items[0].handler != nil)
        #expect(selected.items[2].handler == nil)
    }

    @MainActor
    private func item(
        id: SupportAction,
        handler: (@MainActor () -> Void)? = {}
    ) -> SupportStyleConfiguration.Item {
        SupportStyleConfiguration.Item(
            id: id,
            title: id.rawValue,
            suggestedIcon: Image(systemName: "questionmark"),
            suggestedSystemImage: "questionmark",
            accessory: .disclosure,
            handler: handler
        )
    }
}
