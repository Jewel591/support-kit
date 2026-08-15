import Foundation
import OSLog

struct SupportHost: Equatable, Sendable {
    let bundleIdentifier: String
    let appStoreID: String?

    var appStoreURL: URL? {
        guard let appStoreID else { return nil }
        return URL(string: "https://apps.apple.com/app/id\(appStoreID)")
    }

    var reviewURL: URL? {
        guard let appStoreID else { return nil }
        return URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")
    }
}

enum SupportHostCatalog {
    private static let logger = Logger(
        subsystem: "com.weisenjoy.SupportKit",
        category: "HostCatalog"
    )

    private static let entries = [
        SupportHost(bundleIdentifier: "weisenjoytech.mono-finance", appStoreID: "6670716062"),
        SupportHost(bundleIdentifier: "com.weisenjoytech.CodeCat", appStoreID: "6749771947"),
        SupportHost(bundleIdentifier: "weisenjoytech.Filmo", appStoreID: "6741805793"),
        SupportHost(bundleIdentifier: "com.linliao.SupaMate", appStoreID: "6791957298"),
        SupportHost(bundleIdentifier: "com.linliao.LastTime", appStoreID: "6762844702"),
        SupportHost(bundleIdentifier: "com.liaolin.apper", appStoreID: "6792308429"),
        SupportHost(bundleIdentifier: "com.linliao.KneeCue", appStoreID: nil),
        SupportHost(bundleIdentifier: "com.linliao.Wobink", appStoreID: nil),
    ]

    static func host(for bundleIdentifier: String) -> SupportHost? {
        entries.first { $0.bundleIdentifier == bundleIdentifier }
    }

    static var currentHost: SupportHost? {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            logger.error("Host bundle identifier is unavailable")
            return nil
        }
        guard let host = host(for: bundleIdentifier) else {
            logger.error("Unknown host bundle identifier: \(bundleIdentifier, privacy: .public)")
            return nil
        }
        return host
    }
}
