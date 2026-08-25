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

/// Package-provided display metadata available only while building a package-owned control.
public struct SupportActionContent {
    public let title: String
    /// A package-owned icon prepared for custom styles to place in a bounded frame.
    ///
    /// SF Symbols remain template images and respond to `font` and `foregroundStyle`.
    /// Full-color brand artwork is already original-rendered and resizable, so custom
    /// styles should not force a rendering mode or call `resizable()` themselves.
    public let suggestedIcon: Image
    public let suggestedSystemImage: String
    public let accessory: SupportAccessory

    init(
        title: String,
        suggestedIcon: Image,
        suggestedSystemImage: String,
        accessory: SupportAccessory
    ) {
        self.title = title
        self.suggestedIcon = suggestedIcon
        self.suggestedSystemImage = suggestedSystemImage
        self.accessory = accessory
    }
}

@MainActor
public struct SupportStyleConfiguration {
    struct Group: Identifiable {
        let id: String
        let title: String
        let items: [Item]

        init(id: String, title: String, items: [Item]) {
            self.id = id
            self.title = title
            self.items = items
        }
    }

    public struct Item: Identifiable {
        public let id: SupportAction
        let content: SupportActionContent
        let handler: (@MainActor () -> Void)?

        init(
            id: SupportAction,
            title: String,
            suggestedIcon: Image,
            suggestedSystemImage: String,
            accessory: SupportAccessory,
            handler: (@MainActor () -> Void)?
        ) {
            self.id = id
            content = SupportActionContent(
                title: title,
                suggestedIcon: suggestedIcon,
                suggestedSystemImage: suggestedSystemImage,
                accessory: accessory
            )
            self.handler = handler
        }
    }

    public let navigationTitle: String
    /// The actions selected for this surface, in the order requested by the host.
    public let items: [Item]
    let groups: [Group]

    init(navigationTitle: String, groups: [Group]) {
        self.navigationTitle = navigationTitle
        items = groups.flatMap(\.items)
        self.groups = groups
    }

    private init(navigationTitle: String, items: [Item], groups: [Group]) {
        self.navigationTitle = navigationTitle
        self.items = items
        self.groups = groups
    }

    func selecting(_ actions: [SupportAction]) -> Self {
        var seenActions = Set<SupportAction>()
        var selectedItems: [Item] = []
        var selectedGroupIDs: [String] = []
        var selectedItemsByGroupID: [String: [Item]] = [:]

        for action in actions where seenActions.insert(action).inserted {
            guard let group = groups.first(where: { group in
                group.items.contains(where: { $0.id == action })
            }), let item = group.items.first(where: { $0.id == action }) else {
                continue
            }

            if selectedItemsByGroupID[group.id] == nil {
                selectedGroupIDs.append(group.id)
            }
            selectedItems.append(item)
            selectedItemsByGroupID[group.id, default: []].append(item)
        }

        let selectedGroups = selectedGroupIDs.compactMap { groupID -> Group? in
            guard let sourceGroup = groups.first(where: { $0.id == groupID }),
                  let selectedItems = selectedItemsByGroupID[groupID]
            else {
                return nil
            }
            return Group(
                id: sourceGroup.id,
                title: sourceGroup.title,
                items: selectedItems
            )
        }

        return Self(
            navigationTitle: navigationTitle,
            items: selectedItems,
            groups: selectedGroups
        )
    }
}

@MainActor
public protocol SupportStyle {
    associatedtype Body: View

    @ViewBuilder
    func makeBody(configuration: SupportStyleConfiguration) -> Body
}

/// A package-owned support control for settings and list rows.
///
/// The label remains entirely host-defined, while SupportKit owns whether the item is
/// interactive, which action runs, and the full-width rectangular interaction region.
public struct SupportActionRow<Label: View>: View {
    private let item: SupportStyleConfiguration.Item
    private let label: Label

    public init(
        _ item: SupportStyleConfiguration.Item,
        @ViewBuilder label: (SupportActionContent) -> Label
    ) {
        self.item = item
        self.label = label(item.content)
    }

    public var body: some View {
        if let handler = item.handler {
            Button(action: handler) {
                content
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }

    private var content: some View {
        label
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.interaction, Rectangle())
    }
}

/// A package-owned support control for compact inline links.
///
/// Unlike ``SupportActionRow``, this control keeps the label's intrinsic width so adjacent
/// links do not compete for or overlap one another's interaction regions.
public struct SupportActionLink<Label: View>: View {
    private let item: SupportStyleConfiguration.Item
    private let label: Label

    public init(
        _ item: SupportStyleConfiguration.Item,
        @ViewBuilder label: (SupportActionContent) -> Label
    ) {
        self.item = item
        self.label = label(item.content)
    }

    public var body: some View {
        if let handler = item.handler {
            Button(action: handler) {
                content
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }

    private var content: some View {
        label.contentShape(.interaction, Rectangle())
    }
}

public struct SystemSupportStyle: SupportStyle {
    public init() {}

    public func makeBody(configuration: SupportStyleConfiguration) -> some View {
        List {
            ForEach(configuration.groups) { group in
                Section(group.title) {
                    ForEach(group.items) { item in
                        SupportActionRow(item) { content in
                            row(content)
                        }
                    }
                }
            }
        }
        .navigationTitle(configuration.navigationTitle)
    }

    private func row(_ content: SupportActionContent) -> some View {
        HStack {
            Text(content.title)
                .foregroundStyle(.primary)

            Spacer()

            accessory(content.accessory)
        }
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
