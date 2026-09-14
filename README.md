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

## Information architecture

Each app owns where support actions appear. Select the actions for each surface explicitly;
SupportKit keeps the action implementation, availability, localization, and fallbacks:

```swift
import SupportKit

SupportKit.SupportView(
    actions: [
        .featureSuggestion,
        .problemFeedback,
        .rateApp,
        .shareApp,
    ],
    style: AppSettingsSupportStyle()
)

NavigationLink("Support") {
    SupportKit.SupportView(
        actions: [.privacyPolicy, .termsOfUse, .version]
    )
}
```

`SupportView(actions:)` omits unknown or unavailable actions, ignores duplicate identifiers after
their first occurrence, and hands the public item sequence to the style in host-requested order.
Use `SupportView()` when a page should show the complete catalog. SupportKit deliberately has no
primary/secondary classification: first-level versus secondary-page placement is a product UI
decision, not a package behavior rule.

默认 `SystemSupportStyle` 使用系统 `List` 和 `Section`，不添加装饰性前置图标。
功能建议与问题反馈是两个独立动作，均直接打开邮件，并按反馈类型填写主题、提示和设备信息。

### 当前错误的诊断信息

错误页可以通过 `feedbackDiagnostics` 提供当前错误快照，让用户从该页直接反馈：

```swift
SupportKit.SupportView(
    actions: [.problemFeedback],
    feedbackDiagnostics: failureDiagnostics,
    style: AppSettingsSupportStyle()
)
```

该参数默认为 `nil`，只补充问题反馈的邮件正文；功能建议和既有入口保持原行为。
系统邮件编辑器与 `mailto` 降级使用相同正文，用户确认发送后才会发出邮件。
宿主只提供已取得的技术诊断快照，不包含账号、凭据或用户业务内容；Kit 不读取宿主数据库、
日志文件或附件。无需自定义样式时，也可使用 `SupportView(actions:feedbackDiagnostics:)`。

## Custom UI

Implement `SupportStyle` to replace the entire page rendering without copying contact data or
action behavior:

```swift
struct BrandSupportStyle: SupportStyle {
    func makeBody(configuration: SupportStyleConfiguration) -> some View {
        ScrollView {
            VStack {
                ForEach(configuration.items) { item in
                    SupportActionRow(item) { content in
                        Text(content.title)
                    }
                }
            }
        }
        .navigationTitle(configuration.navigationTitle)
    }
}

SupportKit.SupportView(
    actions: [.privacyPolicy, .termsOfUse, .version],
    style: BrandSupportStyle()
)
```

Styles receive already-localized display values but never receive action closures. Use
`SupportActionRow` for a full-width settings/list row and `SupportActionLink` for a compact inline
link. Both controls create the Button, execute the package action, and preserve read-only items
such as the app version as static content. A custom style owns only the label visuals; URLs, mail
presentation, clipboard behavior, hit regions, and fallbacks remain inside the package.
Styles should render `suggestedIcon` directly to use package-owned symbols and brand artwork
while retaining control over its bounded frame and surrounding layout:

```swift
item.suggestedIcon
    .font(.title3)
    .foregroundStyle(.tint)
    .frame(width: 36, height: 36)
```

`suggestedIcon` is prepared by SupportKit for this uniform call site: SF Symbols remain template
images and respond to `font` / `foregroundStyle`, while full-color brand artwork is already
original-rendered and resizable. Do not call `.resizable()` or force `.renderingMode(.template)`
in a custom style; doing so either enlarges SF Symbols unexpectedly or destroys brand colors.
`suggestedSystemImage` remains available only as a fallback when an app intentionally chooses
not to display package-owned brand artwork.

### Migrating from 1.x

Version 2.0 removes `SupportPlacement`, `recommendedPlacement`, `SupportView(placement:)`, and
the public `Item.perform` closure. Replace each placement with the App's explicit action list.
Custom styles may iterate `configuration.groups` to preserve SupportKit's localized semantic
sections or `configuration.items` to organize actions themselves; every label must be wrapped in
`SupportActionRow` or `SupportActionLink`, never a host-created Button. Apps that already use the
complete `SupportView()` only need to update their minimum compatible version and refresh
`Package.resolved`.

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
