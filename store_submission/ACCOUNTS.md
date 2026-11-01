# Accounts and secrets tracking

Updated before every dashboard action. Secret values are never written here; only names and status.

| Item | Value | Status |
| --- | --- | --- |
| Product name | Tahor Fast & Private Browser | Fixed (D-32) |
| Dart package | `tahorbrowser` | Fixed |
| Reverse-DNS identifier | `com.zdmgold.tahorbrowser` | Fixed; immutable after the first release |
| GitHub repository | https://github.com/holydunamis1/Tahor-Browser | Created, public |
| Flutter pin | 3.47.7 (Dart 3.13.5) in `tool/flutter_version.txt` | Verified in CI |
| Support email | stmakarios@gmail.com | Supplied by the owner |
| Website host | Cloudflare Worker `tahor-browser` serving `website/` through `wrangler.jsonc` (D-45) | Connected to this repository by the owner. Public URL confirmed live on 2026-11-01: https://tahor-browser.holydunamis1.workers.dev |
| Blocklist signing keypair | Private key in `BLOCKLIST_SIGNING_KEY_B64`, public key in an app asset | Not created yet (B14) |
| Android upload keystore | Alias `Tahor Browser`; secrets `ANDROID_KEYSTORE_B64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD` | Not created yet; generated after the first debug APK is tested. The agent hands the owner the `.jks` and its base64 for an offline backup |
| Ad units | Google's published sample IDs | In use for the whole build (D-44) |
| In-app product | `com.zdmgold.tahorbrowser.pro`, one-time | Created in the stores after the app is complete |
| Google Play developer account | | Not created; after the app is complete |
| Apple Developer Program, team ID, App Store Connect key, default-browser entitlement request | | Not created; after the app is complete |
| Privacy policy URL and support URL | `website/privacy.html`, `website/support.html` | Written in B43 |

Codemagic secrets, created when iOS signing starts: `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_PRIVATE_KEY`.

## Change history

| Date | Change |
| --- | --- |
| 2026-11-01 | File created in B0 with the owner's identifiers, repository and decisions D-31 to D-44 |
| 2026-11-01 | Website host changed from Pages to a Worker with static assets (D-45) |
| 2026-11-01 | Website URL confirmed by the owner; preview URLs switched off in `wrangler.jsonc` |
