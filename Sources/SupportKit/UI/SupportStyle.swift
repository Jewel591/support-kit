import SwiftUI

public enum SupportAction: String, Identifiable, Sendable {
    case featureSuggestion
    case problemFeedback
    case emailFeedback
    case copyWeChatID
    case xiaohongshu
    case officialWebsite
    case rateApp
    case shareApp
    case privacyPolicy
    case termsOfUse
    case version

    public var id: String { rawValue }
}

public enum SupportAccessory: Sendable {
    case disclosure
    case externalLink
    case copy
    case share
    case value(String)
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
        public let suggestedSystemImage: String
        public let accessory: SupportAccessory
        public let perform: (@MainActor () -> Void)?

        init(
            id: SupportAction,
            title: String,
            suggestedSystemImage: String,
            accessory: SupportAccessory,
            perform: (@MainActor () -> Void)?
        ) {
            self.id = id
            self.title = title
            self.suggestedSystemImage = suggestedSystemImage
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
        switch accessory {
        case .disclosure:
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        case .externalLink:
            Image(systemName: "arrow.up.right")
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        case .copy:
            Image(systemName: "doc.on.doc")
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        case .share:
            Image(systemName: "square.and.arrow.up")
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        case .value(let value):
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
