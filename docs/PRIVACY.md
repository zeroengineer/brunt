# BRUNT — Privacy Policy

**BRUNT collects no data.**

- BRUNT has no servers, no accounts, no analytics, no ads and no crash reporting.
- The Android app ships without the `INTERNET` permission. It cannot send anything anywhere.
- Everything you enter (accounts, salary, bills, daily spends) is stored only on your phone, in a
  database encrypted with AES-256 (SQLCipher). The key is protected by your 6-digit PIN
  (Argon2id) and, if you enable it, by your phone's biometric hardware (Android Keystore / iOS Keychain).
- Your data is excluded from Android cloud backup and iCloud backup.
- Notifications are scheduled on the device and never contain amounts.
- Encrypted backups are created only when you ask, protected with a password you choose, and
  saved wherever you decide. Nobody, including the developers, can open them without that password.

If you uninstall BRUNT or forget your PIN without a backup, your data is gone. There is no recovery,
because there is no copy anywhere else.
