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

    @Test("Feedback purposes expose the preferred settings symbols")
    func feedbackPurposeSymbols() {
        #expect(FeedbackPurpose.featureSuggestion.suggestedSystemImage == "sparkles")
        #expect(FeedbackPurpose.problemReport.suggestedSystemImage == "exclamationmark.bubble")
    }

    @Test("Style metadata accepts future package tokens")
    func extensibleTokens() {
        let action = SupportAction(rawValue: "futureAction")
        let accessory = SupportAccessory(identifier: "futureAccessory")
        let placement = SupportPlacement(rawValue: "futurePlacement")

        #expect(action.rawValue == "futureAction")
        #expect(action.recommendedPlacement == .secondary)
        #expect(accessory.identifier == "futureAccessory")
        #expect(accessory.valueText == nil)
        #expect(placement.rawValue == "futurePlacement")
    }

    @Test("Important support actions are recommended for the primary level")
    func primaryPlacementRecommendations() {
        let primaryActions: [SupportAction] = [
            .featureSuggestion,
            .problemFeedback,
            .copyWeChatID,
            .xiaohongshu,
            .rateApp,
            .shareApp,
        ]

        #expect(primaryActions.allSatisfy { $0.recommendedPlacement == .primary })
    }

    @Test("About and legal actions are recommended for the secondary level")
    func secondaryPlacementRecommendations() {
        let secondaryActions: [SupportAction] = [
            .officialWebsite,
            .privacyPolicy,
            .termsOfUse,
            .version,
        ]

        #expect(secondaryActions.allSatisfy { $0.recommendedPlacement == .secondary })
    }

    @MainActor
    @Test("Placement filtering keeps matching items and removes empty groups")
    func placementFiltering() {
        let configuration = SupportStyleConfiguration(
            navigationTitle: "Support",
            groups: [
                .init(
                    id: "contact",
                    title: "Contact Us",
                    items: [
                        item(id: .featureSuggestion),
                        item(id: .privacyPolicy),
                    ]
                ),
                .init(
                    id: "primary-only",
                    title: "Primary",
                    items: [item(id: .problemFeedback)]
                ),
            ]
        )

        let primary = configuration.filtered(to: .primary)
        let secondary = configuration.filtered(to: .secondary)

        let primaryGroupIDs = primary.groups.map { $0.id }
        let primaryItemIDs = primary.groups.flatMap { $0.items }.map { $0.id }
        let secondaryGroupIDs = secondary.groups.map { $0.id }
        let secondaryItemIDs = secondary.groups.flatMap { $0.items }.map { $0.id }

        #expect(primaryGroupIDs == ["contact", "primary-only"])
        #expect(
            primaryItemIDs
                == [SupportAction.featureSuggestion, SupportAction.problemFeedback]
        )
        #expect(secondaryGroupIDs == ["contact"])
        #expect(secondaryItemIDs == [SupportAction.privacyPolicy])
    }

    @MainActor
    private func item(id: SupportAction) -> SupportStyleConfiguration.Item {
        SupportStyleConfiguration.Item(
            id: id,
            title: id.rawValue,
            suggestedIcon: Image(systemName: "questionmark"),
            suggestedSystemImage: "questionmark",
            recommendedPlacement: id.recommendedPlacement,
            accessory: .disclosure,
            perform: {}
        )
    }
}
