# Oobli

AI spending & planning companion for Kenya. Oobli reads M-Pesa (Pochi la Biashara, Tills, Paybills, Send Money) and bank SMS, categorises spending with Gemini, and turns it into charts, nudges ("Oobli says…"), monthly plans, savings goals and a monthly "Wrapped" recap.

## Architecture

```
Flutter app (Android)                    Appwrite Cloud (sgp, project 6b012dd80037b9146a2b)
├─ SMS inbox (Kotlin channel, financial  ├─ Auth: email/password
│  senders only) → on-device M-Pesa      ├─ TablesDB "oobli" (row-level security, per-user)
│  parser → categoriser                  │   transactions · merchant_rules · plans · goals
├─ Riverpod state, go_router navigation  └─ Function "oobli-ai" (Node 22)
└─ Appwrite SDK ─────────────────────────────→ Gemini Interactions API (key held server-side)
```

- **No secrets in the app.** Gemini is only called from the `oobli-ai` Appwrite Function; the key is a secret function variable (`GEMINI_API_KEY`). The function rejects anonymous executions.
- **Categorisation pipeline:** user corrections (merchant rules) → message-type/keyword rules (offline) → Gemini for the rest. Correcting a category teaches Oobli for that merchant.
- **De-duplication:** each transaction has a fingerprint (M-Pesa code + amount + direction); a unique index makes re-syncs idempotent.
- **Offline resilience:** every AI surface has a rule-based fallback (`lib/domain/local_insights.dart`), so the app never shows an empty "Oobli says…".

### Code layout

| Path | Purpose |
| --- | --- |
| `lib/core` | config, theme tokens (from the design JSON), formatting, errors |
| `lib/data` | models, Appwrite repositories, AI client, SMS parser/sync |
| `lib/domain` | pure analytics (`SpendingStats`) and local insights |
| `lib/state` | Riverpod controllers |
| `lib/ui/widgets` | design system: buttons, mascot, charts, cards |
| `lib/features` | screens: onboarding, auth, dashboard, activity, analytics, plans, goals, wrapped, settings, Ask Oobli |
| `functions/oobli-ai` | Appwrite Function (Gemini gateway) |
| `test` | unit tests + screen tests with golden images (`test/goldens`) |

## Running

```bash
flutter pub get
flutter run                 # Android device with USB debugging
flutter build apk --release # build/app/outputs/flutter-apk/app-release.apk
```

Endpoint/project can be overridden with `--dart-define=APPWRITE_ENDPOINT=... --dart-define=APPWRITE_PROJECT_ID=...`.

## Themes & branding

- Typography is a single family, **Poppins** (closest open-licence match to Gilroy, as used by modern Kenyan banking apps), set in `lib/core/theme/oobli_text.dart`. To use a licensed font instead, drop its files in `assets/fonts/` and change `OobliFonts.family` + `pubspec.yaml`.
- Light and dark themes come straight from the design tokens (`lib/core/theme`). The app follows the phone's setting by default; users can force Light/Dark in **Settings → App Theme**.
- The launcher icon and the native launch screen are generated from `assets/branding/` (white background in light mode, `#131F24` in dark mode). After changing the logo:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Tests

```bash
flutter test                      # unit + screen tests
flutter test --update-goldens     # regenerate screen snapshots
cd functions/oobli-ai && npm test # function tests
```

## Deploying the AI function

The function has no npm dependencies. Package and deploy from `functions/oobli-ai`:

```bash
tar -czf code.tar.gz package.json src
appwrite functions create-deployment --function-id oobli-ai --code code.tar.gz --activate true
```

Variables: `GEMINI_API_KEY` (secret), `GEMINI_MODEL` (default `gemini-3.5-flash-lite`), optional `GEMINI_FALLBACK_MODEL`, `GEMINI_ATTEMPT_TIMEOUT_MS`.

## Releases (GitHub Actions)

- `CI` runs analyze + tests on every push/PR to `main`.
- `Release` runs on version tags and publishes signed APKs (universal + per-ABI), an `.aab` and checksums to GitHub Releases:

```bash
# bump `version:` in pubspec.yaml if you like; the tag decides the version name
git tag v1.0.1 && git push origin v1.0.1
```

Signing uses repository secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS`. Local release builds use `android/key.properties` (git-ignored). **Back up the upload keystore**: losing it means users must uninstall to update.

## Website (`web/`)

The landing page, Terms of Service and Privacy Policy are a small Vite + React site (three static pages, no router) hosted on **Appwrite Sites** (site `oobli-web`).

```bash
cd web
npm install
npm run dev     # http://localhost:5173
npm test        # vitest
npm run build   # dist/
```

- The `Web` workflow tests, builds and deploys `web/` to Appwrite on every push to `main` that touches it (`.github/scripts/appwrite-deploy-site.sh`).
- The download buttons point to the public `downloads` bucket. The `Release` workflow uploads each new arm64 APK there as `oobli-android`.
- Both need the `APPWRITE_API_KEY` repository secret with scopes `sites.read`, `sites.write`, `files.read` and `files.write`.
- Before launch, set a real contact address in `web/src/config.js` and have the legal pages reviewed.

## Before publishing

- **Google Play SMS policy:** `READ_SMS` is a restricted permission. Play only allows it for approved use cases. Submit the Permissions Declaration Form (financial SMS-based budgeting is a recognised exception), or distribute outside Play.
- Add your release SHA-256 fingerprint to the Appwrite Android platform if you enable passkeys/OAuth.
