import Foundation
import UIKit

struct SupportAppInfo: Equatable {
    let name: String
    let version: String
    let build: String
    let systemVersion: String
    let hardwareModel: String
    let localeIdentifier: String

    static var current: SupportAppInfo {
        SupportAppInfo(
            name: Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
                ?? "App",
            version: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
                as? String ?? "unknown",
            build: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
                ?? "unknown",
            systemVersion: "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)",
            hardwareModel: resolvedHardwareModel(),
            localeIdentifier: Locale.current.identifier
        )
    }

    private static func resolvedHardwareModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingCString: $0) ?? "unknown"
            }
        }
    }
}
