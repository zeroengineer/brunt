# BRUNT

> Takes the brunt of your month — bills, debts, daily costs — so you always know what's truly left to spend.
>
> *Your money. Your phone. Nowhere else.*

A private, fully offline monthly money planner for Android (Flutter). See
[`docs/brunt-plan.md`](docs/brunt-plan.md) for the full product spec and
[`docs/PRIVACY.md`](docs/PRIVACY.md) for the privacy policy.

## Highlights

- **Will this month make it?** — projection engine with gap check before salary, month-end check,
  safe-to-spend-per-day, per-account run-out warnings and card-limit warnings.
- **Money stack** — Priority → Savings → Fixed bills → Daily → Variable, visualised as a ring.
- **Accounts** — cash, bank, UPI (linked to a bank), wallets, credit cards (statement → bill cycle), savings.
- **Daily log** — ✓ as usual / edit / skip, with per-day account override, in two taps.
- **Transfers with presets** — ATM withdrawal, card bill, savings deposit, **Borrowed** (money in from someone; "Pay back X" is scheduled in Plan on the date you choose) and **Lent** (money out to someone, parked under Lent out with a due-back date).
- **Security** — SQLCipher AES-256 DB, Argon2id PIN-wrapped key + biometric-gated key, auto-lock,
  PIN backoff, optional wipe, FLAG_SECURE, no INTERNET permission, no cloud backup.
- **Encrypted backups** — Argon2id + AES-256-GCM with checksum, made in a background isolate.
- **Reports** — month-wise PDF statement of your entries, with the History filters applied.

## Tested on a device

Every flow was walked over adb on a Samsung Galaxy M13 (Android 14, 384×856 dp, 32-bit
`armeabi-v7a`, Mali-G52): onboarding, PIN create/unlock, accounts (cash, bank, UPI → bank,
credit card), recurring items, daily log, expense / transfer / salary received, pay and skip
planned items, history, insights, settings, lock, erase everything.

Measured on that phone with a release/profile build:

| What | Result |
|---|---|
| Cold start → first frame | 2.7 s |
| PIN unlock → dashboard | ≈ 2–3 s (Argon2id 8 MiB in pure Dart) |
| Scrolling the dashboard | 126 frames presented, 0 janky, avg 16.6 ms (60 fps) |

Rendering uses Impeller's OpenGL backend; Vulkan stuttered and broke screen capture on this GPU.
Screenshot blocking (`FLAG_SECURE`) is enabled only in release builds, so debug and profile
builds can be captured for testing.

## Development

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # drift code generation
flutter analyze
flutter test
flutter run                                                 # device over adb
```

Release builds drop the `INTERNET` permission (`tools:node="remove"` in the main manifest; debug
builds keep it only for Flutter tooling). The release signing config is a placeholder — set up an
upload keystore in `android/app/build.gradle.kts` before publishing.

### Layout

```
lib/
  app/        router, theme, shell, session, providers
  core/       money (paise), dates, enums
  design/     tokens, glow background, pills, segment tabs, nav, chips, ring, keypad
  security/   key manager, lock controller, PIN backoff, backup crypto, screen guard
  data/       drift tables, ledger (single write path), month engine, queries, stats
  domain/     projection engine, schedule expander, rollover, card cycle (pure Dart)
  features/   onboarding, lock, dashboard, plan, daily_log, add_entry, accounts,
              insights, history, settings, gallery
```
