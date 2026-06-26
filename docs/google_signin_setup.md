# Google Sign-In / Supabase OAuth Setup

This document explains how to configure Google Sign-In for the Android build of
InvoiceKit so that `PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10, ...)`
(`DEVELOPER_ERROR`) is resolved.

It does **not** commit any secrets. The `google-services.json` file is intentionally
not part of the repository — each developer / CI environment must drop its own
copy into `android/app/`.

## Why `ApiException: 10` happens

`ApiException: 10` from `com.google.android.gms.common.api.ApiException` is the
canonical "DEVELOPER_ERROR" returned by Google Play Services when the running
APK cannot be matched against any registered Android OAuth client ID. In
practice this means **at least one of these is wrong**:

- The Android `applicationId` / package name in the running APK does not match
  the package registered in the OAuth client.
- The SHA-1 / SHA-256 fingerprint of the signing key used to build the APK is
  not registered on the OAuth client.
- The `serverClientId` passed from Flutter (the Web OAuth client ID) is empty,
  wrong, or pointing at a deleted client.
- `google-services.json` is missing, out-of-date, or does not contain the
  expected `oauth_client` entries.

## Android identifiers used by this app

From `android/app/build.gradle.kts`:

- `namespace` / `applicationId`: `com.example.invoice_kit`

> **Before shipping, change `applicationId` to your own package** (e.g.
> `com.yourcompany.invoicekit`). The value above is the Flutter template
> default and will conflict with anyone else who has the same package in their
> Firebase project.

## Step-by-step setup

### 1. Get the debug SHA-1 and SHA-256

From the `android/` directory:

```bash
./gradlew signingReport
```

Scroll to the `debug` variant under `> Task :app:signingReport` and copy the
`SHA1` and `SHA-256` values. These are the fingerprints of the Android debug
keystore Google Play Services will validate against.

> The `release` variant in this project currently signs with the **debug** key
> (`signingConfig = signingConfigs.getByName("debug")` in
> `android/app/build.gradle.kts`). When you add a real release keystore, repeat
> this step for the release variant and add those fingerprints to Firebase as
> well.

### 2. Register the Android OAuth client

In the Google Cloud Console:

1. Select the project that backs your Supabase project (same one used for the
   Supabase URL in `.env`).
2. **APIs & Services → Credentials → Create credentials → OAuth client ID**.
3. Application type: **Android**.
4. Name: e.g. `InvoiceKit Android (debug)`.
5. Package name: `com.example.invoice_kit` (must match
   `android/app/build.gradle.kts`).
6. SHA-1 certificate fingerprint: paste the value from step 1.

Repeat for the release SHA-1 once you have a real signing key.

### 3. Create the Web OAuth client

In the same Credentials page:

1. **Create credentials → OAuth client ID** with application type **Web
   application**.
2. Name: e.g. `InvoiceKit Web (for serverClientId)`.
3. Add `https://localhost` (and your production redirect URL, if applicable)
   to **Authorized redirect URIs** — Supabase's OAuth flow needs a redirect
   target.
4. Copy the **Client ID** (it ends in `.apps.googleusercontent.com`). This is
   your `serverClientId`.

### 4. Configure Supabase

In the Supabase dashboard for your project:

1. **Authentication → Providers → Google** → enable.
2. Paste the Web OAuth **Client ID** and **Client Secret** from step 3.
3. Save.

### 5. Configure the Flutter `.env`

Add the Web OAuth Client ID to your environment file:

```env
GOOGLE_WEB_CLIENT_ID=XXXXXXXXXXXX-XXXXXXXXXXXXXXXX.apps.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=XXXXXXXXXXXX-XXXXXXXXXXXXXXXX.apps.googleusercontent.com
```

The values above are placeholders. Do **not** commit a real client secret — the
`.env` file is the only place this ID is stored. The Flutter code reads these
via `AppConfig.googleWebClientId` and `AppConfig.googleIosClientId`.

`supabase_auth_datasource.dart` will pass `serverClientId` to `GoogleSignIn` on
every platform (it is required for `signInWithIdToken`), and will only pass
`clientId` on iOS. On Android the package name and SHA are discovered from
`google-services.json`, which is why step 6 matters.

### 6. Drop `google-services.json` into the project

In the Firebase console (or Google Cloud, if you do not use Firebase):

1. **Project settings → Your apps → Android app → `com.example.invoice_kit`**.
2. Download `google-services.json`.
3. Copy it into `android/app/google-services.json`.

The file is gitignored (see `.gitignore` entries for `google-services.json`).
Each developer needs their own copy because the file embeds the API key and
project ID for their personal Firebase project / debug signing key.

### 7. Regenerate and restart

```bash
flutter clean
flutter pub get
flutter run
```

## Troubleshooting checklist

| Symptom | Likely cause | Fix |
|---|---|---|
| `ApiException: 10` immediately on tap | Wrong SHA fingerprint in OAuth client | Re-run `./gradlew signingReport`, update the Android OAuth client |
| `ApiException: 10` on release builds only | Release SHA not registered | Add the release SHA-1/SHA-256 to the OAuth client |
| `PlatformException(sign_in_failed, …)` with empty message | `google-services.json` missing or stale | Drop a fresh `google-services.json` into `android/app/` |
| `idToken` is null after sign-in | `serverClientId` is empty | Set `GOOGLE_WEB_CLIENT_ID` in `.env` and restart the app |
| "This app is not verified" warning | Web OAuth client is in testing mode | Add yourself as a test user in the Google Cloud OAuth consent screen, or submit for verification |

## What this app already does

- `supabase_auth_datasource.dart::signInWithGoogle` wires `serverClientId` from
  `AppConfig.googleWebClientId` and skips `clientId` on Android (so it does not
  override the package/SHA lookup from `google-services.json`).
- Any `PlatformException` from `google_sign_in` is wrapped in
  `AuthException` with a message that points back to this document.
- Dio / the legacy backend is **not** involved in Google Sign-In.
