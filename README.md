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
- **Security** — SQLCipher AES-256 DB, Argon2id PIN-wrapped key + biometric-gated key, auto-lock,
  PIN backoff, optional wipe, FLAG_SECURE, no INTERNET permission, no cloud backup.
- **Encrypted backups** — Argon2id + AES-256-GCM with checksum, made in a background isolate.

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
