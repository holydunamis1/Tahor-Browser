# Tahor Fast & Private Browser

A privacy-first browser for Android and iPhone with on-device ad blocking, no accounts and no analytics from us. Built in Flutter on the system web engines (Android WebView and iOS WebKit).

## What it is

- Tabs with session restore, find in page, downloads with pause and resume, history, bookmarks, private tabs, app lock and reader mode.
- Ad blocking on the device, from a signed list. In-stream video ads are not blocked, and no blocked-item count is claimed because the platform does not report one.
- About 90% of Chrome's compatibility, with a one-tap escape to the system browser for sites that refuse embedded web views (some sign-in pages).
- Free with one banner ad from Google AdMob; a one-time purchase removes that banner only. Ads and the iOS tracking prompt are disclosed in the privacy policy and store labels.
- 20 languages, with right-to-left support.

## How it is built

Flutter does not run on a phone, so every check runs in GitHub Actions.

| Workflow | Trigger | Purpose |
| --- | --- | --- |
| `verify` | push to `batch/**` | Static checks, format, `flutter analyze`, tests. Gate 1 for every batch |
| `bootstrap-scaffold` | manual, once | Generates `app/android` and `app/ios` |
| `build-android` | manual | Debug APK (published as a pre-release) or signed release build |

`main` receives only green, squash-merged batches. The full design, file list and batch plan are in [`docs/BLUEPRINT.md`](docs/BLUEPRINT.md); every decision is in [`docs/DECISIONS.md`](docs/DECISIONS.md).

## Repository layout

`app/` is the Flutter app, `website/` is the static marketing site and the published blocklist, `tools/blocklist/` is the list converter and signer, `tool/` holds CI scripts, `docs/` the design documents, `store_submission/` the store paperwork.
