# SupportKit

`SupportKit` is a public Swift Package for the fixed support and contact surfaces shared by
Weisenjoy iOS apps. It centralizes contact channels, legal links, feedback diagnostics,
App Store actions, localization, and fallback behavior while allowing each app to render the
page in its own visual language.

## Installation

Add `https://github.com/Jewel591/support-kit` with **Up to Next Major Version**. Do not use an
exact version, branch, or revision. App and Xcode Cloud projects should commit their normal
`Package.resolved` file for reproducible builds; the dependency declaration must still remain
an automatically compatible version range.

## Standard UI

The host owns the settings row and navigation placement:

```swift
import SupportKit

NavigationLink("Contact Us") {
    SupportKit.SupportView()
}
```

The standard style uses native `List` and `Section` components without decorative leading
icons on the secondary support page. It presents separate Feature Suggestions and Problem
Feedback entries; each lets the user choose between a public App Store review and a private
email with the appropriate subject, prompt, and device diagnostics.

## Custom UI

Implement `SupportStyle` to replace the entire page rendering without copying contact data or
action behavior:

```swift
struct BrandSupportStyle: SupportStyle {
    func makeBody(configuration: SupportStyleConfiguration) -> some View {
        ScrollView {
            ForEach(configuration.groups) { group in
                VStack {
                    Text(group.title)
                    ForEach(group.items) { item in
                        if let perform = item.perform {
                            Button(action: perform) {
                                Text(item.title)
                            }
                        } else {
                            Text(item.title)
                        }
                    }
                }
            }
        }
        .navigationTitle(configuration.navigationTitle)
    }
}

SupportKit.SupportView(style: BrandSupportStyle())
```

Styles receive already-localized display values and package-owned action closures. Interactive
items must call `perform`; a `nil` closure denotes a read-only value such as the app version.
URLs, mail presentation, clipboard behavior, and fallbacks remain inside the package.
Styles can render `suggestedIcon` to use package-owned brand artwork while retaining full
control over sizing and layout. `suggestedSystemImage` remains available as a fallback.

Each item also exposes `recommendedPlacement`. Feedback, rating, sharing, WeChat, and
Xiaohongshu are recommended for `.primary` placement; website, legal links, and version are
recommended for `.secondary` placement. This is information-hierarchy guidance rather than a
navigation requirement: host styles may override it, and unknown future actions default to the
secondary level.

`SupportAction` and `SupportAccessory` are extensible value tokens. Compare known values and
provide a fallback for unknown ones instead of exhaustively switching over package UI metadata.
For compatibility with the original generic feedback row, Problem Feedback keeps the
`.emailFeedback` action identity; `.problemFeedback` is an equivalent descriptive spelling.

### Migrating from 0.1.x

Version 1.0 replaces the original closed `SupportAction` and `SupportAccessory` enums with the
extensible tokens above. Apps that only construct `SupportView()` need no source changes.
Custom styles should replace exhaustive enum switches and associated-value matching with token
comparisons, read `valueText` for value accessories, and provide a fallback for future tokens.
This change is released as a new major version so existing `0.1.x` package ranges do not adopt it
without an explicit host migration.

## Fixed public destinations

- Feedback: `support@weisenjoy.com`
- WeChat: `ivensliao007`
- Xiaohongshu: Ivens' public profile
- Website: reserved but hidden while the new site is under construction
- Privacy: `https://www.weisenjoy.com/privacy`
- Terms: Apple's standard EULA

## Requirements

- iOS 17+
- Swift 6
