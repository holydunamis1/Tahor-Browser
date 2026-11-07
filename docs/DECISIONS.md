# Decisions

Every decision is recorded here with its reason. Decisions D-01 to D-30 come from the final blueprint (section 22). D-31 onward were made while building. Additions only; a superseded decision is marked, not deleted.

## Decision log

| # | Decision | Reason |
| --- | --- | --- |
| D-01 | Gate 1 runs on GitHub Actions; `main` receives only green merges | Flutter has no supported Android host, so analysis cannot run in Termux |
| D-02 | `bootstrap-scaffold.yml` generates `android/` and `ios/` | Same reason |
| D-03 | Vertical slices with a phone build at every milestone exit | Web view bugs appear only on a device |
| D-04 | Build workflows stay manual but are used at every milestone exit | Linux minutes are free on a public repository |
| D-05 | `verify.yml` is the only workflow with `push:`, only on `batch/**` (approved) | It spends no paid minutes and protects `main` |
| D-06 | iOS stays unsigned until the Apple programme is paid for | TestFlight and signed builds need the paid programme |
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
| D-20 | Section and batch numbering fixed in the blueprint | Earlier cross-references were off by one |
| D-21 | Safe Browsing and the fraudulent-website warning on by default, with a switch | Users need a phishing and malware warning; the policy discloses it |
| D-22 | No Material and no Cupertino anywhere in `lib/` | The finish must not read as a framework default |
| D-23 | `background_downloader` for all https downloads | Pause, resume, background and notifications on both platforms |
| D-24 | iPhone only, iOS 15.5 | The translation plugin sets the floor; tablets run the phone layout |
| D-25 | UMP with ATT on iOS; non-personalized ads without consent | AdMob on iOS cannot avoid the ATT prompt |
| D-26 | Compact blocklist seed in the app, full list downloaded on first launch, 3% size ratchet | Keeps the binary small without downloading code |
| D-27 | No built-in password manager in this version | iOS web views cannot save or offer system passwords |
| D-28 | Default browser and iOS Add to Home Screen ship when Apple grants the entitlement | Apple gates both behind one entitlement |
| D-29 | `google_mobile_ads` pinned at 9.1.0 | Confirmed published; exact pins are enforced by CI |
| D-30 | Store title "Tahor Fast & Private Browser" (28 characters); package `tahorbrowser`; repository `Tahor-Browser` | Tahor is Hebrew for pure or clean. The home-screen name part of this decision is superseded by D-32 |
| D-31 | Owner values: GitHub repository `holydunamis1/Tahor-Browser`, account segment `zdmgold`, identifier `com.zdmgold.tahorbrowser`, support email `stmakarios@gmail.com` | Supplied by the owner on 2026-11-01. The identifier is immutable after the first release |
| D-32 | Android label, iOS display name and store title are all "Tahor Fast & Private Browser" (supersedes the "Tahor" home-screen name in D-30) | Owner's choice. Launchers may shorten a long label |
| D-33 | The agent builds in its own sandbox and pushes branch `batch/bN`; after `verify` is green the agent opens the pull request and squash-merges it through the API (replaces the manual web merge in blueprint section 6.6) | Owner works on a phone and asked for sequential pushes without web clicks |
| D-34 | Two installable test APKs: one after B13 (end of M2: browsing, tabs, session restore, theme) and one after B39 (end of M9: every feature and all 20 languages, before brand and website work). Other milestone exits are proven by the `integration-android` emulator workflow | Owner set a maximum of two test APKs |
| D-35 | Debug APKs are published as GitHub pre-release assets (one direct download link) | A phone cannot unzip workflow artifacts conveniently; the debug build contains only Google sample ad unit IDs |
| D-36 | Raw job logs are not reachable from the agent's sandbox, so `tool/ci_run.sh` publishes the tail of each CI step as a workflow annotation, read through the REST API | The log host is blocked in the sandbox; this keeps the push, read, fix loop working |
| D-37 | A local Dart SDK (3.13.7) is used only for `dart format` and syntax checking. Analysis and tests run in CI. Flutter itself cannot run in the sandbox because its download host is blocked | Corrects the earlier plan to run `dart analyze` and `dart test` locally; pub.dev is unreachable from the sandbox |
| D-38 | Generated localizations (`app/lib/l10n/gen/`) are gitignored and generated by `flutter gen-l10n` in every workflow. `synthetic-package: false` was verified on Flutter 3.47.7 | Keeps generated code out of the repository; proven in CI |
| D-39 | Every GitHub Action is pinned to a full commit SHA, enforced by `ci_checks.sh`; runners are `ubuntu-24.04` | Supply-chain hygiene and reproducible builds (the `ubuntu-latest` label is migrating to Ubuntu 26) |
| D-40 | Pin corrections found by resolving the blueprint's pins on Flutter 3.47.7: `package_info_plus` is 10.2.2 (9.0.0 conflicts with `share_plus` 13.3.1 through `win32`), and `intl` is 0.20.3 (the version `flutter_localizations` requires) | Dependency resolution run on 2026-11-01 |
| D-41 | `flutter_localizations` brings `material_ui` 1.9.0 and `cupertino_ui` into the dependency graph as transitive packages on Flutter 3.47.7. Our code never imports them (CI-enforced); their effect on binary size is covered by the size ratchet | Observed in the resolved lock file |
| D-42 | `verify.yml` also runs `dart format --set-exit-if-changed` over every tracked Dart file | Enforces one code style; the agent formats locally before every push |
| D-43 | GitHub secret names follow the blueprint: `ANDROID_KEYSTORE_B64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `BLOCKLIST_SIGNING_KEY_B64` | The owner's notes used `ANDROID_KEYSTORE_BASE64`; one set of names avoids drift |
| D-44 | Ad units use Google's published sample IDs for the whole build; Google Play and Apple accounts are created after the app is complete | Owner's instruction on 2026-11-01 |
| D-45 | The website is served by a Cloudflare Worker with static assets (project `tahor-browser`, created by the owner's Git connection), configured by `wrangler.jsonc` with `assets.directory` set to `./website`; no build command; the deploy command stays `npx wrangler deploy`. The public address is a `workers.dev` address instead of the `pages.dev` address the blueprint assumed | The Cloudflare dashboard created a Worker, which serves the same static files. The Worker name in `wrangler.jsonc` must match the project name |
| D-46 | Site addresses used by the app: website `https://tahor-browser.holydunamis1.workers.dev`, privacy `/privacy.html`, support `/support.html`, blocklist `/blocklist/` (latest.txt, manifest.json, manifest.sig). `preview_urls` is false so only the production address is public | Confirmed live by the owner on 2026-11-01 |
| D-47 | `docs/BLUEPRINT.md` is the blueprint with these adaptations: `[account]` is `zdmgold`, the Termux clone and loop sections follow D-33, hosting follows D-45, `package_info_plus` and `intl` follow D-40, the product name follows D-32, and test APK placement follows D-34 | One document stays the anchor for later sessions; the adaptations are listed in its first section |
| D-48 | B1 structure: an `onAccent` colour token is added (text on the accent fill); `AppThemeData` lives in `core/theme/app_theme_data.dart`, a twelfth file in B1, so the light and dark theme files do not import each other in a cycle; a theme is picked by `AppThemeBuilder.forBrightness`; radii and shadows are instances carried by the theme | The blueprint's token list had no colour for text on the accent button; the extra file removes a cyclic import |
| D-49 | Values the blueprint left open, chosen in B1: palette is clean white and true black with a deep teal accent (every text pair 4.62:1 or better); default search engine DuckDuckGo, with Google, Bing, Brave Search and Ecosia offered; at most 100 open tabs | The owner can change any of these in one line before release |
| D-50 | Repository ruleset `main-protection` (active 2026-11-01) requires a pull request and the `verify` check on `main`, forbids force pushes and deletion, and has no bypass actors. GitHub does not let the Actions app bypass a ruleset on a personal repository, so workflows that produce generated files (`publish-blocklist`, `generate-assets`) push a `batch/` branch; the agent dispatches `verify` on it and squash-merges the pull request. Before the ruleset existed, one empty commit (`test: direct push must be rejected`) reached `main` by mistake; it changes nothing and history was left intact | Enforces green-only merges without exceptions |
| D-51 | Address-bar rules (B2): text with spaces is a search; `http`, `https`, `mailto`, `tel`, `sms` and `about:blank` navigate; `javascript`, `vbscript`, `file`, `data`, `blob`, `content`, `filesystem` and `intent` are refused; any other scheme-like text is a search; dotted host-like text navigates over https, while `localhost`, IP addresses, `.local` names and single-label hosts with a port use http; there is no TLD list, so text like `file.txt` is treated as a host. Display hosts are never converted from punycode, so look-alike IDN hosts show as `xn--` | A TLD list is large and goes stale; showing punycode is the safe display for look-alike hosts |
| D-52 | B3 contract details: the theme choice is the app's own `AppThemeMode` (Flutter's `ThemeMode` lives in the Material library); the progress event is named `ProgressChanged`; the navigation policy returns a `NavigationDecision` that can allow, block, open externally or redirect (the HTTPS upgrade in B19 needs redirect); the engine contract gains `setNavigationPolicy`; `AppInfo` exposes synchronous version getters and its adapter loads them once at start-up | The blueprint named these pieces but not their shapes; fixing them now avoids contract churn in B5, B6 and B19 |
| D-53 | B4a additions: a `scrim` colour token (35% black in light, 60% in dark) for the layer behind sheets and dialogs; `AppScaffold` keeps bottom chrome mounted but takes it out of layout while the keyboard is up, and the content area then ends at the keyboard edge; the edge swipe back covers a 24 px strip on the start side and drives the route's own animation, so it mirrors in right-to-left layouts; sheets slide by their own height so a drag follows the finger one to one | The blueprint's token list had no scrim; the other points settle behaviour the blueprint described but did not specify |
| D-54 | Golden images are generated by the manual `update-goldens` workflow on the CI runner and pushed to the batch branch (it refuses to run on `main`); `verify` then compares against them. GitHub only lets a manual workflow be dispatched once its file is on the default branch, so the workflow landed in its own small batch before the first golden batch | Goldens made on any other system would differ from the runner's, and pictures made by hand cannot be reproduced |
| D-55 | B5 engine details, from reading the resolved plugin source (6.2.0-beta.3): favicons come from `getFavicons()` after a page loads (there is no cross-platform icon callback); load errors map by `WebResourceErrorType` (these are not compile-time constants, so they are compared with `==`); a navigation the policy sends to another app is launched by the engine itself, and a failed `intent:` link then loads its web fallback in the same tab; `PullToRefreshController` takes its colours from the theme when the tab is first built; the plugin's `incognito` setting is never set | The blueprint named these callbacks without checking the beta's API |

## Verified pins

All direct dependencies in `app/pubspec.yaml` resolve together on Flutter 3.47.7 (Dart 3.13.5), checked by a CI dependency resolution on 2026-11-01. `app/pubspec.lock` is committed and is the record of every transitive version.

| Package | Pin |
| --- | --- |
| flutter_inappwebview | 6.2.0-beta.3 |
| phosphoricons_flutter | 1.1.0 |
| pdfrx | 2.6.5 |
| mobile_scanner | 7.1.4 |
| qr | 4.0.0 |
| google_mobile_ads | 9.1.0 |
| in_app_purchase | 3.3.0 |
| background_downloader | 9.5.9 |
| http | 1.6.0 |
| google_mlkit_translation | 0.15.1 |
| google_mlkit_language_id | 0.14.0 |
| flutter_chrome_cast | 1.5.0 |
| sqflite | 2.4.4+2 |
| shared_preferences | 2.5.6 |
| path_provider | 2.1.6 |
| url_launcher | 6.3.3 |
| share_plus | 13.3.1 |
| open_file | 3.5.11 |
| local_auth | 3.0.2 |
| permission_handler | 13.0.2 |
| package_info_plus | 10.2.2 (corrected from 9.0.0, see D-40) |
| cryptography | 2.9.0 |
| intl | 0.20.3 (see D-40) |
| flutter_lints | 6.0.0 |
| flutter_launcher_icons | 0.14.4 |
| flutter_native_splash | 2.4.7 |

## Milestone log

An entry is appended at each milestone exit with the date, the build used, the phone checklist result and the integration run.
