import SupportKit
import SwiftUI
import Testing
import UIKit

@MainActor
struct SupportViewPublicAPITests {
    @Test("Public action initializer delivers the host selection in order")
    func actionInitializerSelectsThePresentedConfiguration() {
        let recorder = SupportConfigurationRecorder()
        let view = SupportView(
            actions: [
                .privacyPolicy,
                .featureSuggestion,
                .privacyPolicy,
                SupportAction(rawValue: "futureAction"),
            ],
            style: RecordingSupportStyle(recorder: recorder)
        )
        _ = view.body

        #expect(recorder.actions == [.privacyPolicy, .featureSuggestion])

        let _: SupportView<SystemSupportStyle> = SupportView(actions: [.privacyPolicy])
    }

    @Test("Unfiltered initializers preserve the complete catalog")
    func unfilteredInitializersPreserveCompleteCatalog() {
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
            actions: [.copyWeChatID, .xiaohongshu],
            style: RecordingSupportStyle(recorder: recorder)
        )
        _ = view.body

        for action in [SupportAction.copyWeChatID, .xiaohongshu] {
            let item = try #require(recorder.items.first { $0.id == action })
            let renderer = ImageRenderer(
                content: SupportActionLink(item) { content in
                    content.suggestedIcon
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
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
                let pixel = try rgbaPixel(atX: 8, y: 13, in: image)
                #expect(
                    pixel.red > 220 && pixel.green > 220 && pixel.blue > 220,
                    "The fitted Xiaohongshu artwork should show its white lettering, not a cropped red field"
                )
            }
        }
    }

    @Test("Package-owned row and link controls accept interactive and read-only items")
    func packageOwnedActionControlsCompileForBothItemRoles() throws {
        let recorder = SupportConfigurationRecorder()
        let view = SupportView(
            actions: [.featureSuggestion, .version],
            style: RecordingSupportStyle(recorder: recorder)
        )
        _ = view.body

        let actionItem = try #require(recorder.items.first { $0.id == .featureSuggestion })
        let valueItem = try #require(recorder.items.first { $0.id == .version })

        _ = SupportActionRow(actionItem) { Text($0.title) }.body
        _ = SupportActionLink(actionItem) { Text($0.title) }.body
        _ = SupportActionRow(valueItem) { Text($0.title) }.body
        _ = SupportActionLink(valueItem) { Text($0.title) }.body
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
        recorder.items = configuration.items
        recorder.actions = recorder.items.map(\.id)
        return EmptyView()
    }
}
