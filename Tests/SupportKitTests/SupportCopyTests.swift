import Foundation
import Testing
@testable import SupportKit

struct SupportCopyTests {
    @Test
    func fiveStarRatingUsesInvitationalCopyInEverySupportedLocale() {
        let expected = [
            "en": "Give Us a 5-Star Rating",
            "de": "Gib uns 5 Sterne",
            "es": "Danos 5 estrellas",
            "fr": "Donnez-nous 5 étoiles",
            "ja": "星5つで評価する",
            "ko": "별 5개로 평가해 주세요",
            "pt-BR": "Avalie-nos com 5 estrelas",
            "zh-Hans": "给我们 5 星好评",
            "zh-Hant": "給我們 5 星好評",
        ]

        for (identifier, copy) in expected {
            #expect(SupportCopy.fiveStarRating(locale: Locale(identifier: identifier)) == copy)
        }
    }
}
