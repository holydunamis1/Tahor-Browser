# Tahor Fast & Private Browser: Final Production Blueprint

This is the single, complete blueprint, written as one sequence: product, verified decisions, design system, architecture, process, features, a 59-batch plan, then every file of every batch in dependency order with what it contains, what it does in the app, what it connects to, and the exact commands to run. It replaces every earlier draft. It has no appendices and no deferred items: every version pin, platform fact and rule below was checked before it was written.

**Corrections made in this edition:** the old draft tail is deleted; `google_mobile_ads` is pinned at exactly 9.1.0; milestones are counted as 14 including M0; B22a lists 8 files (317 files in total); Cast depends on B22a and B20, not on Translate; `verify.yml` on `batch/**` pushes is decision D-05, approved.

**Adaptations in this copy (2026-11-01), all recorded in `docs/DECISIONS.md`:** `[account]` is `zdmgold` (D-31); the product name is "Tahor Fast & Private Browser" everywhere, including the home screen (D-32); the batch loop in section 6.6 is run by the build agent, which pushes `batch/bN`, waits for `verify` and squash-merges through the API (D-33); two installable test APKs are produced, after B13 and after B39 (D-34), delivered as GitHub pre-release assets (D-35); the website is served by a Cloudflare Worker with static assets configured by `wrangler.jsonc` (D-45); `package_info_plus` is 10.2.2 and `intl` is 0.20.3 (D-40); Termux is optional for reading the repository because the agent builds in its own sandbox; ad units use Google's published sample IDs for the whole build and the store accounts are created after the app is complete (D-44).

## 1. Product and scope

Tahor Fast & Private Browser is a privacy-first browser for Android and iPhone with on-device ad blocking, no accounts and no analytics of our own, built in Flutter on the system web engines (Android WebView and iOS WebKit).

| Field | Value |
| --- | --- |
| Product name | Tahor Fast & Private Browser (store title, Android label and iOS display name) |
| Dart package | `tahorbrowser` |
| Reverse-DNS identifier | `com.zdmgold.tahorbrowser`, immutable after the first release |
| Category | Utilities / Browser |
| One-line description | A privacy-first browser with built-in on-device ad blocking, no accounts, no analytics from us, and an honest escape to the system browser when a site refuses embedded web views. |
| Platforms | Android API 24 and later; iPhone only, iOS 15.5 and later (the translation plugin sets the floor); web is a static marketing site only |
| Toolchain | Flutter 3.47.7 (Dart 3.13.5) pinned in `tool/flutter_version.txt`; SDK constraint `^3.13.0` |
| Theme | System default, manual toggle, persisted |
| Orientation | Portrait and landscape on phones |
| Notifications | Download progress only; no push messages and no retention loop |
| Sensors | Camera, microphone and location only through per-site prompts; camera for QR scanning; local network for Cast |
| Accounts, sync, backend | None. Static files only (the blocklist and the website) |
| Monetization | Free with one banner ad; a one-time purchase removes our banner only; no feature is locked |
| Cost floor | $0 monthly; $25 one-time for Google Play; $99 a year for Apple when you are ready to sign |
| Languages | 20: en es fr de pt it nl pl ru uk tr ar hi he ja ko zh vi th id |

### What this version includes

The full list is in section 7. In one line: browsing basics, tabs with session restore, on-device ad blocking, web compatibility (dialogs, permissions, PDF, HTTPS-only, desktop mode, system-browser handoff, find in page, print), downloads with pause and resume, history, bookmarks, private tabs, app lock, reader mode, text and screen comfort, QR, Translate, Add to Home Screen, Cast, consent and ads, a one-time purchase, 20 languages.

### What it does not include

A built-in password manager, remote search suggestions, bookmark import and export, tab groups and sync are outside this version (section 22 records what each would take). Also not built, with no code, permission or marketing claim: VPN, proxy or DNS changes, video download, data saving, gesture and layout editors, custom fonts, scrolling screenshots, a photo editor, text to speech, save-all-images, a block-area picker, Web Push, PWAs, Bluetooth, Widevine L1.

### Honest claims the product may make

- No accounts and no analytics from us. Ads come from Google AdMob; the privacy policy and store labels say what it collects, and iOS shows the tracking prompt.
- About 90% of Chrome's compatibility, with a one-tap escape to the system browser for sites that refuse embedded web views (Google sign-in, some banks).
- Ad blocking works on ordinary sites; in-stream video ads are not blocked. No count of blocked items is claimed because the platform does not report one.
- Dangerous-site warnings come from Google (Android) and Apple (iOS); the policy says visited addresses are checked against their lists.
- Private tabs on Android do not fully separate cookies from normal tabs; the app says so in plain words.
- The first launch downloads the ad-blocking list from our website once, which sees the device's address like any web request.

## 2. Verified decisions

Every plugin and platform assumption was checked against current package pages, changelogs, issue trackers and store policies (October 2026). The findings below fixed the design.

| Area | Finding | Decision |
| --- | --- | --- |
| Flutter | Stable is 3.47.7 with Dart 3.13.5 (October 8, 2026); Material and Cupertino became standalone packages in 3.47; Swift Package Manager is the iOS default since 3.44 ([Shorebird](https://docs.shorebird.dev/getting-started/flutter-version/), [Flutter docs](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui)). | Pin 3.47.7; build the UI on `widgets.dart` only; run `pod install` only if `ios/Podfile` exists. |
| WebView plugin | Stable `flutter_inappwebview` 6.1.5 is two years old; 6.2.0-beta.3 (February 4, 2026) is the only version with `saveState` and `restoreState` on both platforms, Android's file chooser event, Swift Package Manager and the Apple Guideline 2.5.1 fix; its iOS package analyzes cleanly on Flutter 3.47 ([release](https://github.com/pichillilorenzo/flutter_inappwebview/releases/tag/v6.2.0-beta.3), [pana](https://pub.dev/packages/flutter_inappwebview_ios/versions/1.2.0-beta.3/score)). | Pin 6.2.0-beta.3 exactly; no forks. |
| Content blockers | Block, css-display-none and make-https work on Android and iOS; ignore-previous-rules and block-cookies are iOS and macOS only; a 50,000-entry list was reported very laggy on Android; Dart-side `shouldInterceptRequest` was reported to freeze the app ([docs](https://inappwebview.dev/docs/webview/content-blockers/), [issue 1743](https://github.com/pichillilorenzo/flutter_inappwebview/issues/1743), [issue 2580](https://github.com/pichillilorenzo/flutter_inappwebview/issues/2580)). WebKit accepts at most 150,000 rules per list ([Apple forums](https://developer.apple.com/forums/thread/734111)). | Two emitters from one model; Android uses grouped regexes under a 5,000-entry cap, iOS lists split at 50,000; no Dart interception; the B17 performance gate tunes the Android cap by measured load time. |
| Private tabs | Android's plugin `incognito` setting clears every WebView's cookies; profile containers exist only in an unvalidated community fork ([API](https://pub.dev/documentation/flutter_inappwebview/latest/flutter_inappwebview/InAppWebViewSettings/incognito.html)). | Never set it on Android; host-scoped cleanup and honest copy. iOS uses a non-persistent store. |
| Downloads | `background_downloader` 9.5.9 downloads in the background on both platforms (Android workers, iOS background URLSession), supports headers, pause and resume (GET only, `allowPause`, server support checked with `taskCanResume`), notifications, and `moveToSharedStorage` on Android; iOS needs https and the Background Fetch capability; Android 13 needs `POST_NOTIFICATIONS` ([pub](https://pub.dev/packages/background_downloader), [changelog](https://pub.dev/packages/background_downloader/versions/5.4.3/changelog)). | One download engine for both platforms; a foreground Dart downloader only for http URLs on iOS. |
| Find, print, long-press, back/forward | `FindInteractionController` (iOS JS mode reports counts), `printCurrentPage`, `onLongPressHitTestResult` and `getCopyBackForwardList` with `goTo` work on both platforms ([find](https://www.inappwebview.dev/docs/webview/find-interaction-controller), [print](https://pub.dev/documentation/flutter_inappwebview/latest/flutter_inappwebview/InAppWebViewController/printCurrentPage.html), [hit test](https://pub.dev/documentation/flutter_inappwebview/latest/flutter_inappwebview/InAppWebView-class.html), [history list](https://pub.dev/documentation/flutter_inappwebview/latest/flutter_inappwebview/PlatformInAppWebViewController/getCopyBackForwardList.html)). | Custom find bar, link and image menu, back/forward sheet, print row. |
| Pull to refresh | `PullToRefreshController` works on Android (needs `useHybridComposition`; platform spinner) and iOS (system control); only colours are styled ([API](https://pub.dev/documentation/flutter_inappwebview/latest/flutter_inappwebview/PullToRefreshController/PullToRefreshController.html)). | Included; the Android spinner shape is the one platform element in the browser view. |
| Clear data | Cookies and cache clear on both platforms; `WebStorageManager.deleteAllData` is Android only; iOS adds `removeDataModifiedSince` for time ranges ([docs](https://inappwebview.dev/docs/web-storage-manager)). | Time range honoured on iOS; Android clears all time and the sheet says so. |
| Safe Browsing | `safeBrowsingEnabled` (Android 8+) and `isFraudulentWebsiteWarningEnabled` (iOS) default to on; Android's `onSafeBrowsingHit` takes a `SafeBrowsingResponse` ([API](https://pub.dev/documentation/webview_inapp/latest/flutter_inappwebview/SafeBrowsingResponse-class.html)). | On by default with a Privacy switch; answer `SHOW_INTERSTITIAL` with reporting off. |
| Icons | `phosphoricons_flutter` 1.1.0 scores 160/160 and was analyzed on Flutter 3.47.6; Phosphor ships fixed weights ([pub](https://pub.dev/packages/phosphoricons_flutter/versions/1.1.0/score)). | Bold for chrome icons to reach the 2.0 to 2.25 stroke target. |
| PDF | pdfx has no Swift Package Manager support and no release for over a year; pdfrx 2.6.5 needs Flutter 3.47+, bundles PDFium and ships web assets that add size; its viewer widgets need `material_ui` localizations ([pdf\_viewer\_plus](https://pub.dev/packages/pdf_viewer_plus/versions/2.0.0/changelog), [pdfrx](https://pub.dev/packages/pdfrx/versions/2.6.4), [issue 726](https://github.com/espresso3389/pdfrx/issues/726)). `pdfrx_coregraphics` is labelled experimental ([pub](https://pub.dev/documentation/pdfrx_coregraphics/0.4.1/)). | pdfrx's rendering API only, with our own viewer; web assets removed in release builds; PDFium stays on both platforms. |
| QR | `mobile_scanner` 7.1.4: CameraX and ML Kit on Android, Apple Vision on iOS; the Android model can be unbundled through Google Play Services (about 600 KB instead of 3 to 10 MB) with `dev.steenbakker.mobile_scanner.useUnbundled=true` ([pub](https://pub.dev/packages/mobile_scanner)). | Unbundled on Android. |
| Translate | `google_mlkit_translation` 0.15.1 needs iOS 15.5 and Android API 23; both language models must be downloaded first (about 30 MB each, on demand, not part of the app size); a loaded translator uses 30 to 150 MB of memory; `downloadModel` takes `isWifiRequired` ([ML Kit iOS](https://developers.google.com/ml-kit/language/translation/ios), [Android](https://developers.google.com/ml-kit/language/translation/android), [plugin](https://pub.dev/packages/google_mlkit_translation), [installation paths](https://developers.google.com/ml-kit/tips/installation-paths)). | On-device translation; iOS floor 15.5; language detection through `google_mlkit_language_id` 0.14.0. |
| Cast | `flutter_chrome_cast` 1.5.0 initialises with the default receiver (`CC1AD845`, no registration); progressive MP4 casts directly, HLS and DASH need CORS on the media server, protected streams need a custom receiver; only remote URLs can be cast ([README](https://pub.dev/packages/flutter_chrome_cast), [Cast media](https://developers.google.com/cast/docs/media), [rntp](https://www.rntp.dev/docs/casting)). iOS AirPlay for web video is on by default (`allowsAirPlayForMediaPlayback`). | Cast for plain and CORS-enabled media; AirPlay needs no work. |
| Default browser, Add to Home Screen | Android lists a browser with `ACTION_VIEW`, `DEFAULT`, `BROWSABLE` and `http`/`https`, and `RoleManager.ROLE_BROWSER` ([Android](https://developer.android.com/reference/androidx/core/role/RoleManagerCompat)); Android pins website shortcuts with `ShortcutManagerCompat.requestPinShortcut` (API 26+). Apple requires the `com.apple.developer.web-browser` entitlement (request form), `http`/`https` in `Info.plist`, an on-launch URL field, and forbids `NSPhotoLibraryUsageDescription`, `NSLocationAlways...`, HomeKit, Bluetooth-always and HealthKit keys; the same entitlement enables Add to Home Screen by putting the `WKWebView` in a share sheet's `activityItems` ([Apple](https://developer.apple.com/documentation/xcode/preparing-your-app-to-be-the-default-browser)). Platform views join the view hierarchy, so the web view is found by searching it ([Flutter](https://docs.flutter.dev/platform-integration/ios/platform-views)). Flutter's deep-link handling is switched off with `flutter_deeplinking_enabled` and `FlutterDeepLinkingEnabled` ([docs](https://docs.flutter.dev/ui/navigation/deep-linking)). | Both features built; iOS parts ship once Apple grants the entitlement. |
| Passwords | Android's WebView uses the system autofill service; iOS `WKWebView` Password AutoFill fills only for associated domains and does not save ([Apple forums](https://developer.apple.com/forums/thread/654338)). | No built-in password manager in this version; sign-in through the system-browser handoff. |
| Ads and consent | `google_mobile_ads` 9.1.0 is published (GitHub release v9.1.0, August 12, and the pub changelog); 9.x needs Dart 3.10 and Flutter 3.38.1+; UMP debug settings include a regulated US state; AdMob on iOS cannot avoid the ATT prompt ([releases](https://github.com/googleads/googleads-mobile-flutter/releases), [changelog](https://pub.dev/packages/google_mobile_ads/changelog), [AdMob forum](https://groups.google.com/g/google-admob-ads-sdk/c/0fE-R87OA8c)). | Pin 9.1.0 exactly; UMP plus ATT on iOS; non-personalized ads without consent; tracking declared in the labels. |
| Store rules | Google Play forbids downloading executable code (dex, JAR, `.so`) and Apple forbids downloading or installing it ([Play policy](https://support.google.com/googleplay/android-developer/answer/9888379?hl=en)). Personal Play accounts created after November 13, 2023 need a closed test with 12 testers for 14 continuous days ([Choicely](https://www.choicely.com/blog/google-play-12-tester-rule)). | Native libraries ship in the binary, data downloads on first use; the closed test starts after M6. |
| CI | Codemagic's free tier is 500 macOS M2 minutes a month, one build at a time, personal accounts only ([pricing](https://docs.codemagic.io/billing/pricing/)). | Five iOS checkpoint builds of about 20 minutes. |
| Licences | EasyList is dual-licensed GPLv3-or-later and CC BY-SA 3.0-or-later with attribution to its authors ([licence](https://easylist.to/pages/licence.html)). | The converted list is published openly with attribution. |

## 3. Design system

The interface is one iOS-grade design language on both platforms, built only on `package:flutter/widgets.dart`, our own tokens and our own components: no Material, no Cupertino, no `material_ui`, no `cupertino_ui`. Flutter keeps the raw primitives (`EditableText`, `WidgetsApp`, routes, overlays) and design systems are ordinary packages; [brutalist\_ui](https://pub.dev/packages/brutalist_ui) is a published example with its own text-selection controls. The cost is that we write what Material would have supplied (text field, selection menu, page route, toggle, slider, scaffold); batch B4a does it. The type scale follows Apple's sizes, iOS-style bounce scrolling and swipe-back apply on Android too, and CI rejects any import of a Material or Cupertino library. The only platform-drawn element in the browser view is Android's pull-to-refresh spinner, which only takes our colours.

### Values

1. A user cannot name the widget library; if they can, the finish has failed.
2. Every interactive element looks interactive: cards, filled pills or bordered rows with an icon and chevron; no bare text acting as a control; no icon without a 40x40 container in chrome.
3. Icons and type carry equal visual weight (Bold icons at stroke 2.0 to 2.25 next to 16 to 17 pt text).
4. The brand appears once per screen.
5. Space is intentional: every gap is a decision from the spacing scale.
6. Empty boxes are bugs: a slot with no content has zero height, no border, no placeholder.
7. Anything that should feel fixed is structurally fixed, never held by spacing tricks.
8. The cheapest supported phone is the target device.
9. Two gates before a screen is done: analysis, tests and goldens green, and a phone comparison against a reference app (Chrome, Firefox Focus or DuckDuckGo).
10. Uncertain visuals are built in isolation first, looked at on a phone, then integrated.

### Tokens (frozen before any widget; additions only, each recorded in DECISIONS)

| Group | Values |
| --- | --- |
| Colour | bgPrimary, bgSecondary, bgTertiary, accent, accentDim, textPrimary, textSecondary, textTertiary, borderSubtle, borderFocus, error, success, warning, each in light and dark; text pairs verified at 4.5:1 by a test; `incognitoAccent` is added in B27 |
| Type | Display 34/700, Headline 28/600, Title1 22/600, Title2 17/600, Body 17/400, Callout 16/500, Footnote 13/400, Caption 12/400; four roles: display (brand), chrome (UI labels and buttons), body (reading), mono (verbatim); system fonts |
| Spacing | 2, 4, 8, 16, 24, 32, 48, 64 |
| Radii | card 16, hero 20, chip 8, button 12, input 12, sheet 20 (top only), dialog 16, pill half the height |
| Shadow | subtle only, specified per token, none in dark mode |
| Icons | nav 24, row leading 22, row trailing 20, hero 32, chip container 40; Bold weight |
| Motion | push 350 ms, pop 280 ms, sheet 400 ms, press 150 ms, success 300 ms, theme 200 ms; ease curves, no spring; reduce-motion makes every transition instant |

Shape rules: cards use the secondary surface, a hairline border, no elevation and no ripple, with press feedback by opacity; primary actions are filled, never outlined; buttons are 48 high; inputs are filled with the border shifting to the focus colour; every touch target is at least 48x48; the safe area is honoured on both edges.

### Components (built before any screen, used everywhere, never reimplemented per screen)

- Primitives (B4a): scaffold, page route with swipe-back, modal route for sheets and dialogs, text field on `EditableText`, text-selection controls and menu, toggle, scroll behaviour.
- Core (B4): icon wrapper, semantic icons (the only file naming glyphs), icon chip, pressable, card, row, chip, primary button, section header, empty state, error state, bottom sheet, dialog.
- Later additions follow the same rules: slider (B31), banner slot (B34), find bar (B21a), translate bar (B32b), cast controls (B32h).

### Screen shape

Every screen has a nav bar (brand or back on the left, title in the chrome face, actions as chips), primary content, secondary actions as cards or rows, and an optional bottom embed (the banner slot) with reserved height. Chrome is fixed; only content lists scroll, and only when they need to.

### Third-party embeds (the ad slot)

Reserved height equal to the loaded ad, fixed gaps from the spacing scale, and collapse to zero (gap, border, background) while loading, on failure, for the purchased tier, without consent and while the keyboard is up. Nothing is drawn until the ad is ready.

### Forbidden, rejected on sight

A widget library used at its defaults; icon sets without adjustable weight or dated in look; bare icons floating in a toolbar; plain centred text as a control; outlined primary actions; duplicated brand; a hero that eats the top third; a keyboard-pushed bottom bar that re-expands; empty shadowed boxes for embeds; unverified sticky headers; scrolling on screens that do not need it; uniform spacing between unrelated elements; the body face used for UI labels; a component reimplemented per screen.

### Accessibility

A label on every interactive element; text scaling up to the platform maximum; colour never the only indicator; 4.5:1 contrast; 48x48 targets; reduce-motion honoured; logical reading order verified; right-to-left layouts through directional helpers.

## 4. Architecture and rules

### Repository layout

```
Tahor-Browser/
  app/                    Flutter app (android/ and ios/ are generated by the bootstrap workflow)
    lib/{app,core,platform,screens,widgets,l10n}/ + main.dart
    assets/{blocklist,branding}/   test/   integration_test/
  website/                static site; website/blocklist/ holds the published signed lists
  tools/blocklist/        pure-Dart converter and signer, run in CI
  tool/                   CI scripts and the Flutter version pin
  docs/                   BLUEPRINT.md, DECISIONS.md, PERFORMANCE.md, CONSENT_TEST_MATRIX.md, size-baseline.json
  store_submission/       ACCOUNTS, ASO_METADATA, DATA_BACKING, SCREENSHOT_STRATEGY, EEA_CONSENT, COMPLIANCE_MAP, PRIVACY_LABELS, RELEASE_CHECKLIST
  .github/workflows/      bootstrap-scaffold, verify, build-android, integration-android, publish-blocklist, generate-assets
  wrangler.jsonc          Cloudflare Worker static-assets config serving website/
  codemagic.yaml          iOS, manual trigger
```

`app/` and `website/` never share code, imports or build triggers.

### Layering (enforced by `tool/ci_checks.sh`)

- `core/` imports only `dart:async|convert|collection|typed_data|math`, `package:flutter/foundation`, `package:flutter/widgets` and pure-Dart packages (`meta`, `collection`, `cryptography`, `intl`, `qr`). Forbidden in core: `dart:io`, any plugin, `package:flutter/services`.
- `platform/` is the only place plugins and `dart:io` appear. It implements `core/contracts/*`. `platform/common/` holds adapters identical on both systems; `platform/android/` and `platform/ios/` hold only real differences.
- `widgets/` and `screens/` import `core/` and `widgets/` only, never `platform/` or a plugin. Clipboard and text-input services may be imported in `widgets/`.
- `lib/app/` is the composition root and the only code that sees both sides, through `platform_factory`.
- Forbidden everywhere in `lib/`: `package:flutter/material.dart`, `package:flutter/cupertino.dart`, `package:material_ui`, `package:cupertino_ui`.
- A web view is a plugin widget, so it is built behind `BrowserEngine.buildTab(...)` and screens place the returned widget.

### State ownership

`tabs_provider` owns the tab list and the active index. The `BrowserEngine` owns the live controllers keyed by tab id and emits events the provider consumes. Persisted state goes through `session_restore_service`. At most three engines stay live; idle tabs are saved and disposed (hibernated) and woken on selection. This split is fixed in M1 so M2 never retrofits it.

### Canonical blocklist grammar

One rule per line, `|`-separated, `#` for comments; pure data compiled by one function.

```
block|<url-filter regex>|<types csv or *>|<party: third|first|*>|<if-domain csv or *>|<unless-domain csv or *>
allow|<same fields>                      # iOS: ignore-previous-rules; Android: dropped and counted
hide|<domain csv or *>|<css selector>    # css-display-none
```

Types: `document image style-sheet script font raw media svg-document popup`. **iOS** gets every rule type as WebKit rule lists split at 50,000 rules each (WebKit's maximum is 150,000), with per-site exceptions appended as ignore-previous-rules with if-domain. **Android** gets domain-only block rules merged into alternation regexes, path rules kept individual under a 5,000-entry cap, `allow` rules dropped and counted, and per-site exceptions applied by clearing the content blockers for that host and reloading; css-display-none needs JavaScript enabled there. The B17 performance gate halves the Android cap until a 100-subresource page loads within 15% of the unblocked time.

### Web view callbacks: every row is wired or sites break silently

| Signal | Handled by | Batch |
| --- | --- | --- |
| Load start, stop, progress, title, icon, visited history | engine base, then `TabEvent`s | B5 |
| Main-frame load error | inline error view with Retry | B8 |
| URL loading (`intent://`, `market://`, `tel:`, `mailto:`, HTTP upgrade) | `url_policy_service`, launchers | B6, B19 |
| `window.open` and `target=_blank` | new tab | B20 |
| JS alert, confirm, prompt | `js_alert_dialog` | B18 |
| File input | plugin default, verified by the contract test | B22 |
| Camera, microphone and geolocation prompts | `site_settings_sheet`, `permissions` | B18, B20 |
| Fullscreen enter and exit | `fullscreen_adapter` | B20 |
| PDF URL | `url_policy_service` to `pdf_screen` | B19, B21 |
| `disallowed_useragent` (URL pattern on identity hosts plus 403) | `open_in_system_browser_banner` | B19 |
| Certificate error | `https_interstitial`, no silent bypass | B18 |
| Safe Browsing hit (Android) | answer `SHOW_INTERSTITIAL`, reporting off | B20 |
| Renderer gone (Android) and content process terminated (iOS) | reload from saved state with feedback | B20 |
| Long-press on link or image | `image_long_press_menu` | B21a |
| Find results | `find_provider` | B21a |
| Page's own `window.print()` | print flow | B21a |
| Download start, blob and data links | `download_service`, `blob_handler` | B23 |
| Pull to refresh | `PullToRefreshController` | B5, B8 |

### Consent and ads rules, and where each is enforced

| Rule | Enforced by |
| --- | --- |
| Applies to EEA, UK and Switzerland users wherever the developer is | UMP region logic in `ump_consent_adapter`; matrix rows |
| A certified CMP gates every ad request | `canRequestAds` in `consent_provider`; CI check that `AdRequest(` appears only in `admob_ad_slot.dart` after the guard |
| Refresh on every launch; show the form only when required | `consent_provider` state machine and its test table |
| Outside regulated regions no form appears and ads start normally | provider test, matrix |
| A failed or offline refresh never overrides a saved record that permits ads; only a decline, a withdrawal or no answer disables ads | provider test table |
| Banner and any interstitial gated identically (this version has no interstitials) | one gate; `ad_banner_slot` test |
| Test regions with production ad unit IDs and test-region settings before release | M8 exit, `EEA_CONSENT.md` evidence |

### Permission allowlist (source manifest and Info.plist; anything else fails CI)

| Platform | Entry | Feature | Batch |
| --- | --- | --- | --- |
| Android | `INTERNET`, `usesCleartextTraffic` | browsing HTTP and HTTPS pages | B9 |
| Android | `CAMERA`, `RECORD_AUDIO`, `MODIFY_AUDIO_SETTINGS`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` (all runtime) | per-site prompts, QR | B22 |
| Android | `WRITE_EXTERNAL_STORAGE` (maxSdkVersion 28), `POST_NOTIFICATIONS` | downloads | B24 |
| Android | `USE_BIOMETRIC` | app lock | B28 |
| Android | `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, Cast options provider and service | Cast | B32g |
| Android | `com.google.android.gms.permission.AD_ID`, AdMob application ID | banner ad | B34 |
| iOS | `NSAllowsArbitraryLoadsInWebContent`, `LSApplicationQueriesSchemes` | HTTP pages, external links | B9 |
| iOS | `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSLocationWhenInUseUsageDescription` | per-site prompts, QR | B22 |
| iOS | `UIBackgroundModes` with `fetch` | downloads | B24 |
| iOS | `CFBundleURLTypes` for `http` and `https`, `FlutterDeepLinkingEnabled` false | default browser | B22a |
| iOS | `NSFaceIDUsageDescription` | app lock | B28 |
| iOS | `NSUserTrackingUsageDescription`, `GADApplicationIdentifier`, `SKAdNetworkItems` | ads and ATT | B34 |
| iOS | `NSLocalNetworkUsageDescription`, `NSBonjourServices` (`_googlecast._tcp`, `_CC1AD845._googlecast._tcp`) | Cast | B32g |
| iOS | `CFBundleLocalizations` (all 20 codes) | languages | B39 |
| iOS | entitlement `com.apple.developer.web-browser` | default browser, Add to Home Screen | after Apple grants it |

The tests also fail on the keys Apple forbids with that entitlement (`NSPhotoLibraryUsageDescription`, `NSLocationAlways...`, HomeKit, Bluetooth-always, HealthKit). The merged-manifest audit (B45) lists the permissions plugins add (for example network state from the ad SDK), each with a reason.

### Localization

ARB files at `lib/l10n/app_<code>.arb`; English keys grow in every batch and the other 19 languages land in M9; zero hardcoded strings in widget files (CI check from B37); right-to-left through `Directionality` and directional helpers; locale-aware dates and numbers; store listings localized separately.

### Size policy

Code ships in the binary and data downloads on first use (Google Play and Apple forbid downloading executable code). The browser engine is the system's. The ad-blocking list ships as a compact seed and the full signed list downloads once from the website. Translation models (about 30 MB each) download from Google on demand and add nothing to the app size. The Android barcode model is unbundled (about 600 KB instead of 3 to 10 MB). Android language detection adds about 900 KB; iOS scanning uses Apple's own scanner at no cost. Release builds drop pdfrx's web assets (`dart run pdfrx:remove_wasm_modules`); PDFium stays because native code cannot be downloaded. Sideload APKs are built `--split-per-abi`. `tool/check_size.sh` fails any merge that grows a per-ABI APK or the IPA by more than 3% over `docs/size-baseline.json`, and every release build uploads an `--analyze-size` report. No second repository is needed: the full blocklist is published into `website/blocklist/` by `publish-blocklist.yml`.

### Performance targets

Launch to interactive under 2 s on a mid-range phone; 60 fps scrolling on lists of 100 or more rows; history queries under 50 ms at the 5,000-row cap; blocklist compile off the UI isolate with no first-paint delay; an explicit timeout and retry budget on every network call.

## 5. Dependencies

Every package is pinned to an exact version in `app/pubspec.yaml`, `pubspec.lock` is committed, and `ci_checks.sh` fails on any caret or range. All pins below were resolved together on Flutter 3.47.7 in CI on 2026-11-01.

| Purpose | Package and version |
| --- | --- |
| Web view | `flutter_inappwebview` 6.2.0-beta.3 |
| Icons | `phosphoricons_flutter` 1.1.0 (Bold weight) |
| PDF rendering | `pdfrx` 2.6.5, rendering API only |
| QR scan | `mobile_scanner` 7.1.4 (Android model unbundled); QR generation uses `qr` 4.0.0 with our own painter |
| Ads and consent | `google_mobile_ads` 9.1.0 |
| Purchases | `in_app_purchase` 3.3.0 |
| Downloads | `background_downloader` 9.5.9; `http` 1.6.0 for the foreground fallback and blocklist refresh |
| Translation | `google_mlkit_translation` 0.15.1, `google_mlkit_language_id` 0.14.0 |
| Cast | `flutter_chrome_cast` 1.5.0 (API classes only) |
| Storage | `sqflite` 2.4.4+2, `shared_preferences` 2.5.6, `path_provider` 2.1.6 |
| System integration | `url_launcher` 6.3.3, `share_plus` 13.3.1, `open_file` 3.5.11, `local_auth` 3.0.2, `permission_handler` 13.0.2, `package_info_plus` 10.2.2 |
| Crypto | `cryptography` 2.9.0 (Ed25519 and SHA-256) |
| SDK-pinned | `intl` 0.20.3 (the version `flutter_localizations` requires), `flutter_localizations` |
| Dev | `flutter_test`, `integration_test`, `flutter_lints` 6.0.0, `flutter_launcher_icons` 0.14.4, `flutter_native_splash` 2.4.7 |

Not used, and why: Material and Cupertino libraries (design stance); `pdfx` (no Swift Package Manager support, no release for over a year); `open_filex` (no release for 17 months, no Swift Package Manager support); `qr_flutter` (replaced by our painter); an Android intent plugin (intent links are parsed in pure Dart and opened through `url_launcher`); a separate hashing package (`cryptography` provides SHA-256); `pdfrx_coregraphics` (experimental).

## 6. Delivery process

Flutter does not run in Termux or in the build agent's sandbox, so Termux is used only for reading the repository. Analysis, tests and builds run in GitHub Actions and Codemagic, and every batch reaches `main` only through a green check.

### 6.1 Pre-flight (M0, completed 2026-11-01)

1. The empty public GitHub repository `Tahor-Browser` exists under `holydunamis1`.
2. The account slug is `zdmgold`, so the identifier is `com.zdmgold.tahorbrowser`.
3. The repository URL was supplied and the contract block below was confirmed.
4. A personal Codemagic account linked to the repository is needed at B13.

```
REPO URL:        https://github.com/holydunamis1/Tahor-Browser.git
WORKING DIR:     the build agent's sandbox clone (Termux clone optional: ~/tahor-browser)
BATCH PLAN:      section 8 (59 batches, 14 milestones)
PER-BATCH LOOP:  branch, place files, commit, push, verify.yml green, squash-merge by the agent (D-33)
FINAL GATE:      section 21, manual workflow_dispatch builds only
```

### 6.2 Termux setup (optional, read-only access)

```
pkg update -y && pkg install -y git
git clone https://github.com/holydunamis1/Tahor-Browser.git ~/tahor-browser
cd ~/tahor-browser && git pull
```

### 6.3 Seed commit and branch protection

The one direct push to `main` created the branch and committed the ignore file before any dependency resolution (done). A repository ruleset requiring the `verify` status check on pull requests, with a bypass for GitHub Actions so the workflows that commit generated files can still push, is configured when the first batches have run. Automatically delete head branches is enabled.

### 6.4 Accounts and secrets tracking (`store_submission/ACCOUNTS.md`, updated before every dashboard action)

| Item | Value | When |
| --- | --- | --- |
| Reverse-DNS identifier, repository, Flutter pin | as above | M0, B0 |
| Blocklist signing keypair | private key in `BLOCKLIST_SIGNING_KEY_B64`, public key in an app asset | B14 |
| Google Play account ($25) and app entry; Play App Signing | upload keystore with offline backup | after the app is complete (D-44) |
| AdMob app IDs and banner unit IDs; UMP message with the IDFA explainer | Google's published sample IDs until the stores are set up | M8 |
| IAP product ID `com.zdmgold.tahorbrowser.pro` | one-time product | after the app is complete |
| Apple Developer Program ($99), team ID, App Store Connect key; default-browser entitlement request | first needed at B42 | after the app is complete |
| Privacy policy URL and support URL | `website/privacy.html`, `website/support.html` on https://tahor-browser.holydunamis1.workers.dev | B43 |

GitHub secrets: `ANDROID_KEYSTORE_B64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `BLOCKLIST_SIGNING_KEY_B64`. Codemagic secrets: `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_PRIVATE_KEY`.

### 6.5 Workflows

| Workflow | Trigger | Purpose |
| --- | --- | --- |
| `verify.yml` | push to `batch/**`, manual | `ci_checks.sh`, format check, `flutter analyze`, `flutter test`; no artifacts |
| `bootstrap-scaffold.yml` | manual, once (done) | generates `android/` and `ios/` and commits them to `main` |
| `build-android.yml` | manual | debug APK published as a pre-release asset, or release APK and AAB; release adds signing, size gate, manifest audit |
| `integration-android.yml` | manual | integration tests on an emulator with screenshots |
| `generate-assets.yml` | manual | rasterizes the icon SVGs and generates icons and splash |
| `publish-blocklist.yml` | manual | converts, signs and publishes the blocklist into `website/blocklist/` |
| `codemagic.yaml` | manual | `ios-verify` (unsigned simulator build and integration tests), later `ios-release` |

`verify.yml` is the only workflow with a `push:` trigger, and only on `batch/**`; it spends no paid minutes (decision D-05). No build workflow ever triggers on push.

### 6.6 The batch loop (every batch, N is the batch id; run by the build agent, D-33)

```
git checkout main && git pull --ff-only
git checkout -b batch/bN
# place the files of the batch, in the listed order
git add -A
git commit -m "bN: <purpose>"
git push -u origin batch/bN
```

Then `verify` runs on the pushed branch. When it is green the agent opens the pull request and squash-merges it with the title `bN: <purpose>`, and the branch is deleted. If `verify` is red, the agent reads the failing step output, fixes on the same branch and pushes again. No next batch until the previous one is merged. A file listed as Modified is read from the repository first and never rewritten from memory. Every batch below shows its branch and commit title as a one-line `Run:` entry. The owner can read progress on the repository's commit list.

### 6.7 Gates

- **Gate 1 (every batch):** `verify.yml` green.
- **Gate 2 (every screen):** golden tests (generated and compared on the same Linux runner) plus a phone comparison of the milestone build against a reference app.
- **Gate 3 (milestone):** `integration_test` smoke on the Android emulator workflow, and on the iOS simulator at iOS checkpoints.

### 6.8 Milestone exit (every milestone)

The agent dispatches `integration-android` and logs the result in `docs/DECISIONS.md` (a small batch such as `m2-log: milestone 2 log`). Two milestone exits also produce an installable test APK for the owner's phone (D-34): the M2 exit (after B13) and the M9 exit (after B39). The agent dispatches `build-android` in mode `debug`; the APK appears as a pre-release asset on the repository's Releases page. The owner installs it and runs that milestone's phone checklist. The first release build creates `docs/size-baseline.json`.

### 6.9 iOS checkpoints (unsigned simulator builds on Codemagic, about 20 minutes each, about 100 of 500 free minutes)

iOS-1 after B13, iOS-2 after B17, iOS-3 after B29, iOS-4 after B36 (covers M7a to M7c), iOS-5 after B46 (signed, after paying Apple). Start each from Codemagic, workflow `ios-verify`, branch `main`, and read the simulator screenshots in the artifacts.

### 6.10 Release rails

After the app is complete (D-44), run B41 and the privacy and support pages of B43, then upload a signed build to a Play closed-testing track so the 12-tester, 14-day clock runs.

## 7. Features and menus

### Final feature list (the milestone is when each is built)

**Browsing basics.** Address bar with search or address entry, chosen search engine, a Not secure label on HTTP, clear and paste-and-go (M1). Back, forward, reload, stop, progress bar, pull to refresh, edge-swipe back and the Android Back button (M1). An error page with Retry (M1). Share page and open in system browser (M1). Portrait and landscape on phones; iPhone-only on iOS (M1). Copy link (M2). Find in page, Print or Save as PDF, back/forward list on long-press of Back or Forward, link and image long-press menus (M4). Open links from other apps and set as default browser (M4). Translate page (M7a). Add to Home Screen (M7b). Cast video, with iOS AirPlay working by default (M7c).

**Tabs and sessions (M2).** Multiple tabs, tab grid with thumbnails, new tab, close, close all, reopen closed tab; session restore of tabs, each tab's history and scroll after the app is closed or killed; hibernation of idle tabs; start-up choice (continue or start page); start page.

**Ad blocking (M3).** On-device network blocking and element hiding; shield with per-site exception; signed blocklist (compact seed in the app, full list downloaded once from the website, manual or optional weekly refresh); a screen with the list version and honest limits.

**Web compatibility (M4).** Site dialogs; new windows as tabs; per-site camera, microphone and location prompts; file uploads; fullscreen video; external-app links; PDF viewer; HTTPS-only with a fallback page and certificate warnings; mobile and desktop site per site; system-browser handoff banner; site settings per site and a list of all; renderer-crash recovery; dangerous-site warnings with a switch (engine setting in M1, switch in M6).

**Downloads (M5).** Background downloads on both platforms with pause and resume where the server allows, notifications, cookies for signed-in downloads, blob and data downloads up to 20 MB, a download sheet and screen, Save image.

**Privacy and data (M6).** History (off by default), bookmarks with folders and editing, address-bar suggestions from your own data, private tabs, biometric app lock, Clear browsing data with a time range, a first-run welcome. No accounts, no analytics from us.

**Comfort (M7).** Reader mode; text size from a menu sheet and Settings; screen filter; one-handed mode; QR scan and generate; light and dark theme (M1).

**Money, consent, languages.** One banner ad on the start page, bookmarks and downloads screens (M8); consent for the EEA, UK and Switzerland and the ATT prompt on iOS (M8); a one-time purchase that removes our banner only, with Restore purchases (M8); 20 languages with right-to-left support (M9); accessibility throughout.

### Browser menu

The menu is `browser_menu_sheet`: a bottom sheet with a 20 radius, rows made of a 40x40 icon chip, one label and a trailing control or chevron, grouped under small uppercase headers. Items that do not apply are not drawn: on a blank tab only the tab, library and app items appear.

| Group | Item | Shown when | Batch | Opens |
| --- | --- | --- | --- | --- |
| Quick row | Reload / Stop | a page is loaded or loading | B7 | `browser_engine` |
| Quick row | Bookmark (filled when saved) | a page is loaded | B26 | `bookmarks_provider` |
| Quick row | Share | a page is loaded | B7 | `share` |
| Quick row | Find in page | a page is loaded | B21a | `find_bar` |
| This page | Desktop site (switch) | a page is loaded | B19 | `view_mode_provider`, remembered per site |
| This page | Translate page | the page language differs from the target | B32b | `translate_bar` |
| This page | Cast video | the page has castable video | B32h | `cast_sheet` |
| This page | Text size | a page is loaded | B31 | `text_size_sheet` |
| This page | Reader mode | the page passes the readability probe | B30 | `reader_screen` |
| This page | Print or Save as PDF | a page is loaded | B21a | the system print dialog |
| This page | Copy link | a page is loaded | B12 | clipboard, then feedback banner |
| This page | Add to Home Screen | Android 8+, or iOS once entitled | B32d, B32e | `home_screen` |
| This page | Page QR code | a page is loaded | B32 | `qr_screen`, My page mode |
| This page | Site settings | a page is loaded | B18 | `site_settings_sheet` |
| This page | Open in system browser | a page is loaded | B7 | `external_launcher` |
| Tabs | New tab | always | B12 | blank tab with `new_tab_page` |
| Tabs | New private tab | always | B27 | blank tab with `incognito_home` |
| Tabs | Reopen closed tab | a tab was closed this session | B12 | `tabs_provider` |
| Library | Bookmarks | always | B26 | `bookmarks_screen` |
| Library | History | always | B26 | `history_screen` (explains history is off until enabled) |
| Library | Downloads | always | B25 | `downloads_screen` |
| Library | Scan QR code | always | B32 | `qr_screen`, Scan mode |
| Library | Clear browsing data | always | B29 | `clear_data_sheet` |
| App | Settings | always | B7 | `settings_screen` |

**Settings** holds: Default browser (B22a), Appearance (theme, text size, screen filter, one-handed mode), General (start-up choice), Search engine, Ad blocking, Site settings, Privacy (history, HTTPS-only, dangerous-site warnings, app lock, Clear browsing data, consent options), Translation (target language, models, Wi-Fi-only), Language, Pro and Restore purchases, About and licences.

**Always available outside the menu.** Back and Forward (bottom bar, edge swipe, Android Back; long-press for the list), Stop (the reload button turns into stop while loading), pull to refresh, the tab switcher (tab count button), close tab and close all (tab screen), address-bar actions (clear, paste and go, suggestions, reader chip, cast chip), the translate bar.

**Long-press menus.** On a link: Open, Open in new tab, Open in private tab, Copy link, Share link. On an image: Open image, Open in new tab, Copy image link, Save image, Share. A linked image shows both. Selecting text on a web page uses the system's selection menu; selecting text in our own fields uses `app_text_selection`.

## 8. Batch plan in dependency order

Phases are runnable milestones; each ends with something that works on a real phone. There are 14 milestones: M0 (pre-flight), M1 to M10, and M7a, M7b, M7c. Batches are push units of at most 15 files. A batch needs only the batches listed under Needs. The file-level specification of each is in the section named in the last column, under the same batch id.

| Phase | Batch | What it delivers | Files | Needs | Section |
| --- | --- | --- | --- | --- | --- |
| M1 First light | B0 | Repository, CI, pins, size gate | 15 | none | 9 |
| M1 | B1 | Design tokens and themes | 11 | B0 | 9 |
| M1 | B2 | Errors, utilities, localization glue | 7 | B1 | 9 |
| M1 | B3 | Models and contracts for the first run | 7 | B2 | 9 |
| M1 | B4a | Design primitives: route, scaffold, text field, selection menu, toggle, scroll | 7 | B1, B2 | 9 |
| M1 | B4 | Core widgets and icons | 13 | B4a | 9 |
| M1 | B5 | Platform layer: engines, launchers, factory | 10 | B3 | 9 |
| M1 | B6 | Services and providers | 6 | B3, B5 | 9 |
| M1 | B7 | Browser and settings widgets | 7 | B4, B6 | 9 |
| M1 | B8 | Screens and shell, pull to refresh | 7 | B7 | 9 |
| M1 | B9 | Native configuration, iPhone only, orientations | 5 | B8 | 9 |
| M2 Tabs and sessions | B10 | Persistence foundation | 10 | B3 | 10 |
| M2 | B11 | Session restore and tab lifecycle | 4 | B10 | 10 |
| M2 | B12 | Tab interface, copy link, reopen closed tab, start-up choice | 6 | B11 | 10 |
| M2 | B13 | Integration harness and iOS verify | 6 | B12 | 10 |
| M3 Ad blocking | B14 | Blocklist seed, full list, tools, signing | 8 | B0 | 11 |
| M3 | B15 | Compiler core | 7 | B14 | 11 |
| M3 | B16 | Site settings, providers, shield, ad-block screen | 8 | B15, B12 | 11 |
| M3 | B17 | Engine wiring and performance gate | 1 | B16 | 11 |
| M4 Web completeness | B18 | Dialogs, sheets, interstitials | 6 | B17 | 12 |
| M4 | B19 | Policy, user agents, view mode | 3 | B18 | 12 |
| M4 | B20 | Callback contracts and adapters, Safe Browsing handler | 6 | B19 | 12 |
| M4 | B21 | Site settings, PDF and About screens | 3 | B20 | 12 |
| M4 | B21a | Find in page, back/forward list, link menu, print | 3 | B21 | 12 |
| M4 | B22 | Manifest, plist and contract tests | 1 | B21a | 12 |
| M4 | B22a | Incoming links and default browser | 8 | B22, B11 | 12 |
| M5 Downloads | B23 | Download core | 7 | B22a | 13 |
| M5 | B24 | Downloader engine and cookies | 2 | B23 | 13 |
| M5 | B25 | Download interface and verification | 3 | B24 | 13 |
| M6 Privacy and data | B26 | History, bookmarks, folders | 10 | B25 | 14 |
| M6 | B26a | Address-bar suggestions | 3 | B26 | 14 |
| M6 | B27 | Private tabs | 3 | B26 | 14 |
| M6 | B28 | Biometric lock | 5 | B27 | 14 |
| M6 | B29 | Privacy settings, clear data, welcome | 4 | B28 | 14 |
| M7 Comfort | B30 | Reader mode | 6 | B29 | 15 |
| M7 | B31 | Appearance and text size | 7 | B30 | 15 |
| M7 | B32 | QR scan and generate | 4 | B31 | 15 |
| M7a Translate | B32a | Translate core | 5 | B32 | 16 |
| M7a | B32b | Translate platform and interface | 4 | B32a | 16 |
| M7a | B32c | Translate verification | 1 | B32b | 16 |
| M7b Home screen | B32d | Add to Home Screen, Android | 3 | B22a | 17 |
| M7b | B32e | Add to Home Screen, iOS | 2 | B32d | 17 |
| M7c Cast | B32f | Cast core | 5 | B22a, B20 | 17 |
| M7c | B32g | Cast platform | 1 | B32f | 17 |
| M7c | B32h | Cast interface | 3 | B32g | 17 |
| M8 Consent, ads, purchases | B33 | Consent core | 4 | B32h | 18 |
| M8 | B34 | Ads | 3 | B33 | 18 |
| M8 | B35 | Purchases and entitlement | 5 | B34 | 18 |
| M8 | B36 | Consent and ad verification | 2 | B35 | 18 |
| M9 Localization | B37 | Locales, first ten | 10 | B36 | 19 |
| M9 | B38 | Locales, remaining nine | 9 | B37 | 19 |
| M9 | B39 | Locale verification and language picker | 3 | B38 | 19 |
| M10 Release | B40 | Icon and splash | 6 | B39 | 20 |
| M10 | B41 | Android release configuration | 1 | B40 | 20 |
| M10 | B42 | iOS release configuration | 2 | B41 | 20 |
| M10 | B43 | Website | 7 | B42 | 20 |
| M10 | B44 | Store documents | 7 | B43 | 20 |
| M10 | B45 | Audits and performance | 5 | B44 | 20 |
| M10 | B46 | Final documents | 0 | B45 | 20 |

**Totals:** 59 batches in 14 milestones; 317 files (source, configuration, documents and integration tests) plus about 60 unit tests and fixtures, which are listed with the batch that introduces the code they test. The 47 numbered batches B0 to B46 run in sequence; the 12 lettered batches (B4a, B21a, B22a, B26a, B32a to B32h) slot in where their dependencies are met. Batches are executed in the order shown, top to bottom.

## 9. File manifest, M1: First light (B0 to B9)

Entry format: `path`. Contains (what is inside). Role (what it does in the app). Uses (what it imports or calls). Used by (what depends on it). Tests are listed per batch with what each asserts. Files marked Modified are read from the repository first. Each batch ends with its `Run:` line: the branch and commit title for the loop in section 6.6.

**M1 exit (phone checklist):** the M1 build is verified by the emulator integration run; the installable test APK for the owner comes at the M2 exit (D-34). The checklist: load five sites (HTTP and HTTPS); back, forward, reload, stop and pull to refresh; address-bar behaviour; force-stop and relaunch (theme and search engine persist); menu share and system-browser handoff; the Android Back button; the keyboard does not push or re-expand the bottom bar; compare against the reference app for weight, spacing and clarity; the first release build creates `docs/size-baseline.json`.

### B0. Repository, CI, pins, size gate

`.gitignore` and `README.md` already sit on `main` from the seed commit (section 6.3); this batch edits README and adds the other 13 files. As built, B0 also added `tool/ci_run.sh` (publishes the tail of each CI step as a workflow annotation, D-36), and the files `app/pubspec.lock`, `app/l10n.yaml` and `app/analysis_options.yaml`; the website stub and `wrangler.jsonc` followed as small batches (D-45).

- `README.md`. Contains: one-line description, honest feature list, how builds run in CI, link to the blueprint. Role: front door; finalized in B46.
- `.gitignore`. Contains: Flutter, Dart, Android and iOS ignores, `key.properties`, `*.jks`, `*.keystore`, `*.p12`, `symbols/`, `build/`, `.dart_tool/`, `Pods/`; keeps `pubspec.lock` tracked. Role: committed before any dependency resolution so artifacts are never staged.
- `docs/BLUEPRINT.md`. Contains: this document. Used by: every batch.
- `docs/DECISIONS.md`. Contains: the decision log from section 22, the verified pin list, and a milestone log written at each exit.
- `store_submission/ACCOUNTS.md`. Contains: the accounts table from section 6.4 with change history; checked before every dashboard action.
- `tool/flutter_version.txt`. Contains: exactly one line, `3.47.7`. Used by: all workflows.
- `tool/ci_checks.sh`. Contains: bash checks: layering greps from section 4; an exact-pin check on `pubspec.yaml`; forbidden imports of Material and Cupertino libraries; forbidden tokens (`TODO`, `FIXME`, `UnimplementedError`, `localStorage`); a workflow-trigger audit (only `verify.yml` may use `push:`, only on `batch/**`); every action pinned to a full commit SHA. Later batches append: permission allowlist and forbidden Info.plist keys (B22), `AdRequest(` guard (B36), hardcoded-string check (B37), merged-manifest audit (B45). Used by: `verify.yml`.
- `tool/check_size.sh`. Contains: compares per-ABI release APK sizes (and the IPA on iOS) with `docs/size-baseline.json` and fails on growth above 3%. Used by: `build-android.yml`, `codemagic.yaml`.
- `.github/workflows/bootstrap-scaffold.yml`. Contains: manual; aborts if `app/android` exists; runs `flutter create --org com.zdmgold --project-name tahorbrowser --platforms android,ios` in a temp directory; copies only `android/`, `ios/` and `.metadata` into `app/`; commits to `main` with `GITHUB_TOKEN`. Role: replaces a local `flutter create`.
- `.github/workflows/verify.yml`. Contains: triggers `push` on `batch/**` and manual; Flutter from the pin file; `flutter pub get`; `ci_checks.sh`; `flutter gen-l10n`; a `dart format` check; `flutter analyze` (zero issues); `flutter test` if `test/` exists; later `dart test` in `tools/blocklist`. No artifacts. Role: Gate 1.
- `.github/workflows/build-android.yml`. Contains: manual with input `mode` (debug or release); Temurin 17. Debug builds `flutter build apk --debug` and publishes it as a pre-release asset. Release decodes `ANDROID_KEYSTORE_B64`, writes `key.properties`, runs `dart run pdfrx:remove_wasm_modules`, builds the AAB and per-ABI APKs with `--obfuscate --split-debug-info=symbols --split-per-abi`, runs the size report, `tool/check_size.sh`, `apksigner verify` and (from B45) the merged-manifest audit, and uploads artifacts, symbols and the size report. The release path is inert until B41.
- `app/pubspec.yaml`. Contains: name, SDK constraint `^3.13.0`, every dependency from section 5 pinned exactly, `flutter: generate: true`, assets lists (blocklist assets added in B14, branding in B40). Used by: everything.
- `app/analysis_options.yaml`. Contains: `flutter_lints`, strict-casts, strict-inference, strict-raw-types, `avoid_print` as an error, generated l10n excluded.
- `app/l10n.yaml`. Contains: `arb-dir: lib/l10n`, `template-arb-file: app_en.arb`, `output-class: AppLocalizations`, `output-dir: lib/l10n/gen`, `synthetic-package: false`.
- `app/lib/l10n/app_en.arb`. Contains: seed key `appName`; every later batch adds its keys. Used by: `l10n_extensions`.

Run: branch `batch/b0`, commit `b0: repository, CI, pins, size gate`; then the bootstrap-scaffold workflow once.

### B1. Design tokens and themes (frozen before any widget)

- `app/lib/core/constants/design_tokens.dart`. Contains: `AppPalette`, the colour tokens from section 3 in light and dark. Used by: themes, every widget.
- `app/lib/core/constants/typography.dart`. Contains: the eight styles mapped to the four roles. Used by: themes, widgets.
- `app/lib/core/constants/spacing.dart`. Contains: the spacing scale and directional inset helpers. Used by: all layouts.
- `app/lib/core/constants/radii.dart`. Contains: the radii. Used by: themes, widgets.
- `app/lib/core/constants/shadows.dart`. Contains: the only allowed shadow specs, none in dark mode. Used by: card, sheets.
- `app/lib/core/constants/icon_sizes.dart`. Contains: icon sizes, chip container size, stroke weight. Used by: icon\_wrapper, icon\_chip.
- `app/lib/core/constants/motion.dart`. Contains: durations and curves, and `Motion.of(context)` returning zero when reduce-motion is on. Used by: every animation.
- `app/lib/core/constants/app_constants.dart`. Contains: the search engine list (id, name, URL template), default engine, maximum tabs, hibernation limits, the 20 MB blob ceiling, blocklist and support URLs (D-46), the supported locales with native names (added in B39). Used by: services, providers, settings.
- `app/lib/core/theme/light_theme.dart`. Contains: the light `AppThemeData` (palette, text styles, radii, shadows, motion) as plain immutable Dart; no Material `ThemeData` anywhere. Used by: theme\_builder.
- `app/lib/core/theme/dark_theme.dart`. Contains: the dark `AppThemeData`, zero shadows. Used by: theme\_builder.
- `app/lib/core/theme/theme_builder.dart`. Contains: `AppThemeData.of(brightness)` and the `AppTheme` InheritedWidget with `AppTheme.of(context)`; every widget reads colours, text styles, radii and shadows through it. Used by: app\_shell, theme\_provider, every widget.

Tests: `design_tokens_test` (4.5:1 contrast for every text and background pair in both modes), `motion_test` (reduce-motion returns zero).

Run: branch `batch/b1`, commit `b1: design tokens and themes`.

### B2. Errors, utilities, localization glue

- `app/lib/core/error/error_taxonomy.dart`. Contains: sealed `AppError` classified on three axes (recoverable or fatal, retriable or terminal, user-caused or system-caused) and `ErrorTreatment` (inline banner, feedback banner, full screen, silent log); factories for network, storage, permission, web view, blocklist, billing, consent. Role: every error has a defined UI treatment. Used by: global\_error\_handler, services, providers, error\_state.
- `app/lib/core/error/global_error_handler.dart`. Contains: installs `FlutterError.onError`, `PlatformDispatcher.onError` and a guarded-zone runner; classifies through the taxonomy; keeps a 100-entry in-memory log that is never sent anywhere. Used by: bootstrap, main.
- `app/lib/core/error/global_error_widget.dart`. Contains: replacement for `ErrorWidget.builder`: full-screen fallback with Retry (rebuilds the root) and Report (a `mailto:` carrying an error code only). Used by: app\_shell.
- `app/lib/core/utils/formatters.dart`. Contains: locale-aware byte size, relative time, number and display-host formatting. Used by: download rows, history, tab cards.
- `app/lib/core/utils/url_utils.dart`. Contains: `resolveInput(text, searchEngine)` returning a navigation or a search URL; scheme detection (`javascript:` and `file:` refused from the address bar); IDN-safe display host; `isPdfUrl`; `isSecureScheme`; `parseIntentUri`, which extracts scheme, host, path, package and `S.browser_fallback_url` from `intent:` links so Android can open the app through `url_launcher`, open the store, or use the fallback. Used by: address\_bar, tabs\_provider, url\_policy\_service, android\_external\_launcher.
- `app/lib/core/utils/debouncer.dart`. Contains: a timer-based debouncer. Used by: session\_restore\_service, address\_bar, suggestion\_service.
- `app/lib/l10n/l10n_extensions.dart`. Contains: `context.l10n` shortcut to the generated localizations. Used by: every widget and screen.

Modified: `app_en.arb` (error and fallback strings). Tests: `url_utils_test` (`example.com`, `http://x`, `foo bar` becomes a search, `localhost:3000`, `javascript:` refused, IDN host, intent links), `formatters_test`, `error_taxonomy_test` (every class maps to a treatment).

Run: branch `batch/b2`, commit `b2: errors, utilities, localization glue`.

### B3. Models and contracts for the first run

- `app/lib/core/models/app_settings.dart`. Contains: immutable `AppSettings` (themeMode, searchEngineId, localeCode in B3; later batches add fields with migrations: httpsOnly, startupMode, historyEnabled, welcomeSeen, warnDangerousSites, text size, screen filter, one-handed, translation target and Wi-Fi-only) with `copyWith`, `toJson`, `fromJson`, `==` and an embedded schema version; unknown fields ignored, missing fields default. Used by: settings\_service, settings\_provider.
- `app/lib/core/models/tab_model.dart`. Contains: `TabModel` (id, url, title, faviconUrl, isIncognito, viewMode, scrollY, stateKey). Role: complete from day one, the single exception to just-in-time creation, because tab ownership is the costliest thing to retrofit. Used by: tabs\_provider, session\_snapshot, tab\_card, engine events.
- `app/lib/core/contracts/key_value_store.dart`. Contains: async get, set, remove for string, int, bool and JSON. Implemented by: shared\_prefs\_key\_value\_store.
- `app/lib/core/contracts/browser_engine.dart`. Contains: `buildTab(TabViewConfig, TabEventSink)`, `load`, `goBack`, `goForward`, `reload`, `stop`, `dispose(tabId)`, a `NavigationPolicy` callback and a sealed `TabEvent` family (PageStarted, Progress, PageFinished, TitleChanged, FaviconChanged, NavigationStateChanged, ErrorOccurred). Later batches extend it (state, content rules, dialogs, find, print, long-press, back/forward list, incognito, HTML tabs). Used by: tabs\_provider, browser\_screen, inappwebview\_engine\_base.
- `app/lib/core/contracts/external_launcher.dart`. Contains: `openInSystemBrowser(Uri)`, `openExternalApp(Uri)`; B24 adds `openFile`. Used by: browser\_menu\_sheet, url policy flow.
- `app/lib/core/contracts/app_info.dart`. Contains: version and build number. Used by: about\_screen, the error report mail.
- `app/lib/core/contracts/share.dart`. Contains: `shareUrl(Uri, title)`. Used by: browser\_menu\_sheet.

Tests: `model_roundtrip_test` (toJson, fromJson, equality and copyWith for both models; tolerant parsing).

Run: branch `batch/b3`, commit `b3: models and contracts for the first run`.

### B4a. Design primitives (no Material, no Cupertino)

- `app/lib/widgets/core/app_scaffold.dart`. Contains: background token, safe area on both edges, top and bottom chrome slots, a layout stable under the keyboard (bottom chrome never re-expands). Used by: every screen.
- `app/lib/widgets/core/app_page_route.dart`. Contains: `PageRoute` with the motion-spec transition (push 350 ms fade plus 20 px slide, pop 280 ms, instant under reduce-motion) and an iOS-style edge swipe back on both platforms. Used by: router, app\_shell.
- `app/lib/widgets/core/app_modal_route.dart`. Contains: presentation for sheets (drag to dismiss, 20 top radius) and dialogs (fade) with a token scrim. Used by: premium\_bottom\_sheet, premium\_dialog.
- `app/lib/widgets/core/premium_text_field.dart`. Contains: a field built on `EditableText`: 48dp filled surface, focus border, clear button, cursor and selection colours from tokens, input action, obscure option, semantics. Used by: address\_bar, find\_bar, suggestion fields, prompt dialogs.
- `app/lib/widgets/core/app_text_selection.dart`. Contains: `AppTextSelectionControls` (handles) and a `contextMenuBuilder` (Cut, Copy, Paste, Select all, localized, token-styled) with an optional Paste and go action for the address bar. Role: `EditableText` shows no selection UI without it. Used by: premium\_text\_field.
- `app/lib/widgets/core/premium_toggle.dart`. Contains: an animated switch drawn with `CustomPaint`, 48dp hit area, checked-state semantics. Used by: setting\_switch.
- `app/lib/widgets/core/app_scroll_behavior.dart`. Contains: iOS-style bouncing physics and no glow on both platforms. Used by: app\_shell.

Tests: `premium_text_field_test` (focus, long-press shows the menu, paste, right-to-left), `app_page_route_test` (swipe back, reduce-motion), `app_scaffold_test` (the keyboard leaves bottom chrome stable).

Run: branch `batch/b4a`, commit `b4a: design primitives`.

### B4. Core widgets and icons

- `app/lib/widgets/core/icon_wrapper.dart`. Contains: the single icon widget with role-based size and weight. Used by: all icons through semantic\_icons.
- `app/lib/widgets/icons/semantic_icons.dart`. Contains: the only file naming glyphs from `phosphoricons_flutter` (Bold for chrome icons, Regular at 20 px and below), as aliases such as back, reload, tabs, shield, share, settings. Used by: every widget.
- `app/lib/widgets/core/icon_chip.dart`. Contains: a 40x40 container around an icon with a 48dp hit area and a semantic label. Used by: nav bar, address bar, screens.
- `app/lib/widgets/core/pressable.dart`. Contains: opacity press feedback, no ripple, minimum 48x48. Used by: card, chip, button, row.
- `app/lib/widgets/core/premium_card.dart`. Contains: secondary-surface fill, hairline border, radius 16, no elevation, optional leading icon, label, value, chevron. Used by: settings, tabs, downloads.
- `app/lib/widgets/core/premium_row.dart`. Contains: a transparent two-line row with leading icon, trailing chevron and tint press. Used by: lists everywhere.
- `app/lib/widgets/core/premium_chip.dart`. Contains: a small labelled pill. Used by: metadata and status.
- `app/lib/widgets/core/primary_button.dart`. Contains: a filled accent button, radius 12, 48 high, disabled at reduced opacity; never outlined. Used by: dialogs, empty states.
- `app/lib/widgets/core/section_header.dart`. Contains: small uppercase, letter-spaced, tertiary text. Used by: settings, lists.
- `app/lib/widgets/core/empty_state.dart`. Contains: icon, title, optional subtitle, centred. Used by: tabs, bookmarks, history, downloads.
- `app/lib/widgets/core/error_state.dart`. Contains: a taxonomy-driven error view with Retry. Used by: any screen that loads data.
- `app/lib/widgets/core/premium_bottom_sheet.dart`. Contains: sheet helper with 20 top radius and safe-area handling. Used by: menu, site settings, downloads.
- `app/lib/widgets/core/premium_dialog.dart`. Contains: a 16-radius dialog with a filled primary and a text secondary action. Used by: confirmations, JS dialogs.

Tests: `premium_components_golden_test` with `test/support/golden_helpers.dart` (light, dark, right-to-left, 2x text scale) and a semantics test (labels present, 48dp targets).

Run: branch `batch/b4`, commit `b4: core widgets and icons`.

### B5. Platform layer: engines, launchers, factory

- `app/lib/platform/platform_info.dart`. Contains: a thin `dart:io` wrapper (`isAndroid`, `isIOS`). Used by: platform\_factory.
- `app/lib/platform/common/shared_prefs_key_value_store.dart`. Contains: `KeyValueStore` over `shared_preferences`, every call in try and catch with an in-memory fallback and a failure flag. Used by: settings\_service through bootstrap.
- `app/lib/platform/common/package_info_app_info.dart`. Contains: `AppInfo` over `package_info_plus`.
- `app/lib/platform/common/share_plus_share.dart`. Contains: `Share` over `share_plus`.
- `app/lib/platform/common/url_launcher_external_launcher.dart`. Contains: system-browser open (`LaunchMode.externalApplication`), `tel:`, `mailto:` and `sms:` handling. Used by: iOS directly; Android extends it.
- `app/lib/platform/common/inappwebview_engine_base.dart`. Contains: the abstract `BrowserEngine` implementation: builds `InAppWebView`; shared settings (JavaScript on, multiple windows supported, inline media, `useHybridComposition` true); a per-tab controller map; load, progress, title, icon and history callbacks mapped to `TabEvent`s; `shouldOverrideUrlLoading` routed to the `NavigationPolicy`; a `PullToRefreshController` per tab styled with token colours that ends refreshing on finish or error; Safe Browsing and the fraudulent-website warning on by default, driven by the Privacy switch; hook methods `configureSettings` and `userAgentFor`. Later batches complete the callback matrix in section 4. Used by: both engines.
- `app/lib/platform/android/android_browser_engine.dart`. Contains: Android settings (mixed-content policy, Safe Browsing on from Android 8). Extends: the base.
- `app/lib/platform/ios/ios_browser_engine.dart`. Contains: iOS settings (back-forward swipe, fraudulent-website warning on, inline media; AirPlay for media stays at its default of on). Extends: the base.
- `app/lib/platform/android/android_external_launcher.dart`. Contains: `intent://` handling through `parseIntentUri` and `url_launcher`, `market://`, and the `S.browser_fallback_url` fallback. Extends: the common launcher.
- `app/lib/platform/platform_factory.dart`. Contains: returns a `PlatformServices` bundle (engine, launcher, share, key-value store, app info), chosen at runtime; later batches add fields. Used by: bootstrap only.

Modified: `docs/DECISIONS.md` (D-21: Safe Browsing and the fraudulent-website warning are on by default with a Privacy switch, and the privacy policy discloses that Google and Apple check visited addresses against their lists).

Run: branch `batch/b5`, commit `b5: platform layer`.

### B6. Services and providers

- `app/lib/core/services/url_policy_service.dart`. Contains: classifies a navigation as allow, open-external or block (scheme allowlist, intent, market, tel and mailto routing). B19 adds the HTTPS upgrade, PDF interception and `disallowed_useragent` detection. Used by: tabs\_provider through the engine's `NavigationPolicy`.
- `app/lib/core/services/settings_service.dart`. Contains: load and save of `AppSettings` through `KeyValueStore`, schema-version check, corrupt-value recovery to defaults. Used by: settings\_provider.
- `app/lib/core/providers/settings_provider.dart`. Contains: `ValueNotifier<AppSettings>`, typed setters, a persistence-failure notifier. Used by: theme, locale, settings\_screen.
- `app/lib/core/providers/theme_provider.dart`. Contains: the theme mode derived from settings. Used by: app\_shell.
- `app/lib/core/providers/locale_provider.dart`. Contains: locale override or system. Used by: app\_shell, the Language row (B39).
- `app/lib/core/providers/tabs_provider.dart`. Contains: the final-shape `ValueNotifier<TabsState>` (tabs, active index); open, close, select; consumes `TabEvent`s; `navigate(text)` through `url_utils` and the policy; closing the last tab creates a blank one. B11 adds persistence hooks. Used by: browser\_screen, tabs\_screen.

Tests: `test/support/fakes.dart` (FakeKeyValueStore, FakeBrowserEngine), `url_policy_service_test`, `settings_service_test` (corrupt value recovery), `tabs_provider_test` (index rules, last-tab close).

Run: branch `batch/b6`, commit `b6: services and providers`.

### B7. Browser and settings widgets

- `app/lib/widgets/browser/page_progress_bar.dart`. Contains: a 2 px accent bar that collapses to zero height when idle. Used by: browser\_screen.
- `app/lib/widgets/browser/address_bar.dart`. Contains: a 48dp pill field built on `premium_text_field`; the host when unfocused, the full URL selected on focus; clear and go actions; an explicit Not secure label for http (scheme only, no certificate claim); semantics. Uses: url\_utils, icon\_chip. Used by: browser\_screen.
- `app/lib/widgets/browser/browser_nav_bar.dart`. Contains: back, forward, reload or stop, and menu as icon chips with disabled states. B12 adds the tab count button; B21a adds the long-press list. Used by: browser\_screen.
- `app/lib/widgets/browser/browser_menu_sheet.dart`. Contains: a bottom sheet rendering a `List<MenuAction>`; B7 items: Reload or Stop, Share, Open in system browser, Settings. Every later batch adds its rows from the menu table in section 7. Used by: browser\_screen.
- `app/lib/widgets/settings/setting_tile.dart`, `setting_switch.dart` (built on premium\_toggle), `setting_choice_tile.dart`. Contains: row-based settings controls built on premium\_row. Used by: all settings screens.

Tests: `address_bar_test` (focus, submit, http label) with a golden; `browser_nav_bar_test` (disabled states, semantics).

Run: branch `batch/b7`, commit `b7: browser and settings widgets`.

### B8. Screens and shell

- `app/lib/screens/browser_screen.dart`. Contains: the address bar on top, the progress bar, `engine.buildTab(...)` filling the middle, the nav bar below; both safe-area edges; fixed chrome; pull to refresh; the Android Back button navigates web view history first (`PopScope`); an inline error view with Retry for main-frame load errors; a layout stable under the keyboard. Uses: tabs\_provider, browser\_engine. The entry route.
- `app/lib/screens/settings_screen.dart`. Contains: Appearance (theme) and Search engine (a choice tile). Other sections arrive with their batches.
- `app/lib/app/app_scope.dart`. Contains: an `InheritedWidget` exposing `AppDependencies` (providers, services, engine). Used by: screens through helpers.
- `app/lib/app/bootstrap.dart`. Contains: async init: error handler, platform factory, settings load, provider construction. Returns `AppDependencies`.
- `app/lib/app/app_shell.dart`. Contains: `WidgetsApp` (no Material app shell) with `AppTheme` from theme\_provider, `AppScrollBehavior`, delegates `[AppLocalizations.delegate, GlobalWidgetsLocalizations.delegate]`, supported locales, `AppPageRoute` as the page route builder, the global error widget and the router. Used by: main.
- `app/lib/app/router.dart`. Contains: named routes (`/`, `/settings`) with motion-spec transitions through `AppPageRoute`; later batches add routes.
- `app/lib/main.dart`. Contains: the guarded entry: `runGuarded(() async { deps = await bootstrap(); runApp(AppScope(deps, AppShell())); })`.

Tests: `widget_test` (the app boots with fakes, the address bar is present, the theme toggle changes the theme).

Run: branch `batch/b8`, commit `b8: screens and shell`.

### B9. Native configuration (read the generated files first)

The generated scaffold (Flutter 3.47.7) uses Android Gradle Plugin 9.1.0, Kotlin 2.4.0 and Gradle 9.3.1 with Kotlin-script Gradle files, no iOS Podfile (Swift Package Manager), and an iOS `SceneDelegate`; the entries below are applied to those generated files.

- `app/android/app/src/main/AndroidManifest.xml` (Modified). Contains: `INTERNET`; `usesCleartextTraffic="true"`; `allowBackup="false"`; `windowSoftInputMode=adjustResize`; the application label "Tahor Fast & Private Browser"; `<queries>` for http and https VIEW intents (package visibility for `url_launcher`). No other permissions yet.
- `app/android/app/build.gradle(.kts)` (Modified; whichever the pinned template generated). Contains: `minSdk 24`, `applicationId com.zdmgold.tahorbrowser`, R8 shrinking for release, debug signing only (release signing arrives in B41).
- `app/android/app/proguard-rules.pro`. Contains: keep rules the web view plugin needs.
- `app/ios/Runner.xcodeproj` and `app/ios/Flutter` settings (Modified). Contains: `platform :ios, '15.5'` in a Podfile only if the generated project has one (Flutter 3.44 and later default to Swift Package Manager); the deployment target set to 15.5 in the Runner project either way, and the device family to iPhone only (`TARGETED_DEVICE_FAMILY = 1`).
- `app/ios/Runner/Info.plist` (Modified). Contains: display name "Tahor Fast & Private Browser"; `NSAppTransportSecurity` with `NSAllowsArbitraryLoadsInWebContent` true; `LSApplicationQueriesSchemes` (tel, mailto, sms, http, https); supported orientations for portrait and landscape. Usage strings arrive with the batch that needs each.

Run: branch `batch/b9`, commit `b9: native configuration`. Then the M1 exit (section 6.8): the emulator integration run and the M1 checklist; the first release build creates `docs/size-baseline.json`.

## 10. File manifest, M2: Tabs and sessions (B10 to B13)

**M2 exit:** this is the first installable test APK (D-34). On a phone with Don't keep activities on, open four tabs, scroll each, leave and return, then swipe the app away and relaunch; open eight tabs and confirm memory stays stable (hibernation); the agent runs the Android integration workflow and Codemagic `ios-verify` (iOS-1) and reviews the screenshots.

### B10. Persistence foundation

- `app/lib/core/models/session_snapshot.dart`. Contains: version, the ordered non-incognito tab list, active index, savedAt. Used by: session\_restore\_service.
- `app/lib/core/contracts/local_database.dart`. Contains: versioned open, execute, query, transaction. Implemented by: sqflite\_local\_database. Used by: the history, bookmark and site-settings services.
- `app/lib/core/contracts/file_store.dart`. Contains: atomic write, read and delete of bytes by namespace and key. Implemented by: io\_file\_store. Used by: webview\_state\_store, thumbnail\_cache, the blocklist cache, PDF cache.
- `app/lib/core/storage/schema_version.dart`. Contains: the current version integer per store. Used by: migrations.
- `app/lib/core/storage/storage_keys.dart`. Contains: every key and namespace name in one file. Used by: all services.
- `app/lib/core/storage/migrations.dart`. Contains: ordered migrations for key-value and database stores; the downgrade policy (refuse, recover to empty, raise a recoverable error). Used by: bootstrap.
- `app/lib/core/storage/persistence_guard.dart`. Contains: a wrapper that turns any storage failure into an in-memory fallback plus a warning notifier. Used by: services, persistence\_warning\_banner.
- `app/lib/core/storage/webview_state_store.dart`. Contains: per-tab state blobs with a size cap and LRU eviction on top of `file_store`. Used by: session\_restore\_service, tab\_lifecycle\_service.
- `app/lib/platform/common/sqflite_local_database.dart` and `io_file_store.dart`. Contains: the adapters, with try and catch and corrupted-file recovery. Used by: platform\_factory (Modified).

Tests: `migrations_test`, `persistence_guard_test`, `session_snapshot_roundtrip_test`, `webview_state_store_test` (LRU).

Run: branch `batch/b10`, commit `b10: persistence foundation`.

### B11. Session restore and tab lifecycle

- `app/lib/core/scripts/scroll_capture_script.dart`. Contains: JavaScript strings that read `window.scrollY` and restore it with up to five retries until the document is tall enough. Used by: session\_restore\_service through `engine.evaluate`.
- `app/lib/core/services/session_restore_service.dart`. Contains: debounced (500 ms) write-through of the snapshot on every tab change; a flush on pause; scroll capture on pause; on cold start it recreates the tabs in order, loads only the active tab and restores the others lazily; the start-up choice from B12 decides between restoring and the start page; incognito tabs are excluded. Uses: file\_store, webview\_state\_store, engine. Used by: tabs\_provider, bootstrap.
- `app/lib/core/services/tab_lifecycle_service.dart`. Contains: keeps at most three live engines; hibernates the least recently used (save state, thumbnail, dispose the controller) and wakes on selection. Used by: tabs\_provider.
- `app/lib/core/services/thumbnail_cache.dart`. Contains: capped PNG thumbnails by tab id, purged on close. Used by: tab\_card.

Modified: `browser_engine.dart` (adds `saveState`, `restoreState`, `evaluate`, `takeThumbnail`), `inappwebview_engine_base.dart` and both engines (implement them with the plugin's `saveState` and `restoreState`, present on both platforms in 6.2.0-beta.3; a restore that throws falls back to URL plus scroll), `tabs_provider.dart` (change stream, `restore`), `bootstrap.dart`, `app_shell.dart` (a lifecycle observer).

Tests: `session_restore_service_test` (debounce, incognito excluded, lazy load), `tab_lifecycle_service_test`, `thumbnail_cache_test`.

Run: branch `batch/b11`, commit `b11: session restore and tab lifecycle`.

### B12. Tab interface, copy link, reopen closed tab, start-up choice

- `app/lib/widgets/browser/tab_count_button.dart`. Contains: a 40x40 chip with the count (99+ cap) and a semantic label. Used by: browser\_nav\_bar.
- `app/lib/widgets/browser/tab_card.dart`. Contains: thumbnail, favicon, title, host, a 48dp close button, an active border in the focus colour. Used by: tabs\_screen.
- `app/lib/widgets/browser/new_tab_page.dart`. Contains: the wordmark (brand once) and a search entry that focuses the address bar. B26 adds bookmark shortcuts, B32 a scan shortcut, B34 the collapsing banner slot. Used by: browser\_screen.
- `app/lib/widgets/core/persistence_warning_banner.dart`. Contains: a banner shown when the persistence guard has fallen back to memory. Used by: browser\_screen.
- `app/lib/widgets/core/feedback_banner.dart`. Contains: explicit success or failure feedback after save, delete, share and copy. Used by: all action flows.
- `app/lib/screens/tabs_screen.dart`. Contains: a grid of tab cards, a new-tab primary button, close all with confirmation, and a Reopen closed tab button. Uses: tabs\_provider, thumbnail\_cache.

Modified: `browser_nav_bar.dart` (tab count button), `browser_screen.dart`, `browser_menu_sheet.dart` (New tab, Reopen closed tab, Copy link, which writes the page URL with the clipboard and shows a feedback banner), `tabs_provider.dart` (keeps the last ten closed tabs of the session: URL, title, saved-state key), `app_settings.dart` (`startupMode`: continue where I left off, the default, or start page), `settings_screen.dart` (General), `router.dart` (`/tabs`), `app_en.arb`. Tests: `tabs_screen_test`, goldens for `tab_card` and `tab_count_button`, a reopen-closed-tab case in `tabs_provider_test`.

Run: branch `batch/b12`, commit `b12: tab interface, copy link, reopen closed tab, start-up choice`.

### B13. Integration harness and iOS verify

- `app/integration_test/support/test_app.dart`. Contains: boots the real app with the real engine and persisted stores, with a teardown and re-bootstrap helper to simulate a restart.
- `app/integration_test/support/fixtures.dart`. Contains: HTML fixtures as Dart strings loaded as initial data (never shipped as assets).
- `app/integration_test/browser_smoke_test.dart`. Contains: load a fixture, assert the title, back and forward, open and close tabs.
- `app/integration_test/session_restore_test.dart`. Contains: three tabs, scroll, restart, assert tabs, the active index and scroll.
- `.github/workflows/integration-android.yml`. Contains: manual; ubuntu with KVM; `reactivecircus/android-emulator-runner` (API 30); `flutter test integration_test`; uploads logs and screenshots.
- `codemagic.yaml`. Contains: workflow `ios-verify` on `mac_mini_m2` with a 60-minute cap, manual trigger: pub get, `pod install` only if a Podfile exists, `flutter build ios --simulator --no-codesign`, boot a simulator, run the integration tests, capture screenshots with `xcrun simctl io booted screenshot`, store them as artifacts. No publishing section yet.

Run: branch `batch/b13`, commit `b13: integration harness and iOS verify`. Then the M2 exit: the first debug APK, and iOS-1 (sections 6.8 and 6.9).

## 11. File manifest, M3: Ad blocking (B14 to B17)

**M3 exit:** the agent runs the Android integration workflow and iOS-2 and reviews the output. The owner's phone check happens in the final test APK: visit two ad-heavy news sites: ads are absent and the page is usable; the per-site exception works; Update lists in airplane mode shows a failure and keeps the lists; YouTube behaviour is checked and described honestly.

### B14. Blocklist assets, tools, signing

- `app/assets/blocklist/canonical_blocklist.txt`. Contains: the first-launch seed in the grammar of section 4 (the highest-impact ad and tracker hosts, capped by the converter's seed limit), with a header comment (version, date, sources). Cosmetic rules live in the same file as `hide|` lines, so there is one parser. The full list is published on the website and downloaded on first launch. Used by: blocklist\_service.
- `app/assets/blocklist/manifest.json`. Contains: a monotonic list version, sha256, `minAppVersion` and the feature-flag map (kill switches). Used by: blocklist\_verifier, feature\_flags\_provider.
- `app/assets/blocklist/SOURCES.md`. Contains: upstream lists, their licences (EasyList and EasyPrivacy are dual-licensed GPLv3-or-later and CC BY-SA 3.0-or-later; attribution to The EasyList authors is required and the converted list is published under the same terms) and a note of modifications. Used by: about\_screen licences, store documents.
- `app/assets/blocklist/update_public_key.txt`. Contains: the Ed25519 public key (base64). Used by: blocklist\_verifier. The keypair is generated before this batch is pushed, so the real public key is committed here.
- `tools/blocklist/pubspec.yaml`. Contains: the pure-Dart tool package.
- `tools/blocklist/convert_abp_to_canonical.dart`. Contains: a CLI that reads ABP-syntax lists, keeps the supported subset (domain anchors, path prefixes, `$third-party`, resource types, `$domain=`, `##` element hiding), drops the rest (regex, scriptlets, redirects), reports the dropped counts, enforces size and rule-count caps, and writes two files: the compact seed bundled in the app and the full list published on the website.
- `tools/blocklist/sign_blocklist.dart`. Contains: computes sha256, writes the manifest with the next version and signs it with the Ed25519 private key from the environment.
- `.github/workflows/publish-blocklist.yml`. Contains: manual; downloads the upstream lists, runs the converter and signer with `BLOCKLIST_SIGNING_KEY_B64`, and commits `latest.txt`, `manifest.json` and `manifest.sig` to `website/blocklist/` on `main` with `GITHUB_TOKEN`.

Modified: `app/pubspec.yaml` (declare assets), `verify.yml` (`dart test` in `tools/blocklist`), `store_submission/ACCOUNTS.md` (signing keypair created). Tests: `tools/blocklist/test/converter_test` (supported subset kept, unsupported dropped and counted, caps and seed limit enforced).

Run: branch `batch/b14`, commit `b14: blocklist assets, tools, signing`. The converter lands first and CI runs it on the upstream lists to produce the seed, which is committed as generated output (never hand-written); the private key is stored as the `BLOCKLIST_SIGNING_KEY_B64` secret and also handed to the owner for backup; `publish-blocklist` is dispatched once.

### B15. Compiler core (pure Dart)

- `app/lib/core/models/blocklist_rule.dart`. Contains: sealed `BlockRule`, `AllowRule`, `HideRule` matching the grammar; value equality. Used by: parser, compiler, cosmetic\_filter.
- `app/lib/core/contracts/http_client.dart`. Contains: `get(Uri, headers, timeout)` returning status and bytes. Implemented by: http\_client\_adapter. Used by: blocklist\_service, the foreground downloader, pdf\_screen, suggestion sources.
- `app/lib/core/blocklist/canonical_parser.dart`. Contains: a line parser that reports per-line errors without failing the file and enforces limits. Used by: blocklist\_service.
- `app/lib/core/blocklist/content_rule_compiler.dart`. Contains: one canonical model, two emitters. iOS: WebKit-format content-rule JSON with merged triggers, lists of at most 50,000 rules, and per-site exceptions appended as `ignore-previous-rules` with `if-domain`. Android: domain-only block rules grouped into alternation regexes, path rules individual under a hard cap, allow rules dropped and counted, and per-site exceptions applied by clearing the content blockers for that host and reloading. Deterministic output; cache key is version plus exception-set hash. Used by: blocklist\_service, adblock\_provider.
- `app/lib/core/blocklist/cosmetic_filter.dart`. Contains: `hide` rules to `css-display-none` entries (domain-scoped and generic) plus a small document-start script for dynamic fallbacks. Used by: the compiler, the engine.
- `app/lib/core/blocklist/blocklist_verifier.dart`. Contains: the Ed25519 signature check against the bundled key, the sha256 check, rejection of non-increasing versions. Used by: blocklist\_service.
- `app/lib/core/blocklist/blocklist_service.dart`. Contains: load the seed, parse, compile and expose `CompiledBlocklist`; the first launch fetches the full signed list once in the background, and later refreshes are manual (or weekly if the switch in Ad blocking settings is on; it is off by default); fetch, verify, compile, persist to `file_store`, swap; a failed or unverifiable fetch never replaces the last good or bundled list; a status notifier. Used by: adblock\_provider.

Tests: `canonical_parser_test`, `content_rule_compiler_test` (golden JSON in `test/fixtures/blocklist/`), `cosmetic_filter_test`, `blocklist_verifier_test` (valid, tampered, rollback), `blocklist_service_test` (a failed fetch keeps the last good list).

Run: branch `batch/b15`, commit `b15: compiler core`.

### B16. Site settings, providers, shield, ad-block screen

- `app/lib/core/models/site_setting.dart`. Contains: host, jsEnabled, desktopMode (nullable), adblockEnabled, permission decisions (camera, microphone, location: ask, allow, deny), updatedAt. Used by: site\_settings\_service, view\_mode\_provider, adblock\_provider.
- `app/lib/core/services/site_settings_service.dart`. Contains: CRUD over `local_database` (table `site_settings`, schema v2), registrable-host normalization, a cache. Used by: site\_settings\_provider.
- `app/lib/core/providers/site_settings_provider.dart`. Contains: the current host's settings notifier and setters; change events consumed by adblock and the engine.
- `app/lib/core/providers/adblock_provider.dart`. Contains: the global switch, compiled lists, per-site exceptions derived from site settings, refresh status, `rulesForHost(host)`; tells the engine to re-apply on change. Used by: engine wiring, shield\_button, adblock\_settings\_screen.
- `app/lib/core/providers/feature_flags_provider.dart`. Contains: flags from the verified manifest with compiled-in defaults; `isEnabled(flag)`; kill switches for blocklist refresh, tier-3 downloads, reader, translation, cast. Used by: providers and screens.
- `app/lib/platform/common/http_client_adapter.dart`. Contains: `HttpClient` over `package:http` with timeouts, a retry budget of two and an app-specific user agent.
- `app/lib/widgets/browser/shield_button.dart`. Contains: a 40x40 chip with on, off and site-exception states; it opens a one-switch sheet until B18 re-points it to `site_settings_sheet`. No blocked-count claim.
- `app/lib/screens/adblock_settings_screen.dart`. Contains: the global switch, the list version and date, a primary Update lists now button with explicit result feedback, the weekly auto-update switch (off by default), the per-site exceptions list, and honest limits text (in-stream video ads are not blocked).

Modified: `settings_screen` (Ad blocking), `router` (`/adblock`), `address_bar` (shield slot), `browser_screen`, `app_en.arb`. Tests: `adblock_provider_test`, `site_settings_service_test`, `feature_flags_provider_test` (defaults, kill switch), a `shield_button` golden.

Run: branch `batch/b16`, commit `b16: site settings, providers, shield, ad-block screen`.

### B17. Engine wiring and performance gate

Modified: `browser_engine.dart` (adds `setContentRules`, `setUserScripts`), `inappwebview_engine_base.dart` (applies the plugin's `ContentBlocker` lists and document-start scripts per tab and re-applies on change), both engines (Android: css-display-none needs JavaScript on), `bootstrap.dart` (blocklist service and providers; compile runs off the UI isolate and tabs load with the cached lists), `platform_factory.dart` (HTTP client), `tool/ci_checks.sh` (assets declared).

- `app/integration_test/adblock_test.dart`. Contains: a fixture page referencing a blocked and an allowed resource; asserts the blocked one never loads and the allowed one does; the per-site exception test; the hide-rule test; and the Android performance gate (load time of a 100-subresource fixture with the Android rule set within 15% of the same page with no rules, otherwise halve the cap); on iOS the test compiles every list in WebKit and fails if WebKit rejects one.

Run: branch `batch/b17`, commit `b17: engine wiring and performance gate`. Then the M3 exit and iOS-2.

## 12. File manifest, M4: Web completeness (B18 to B22a)

**M4 exit:** the agent runs the integration workflows. The owner's phone check happens in the final test APK: ten representative sites in mobile and desktop mode (news, video, maps, social, bank-style login, e-commerce, documents, search, webmail, forum; the list is recorded in DECISIONS); a Google sign-in page triggers the banner and the system-browser handoff works; a camera permission test page; a PDF opens; an HTTP-only site shows the interstitial; `target=_blank` opens a tab; JS dialogs work; find in page, print, the back/forward list and the link menu work; a picture-in-picture check on iOS video (the plugin's `allowsPictureInPictureMediaPlayback` is on by default).

### B18. Dialogs, sheets, interstitials

- `app/lib/widgets/browser/js_alert_dialog.dart`. Contains: alert, confirm and prompt with the origin host shown and a Prevent more dialogs option after two. Uses: premium\_dialog. Used by: browser\_screen.
- `app/lib/widgets/browser/site_settings_sheet.dart`. Contains: a host header; switches for JavaScript, ad blocking and desktop site; camera, microphone and location rows (ask, allow, deny); also the runtime permission prompt variant. Used by: shield\_button, browser\_menu\_sheet, browser\_screen.
- `app/lib/widgets/browser/https_interstitial.dart`. Contains: shown when the HTTPS upgrade fails (Go back primary, Continue over HTTP once) and for certificate errors (Go back primary, proceed hidden behind a details expander, per session only). Used by: browser\_screen.
- `app/lib/widgets/browser/open_in_system_browser_banner.dart`. Contains: a dismissible per-host banner offering the handoff when a site refuses embedded web views. Uses: external\_launcher.
- `app/lib/widgets/browser/image_long_press_menu.dart`. Contains: the image menu (Open image, Open in new tab, Copy image link, Share); B21a adds the link targets and B25 adds Save image.
- `app/lib/widgets/browser/view_mode_toggle.dart`. Contains: the menu control for mobile or desktop with the current state.

Modified: `shield_button.dart` (opens `site_settings_sheet`). Tests: goldens and semantics for each; dialog-suppression logic test.

Run: branch `batch/b18`, commit `b18: dialogs, sheets, interstitials`.

### B19. Policy, user agents, view mode

- `app/lib/core/utils/user_agent_utils.dart`. Contains: pure functions deriving a desktop UA (and a browser-like UA with the web-view marker removed) from the engine's default UA, and the iOS desktop Safari UA. Used by: engines, view\_mode\_provider.
- `app/lib/core/scripts/viewport_script.dart`. Contains: document-start JavaScript that rewrites the viewport meta for desktop width and restores it for mobile. Used by: the engine.
- `app/lib/core/providers/view_mode_provider.dart`. Contains: per-tab mode with per-site memory through site settings; triggers the UA change and a reload. Used by: view\_mode\_toggle, tabs\_provider.

Modified: `url_policy_service.dart` (HTTPS-only upgrade with a fallback signal; PDF detection by extension and a content-type hook; `disallowed_useragent` detection from the URL pattern on known identity hosts plus a 403 status; intent routing), `app_settings.dart` (`httpsOnly`, default on, with a migration), `site_settings_provider.dart` (permission decisions), `tabs_provider.dart` (pending suggestions per tab). Tests: `user_agent_utils_test` (Android WebView and iOS fixtures), `url_policy_service_test` (upgrade, fallback, disallowed\_useragent), `view_mode_provider_test`.

Run: branch `batch/b19`, commit `b19: policy, user agents, view mode`.

### B20. Callback contracts and adapters, Safe Browsing handler

- `app/lib/core/contracts/permissions.dart`. Contains: query and request camera, microphone and location at the OS level, open app settings; B24 adds notifications. Used by: site\_settings\_provider, the QR flow, downloads.
- `app/lib/core/contracts/fullscreen.dart`. Contains: enter and exit immersive mode and release orientation.
- `app/lib/core/contracts/pdf_viewer.dart`. Contains: a document API: open a file, page count, render page N at a given width into an image. There is no viewer widget; our own paging and zoom view is built on widgets in B21.
- `app/lib/platform/common/permission_handler_permissions.dart`, `fullscreen_adapter.dart`, `pdfrx_pdf_viewer.dart`. Contains: the adapters; fullscreen restores on exit, on dispose and on lifecycle change; the PDF adapter uses only pdfrx's rendering API.

Modified: `browser_engine.dart` (events NewWindowRequested, JsDialogRequested, PermissionRequested, GeolocationRequested, FullscreenChanged, ServerTrustError, HttpError, PdfDetected, RenderProcessGone; actions `resolveJsDialog`, `resolvePermission`, `setDesktopMode`), `inappwebview_engine_base.dart` (wires the callback matrix in section 4, including `onSafeBrowsingHit` answered with `SHOW_INTERSTITIAL` and reporting off, and a reload from saved state after a renderer crash), `android_browser_engine.dart` (permission, geolocation and fullscreen custom-view handling; the file chooser stays at the plugin default), `ios_browser_engine.dart` (iOS 15 media-capture permission delegate), `platform_factory.dart`. Tests: fakes extended; permission-flow tests in the provider tests; a `safe_browsing_handler_test`.

Run: branch `batch/b20`, commit `b20: callback contracts and adapters, Safe Browsing handler`.

### B21. Site settings, PDF and About screens

- `app/lib/screens/site_settings_screen.dart`. Contains: the hosts with overrides, remove one or clear all with confirmation.
- `app/lib/screens/pdf_screen.dart`. Contains: our own viewer (pages rendered through pdfrx's engine into a zoomable list) with a page indicator, share and open in system; remote PDFs are fetched to a cache file with progress through `http_client`.
- `app/lib/screens/about_screen.dart`. Contains: version, privacy and support links, open-source licences (Flutter plus the blocklist attribution) and an honest limitations note (about 90% of Chrome's compatibility; some sign-in pages need your system browser). Restore purchases is added in B35.

Modified: `settings_screen` (site settings, About), `router`, `browser_screen` (hosts banners, interstitials, dialogs and fullscreen; new windows open as tabs; PDF detection routes to `/pdf`), `browser_menu_sheet` (Desktop site, Site settings, Open in system browser), `app_en.arb`. Tests: widget tests for the banner and interstitial flows against `FakeBrowserEngine`.

Run: branch `batch/b21`, commit `b21: site settings, PDF and About screens`.

### B21a. Find in page, back/forward list, link menu, print

- `app/lib/core/providers/find_provider.dart`. Contains: open or closed state, query, active match and total (from the engine's find-result event), next, previous, close. Uses: browser\_engine. Used by: find\_bar, browser\_screen.
- `app/lib/widgets/browser/find_bar.dart`. Contains: a bar above the keyboard with a `premium_text_field`, a "3 of 12" counter, previous and next icon chips and a close chip; stable under the keyboard. Used by: browser\_screen, browser\_menu\_sheet.
- `app/lib/widgets/browser/back_forward_sheet.dart`. Contains: the tab's session-history entries (title, host, current marked); tapping one jumps there. Opened by long-press on Back or Forward. Used by: browser\_nav\_bar.

Modified: `image_long_press_menu.dart` (link target: Open, Open in new tab, Open in private tab once B27 lands, Copy link, Share link; image target as before; a linked image shows both), `browser_engine.dart` (`findAll`, `findNext`, `clearMatches`, a `FindResult` event; `printPage`; `backForwardList`, `goToIndex`; a `LongPressTarget` event with kind and URL), `inappwebview_engine_base.dart` (one `FindInteractionController` per tab with `isFindInteractionEnabled` left off so counts are reported on iOS; `printCurrentPage` and `onPrintRequest`; `getCopyBackForwardList` and `goTo`; `onLongPressHitTestResult`), `browser_nav_bar.dart`, `browser_menu_sheet.dart` (Find in page, Print or Save as PDF), `browser_screen.dart`, `app_en.arb`. Tests: `find_provider_test`, widget tests for each long-press target, a find and a print case in the contract test (B22).

Run: branch `batch/b21a`, commit `b21a: find in page, back/forward list, link menu, print`.

### B22. Manifest, plist and contract tests

Modified: `AndroidManifest.xml` (adds `CAMERA`, `RECORD_AUDIO`, `MODIFY_AUDIO_SETTINGS`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, with camera, microphone and location `uses-feature required="false"`; all runtime, no install prompt), `Info.plist` (`NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSLocationWhenInUseUsageDescription`, each tied to the real feature), `tool/ci_checks.sh` (the permission allowlist from section 4 and a check for the Info.plist keys Apple forbids with the default-browser entitlement).

- `app/integration_test/webview_contract_test.dart`. Contains: fixture pages that trigger alert, confirm and prompt, `window.open`, `target=_blank`, a fullscreen request, a file input, find in page and `window.print()`; asserts each is handled with no silent failure.

Run: branch `batch/b22`, commit `b22: manifest, plist and contract tests`.

### B22a. Incoming links and default browser

Verified: Android lists a browser through an `ACTION_VIEW` intent filter with `DEFAULT` and `BROWSABLE` categories and `http` and `https` schemes, and `RoleManager.ROLE_BROWSER` requests the role; Apple requires `http` and `https` in `Info.plist` and the managed entitlement; Flutter's own deep-link handling must be switched off so the full URL reaches our code (section 2). The generated iOS project uses a `SceneDelegate`, so incoming URLs arrive through the scene delegate's open-URL and continue-activity callbacks as well as `AppDelegate`; both are wired to the channel.

- `app/lib/core/contracts/incoming_links.dart`. Contains: `initialLink()` and a stream of links opened from other apps. Implemented by: method\_channel\_incoming\_links. Used by: incoming\_link\_service.
- `app/lib/core/contracts/default_browser.dart`. Contains: `requestDefault()`. Implemented by: the two platform adapters. Used by: settings\_screen.
- `app/lib/core/services/incoming_link_service.dart`. Contains: accepts only `http` and `https`, ignores everything else, waits for session restore on a cold start, opens the link in a new tab, drops duplicates delivered twice. Uses: tabs\_provider.
- `app/lib/platform/common/method_channel_incoming_links.dart`. Contains: the channel client for `tahorbrowser/links`.
- `app/lib/platform/android/android_default_browser.dart`. Contains: the channel client that requests the browser role.
- `app/android/app/src/main/kotlin/com/zdmgold/tahorbrowser/DefaultBrowserChannel.kt`. Contains: requests `ROLE_BROWSER` on Android 10 and later and opens the system default-apps settings on older versions.
- `app/lib/platform/ios/ios_default_browser.dart`. Contains: opens the app's page in system Settings, where the Default Browser App choice appears once the entitlement is present.
- `app/ios/Runner/Runner.entitlements`. Contains: `com.apple.developer.web-browser` set to true. Created only after Apple grants the entitlement (the request form is submitted as soon as the paid account exists, at B42); it needs manual signing with the managed-capability profile in `codemagic.yaml`. If it is not granted by the first iOS release, iOS ships without default-browser support and Android is unaffected.

Modified: `MainActivity.kt` (the link channel: launch intent and `onNewIntent`), `AndroidManifest.xml` (the browser intent filter, `flutter_deeplinking_enabled` false, `launchMode` singleTop), `AppDelegate.swift` and `SceneDelegate.swift` (open-URL callbacks to the channel), `Info.plist` (`CFBundleURLTypes` for `http` and `https`, `FlutterDeepLinkingEnabled` false), `settings_screen.dart` (the Default browser row), `platform_factory.dart`, `app_en.arb`. Tests: `incoming_link_service_test` (scheme filter, cold-start order, duplicates); `info_plist_test` also fails on the forbidden keys.

Run: branch `batch/b22a`, commit `b22a: incoming links and default browser`. Then the M4 exit.

## 13. File manifest, M5: Downloads (B23 to B25)

Verified: pausing works only for GET downloads, with `allowPause` true and a server that supports it (`taskCanResume`); iOS requires https URLs and the Background Fetch capability; Android 13 and later needs `POST_NOTIFICATIONS` for notifications; `moveToSharedStorage` moves a finished file to the shared Downloads folder on Android. A blob or data URL has no server to resume from, so those downloads cannot resume.

**M5 exit:** the agent runs the integration workflows including the download test. The owner's phone check happens in the final test APK: download a PDF, a zip and an image from real sites; a cookie-gated file; a blob download from a web app; a blob over 20 MB shows the clear error; pause and resume (toggle airplane mode mid-download), cancel, delete, open and share each work.

### B23. Download core

- `app/lib/core/models/download_item.dart`. Contains: id, url, file name, MIME type, total and received bytes, status, tier, saved path or URI, createdAt, error code. Used by: downloads\_provider, download\_service.
- `app/lib/core/contracts/download_engine.dart`. Contains: Tier-1 start, pause, resume, cancel, progress and status streams. Implemented by: background\_downloader\_engine.
- `app/lib/core/contracts/cookie_store.dart`. Contains: `cookieHeaderFor(Uri)`. Used by: download\_service.
- `app/lib/core/scripts/blob_capture_script.dart`. Contains: JavaScript that catches blob and data link clicks, checks `blob.size` against the ceiling before reading, then sends base64 chunks (256 KB) through a JS handler.
- `app/lib/core/services/blob_handler.dart`. Contains: reassembles chunks, enforces the 20 MB ceiling with a clear `blobTooLarge` error, writes through `file_store`.
- `app/lib/core/services/download_service.dart`. Contains: the tier router: Tier 1 (`background_downloader`, with the web view's cookies, user agent and referer as headers, resumable when the server allows) for every https file download, signed in or not; Tier 2 (a foreground Dart downloader, no pause) only for `http://` URLs on iOS, where background URLSession requires https; Tier 3 for blob and data URLs. Filename sanitizing and collision handling. POST downloads and HLS or DASH streams raise a recoverable not-supported error and are never claimed in marketing.
- `app/lib/core/providers/downloads_provider.dart`. Contains: list and progress notifiers; persists items (table `downloads`, schema v3); retry, pause, resume, cancel, delete.

Modified: `external_launcher.dart` (adds `openFile`). Tests: `blob_handler_test` (assembly, ceiling), `download_service_test` (tier choice, sanitizing, auth headers, http on iOS), `downloads_provider_test`.

Run: branch `batch/b23`, commit `b23: download core`.

### B24. Downloader engine and cookies

- `app/lib/platform/common/webview_cookie_store.dart`. Contains: `CookieStore` over the plugin's cookie manager.
- `app/lib/platform/common/background_downloader_engine.dart`. Contains: `DownloadEngine` over `background_downloader` 9.5.9 for both platforms (background workers on Android, background URLSession on iOS, so downloads continue when the app is not in front). It enqueues https GET downloads with the web view's cookies, user agent and referer as headers and `allowPause` true; exposes status and progress streams; checks `taskCanResume` and hides Pause when the server cannot resume; supports resume and cancel; shows progress notifications with pause, resume and cancel actions. Android moves finished files to the shared Downloads folder with `moveToSharedStorage`; iOS keeps them in app Documents and offers Save to Files through the share sheet. Used by: download\_service.

Modified: `AndroidManifest.xml` (`POST_NOTIFICATIONS` for download notifications; `WRITE_EXTERNAL_STORAGE` with `maxSdkVersion="28"` only), `android/settings.gradle(.kts)` (Kotlin plugin 2.1.0 or newer, which `background_downloader` requires; the generated project already uses Kotlin 2.4.0), `AppDelegate.swift` (sets `UNUserNotificationCenter.current().delegate`), `Info.plist` (`UIBackgroundModes` with `fetch`), `url_launcher_external_launcher.dart` (`openFile` through `open_file`), `inappwebview_engine_base.dart` (DownloadRequested event, blob JS handler, blob script), `permissions.dart` and `permission_handler_permissions.dart` (notification permission requested at the first download), `platform_factory.dart`.

Run: branch `batch/b24`, commit `b24: downloader engine and cookies`.

### B25. Download interface and verification

- `app/lib/widgets/browser/download_sheet.dart`. Contains: confirmation on download start (name, size, Save, Cancel) turning into progress with Pause and Resume.
- `app/lib/screens/downloads_screen.dart`. Contains: premium rows with progress and status chips; open, share, delete, retry, and Pause or Resume while a download runs; an empty state. The banner slot arrives in B34.
- `app/integration_test/download_test.dart`. Contains: a loopback test server serving an attachment, a cookie-gated file and a blob link; asserts all three tiers and a pause then resume of the cookie-gated file against a server that supports ranges.

Modified: `browser_menu_sheet` (Downloads), `image_long_press_menu` (Save image), `router`, `app_en.arb`.

Run: branch `batch/b25`, commit `b25: download interface and verification`. Then the M5 exit.

## 14. File manifest, M6: Privacy and data (B26 to B29)

**M6 exit:** the agent runs the integration workflows and iOS-3. The owner's phone check happens in the final test APK: history is off by default and enabling it records visits; suggestions appear from bookmarks and history only; private tabs leave nothing (and the Android note is visible); the lock engages after backgrounding and the app switcher is blank; Clear browsing data works with a time range; the welcome screen shows once.

### B26. History, bookmarks, folders

- `app/lib/core/models/history_entry.dart`. Contains: id, url, title, host, visitedAt. Used by: history\_service, history\_screen.
- `app/lib/core/models/bookmark.dart`. Contains: id, url, title, faviconUrl, createdAt, position, `folderId`. Used by: bookmark\_service, new\_tab\_page.
- `app/lib/core/models/bookmark_folder.dart`. Contains: id, name, position. Used by: bookmark\_service, bookmarks\_screen.
- `app/lib/core/services/history_service.dart`. Contains: records a visit only when history is enabled and the tab is not private; collapses repeat visits; search, delete range, clear; table `history` (schema v4) indexed on visitedAt with a row cap that prunes the oldest. Used by: history\_provider, tabs\_provider, suggestion\_service.
- `app/lib/core/services/bookmark_service.dart`. Contains: add, remove, toggle by URL, list; folder create, rename, delete and move; tables `bookmarks` and folders (schema v5). Used by: bookmarks\_provider.
- `app/lib/core/providers/history_provider.dart`. Contains: the enabled flag (default off), list and search notifiers.
- `app/lib/core/providers/bookmarks_provider.dart`. Contains: list notifier and `isBookmarked(url)` for the active tab.
- `app/lib/screens/history_screen.dart`. Contains: a day-grouped list with section headers, search, per-row delete, clear with confirmation; the empty state explains that history is off by default and offers to enable it.
- `app/lib/screens/bookmarks_screen.dart`. Contains: folders as rows with a chevron, bookmark rows, edit and delete actions, an empty state. The banner slot arrives in B34.
- `app/lib/widgets/browser/bookmark_edit_sheet.dart`. Contains: title, address and folder picker; delete. Used by: bookmarks\_screen, the Bookmark quick action.

Modified: `app_settings.dart` (`historyEnabled`), `tabs_provider.dart` (page finished feeds history), `browser_menu_sheet` (Bookmark quick action, Bookmarks, History), `new_tab_page` (bookmark shortcuts), `router`, `migrations.dart` (database v4 and v5), `app_en.arb`. Tests: `history_service_test` (disabled records nothing, private tabs excluded, pruning), `bookmark_service_test` (folders, move), provider tests.

Run: branch `batch/b26`, commit `b26: history, bookmarks, folders`.

### B26a. Address-bar suggestions

Local only: nothing typed is sent to anyone before you submit it.

- `app/lib/core/services/suggestion_service.dart`. Contains: matches the typed text against bookmarks, history (if enabled) and open tabs; host-prefix matches rank first, then title matches; at most six results; debounced; also supplies inline completion of the host. Used by: suggestion\_provider.
- `app/lib/core/providers/suggestion_provider.dart`. Contains: the current suggestion list and the completion candidate. Used by: address\_bar.
- `app/lib/widgets/browser/suggestion_list.dart`. Contains: premium rows under the address bar with an icon chip, title and host. Used by: browser\_screen.

Modified: `address_bar.dart` (inline completion), `browser_screen.dart`. Tests: `suggestion_service_test` (ranking, limit, history disabled, private tab).

Run: branch `batch/b26a`, commit `b26a: address-bar suggestions`.

### B27. Private tabs

- `app/lib/core/providers/incognito_provider.dart`. Contains: whether private tabs exist, opening them, and the last-private-tab-closed signal. Used by: tabs\_provider, tabs\_screen.
- `app/lib/core/services/incognito_cleanup_service.dart`. Contains: on the last private tab closing and on app start, calls `engine.clearIncognitoData(hosts)` for the hosts visited in private tabs. iOS: the tab used a non-persistent data store, so nothing remains. Android: cookies are process-wide, so cleanup deletes cookies, web storage and cache for the hosts visited in private tabs; the plugin's `incognito` setting is never enabled on Android because it clears every web view's cookies. Used by: tabs\_provider, bootstrap.
- `app/lib/screens/incognito_home.dart`. Contains: shown for a blank private tab: what is and is not saved, and the Android limitation in plain words.

Modified: `browser_engine.dart` (`incognito` in the tab config, `clearIncognitoData`), both engines (iOS non-persistent store; Android host-scoped cleanup), `tabs_provider.dart`, `session_restore_service.dart` and `thumbnail_cache.dart` (skip private tabs), `history_service.dart` (skip), `tabs_screen.dart` (normal and private switch), `browser_screen.dart` (visual cue), `design_tokens.dart` (adds `incognitoAccent`), `image_long_press_menu.dart` (Open in private tab), `browser_menu_sheet.dart` (New private tab), `app_en.arb`. Tests: `incognito_provider_test`, `incognito_cleanup_service_test` (host tracking, platform paths), a session-exclusion test; integration `incognito_test` (set a cookie in a private tab, close it, assert it is gone).

Run: branch `batch/b27`, commit `b27: private tabs`.

### B28. Biometric lock

- `app/lib/core/contracts/biometric.dart`. Contains: `isAvailable`, `authenticate(reason)` returning success, failed, canceled, unavailable or lockedOut.
- `app/lib/platform/common/local_auth_biometric.dart`. Contains: the adapter over `local_auth` with device-credential fallback.
- `app/lib/core/providers/lock_provider.dart`. Contains: the enabled flag, locking when the app goes to background, locked and unlocked state, failure handling. Used by: app\_shell, privacy\_settings\_screen.
- `app/lib/widgets/browser/biometric_gate.dart`. Contains: an overlay covering content while locked and on the inactive lifecycle state so the app switcher shows nothing.
- `app/lib/screens/lock_screen.dart`. Contains: the wordmark once, a primary Unlock button, a retry state.

Modified: `app_shell.dart` (the gate wraps the navigator), `AndroidManifest.xml` (`USE_BIOMETRIC`), `MainActivity.kt` (extends `FlutterFragmentActivity`, which `local_auth` requires), `Info.plist` (`NSFaceIDUsageDescription`), `tool/ci_checks.sh` (allowlist), `platform_factory.dart`, `app_en.arb`. Tests: `lock_provider_test` (background lock, failure, unavailable).

Run: branch `batch/b28`, commit `b28: biometric lock`.

### B29. Privacy settings, clear data, welcome

- `app/lib/core/services/clear_browsing_data_service.dart`. Contains: selective clear with a time range (last hour, last 24 hours, last 7 days, all time) of history, cookies and site data, cache, the downloads list (files stay) and saved tab state, through the engine and services. iOS honours the range for cookies, site data and cache; Android's cookie, storage and cache calls only clear everything, so the sheet says so and applies all time there. Returns a result report for feedback.
- `app/lib/widgets/browser/clear_data_sheet.dart`. Contains: checkboxes (Browsing history, Cookies and site data, Cached images and files, Downloads list, Saved tabs), time-range chips, a primary Clear button with a confirmation and a feedback banner. Used by: browser\_menu\_sheet, privacy\_settings\_screen.
- `app/lib/screens/privacy_settings_screen.dart`. Contains: save history (off by default), HTTPS-only, Warn about dangerous sites (on by default), biometric lock (only if available), Clear browsing data. B33 adds the consent privacy-options row.
- `app/lib/screens/welcome_screen.dart`. Contains: shown once: no accounts, no analytics from us; says that the app downloads its ad-blocking list from our website once; a history opt-in switch (off), a search engine choice, a primary Continue.

Modified: `settings_screen`, `browser_menu_sheet` (Clear browsing data), `router` (`/privacy`, `/welcome`), `bootstrap.dart` (first-run routing), `app_settings.dart` (`welcomeSeen`, `warnDangerousSites`), `app_en.arb`. Tests: `clear_browsing_data_service_test`, a welcome flow widget test.

Run: branch `batch/b29`, commit `b29: privacy settings, clear data, welcome`. Then the M6 exit and iOS-3.

## 15. File manifest, M7: Comfort (B30 to B32)

**M7 exit:** the agent runs the integration workflows. The owner's phone check happens in the final test APK: reader mode on three articles and one non-article; text size at 150% on real sites; the screen filter dims; one-handed layout with the keyboard open; scan a QR code from another screen; generate one and scan it from another device.

### B30. Reader mode

- `app/lib/core/scripts/reader_extract_script.dart`. Contains: JavaScript that finds the main article by text density, strips navigation, forms and ads, and returns title, byline, sanitized HTML, language and direction with a size cap; plus a cheap `isReadable` probe.
- `app/lib/core/scripts/reader_template.dart`. Contains: a pure function building a self-contained HTML page from the extraction with typography tokens, light and dark, size steps and right-to-left; no external resources; script tags are never emitted.
- `app/lib/core/services/reader_service.dart`. Contains: evaluate the extract, parse, render; a failure becomes a recoverable not-available-here message.
- `app/lib/core/providers/reader_provider.dart`. Contains: reader active per tab, font size, the readable flag from the probe.
- `app/lib/widgets/browser/reader_toolbar.dart`. Contains: size minus and plus chips and close.
- `app/lib/screens/reader_screen.dart`. Contains: a JavaScript-disabled engine tab loaded with the rendered HTML and base URL.

Modified: `browser_engine.dart` (`initialHtml` and a JavaScript-disabled tab config), `address_bar` (reader chip when readable), `browser_menu_sheet` (Reader mode), `router`, `app_en.arb`. Tests: `reader_service_test` (article, non-article and right-to-left fixtures), template sanitization test.

Run: branch `batch/b30`, commit `b30: reader mode`.

### B31. Appearance and text size

- `app/lib/core/providers/appearance_provider.dart`. Contains: enlarge text (100 to 200%), screen filter intensity, one-handed mode; persisted in settings.
- `app/lib/core/scripts/text_zoom_script.dart`. Contains: the iOS text-size CSS script (Android uses the web view's text-zoom setting).
- `app/lib/widgets/settings/setting_slider.dart`. Contains: a labelled slider row on a custom slider (drag, 48dp thumb target, semantics); there is no Material slider.
- `app/lib/widgets/browser/screen_filter_overlay.dart`. Contains: a pointer-transparent tint and dim overlay; not built at zero intensity.
- `app/lib/widgets/browser/one_handed_wrapper.dart`. Contains: a layout swap placing the address bar and nav at the bottom, stable under the keyboard.
- `app/lib/screens/appearance_settings_screen.dart`. Contains: theme, text size with a live preview row, screen filter, one-handed switch.
- `app/lib/widgets/browser/text_size_sheet.dart`. Contains: minus, plus and reset controls with the current percentage, bound to `appearance_provider`. Used by: browser\_menu\_sheet.

Modified: `app_settings.dart`, both engines (text zoom), `browser_screen.dart`, `settings_screen`, `browser_menu_sheet` (Text size), `router`, `app_en.arb`. Tests: `appearance_provider_test`, a one-handed layout golden, an overlay-absent-at-zero test, a text-size sheet widget test.

Run: branch `batch/b31`, commit `b31: appearance and text size`.

### B32. QR scan and generate

- `app/lib/core/contracts/qr_scanner.dart`. Contains: `buildScanner(onCode)` widget factory and a torch toggle.
- `app/lib/platform/common/mobile_scanner_qr.dart`. Contains: the adapter over `mobile_scanner`.
- `app/lib/widgets/browser/qr_code_card.dart`. Contains: a QR code for the current URL drawn by our own painter from the `qr` package on a fixed high-contrast background, with share.
- `app/lib/screens/qr_screen.dart`. Contains: Scan and My page modes; a result sheet with Open and Copy; it never auto-opens; recovery from a permission denied for good, with a button to app settings; non-URL text is shown as text only.

Modified: `android/gradle.properties` (`dev.steenbakker.mobile_scanner.useUnbundled=true`, so Android downloads the barcode model on first use through Google Play Services instead of bundling it), `browser_menu_sheet` (Page QR code, Scan QR code), `new_tab_page` (scan shortcut), `router`, `Info.plist` (the camera string now covers scanning), `app_en.arb`. Tests: `qr_screen_test` with a fake scanner including permission states.

Run: branch `batch/b32`, commit `b32: QR scan and generate`. Then the M7 exit.

## 16. File manifest, M7a: Translate (B32a to B32c)

Verified: `google_mlkit_translation` 0.15.1 needs iOS 15.5 or later and Android API 23 or later; both the source and the target model must be downloaded before translating; `downloadModel` takes `isWifiRequired` (default true); models are about 30 MB each, downloaded on demand, and a loaded translator uses 30 to 150 MB of memory. `google_mlkit_language_id` 0.14.0 detects the source language. Translation runs on the device, so page text is never sent to a server; the model files come from Google.

**M7a exit:** the agent runs the integration translate test. The owner's phone check happens in the final test APK: translate three real pages in three language pairs with the models downloaded over Wi-Fi, and confirm memory stays stable after translating and closing the tab.

### B32a. Translate core (pure Dart)

- `app/lib/core/contracts/translator.dart`. Contains: `detectLanguage(sample)`, `isModelDownloaded(code)`, `downloadModel(code, wifiOnly)`, `deleteModel(code)`, `translate(from, to, texts)`, `close()`. Implemented by: mlkit\_translator. Used by: translation\_service, translation\_models\_screen.
- `app/lib/core/models/translation_language.dart`. Contains: `TranslationLanguage` (code, native name, English name), the ML Kit language list, and the mapping from the app locale to a supported target. Used by: language\_picker\_sheet, translation\_service, translation\_models\_screen.
- `app/lib/core/scripts/translate_scripts.dart`. Contains: four JavaScript constants. Collect walks the text nodes under the body, skipping `script`, `style`, `noscript`, `code`, `pre`, `textarea`, `input`, `select`, editable regions, `translate="no"` and `.notranslate`, skipping whitespace-only and number-only text, returning batches of at most 2,000 characters and stopping at 200,000 characters per page. Apply replaces by id and keeps the originals. Restore puts them back. Observe is a `MutationObserver` that reports new text nodes after 500 ms of quiet. Apply also sets `lang` and right-to-left direction for Arabic, Hebrew, Persian and Urdu targets. Used by: translation\_service through `engine.evaluate` and a JS handler.
- `app/lib/core/services/translation_service.dart`. Contains: detects the source (the page's `lang` attribute, otherwise the first 1,000 characters through the translator); compares it with the target; requires both models (reporting the roughly 30 MB each); translates batches one at a time; applies the results; watches for new content; restores on request; cancels on navigation; closes the translator after 30 seconds idle to release memory; errors through the taxonomy. Uses: translator, translate\_scripts, browser\_engine. Used by: translation\_provider.
- `app/lib/core/providers/translation_provider.dart`. Contains: per-tab state (idle, detecting, needs model, downloading with progress, translating with progress, translated to a language, failed). Used by: translate\_bar, browser\_menu\_sheet.

Modified: `app_settings.dart` (`translateTargetLang`, default the app language when supported and English otherwise; `translateWifiOnly`, default true), `migrations.dart`, `app_en.arb`. Tests: `translation_service_test` (fake translator: model gating, batching, cancel, restore), `translation_language_test` (list integrity, locale mapping), `translate_scripts_test` (skip rules and batch limits on fixture markup).

Run: branch `batch/b32a`, commit `b32a: translate core`.

### B32b. Translate platform and interface

- `app/lib/platform/common/mlkit_translator.dart`. Contains: `Translator` over the two plugins; one `OnDeviceTranslator` per language pair, closed when idle. Used by: platform\_factory.
- `app/lib/widgets/browser/translate_bar.dart`. Contains: a bar under the address bar: "Translate to X", progress, "Show original", and a language chip that opens the picker. Used by: browser\_screen.
- `app/lib/widgets/browser/language_picker_sheet.dart`. Contains: a searchable list of supported languages with a downloaded badge. Used by: translate\_bar, translation\_models\_screen.
- `app/lib/screens/translation_models_screen.dart`. Contains: the language list with download and delete, a model size note, and the Wi-Fi-only switch. Used by: settings\_screen.

Modified: `pubspec.yaml`, `platform_factory.dart`, `settings_screen.dart` (Translation), `browser_menu_sheet.dart` (Translate page, shown when the page language differs from the target), `router.dart`, `tool/ci_checks.sh` (the iOS floor of 15.5), `app_en.arb`.

Run: branch `batch/b32b`, commit `b32b: translate platform and interface`.

### B32c. Translate verification

- `app/integration_test/translate_test.dart`. Contains: a fixture page with a fake translator: collect, apply, observe a late-added node, restore.

Modified: `store_submission/PRIVACY_LABELS.md` (created in B44; until then the note is kept in `docs/DECISIONS.md`) and `website/privacy.html` (written in B43) record that translation runs on the device and model files are downloaded from Google; `docs/DECISIONS.md`.

Run: branch `batch/b32c`, commit `b32c: translate verification`. Then the M7a exit.

## 17. File manifest, M7b: Add to Home Screen and M7c: Cast (B32d to B32h)

### M7b. Add to Home Screen (B32d, B32e)

Verified: Android's `ShortcutManagerCompat` requests a pinned shortcut that opens a website after checking `isRequestPinShortcutSupported` (API 26 and later), with user confirmation. Apple's Add to Home Screen needs the default-browser entitlement and the current `WKWebView` in a `UIActivityViewController`'s `activityItems`. iOS platform views are appended to the view hierarchy, so the web view is found by searching it, the same technique Flutter's own engine uses to detect web views inside platform views.

**M7b exit:** on an Android 8 or later phone (the final test APK), add a site to the home screen and open it from the shortcut; the row is hidden on an unsupported launcher; on iOS the row stays hidden until the entitlement is granted.

#### B32d. Android

- `app/lib/core/contracts/home_screen.dart`. Contains: `isSupported()` and `add(url, title, iconPng)`. Used by: browser\_menu\_sheet.
- `app/lib/platform/android/android_home_screen.dart`. Contains: the channel client; reports unsupported below API 26 or when the launcher cannot pin.
- `app/android/app/src/main/kotlin/com/zdmgold/tahorbrowser/HomeScreenChannel.kt`. Contains: builds a `ShortcutInfoCompat` whose intent is `ACTION_VIEW` for the URL aimed at our activity (the incoming-link service from B22a opens it), with the page favicon or the app icon, then `requestPinShortcut`.

Modified: `MainActivity.kt` (register the channel), `browser_menu_sheet.dart` (the row, hidden when unsupported), `platform_factory.dart`, `app_en.arb`. Test: `home_screen_menu_test` (row visibility from a fake contract).

Run: branch `batch/b32d`, commit `b32d: add to home screen, Android`.

#### B32e. iOS (gated by Apple's entitlement)

- `app/lib/platform/ios/ios_home_screen.dart`. Contains: the channel client; `isSupported()` is true only in builds made with `--dart-define=HOME_SCREEN_ENTITLED=true`, set after Apple grants the entitlement.
- `app/ios/Runner/HomeScreenPlugin.swift`. Contains: finds the visible `WKWebView` by depth-first search of the key window's subviews and presents a `UIActivityViewController` with that web view in `activityItems`; the system share sheet then offers Add to Home Screen.

Modified: `AppDelegate.swift` (register), `Runner.entitlements` (from B22a, once granted), `codemagic.yaml` (the define). Until the entitlement is granted the iOS row is hidden and Android is unaffected.

Run: branch `batch/b32e`, commit `b32e: add to home screen, iOS`.

### M7c. Cast (B32f to B32h)

Verified: Google Cast plays progressive MP4 downloads directly, adaptive protocols (HLS and DASH) need CORS headers on the media server, and protected streams need a custom receiver; only remote media URLs can be cast. `flutter_chrome_cast` 1.5.0 supports Android and iOS and initialises with `GoogleCastDiscoveryCriteria.kDefaultApplicationId`, the default receiver (`CC1AD845`), which needs no registration. iOS requires `NSLocalNetworkUsageDescription` and `NSBonjourServices` (`_googlecast._tcp` and `_CC1AD845._googlecast._tcp`); Android requires the `FOREGROUND_SERVICE_MEDIA_PLAYBACK` permission, the `GoogleCastOptionsProvider` meta-data and the `MediaNotificationService` with `foregroundServiceType="mediaPlayback"`. iOS AirPlay for web video needs no work (`allowsAirPlayForMediaPlayback` is on by default).

**M7c exit:** cast a plain MP4 page to a Chromecast; confirm an HLS page with CORS works and a blob-video page shows no cast button (final test APK); then run iOS-4 after B36 (section 6.9).

#### B32f. Cast core

- `app/lib/core/contracts/cast_session.dart`. Contains: a device stream, connect, disconnect, `load(CastMedia)`, play, pause, seek, volume, stop, session state. Implemented by: chrome\_cast\_session. Used by: cast\_service.
- `app/lib/core/models/cast_media.dart`. Contains: URL, MIME type, title, poster, live flag, kind (progressive, hls, dash). Used by: cast\_service, cast\_sheet.
- `app/lib/core/scripts/cast_probe_script.dart`. Contains: JavaScript that reads each `video` and `audio` element's `currentSrc` and `source` children and classifies the URL: `.mp4` and `.webm` progressive, `.m3u8` HLS, `.mpd` DASH; `blob:` and `mediastream:` are not castable. Used by: cast\_service.
- `app/lib/core/services/cast_service.dart`. Contains: runs the probe on menu open and when playback starts, accepts only http and https URLs, marks HLS and DASH as needing CORS, and exposes the best candidate. Used by: cast\_provider.
- `app/lib/core/providers/cast_provider.dart`. Contains: castable media for the active tab, session state, the selected device. Used by: cast\_button, cast\_sheet, browser\_menu\_sheet.

Tests: `cast_service_test` (classification, scheme filter, candidate choice), `cast_probe_script_test` (fixture markup).

Run: branch `batch/b32f`, commit `b32f: cast core`.

#### B32g. Cast platform

- `app/lib/platform/common/chrome_cast_session.dart`. Contains: `CastSession` over `flutter_chrome_cast`'s discovery, session and media APIs only (its Material widgets are not used); initialises the Cast context with the default receiver when the cast sheet first opens, so the local-network prompt appears only then.

Modified: `AndroidManifest.xml` (the permission, the options-provider meta-data, `MediaNotificationService`), `Info.plist` (`NSLocalNetworkUsageDescription`, `NSBonjourServices`), `tool/ci_checks.sh` (allowlist), `platform_factory.dart`, `pubspec.yaml`.

Run: branch `batch/b32g`, commit `b32g: cast platform`.

#### B32h. Cast interface

- `app/lib/widgets/browser/cast_button.dart`. Contains: an icon chip in the address bar, drawn only when a castable video exists. Used by: address\_bar.
- `app/lib/widgets/browser/cast_sheet.dart`. Contains: the device list with connect state. Used by: cast\_button, browser\_menu\_sheet.
- `app/lib/widgets/browser/cast_controls_sheet.dart`. Contains: play and pause, seek, volume, stop, built from our own slider and chips.

Modified: `browser_menu_sheet.dart` (Cast video), `address_bar.dart`, `app_en.arb`. The privacy notes (Cast discovers devices on the local network and sends the media address to the receiver) go into `docs/DECISIONS.md` now and into `website/privacy.html` and `PRIVACY_LABELS.md` in B43 and B44. Test: `integration_test/cast_probe_test.dart` (fixture pages with an MP4, an HLS source and a blob video: classification only).

Run: branch `batch/b32h`, commit `b32h: cast interface`. Then the M7c exit.

## 18. File manifest, M8: Consent, ads, purchases (B33 to B36)

**M8 exit:** run the full consent matrix with the UMP test geographies and test-device settings using Google's published sample ad unit IDs (D-44); verify banner collapse in every case; test a purchase and Restore with store test accounts once the store accounts exist; run iOS-4 (covers M7a to M7c). The production-ID consent run and the Play closed-test upload happen after the store accounts are created.

### B33. Consent core

- `app/lib/core/models/consent_record.dart`. Contains: status (unknown, notRequired, required, obtained, denied, withdrawn), the last-known `canRequestAds`, `privacyOptionsRequired`, updatedAt; persisted. Used by: consent\_provider.
- `app/lib/core/contracts/consent.dart`. Contains: `refresh()`, `showFormIfRequired()`, `showPrivacyOptions()`, the current info.
- `app/lib/core/providers/consent_provider.dart`. Contains: the state machine. Every launch refreshes consent and shows the form only when required (outside the EEA, UK and Switzerland no form appears and ads start normally). A failed or offline refresh never overrides a saved record that permits ads; only a decline, a withdrawal or no prior answer disables ads. It exposes the single gate `canRequestAds`. Used by: admob\_ad\_slot, ad\_banner\_slot, privacy\_settings\_screen.
- `app/lib/platform/common/ump_consent_adapter.dart`. Contains: the adapter over the Google UMP APIs in `google_mobile_ads`; debug geography and test-device IDs come from `--dart-define` and are compiled out of release. On iOS the UMP flow presents the ATT prompt through the IDFA explainer message configured in AdMob Privacy & messaging.

Modified: `privacy_settings_screen` (a Privacy options row only when required), `bootstrap.dart` (refresh before ad init, never blocking the UI), `platform_factory.dart`, `app_en.arb`. Tests: `consent_provider_test` as a full table: first launch in a regulated region shows the form; a non-regulated region shows none; an offline refresh with a saved permitting record keeps ads; offline with no record disables ads; withdrawal disables; denial disables; persistence across restart.

Run: branch `batch/b33`, commit `b33: consent core`.

### B34. Ads

Decision (resolved by verification): ship Google UMP together with the ATT prompt on iOS, add `NSUserTrackingUsageDescription`, request non-personalized ads whenever consent or ATT is not granted, declare tracking identifiers in the privacy labels, and never describe the app as free of tracking.

- `app/lib/core/contracts/ad_slot.dart`. Contains: a controller with `initialize`, `loadAdaptiveBanner(width)`, state (idle, loading, loaded(height), failed) and `buildBanner()`.
- `app/lib/platform/common/admob_ad_slot.dart`. Contains: wraps `google_mobile_ads`; initializes only after `canRequestAds`; requests non-personalized ads whenever consent or ATT is not granted; any SDK failure becomes state `failed` and a local log line, never a crash or a blocked screen; Google's published sample unit IDs by default, production IDs through `--dart-define` once they exist.
- `app/lib/widgets/browser/ad_banner_slot.dart`. Contains: the collapse-to-zero widget: draws nothing (no gap, border or placeholder) unless the ad is loaded and the user is on the free tier with consent; also zero while the keyboard is up. Reserved height equals the loaded ad height; gaps come from spacing tokens.

Modified: `new_tab_page`, `downloads_screen`, `bookmarks_screen` (a bottom slot; never on the web page view), `platform_factory.dart`, `AndroidManifest.xml` (AdMob application ID, Google's sample ID until release; `com.google.android.gms.permission.AD_ID`), `Info.plist` (`GADApplicationIdentifier`, `SKAdNetworkItems` per Google's current list, `NSUserTrackingUsageDescription`), `tool/ci_checks.sh` (allowlist), `app_constants.dart`. Tests: `ad_banner_slot_test` (zero height when loading, failed, pro, no consent, keyboard up; a golden of the collapsed state).

Run: branch `batch/b34`, commit `b34: ads`.

### B35. Purchases and entitlement

- `app/lib/core/models/entitlement_state.dart`. Contains: free, pro or unknown with source and verifiedAt.
- `app/lib/core/contracts/purchases.dart`. Contains: product query, buy, restore, the purchase stream, the store entitlement lookup.
- `app/lib/platform/common/iap_purchases.dart`. Contains: the adapter over `in_app_purchase`: Android acknowledgement, iOS transaction completion, error mapping, product ID `com.zdmgold.tahorbrowser.pro`.
- `app/lib/core/providers/entitlement_provider.dart`. Contains: the single source of truth; persists the last known state so pro survives offline; revalidates each launch; never inferred at the point of use.
- `app/lib/screens/pro_screen.dart`. Contains: an optional upgrade page reachable from Settings: it states plainly that it removes our banner ad only and does not change ad blocking; the store price; a primary Buy; Restore visible; never a blocking modal.

Modified: `settings_screen` (Pro entry; Restore purchases always visible), `about_screen`, `ad_banner_slot` (reads the entitlement), `router`, `platform_factory.dart`, `app_en.arb`. Tests: `entitlement_provider_test` (offline retention, restore, pending, a refund returns to free after revalidation).

Run: branch `batch/b35`, commit `b35: purchases and entitlement`.

### B36. Consent and ad verification

- `docs/CONSENT_TEST_MATRIX.md`. Contains: a manual matrix of region (EEA, UK, Switzerland, a regulated US state and a non-regulated region, using the UMP debug geographies) by state (first launch, consent given, denied, withdrawn, offline relaunch with saved consent) with the expected ad and form behaviour and a place to log evidence. Used by: `EEA_CONSENT.md`.
- `app/integration_test/ad_collapse_test.dart`. Contains: with ads unavailable, the banner area measures zero height on every host screen.

Modified: `tool/ci_checks.sh` (every `AdRequest(` appears only in `admob_ad_slot.dart` after a `canRequestAds` guard).

Run: branch `batch/b36`, commit `b36: consent and ad verification`. Then the M8 exit and iOS-4.

## 19. File manifest, M9: Localization (B37 to B39)

English keys have grown in every batch since B0, so M9 only adds translations and verification. The translations are drafted by the agent; have a native reader review the consent, privacy and purchase strings in particular, because they carry legal meaning.

**M9 exit:** this is the second and last installable test APK (D-34): every feature, all 20 languages, before brand and website work. On a phone, switch to Arabic and Hebrew (the layout mirrors), Japanese and Thai (rendering and wrapping), German and Russian (the longest strings, no overflow); the native-reader review of the legal strings is logged.

### B37. Locales, first ten

- `app/lib/l10n/app_es.arb`, `app_fr.arb`, `app_de.arb`, `app_pt.arb`, `app_it.arb`, `app_nl.arb`, `app_pl.arb`, `app_ru.arb`, `app_uk.arb`, `app_tr.arb`. Contains: every key from `app_en.arb`, `@@locale`, placeholders identical to English, and ICU plurals using each language's categories (ru, uk and pl need few and many). Role: one file per language, no code change. Used by: the generated localizations.

Modified: `tool/ci_checks.sh` (a hardcoded-string check that fails on string literals inside `Text(`, `Tooltip(message:`, `semanticsLabel:` and similar in `lib/widgets` and `lib/screens`).

Run: branch `batch/b37`, commit `b37: locales, first ten`.

### B38. Locales, remaining nine

- `app/lib/l10n/app_ar.arb`, `app_hi.arb`, `app_he.arb`, `app_ja.arb`, `app_ko.arb`, `app_zh.arb`, `app_vi.arb`, `app_th.arb`, `app_id.arb`. Contains: the same full key set. Arabic uses all six plural categories; ja, ko, zh, vi, th and id have none; `ar` and `he` are right-to-left (layouts flip through `Directionality`, helpers are directional); `zh` is Simplified (Traditional is a later addition). Used by: the generated localizations.

Run: branch `batch/b38`, commit `b38: locales, remaining nine`.

### B39. Verification and language picker

- `app/test/l10n_completeness_test.dart`. Contains: every key exists in every locale, placeholder sets match, plural categories are valid.
- `app/test/rtl_golden_test.dart`. Contains: Arabic and Hebrew goldens for the browser chrome, tabs and settings at 1x and 2x text scale, plus a +40% pseudo-locale overflow test.
- `tool/lint_hardcoded_strings.sh`. Contains: the script behind the B37 check. Used by: `ci_checks.sh`.

Modified: `app_constants.dart` (the supported locales with native names, which are data and not translated), `settings_screen` (a Language row: System default plus the 20 languages), `locale_provider.dart`, `Info.plist` (`CFBundleLocalizations` listing all 20 codes, without which iOS offers English only).

Run: branch `batch/b39`, commit `b39: locale verification and language picker`. Then the M9 exit and the second test APK.

## 20. File manifest, M10: Release engineering (B40 to B46)

### B40. Launcher icon and splash

- `app/assets/branding/icon.svg`, `icon_foreground.svg`, `splash_logo.svg`. Contains: vector sources authored as text (the adaptive-icon safe zone respected). Role: a phone-only workflow can author them; CI rasterizes.
- `app/flutter_launcher_icons.yaml`. Contains: Android adaptive (background colour from the palette), iOS with alpha removed, minimum SDK 24.
- `app/flutter_native_splash.yaml`. Contains: light and dark background colours, the logo, an Android 12 section.
- `.github/workflows/generate-assets.yml`. Contains: manual; installs `librsvg2-bin`, rasterizes the SVGs, runs `dart run flutter_launcher_icons` and `dart run flutter_native_splash:create`, and commits the generated resources to `main` with `GITHUB_TOKEN`.

Modified: `pubspec.yaml` (branding assets and dev-dependency config).

Run: branch `batch/b40`, commit `b40: launcher icon and splash`. After the merge the agent dispatches `generate-assets` and checks the generated icon.

### B41. Android release configuration

- `app/android/key.properties.example`. Contains: the property names only (store file path, alias); no secrets.

Modified: `app/android/app/build.gradle(.kts)` (release signing from `key.properties` or the environment, shrink and obfuscate, version from pubspec, the AdMob application ID injected through manifest placeholders so debug keeps the sample ID), `proguard-rules.pro` (keep rules for ads, billing, the scanner, ML Kit and the downloader; confirmed by launching the release APK), `AndroidManifest.xml` (the AdMob placeholder), `.github/workflows/build-android.yml` (the release path described in B0 becomes live), `store_submission/ACCOUNTS.md` (keystore steps).

Keystore: the build agent generates it with `keytool` (RSA 2048, validity 10000 days, alias `Tahor Browser`), stores it as the `ANDROID_KEYSTORE_B64` secret together with the alias and passwords, and hands the owner the `.jks` and its single-line base64 for an offline backup, because GitHub secrets cannot be read back. Never commit the `.jks` file (the ignore file blocks it). The owner enrols in Play App Signing when the Play account exists.

Run: branch `batch/b41`, commit `b41: Android release configuration`. Then dispatch `build-android` with mode `release`; this build is the one uploaded to the Play closed track.

### B42. iOS release configuration

- `app/ios/ExportOptions.plist`. Contains: method `app-store`, the team ID tracked in ACCOUNTS, `uploadSymbols` true.
- `app/ios/Runner/PrivacyInfo.xcprivacy`. Contains: the required-reason API declarations the app and its plugins use, the collected data types for the ad SDK, tracking declared per the ATT decision, empty tracking domains. Must match `PRIVACY_LABELS.md`.

Modified: `Info.plist` (final: localizations, reviewed usage strings, `ITSAppUsesNonExemptEncryption` set after confirming the export answer), `codemagic.yaml` (adds workflow `ios-release`: manual, the App Store Connect API key from secrets, `flutter build ipa --release --export-options-plist=ios/ExportOptions.plist`, artifacts, TestFlight on, App Store submission off, manual signing with the managed-capability profile once the default-browser entitlement is granted). This is the first point the $99 is needed, and the point to submit Apple's default-browser entitlement request.

Run: branch `batch/b42`, commit `b42: iOS release configuration`.

### B43. Website (independent of the app)

- `website/index.html`. Contains: the one-sentence description, the honest feature list, the parity statement, screenshots, semantic HTML, Open Graph and `SoftwareApplication` JSON-LD. Store links are added when the listings exist. A stub with the name, description and contact already exists from the hosting setup and is replaced here.
- `website/privacy.html`. Contains: what we collect (nothing ourselves); what third parties collect (the ad SDK and consent form, store billing, the platform Safe Browsing checks by Google and Apple); on-device translation with Google-hosted model downloads; Cast's local-network discovery and the media address sent to the receiver; download notifications; what stays on the device; the first-launch blocklist download and the manual refresh, which expose the device's address to the static host; regional rights; how to delete data (Clear browsing data or uninstall); contact.
- `website/support.html`. Contains: an FAQ (sign-in pages and the system browser, ad-blocking limits, restoring a purchase, clearing data, translation models) and a contact email.
- `website/style.css`. Contains: tokens mirrored as CSS variables, light and dark through `prefers-color-scheme`, responsive, no external fonts.
- `website/robots.txt`, `website/sitemap.xml`, `website/images/og-image.svg`. Contains: crawl and share assets.

`website/blocklist/` is written only by `publish-blocklist.yml`. The website shares no code, import or trigger with `app/`. The privacy and support pages are published before the Play closed test starts.

Run: branch `batch/b43`, commit `b43: website`.

### B44. Store documents

- `store_submission/ASO_METADATA.md`. Contains: per-store title, subtitle, short and long descriptions and keywords, localized separately for all 20 languages, with a claims audit line per sentence.
- `store_submission/DATA_BACKING.md`. Contains: what each claim rests on (blocklist size and rule counts, the parity statement) and what is not supported (POST downloads, HLS or DASH downloads, in-stream video ads, Widevine L1, a built-in password manager).
- `store_submission/SCREENSHOT_STRATEGY.md`. Contains: the screens to capture, the required sizes for both stores, the sources (emulator, simulator, goldens), localized sets.
- `store_submission/EEA_CONSENT.md`. Contains: the CMP vendor (Google UMP), the region logic, the offline-never-overrides rule, and dated test evidence from `CONSENT_TEST_MATRIX.md`.
- `store_submission/COMPLIANCE_MAP.md`. Contains: a guideline-to-mitigation table (performance, misleading marketing, privacy policy, data-collection accuracy, tracking transparency, ads, in-app purchase, content rights for the blocklist licence, regional variations, data subject rights through Clear browsing data since there is no account).
- `store_submission/PRIVACY_LABELS.md`. Contains: the Play Data safety and App Store privacy answers, consistent with `PrivacyInfo.xcprivacy`, the ad SDK, Safe Browsing, translation model downloads, Cast and notifications; the update rule: changed before any data-touching feature ships.
- `store_submission/RELEASE_CHECKLIST.md`. Contains: the ordered release steps (section 21) and the rollback plan: halt the staged rollout, flip a feature flag, republish the previous signed blocklist.

Run: branch `batch/b44`, commit `b44: store documents`.

### B45. Audits and performance

- `app/test/manifest_permissions_test.dart`. Contains: parses the source `AndroidManifest.xml` and asserts the permission set equals the allowlist in section 4 exactly.
- `app/test/info_plist_test.dart`. Contains: asserts a usage string exists for every declared capability, the web-content ATS key, exactly 20 localizations, the `http` and `https` URL types, and none of the keys Apple forbids with the default-browser entitlement.
- `tool/audit_merged_manifest.sh`. Contains: after a release build, inspects the merged manifest and fails on any permission outside the allowlist plus the known plugin additions, each listed with a reason. Used by: `build-android.yml`.
- `docs/PERFORMANCE.md`. Contains: the targets from section 4 and how each is measured, the installed size of the PDF engine and of each ABI, and the size baseline history.
- `app/integration_test/performance_test.dart`. Contains: logs launch time, tab-switch time and a real-database history query; the results are copied into `PERFORMANCE.md`.

Modified: `build-android.yml` (runs the merged-manifest audit).

Run: branch `batch/b45`, commit `b45: audits and performance`.

### B46. Final documents

Modified: `README.md` (final, matches the shipped behaviour), `docs/BLUEPRINT.md` (as built), `docs/DECISIONS.md` (final), `store_submission/ACCOUNTS.md` (every status current).

Run: branch `batch/b46`, commit `b46: final documents`.

## 21. The release gate

1. All batches merged; `verify.yml` green on `main`.
2. Dispatch `build-android` (release): the AAB and per-ABI APKs are produced; `apksigner verify`, the size gate and the merged-manifest audit pass.
3. Sideload the release APK; cold-start restore with Don't keep activities; run the regression pass of every milestone phone checklist.
4. Upload the AAB to the Play internal track (Play App Signing); the closed test must complete its 14 days with 12 testers before applying for production access.
5. Pay the Apple program, set up signing in Codemagic, dispatch `ios-release`, ship to TestFlight, and test on a physical iPhone (borrowed, or a used SE) once (iOS-5).
6. Only after TestFlight validation, submit to the App Store.

**Forbidden at every point:** a `push:` trigger on any build workflow; pushing directly to `main` (the one seed commit in section 6.3 excepted, and the generated-file commits made by the bootstrap, publish-blocklist and generate-assets workflows); merging a red batch; adding a permission without updating the allowlist and `PRIVACY_LABELS.md`; any `TODO`, `FIXME` or `UnimplementedError` in `lib/`.

## 22. Decisions, deferred features, cost, checklist

### Decision log

Each decision is also recorded in `docs/DECISIONS.md` (B0), with the reason and the section that applies it. Decisions D-31 onward were made while building and live only in that file.

| # | Decision | Reason |
| --- | --- | --- |
| D-01 | Gate 1 runs on GitHub Actions; `main` receives only green merges | Flutter has no supported Android host, so analysis cannot run in Termux |
| D-02 | `bootstrap-scaffold.yml` generates `android/` and `ios/` | Same reason |
| D-03 | Vertical slices with a phone build at every milestone exit (amended by D-34: two installable APKs, emulator proof at the other exits) | Web view bugs appear only on a device |
| D-04 | Build workflows stay manual but are used at every milestone exit | Linux minutes are free on a public repository |
| D-05 | `verify.yml` is the only workflow with `push:`, only on `batch/**` (approved) | It spends no paid minutes and protects `main`; the alternative is a manual click after each of 59 batches |
| D-06 | iOS stays unsigned until you pay Apple | TestFlight and signed builds need the paid programme |
| D-07 | Camera, microphone and location are declared and requested at runtime per site | The web view silently denies them otherwise |
| D-08 | One blocklist model, two emitters | Android's matcher lags on large lists and lacks ignore-previous-rules |
| D-09 | Cosmetic rules are part of the rule lists | Injecting after load flashes ads first |
| D-10 | No blocked-item counter | The platform reports none |
| D-11 | Contracts and pure logic in `core/`, plugins in `platform/` | One enforceable boundary |
| D-12 | English strings from B0, translations in M9, CI blocks hardcoded strings | Retrofitting strings is the worst rework |
| D-13 | "No accounts, no analytics from us", with the ad SDK disclosed | An ad SDK collects data, and the claim must be true |
| D-14 | The blocklist is signed (Ed25519) and attributed | An unsigned downloaded list is a supply-chain risk |
| D-15 | Release signing with Play App Signing and an offline keystore backup | The AAB cannot be uploaded otherwise |
| D-16 | Cleartext allowed on Android and iOS web content | A browser must load HTTP pages; HTTPS-only is a feature on top |
| D-17 | At most three live tabs; the rest are hibernated | Many live web views get the app killed |
| D-18 | Private tabs: non-persistent store on iOS; host-scoped cleanup and honest copy on Android | Android cookie storage is process-wide |
| D-19 | Automated smoke tests on an emulator and the iOS simulator | Without a Mac, iOS would otherwise be unverified |
| D-20 | Section and batch numbering fixed in this document | Earlier cross-references were off by one |
| D-21 | Safe Browsing and the fraudulent-website warning on by default, with a switch | Users need a phishing and malware warning; the policy discloses it |
| D-22 | No Material and no Cupertino anywhere | The finish must not read as a framework default |
| D-23 | `background_downloader` for all https downloads | It gives pause, resume, background and notifications on both platforms |
| D-24 | iPhone only, iOS 15.5 | The translation plugin sets the floor; tablets run the phone layout |
| D-25 | UMP with ATT on iOS; non-personalized ads without consent | AdMob on iOS cannot avoid the ATT prompt |
| D-26 | Compact blocklist seed in the app, full list downloaded on first launch, 3% size ratchet | Keeps the binary small without downloading code |
| D-27 | No built-in password manager in this version | iOS web views cannot save or offer system passwords; a manager is a project of its own |
| D-28 | Default browser and iOS Add to Home Screen ship when Apple grants the entitlement | Apple gates both behind one entitlement |
| D-29 | `google_mobile_ads` pinned at 9.1.0 | Confirmed published; exact pins are enforced by CI |
| D-30 | Store title "Tahor Fast & Private Browser" (28 characters, inside both stores' 30-character title limit); package tahorbrowser; repository Tahor-Browser; identifier com.zdmgold.tahorbrowser (home-screen name amended by D-32) | Tahor is Hebrew for pure or clean. "Private" in the title is a claim, so every listing line stays within the honest claims in section 1: no accounts and no analytics from us, ads and the tracking prompt disclosed |

### Deferred features and what each would take

Sizes are estimates (S small, M medium, L large, XL a project of its own).

| Feature | Size | What it takes | Constraint |
| --- | --- | --- | --- |
| Remote search suggestions | S | A source in `suggestion_service` that calls the chosen engine's suggest endpoint, one URL template and parser per engine, an opt-in switch off by default, never in private tabs | Public suggest endpoints exist for DuckDuckGo, Google, Bing and Brave but are unofficial and can change; every keystroke goes to the engine, so the policy and labels must say so |
| Bookmark import and export | S to M | A pure-Dart parser and writer for the Netscape bookmark HTML format (`DL`, `DT`, `H3` folders, `A HREF`, dates in seconds since 1970), import through `file_picker` 12.3.0, export through the share sheet | Needs the folder model from B26; tests against real Chrome and Firefox exports |
| Tab groups | M | A `TabGroup` model and `groupId` on `TabModel`, snapshot migration, group headers in `tabs_screen`, rules for closing, hibernation and private tabs | Touches tab ownership and restore, so the M2 restore tests grow |
| Built-in password manager | L | Keychain and Keystore storage, form detection by script, biometric unlock, a fill sheet, a security review | Required for saved passwords on iOS (section 2) |
| Sync | XL | An account system, server, end-to-end encryption with key recovery, conflict resolution, device management | Triggers Apple's in-app account deletion rule and Google Play's in-app plus web deletion requirement; ends the no-accounts and zero-cost promises; bookmark export is the practical stand-in |

### Cost ledger

| Item | Cost | Note |
| --- | --- | --- |
| Website hosting, blocklist hosting | $0 | static, on a Cloudflare Worker |
| Android CI (verify, build, emulator tests) | $0 | public repository, Linux minutes |
| iOS CI | $0 | five checkpoint builds of about 20 minutes inside the 500 free minutes |
| Flutter, Dart, plugins, UMP, ad SDK | $0 |  |
| Google Play developer account | $25 one-time | after the app is complete |
| Apple Developer Program | $99 a year | first needed at B42 |
| Used iPhone SE (optional) | about $100 | one final physical check |
| Ongoing monthly | $0 | no backend, no server |

### Final pre-generation checklist

- [x] Accounts table created; Flutter pinned; the contract block confirmed
- [x] Seed commit pushed; Termux setup is optional (section 6.2)
- [ ] Repository ruleset requiring `verify` on pull requests, with the Actions bypass (section 6.3)
- [x] Layering, exact pins and forbidden imports enforced by `ci_checks.sh`
- [x] Bootstrap run; `android/` and `ios/` committed; `verify.yml` green on `batch/b0`
- [ ] Design tokens frozen before any widget; additions recorded in DECISIONS
- [ ] Session restore, system-browser handoff, background downloads and consent gating present in their milestones
- [ ] Every milestone exit performed and logged; size baseline created at M1
- [ ] 20 locales complete and right-to-left verified; zero hardcoded strings
- [ ] Marketing matches what ships: no proxy, VPN or no-logs claims; about 90% of Chrome's compatibility with an honest system-browser escape; ads, tracking prompt, Safe Browsing and model downloads disclosed; no blocked-count claim
- [ ] No `TODO`, `FIXME` or `UnimplementedError` in `lib/`

