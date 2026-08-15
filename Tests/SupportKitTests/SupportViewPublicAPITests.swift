import SupportKit
import SwiftUI
import Testing

@MainActor
struct SupportViewPublicAPITests {
    @Test("Public placement initializers deliver filtered configurations to styles")
    func placementInitializersFilterThePresentedConfiguration() {
        let primaryRecorder = SupportConfigurationRecorder()
        let primaryView = SupportView(
            placement: .primary,
            style: RecordingSupportStyle(recorder: primaryRecorder)
        )
        _ = primaryView.body

        let secondaryRecorder = SupportConfigurationRecorder()
        let secondaryView = SupportView(
            placement: .secondary,
            style: RecordingSupportStyle(recorder: secondaryRecorder)
        )
        _ = secondaryView.body

        #expect(primaryRecorder.actions.contains(.featureSuggestion))
        #expect(primaryRecorder.actions.contains(.problemFeedback))
        #expect(primaryRecorder.actions.allSatisfy { $0.recommendedPlacement == .primary })
        #expect(secondaryRecorder.actions.contains(.privacyPolicy))
        #expect(secondaryRecorder.actions.contains(.termsOfUse))
        #expect(secondaryRecorder.actions.allSatisfy { $0.recommendedPlacement == .secondary })

        let _: SupportView<SystemSupportStyle> = SupportView(placement: .primary)
    }

    @Test("Deprecated style initializer preserves the complete catalog")
    func unfilteredStyleInitializerRemainsCompatible() {
        let recorder = SupportConfigurationRecorder()
        let view = SupportView(style: RecordingSupportStyle(recorder: recorder))

        _ = view.body

        #expect(recorder.actions.contains(.featureSuggestion))
        #expect(recorder.actions.contains(.privacyPolicy))

        let _: SupportView<SystemSupportStyle> = SupportView()
    }
}

@MainActor
private final class SupportConfigurationRecorder {
    var actions: [SupportAction] = []
}

private struct RecordingSupportStyle: SupportStyle {
    let recorder: SupportConfigurationRecorder

    func makeBody(configuration: SupportStyleConfiguration) -> some View {
        recorder.actions = configuration.groups.flatMap(\.items).map(\.id)
        return EmptyView()
    }
}
