import Foundation
import Testing
@testable import SupportKit

@Suite("Support host catalog")
struct SupportHostCatalogTests {
    @Test("Known App Store hosts resolve their public product pages")
    func knownHostResolvesAppStoreURLs() {
        let host = SupportHostCatalog.host(for: "weisenjoytech.mono-finance")

        #expect(host?.appStoreID == "6670716062")
        #expect(host?.appStoreURL?.absoluteString == "https://apps.apple.com/app/id6670716062")
        #expect(
            host?.reviewURL?.absoluteString
                == "https://apps.apple.com/app/id6670716062?action=write-review"
        )
    }

    @Test("Registered unpublished hosts omit App Store actions")
    func unpublishedHostOmitsAppStoreActions() {
        let host = SupportHostCatalog.host(for: "com.linliao.KneeCue")

        #expect(host != nil)
        #expect(host?.appStoreURL == nil)
        #expect(host?.reviewURL == nil)
    }

    @Test("Unknown hosts fail closed")
    func unknownHostFailsClosed() {
        #expect(SupportHostCatalog.host(for: "com.example.unknown") == nil)
    }
}
