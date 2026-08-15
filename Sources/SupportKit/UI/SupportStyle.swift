import SwiftUI

public struct SupportAction: RawRepresentable, Hashable, Identifiable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public var id: String { rawValue }

    public static let featureSuggestion = Self(rawValue: "featureSuggestion")
    public static let emailFeedback = Self(rawValue: "emailFeedback")
    public static let problemFeedback = emailFeedback
    public static let copyWeChatID = Self(rawValue: "copyWeChatID")
    public static let xiaohongshu = Self(rawValue: "xiaohongshu")
    public static let officialWebsite = Self(rawValue: "officialWebsite")
    public static let rateApp = Self(rawValue: "rateApp")
    public static let shareApp = Self(rawValue: "shareApp")
    public static let privacyPolicy = Self(rawValue: "privacyPolicy")
    public static let termsOfUse = Self(rawValue: "termsOfUse")
    public static let version = Self(rawValue: "version")

    /// The package's recommended information-hierarchy placement for this action.
    ///
    /// Hosts may override this recommendation to fit their own settings structure.
    /// Unknown future actions default to the secondary level so package updates do not
    /// unexpectedly add prominent rows to an app's root settings page.
    public var recommendedPlacement: SupportPlacement {
        switch self {
        case .featureSuggestion, .emailFeedback, .copyWeChatID, .xiaohongshu,
            .rateApp, .shareApp:
            .primary
        default:
            .secondary
        }
    }
}

public struct SupportPlacement: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Recommended for important actions shown directly on the host settings page.
    public static let primary = Self(rawValue: "primary")

    /// Recommended for lower-frequency actions shown on a secondary support/about page.
    public static let secondary = Self(rawValue: "secondary")
}

public struct SupportAccessory: Hashable, Sendable {
    public let identifier: String
    public let valueText: String?

    public init(identifier: String, valueText: String? = nil) {
        self.identifier = identifier
        self.valueText = valueText
    }

    public static let disclosure = Self(identifier: "disclosure")
    public static let externalLink = Self(identifier: "externalLink")
    public static let copy = Self(identifier: "copy")
    public static let share = Self(identifier: "share")

    public static func value(_ value: String) -> Self {
        Self(identifier: "value", valueText: value)
    }
}

@MainActor
public struct SupportStyleConfiguration {
    public struct Group: Identifiable {
        public let id: String
        public let title: String
        public let items: [Item]

        init(id: String, title: String, items: [Item]) {
            self.id = id
            self.title = title
            self.items = items
        }
    }

    public struct Item: Identifiable {
        public let id: SupportAction
        public let title: String
        /// A package-owned icon that custom styles can size and shape for their UI.
        public let suggestedIcon: Image
        public let suggestedSystemImage: String
        public let recommendedPlacement: SupportPlacement
        public let accessory: SupportAccessory
        public let perform: (@MainActor () -> Void)?

        init(
            id: SupportAction,
            title: String,
            suggestedIcon: Image,
            suggestedSystemImage: String,
            recommendedPlacement: SupportPlacement,
            accessory: SupportAccessory,
            perform: (@MainActor () -> Void)?
        ) {
            self.id = id
            self.title = title
            self.suggestedIcon = suggestedIcon
            self.suggestedSystemImage = suggestedSystemImage
            self.recommendedPlacement = recommendedPlacement
            self.accessory = accessory
            self.perform = perform
        }
    }

    public let navigationTitle: String
    public let groups: [Group]

    init(navigationTitle: String, groups: [Group]) {
        self.navigationTitle = navigationTitle
        self.groups = groups
    }
}

@MainActor
public protocol SupportStyle {
    associatedtype Body: View

    @ViewBuilder
    func makeBody(configuration: SupportStyleConfiguration) -> Body
}

public struct SystemSupportStyle: SupportStyle {
    public init() {}

    public func makeBody(configuration: SupportStyleConfiguration) -> some View {
        List {
            ForEach(configuration.groups) { group in
                Section(group.title) {
                    ForEach(group.items) { item in
                        if let perform = item.perform {
                            Button(action: perform) {
                                row(item)
                            }
                            .buttonStyle(.plain)
                        } else {
                            row(item)
                        }
                    }
                }
            }
        }
        .navigationTitle(configuration.navigationTitle)
    }

    private func row(_ item: SupportStyleConfiguration.Item) -> some View {
        HStack {
            Text(item.title)
                .foregroundStyle(.primary)

            Spacer()

            accessory(item.accessory)
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func accessory(_ accessory: SupportAccessory) -> some View {
        if accessory == .disclosure {
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        } else if accessory == .externalLink {
            Image(systemName: "arrow.up.right")
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        } else if accessory == .copy {
            Image(systemName: "doc.on.doc")
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        } else if accessory == .share {
            Image(systemName: "square.and.arrow.up")
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        } else if let value = accessory.valueText {
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
