# MEEZAN — ميزان

A complete cross-platform legal services platform for Iraq. One Flutter codebase produces:

- **Android APK** — client (B2C) and lawyer (B2B) mobile apps
- **Web app** — same app in the browser, plus the **Admin Control Panel** (shown automatically to accounts holding the `admin` claim)

Everything builds and deploys through **GitHub Actions only** — no Android Studio, no local Flutter SDK, no local Firebase CLI required.

---

## Feature map

| Area | What's included |
|---|---|
| Auth & RBAC | Email/password (Firebase Auth). Role selector at signup (Client / Lawyer). Dynamic routing: client → client dashboard, lawyer → verification → lawyer dashboard, admin claim → Admin Panel. |
| Lawyer verification | Lawyer registers as `pending` → uploads Iraqi Lawyers Syndicate card to Storage → admin approves/rejects from the web panel → rejection reason is stored **and emailed** to the applicant. Pending/rejected lawyers are locked out of all B2B tools. |
| Languages | Arabic (default), Kurdish Sorani (`ckb`), English. Full RTL for ar + ckb, Cairo font, language saved per-account. |
| AI (Gemini) | Server-side only. Clients get **Legal Assistant AI**; approved lawyers get **Co-Counsel AI** (summarize briefs, analyze pasted documents, draft under Iraqi statutes). The Gemini key never ships in the app. |
| Client tools | Case tracking (milestones, hearings), consultation booking (video/phone/in-person), verified-lawyer directory (filter by specialization + all 19 governorates), secure document vault with per-lawyer sharing. |
| Lawyer tools | Case management (create by client email, milestones, hearings, view client-shared docs), smart calendar (hearings + appointments + statutory deadlines with Civil Procedure Code 83/1969 window reminders), IQD billing with installments, offline Iraqi legal library. |
| Security | Firestore + Storage rules enforce ownership, role immutability, lawyer-pending-on-create, and doc sharing. Admin is a custom auth claim, never a Firestore field. |

---

## Repo layout

```
lib/
  core/            theme, constants (governorates/specializations/IQD),
                   models, locale + ckb fallbacks, Firebase services
  features/
    auth/          login + register (role selector)
    onboarding/    syndicate-card upload, pending/rejected status
    client/        shell, cases, booking, directory, vault
    lawyer/        shell, case mgmt, calendar, billing, library
    admin/         web Admin Control Panel
    chat/          role-aware Gemini chat
    settings/      language + profile
  l10n/            app_en.arb / app_ar.arb / app_ckb.arb
functions/         geminiChat callable + status-change email trigger
                   scripts/set-admin.js (admin claim)
assets/            legal_library.json (Iraqi codes quick-reference)
.github/workflows/ ci.yml, deploy-firebase.yml, grant-admin.yml
firestore.rules / firestore.indexes.json / storage.rules / firebase.json
```

There are **no `android/` or `web/` folders in the repo** — CI runs `flutter create` at build time and injects Firebase config via `--dart-define`, so the repo stays clean and secret-free.

---

## Setup (one time, ~20 minutes)

### 1. Create the Firebase project

1. Go to [console.firebase.google.com](https://console.firebase.google.com) → **Add project** (e.g. `meezan-app`). Upgrade it to the **Blaze** plan (required for Cloud Functions; free tier limits still apply).
2. **Build → Authentication → Sign-in method** → enable **Email/Password**.
3. **Build → Firestore Database** → Create database (production mode, region e.g. `europe-west1`).
4. **Build → Storage** → Get started.

### 2. Register the two apps

In **Project settings → General → Your apps**:

1. **Add app → Android**, package name **`com.meezan.meezan`**. You do NOT need to download `google-services.json` — just note the values shown.
2. **Add app → Web**. Note the config values.

### 3. Add GitHub Secrets

In your GitHub repo → **Settings → Secrets and variables → Actions → New repository secret**, add:

| Secret | Where to find it |
|---|---|
| `FB_PROJECT_ID` | Project settings → `Project ID` |
| `FB_SENDER_ID` | Project settings → Cloud Messaging → `Sender ID` (a.k.a. messagingSenderId) |
| `FB_STORAGE_BUCKET` | e.g. `meezan-app.firebasestorage.app` |
| `FB_ANDROID_API_KEY` | Android app config → `apiKey` |
| `FB_ANDROID_APP_ID` | Android app config → `appId` (looks like `1:...:android:...`) |
| `FB_WEB_API_KEY` | Web app config → `apiKey` |
| `FB_WEB_APP_ID` | Web app config → `appId` (looks like `1:...:web:...`) |
| `FB_AUTH_DOMAIN` | Web app config → `authDomain` (e.g. `meezan-app.firebaseapp.com`) |
| `FIREBASE_SERVICE_ACCOUNT` | Project settings → Service accounts → **Generate new private key** → paste the ENTIRE JSON file contents |

### 4. Set the Gemini API key (server-side secret)

The key lives only in the Cloud Function. Two options:

- **Console (easiest):** after your first functions deploy (step 6), go to Google Cloud Console → Secret Manager, or:
- **CLI:** `firebase functions:secrets:set GEMINI_API_KEY` and paste a key from [aistudio.google.com/apikey](https://aistudio.google.com/apikey).

> If you deploy before the secret exists, the deploy prompts/fails for `GEMINI_API_KEY` — set it first if possible.

### 5. Install the email extension

Firebase console → **Extensions** → install **“Trigger Email from Firestore”** (`firebase/firestore-send-email`):

- Email documents collection: **`mail`**
- SMTP connection URI: your SMTP provider (Gmail app password, SendGrid, etc.)
- Default FROM: e.g. `MEEZAN <no-reply@yourdomain.com>`

The `onLawyerStatusChange` function writes approval/rejection emails into `/mail`; the extension sends them.

### 6. Deploy backend + web

GitHub → **Actions → Deploy to Firebase → Run workflow**. This deploys Firestore rules + indexes, Storage rules, both Cloud Functions, and the web app to Firebase Hosting (`https://<project-id>.web.app`).

### 7. Build the Android APK

GitHub → **Actions → CI (Build APK + Web) → Run workflow** (it also runs on every push). Download the **`meezan-release-apk`** artifact and install it.

### 8. Create your admin

1. In the app (or on the web URL), **register a normal account** with your email.
2. GitHub → **Actions → Grant Admin → Run workflow** → enter that email.
3. **Sign out and sign back in** (the claim is read from a fresh token). You'll land in the Admin Control Panel.

---

## Daily flow

- **Lawyer signs up** → picks specialization + governorate → uploads syndicate card → sees "under review".
- **You (admin)** open the web app → Pending tab → view the card → Approve or Reject with a reason. Either way the applicant gets an email.
- **Approved lawyers** appear instantly in the client directory and unlock the full practice suite.
- **Clients** book consultations, follow cases, share vault documents with their lawyer, and ask the Legal Assistant AI.

---

## Notes & production hardening

- **APK signing:** the release APK is signed with the debug key (fine for sideloading/testing). For Google Play, add a keystore: create one, add it as base64 secret, and extend the `Scaffold platforms` step in `ci.yml` to write `android/key.properties` + patch `build.gradle`.
- **Kurdish translations** in `lib/l10n/app_ckb.arb` and the governorate/specialization labels were machine-assisted — have a native Sorani speaker review before launch.
- **Legal library** (`assets/legal_library.json`) is a convenience quick-reference of key articles, not an official text. Verify against the Iraqi Official Gazette (الوقائع العراقية) and extend freely — it's plain JSON.
- **AI disclaimer** is shown under the chat; the server prompt also instructs Gemini to add it. Keep both.
- **Gemini model:** change without code edits by setting the `GEMINI_MODEL` env var on the function (defaults to `gemini-2.0-flash`).
- **Costs:** Firestore/Storage/Functions free tiers are generous; Gemini billing depends on your key's plan.

## Troubleshooting

| Symptom | Fix |
|---|---|
| App opens on "Firebase not configured" | One or more `FB_*` secrets missing/typo'd → re-add and re-run CI. |
| AI chat returns an error | `GEMINI_API_KEY` secret not set on the function, or functions not deployed. |
| Approve/Reject emails not arriving | Trigger Email extension not installed or SMTP URI wrong; check the `/mail` docs' `delivery` field for the error. |
| Admin sees client dashboard | Sign out/in after running Grant Admin (token refresh). |
| Lawyer never appears in directory | They're still `pending` — approve them in the Admin Panel. |
