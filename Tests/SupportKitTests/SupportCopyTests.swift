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
    func feedbackExplanationSetsTheExpectedResponseExpectationInEverySupportedLocale() {
        let expected = [
            "en": "We regularly read and respond to App Store reviews. Email is best for details and device diagnostics.",
            "de": "Wir lesen und beantworten regelmäßig App-Store-Rezensionen. Für Details und Gerätediagnosen ist E-Mail am besten geeignet.",
            "es": "Revisamos periódicamente las reseñas del App Store y respondemos a ellas. El correo es la mejor opción para enviar detalles y diagnósticos del dispositivo.",
            "fr": "Nous consultons régulièrement les avis sur l’App Store et y répondons. L’e-mail est préférable pour partager des détails et des diagnostics de l’appareil.",
            "ja": "App Storeのレビューを定期的に確認し、返信しています。詳しい内容やデバイスの診断情報をお送りいただく場合は、メールが適しています。",
            "ko": "App Store 리뷰를 정기적으로 확인하고 답변드리고 있습니다. 자세한 내용과 기기 진단 정보를 보내실 때는 이메일이 가장 적합합니다.",
            "pt-BR": "Lemos regularmente as avaliações na App Store e respondemos a elas. O e-mail é a melhor opção para enviar detalhes e diagnósticos do dispositivo.",
            "zh-Hans": "我们会定期查看并回复 App Store 评论。若要提供详细信息和设备诊断，使用邮件更合适。",
            "zh-Hant": "我們會定期查看並回覆 App Store 評論。若要提供詳細資訊和裝置診斷，使用電郵較合適。",
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
