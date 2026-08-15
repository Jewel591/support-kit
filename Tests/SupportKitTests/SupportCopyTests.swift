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

    @Test
    func appStoreReviewAvoidsPublicDisclosureLanguageInEverySupportedLocale() {
        let expected = [
            "en": "Leave a Review on the App Store",
            "de": "Rezension im App Store verfassen",
            "es": "Escribir una reseña en el App Store",
            "fr": "Laisser un avis sur l’App Store",
            "ja": "App Storeにレビューを投稿",
            "ko": "App Store에 리뷰 남기기",
            "pt-BR": "Deixar uma avaliação na App Store",
            "zh-Hans": "在 App Store 留言",
            "zh-Hant": "在 App Store 留言",
        ]

        for (identifier, copy) in expected {
            #expect(SupportCopy.appStoreReview(locale: Locale(identifier: identifier)) == copy)
        }
    }

    @Test
    func feedbackExplanationSetsTheExpectedResponseExpectationInEverySupportedLocale() {
        let expected = [
            "en": "We regularly read and respond to App Store reviews.",
            "de": "Wir lesen und beantworten regelmäßig App-Store-Rezensionen.",
            "es": "Revisamos periódicamente las reseñas del App Store y respondemos a ellas.",
            "fr": "Nous consultons régulièrement les avis sur l’App Store et y répondons.",
            "ja": "App Storeのレビューを定期的に確認し、返信しています。",
            "ko": "App Store 리뷰를 정기적으로 확인하고 답변드리고 있습니다.",
            "pt-BR": "Lemos regularmente as avaliações na App Store e respondemos a elas.",
            "zh-Hans": "我们会定期查看并回复 App Store 评论。",
            "zh-Hant": "我們會定期查看並回覆 App Store 評論。",
        ]

        for (identifier, copy) in expected {
            #expect(
                SupportCopy.feedbackChannelExplanation(
                    locale: Locale(identifier: identifier)
                ) == copy
            )
        }
    }
}
