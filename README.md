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

## Placement

The host owns settings layout, while the package owns each action and its placement
classification. Render `.primary` actions directly on the host's first-level settings page,
then render `.secondary` actions on a separate support page:

```swift
import SupportKit

SupportKit.SupportView(
    placement: .primary,
    style: AppSettingsSupportStyle()
)

NavigationLink("Support") {
    SupportKit.SupportView(placement: .secondary)
}
```

`SupportView(placement:)` filters groups before handing them to the style and removes empty
groups. Styles therefore render only the requested level and do not duplicate package action
catalogs or placement logic. The unfiltered `SupportView()` initializer remains temporarily
available for source compatibility but is deprecated; new integrations must construct both
explicit placements.

The default `SystemSupportStyle` uses native `List` and `Section` components without decorative
leading icons on the secondary support page. Feature Suggestions and Problem Feedback are
separate primary actions; each lets the user choose between a public App Store review and a
private email with the appropriate subject, prompt, and device diagnostics.

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

SupportKit.SupportView(
    placement: .secondary,
    style: BrandSupportStyle()
)
```

Styles receive already-localized display values and package-owned action closures. Interactive
items must call `perform`; a `nil` closure denotes a read-only value such as the app version.
URLs, mail presentation, clipboard behavior, and fallbacks remain inside the package.
Styles can render `suggestedIcon` to use package-owned brand artwork while retaining full
control over sizing and layout. `suggestedSystemImage` remains available as a fallback.

Each item also exposes `recommendedPlacement`. Feedback, rating, sharing, WeChat, and
Xiaohongshu belong to `.primary`; website, legal links, and version belong to `.secondary`.
Unknown future actions default to the secondary level so package updates cannot silently add a
new first-level settings action.

### Migrating from 1.1.x

Replace the unfiltered `SupportView()` with two explicit surfaces: render
`SupportView(placement: .primary, style: ...)` in the first-level settings page and navigate to
`SupportView(placement: .secondary)` for the remaining support information. The package keeps
the action catalog and placement split consistent across both surfaces.

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
