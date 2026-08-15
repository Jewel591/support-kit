# SupportKit

Public Swift Package for the studio's fixed support and contact surfaces on iOS.

## Product boundary

- The package owns the support email, WeChat ID, Xiaohongshu profile, studio website,
  privacy/EULA destinations, host Bundle ID catalog, App Store links, diagnostics,
  localization, action behavior, fallbacks, and optional SwiftUI surface.
- Host apps own placement and entry navigation. They may replace rendering through
  `SupportStyle`, but must invoke the actions supplied by `SupportStyleConfiguration`.
- App identity and contact destinations are not external parameters. Unknown hosts keep
  contact/legal actions but fail closed by hiding App Store rating and sharing actions.
- Never add secrets, API tokens, user identifiers, account email addresses, or private
  diagnostics to this public repository or to feedback templates.

## Engineering

- Swift 6 strict concurrency; iOS 17 public API.
- Use English source literals and the package String Catalog for user-visible strings.
- Standard UI uses system navigation, lists, sections, semantic text styles, controls,
  and adaptive colors. Secondary-page rows do not add decorative leading icons.
- Do not depend on a host app, analytics SDK, purchase SDK, or third-party UI package.
- Contact/catalog changes and URL fallbacks require focused unit tests.
