import Foundation

struct FeedbackFollowUpPreference {
    private static let followedKey = "SupportKit.hasFollowedXiaohongshuAfterFeedback"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var shouldPrompt: Bool {
        !defaults.bool(forKey: Self.followedKey)
    }

    func markFollowed() {
        defaults.set(true, forKey: Self.followedKey)
    }
}
