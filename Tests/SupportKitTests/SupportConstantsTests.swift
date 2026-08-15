import Testing
@testable import SupportKit

@Suite("Fixed support destinations")
struct SupportConstantsTests {
    @Test("Contact and legal destinations stay canonical")
    func canonicalDestinations() {
        #expect(SupportConstants.feedbackEmail == "support@weisenjoy.com")
        #expect(SupportConstants.weChatID == "ivensliao007")
        #expect(SupportConstants.studioWebsite?.absoluteString == "https://www.weisenjoy.com/")
        #expect(SupportConstants.privacyPolicy?.absoluteString == "https://www.weisenjoy.com/privacy")
        #expect(
            SupportConstants.termsOfUse?.absoluteString
                == "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
        )
    }

    @Test("Xiaohongshu app fallback points to the same public profile")
    func xiaohongshuDestinations() {
        #expect(
            SupportConstants.xiaohongshuApp?.absoluteString
                == "xhsdiscover://user/60c7398e0000000001005786"
        )
        #expect(
            SupportConstants.xiaohongshuWeb?.absoluteString
                == "https://www.xiaohongshu.com/user/profile/60c7398e0000000001005786"
        )
    }
}
