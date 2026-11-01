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
