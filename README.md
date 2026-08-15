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
icons on the secondary support page.

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

## Fixed public destinations

- Feedback: `support@weisenjoy.com`
- WeChat: `ivensliao007`
- Xiaohongshu: the studio's public profile
- Website: `https://www.weisenjoy.com/`
- Privacy: `https://www.weisenjoy.com/privacy`
- Terms: Apple's standard EULA

## Requirements

- iOS 17+
- Swift 6
