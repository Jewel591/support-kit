import SupportKit
import SwiftUI
import Testing
import UIKit

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

    @Test("Package brand icons fit inside a custom style frame")
    func brandIconsFitCustomStyleFrames() throws {
        let recorder = SupportConfigurationRecorder()
        let view = SupportView(
            placement: .primary,
            style: RecordingSupportStyle(recorder: recorder)
        )
        _ = view.body

        for action in [SupportAction.copyWeChatID, .xiaohongshu] {
            let item = try #require(recorder.items.first { $0.id == action })
            let renderer = ImageRenderer(
                content: item.suggestedIcon
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            )
            renderer.scale = 1

            let image = try #require(renderer.uiImage)
            if action == .copyWeChatID {
                let pixel = try rgbaPixel(atX: 3, y: 18, in: image)
                #expect(
                    pixel.red < 40 && pixel.green > 150 && pixel.blue < 160,
                    "The fitted WeChat artwork should show its green edge, not its white center"
                )
            } else {
                let pixel = try rgbaPixel(atX: 4, y: 4, in: image)
                #expect(
                    pixel.red > 200 && pixel.green < 100 && pixel.blue < 130,
                    "The fitted Xiaohongshu artwork should show its red corner, not its white center"
                )
            }
        }
    }

    private func rgbaPixel(
        atX x: Int,
        y: Int,
        in image: UIImage
    ) throws -> (red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        let cgImage = try #require(image.cgImage)
        let width = cgImage.width
        let height = cgImage.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let context = try #require(
            CGContext(
                data: &pixels,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let offset = ((y * width) + x) * 4
        return (
            red: pixels[offset],
            green: pixels[offset + 1],
            blue: pixels[offset + 2],
            alpha: pixels[offset + 3]
        )
    }
}

@MainActor
private final class SupportConfigurationRecorder {
    var actions: [SupportAction] = []
    var items: [SupportStyleConfiguration.Item] = []
}

private struct RecordingSupportStyle: SupportStyle {
    let recorder: SupportConfigurationRecorder

    func makeBody(configuration: SupportStyleConfiguration) -> some View {
        recorder.items = configuration.groups.flatMap(\.items)
        recorder.actions = recorder.items.map(\.id)
        return EmptyView()
    }
}
