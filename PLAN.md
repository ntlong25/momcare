# MomCare+ Publish Readiness Plan

## Phase 1: Scope Cleanup and Medical Claim Audit
Status: Completed

### Task 1.1: Remove Gender Selection
- Remove gender selection entry points from pre-pregnancy Home.
- Remove gender selection entry point from Fertility Planner.
- Remove unused gender selection screen if no references remain.
- Acceptance: no user-accessible route/button/text points to gender selection.
- Result: completed. `rg` found no gender-selection references in `lib`.

### Task 1.2: Audit Medical Claims
- Review user-facing advice content by area: nutrition, tracking, fertility, health diary.
- Document risky claims that should be softened or sourced in later phases.
- Acceptance: audit artifact exists in the repo.
- Result: completed in `MEDICAL_CLAIMS_AUDIT.md`.

### Build and Test Compatibility Fixes
- Updated health-related dependency constraints so package resolution succeeds with the current Flutter/Dart toolchain.
- Updated Android build settings required by the newer health dependency: AGP 8.9.1, minSdk 26, core library desugaring.
- Disabled Kotlin incremental compilation to avoid Windows cross-drive cache path failures when the project is on `F:` and Pub cache is on `C:`.
- Renamed the generated l10n key `continue` to `continueButton` because `continue` is a Dart keyword.
- Replaced the template counter widget test with a MomCare splash smoke test.

## Phase 2: Vietnamese-Only and Encoding Cleanup
Status: Completed

### Task 2.1: Make Vietnamese Default
- Set the runtime app locale to Vietnamese only in `MaterialApp.supportedLocales`.
- Updated `LocaleNotifier` to normalize any stored locale back to `vi`.
- Removed the Settings language selector so users can no longer switch to English in V1.
- Acceptance: fresh install and persisted locale state open in Vietnamese.
- Result: completed.

### Task 2.2: Localize Visible Text
- Localized visible text in the main user flows: Home, pre-pregnancy Home, Tracking, Health Diary, Nutrition, Appointments, Fertility, Guide, Onboarding, Pregnancy Setup, Settings, dialogs, validators, and local notification copy.
- Localized sample pregnancy week and nutrition data used in visible cards/detail screens.
- Kept existing l10n infrastructure and English ARB/generated files for future expansion, but the V1 runtime supported locale is Vietnamese.
- Acceptance: no English user-facing text remains in the prioritized core flows, excluding internal identifiers/generated English localization scaffolding retained for future use.
- Result: completed.

### Task 2.3: Fix Vietnamese Encoding
- Replaced mojibake in user-facing Dart strings and `README.md` with UTF-8 Vietnamese.
- Rebuilt `app_vi.arb` as valid UTF-8 JSON and regenerated localization files with `flutter gen-l10n`.
- Acceptance: `rg` found no mojibake markers in source/README/plan docs excluding generated adapter files.
- Result: completed.

## Phase 3: Privacy Policy and Medical Disclaimer
Status: Completed

### Task 3.1: Add In-App Privacy Policy Screen
- Added a dedicated Vietnamese Privacy Policy screen.
- Covered V1 data handling: local-first storage, no cloud sync, no analytics/ads, health data sensitivity, permission purpose, and encryption when supported by device/security key availability.
- Added a public privacy URL action using the shared app constant.
- Acceptance: accessible from Settings > Thông tin.
- Result: completed.

### Task 3.2: Add Medical Disclaimer Screen
- Added a dedicated Vietnamese Medical Disclaimer screen.
- States clearly that MomCare+ is for reference only and does not diagnose, treat, prescribe, or replace doctors/qualified healthcare professionals.
- Added warning copy to contact a doctor or nearby medical facility for abnormal or concerning symptoms.
- Added a disclaimer page/link in onboarding so first-time users see the medical limitation before starting.
- Acceptance: accessible from Settings and visible during onboarding.
- Result: completed.

### Task 3.3: Add Public Policy URL Placeholder
- Added `AppConstants.privacyPolicyUrl`.
- Added `AppConstants.medicalDisclaimerUrl`.
- Both in-app website buttons use these same constants, ready to replace with the final public URLs before store submission.
- Acceptance: policy/disclaimer website actions use centralized placeholder URLs.
- Result: completed.

## Phase 4: Data Control and Offline-First Trust
Status: Completed

### Task 4.1: Add Delete All Data Flow
- Added a Settings section for privacy/data controls.
- Added a two-step Vietnamese confirmation flow for deleting all local data.
- The final confirmation requires typing `XOA`.
- Delete flow clears Hive boxes, including the settings box.
- Delete flow resets onboarding/app mode/theme/language/user preference keys from SharedPreferences.
- Delete flow cancels all scheduled local notifications.
- After deletion, the app navigates back to onboarding to behave like a fresh install.
- Acceptance: user can delete all local data from Settings and return to first-run flow.
- Result: completed.

### Task 4.2: Add Local Data Explanation
- Added a Settings entry explaining that V1 stores data on the current device.
- Copy states that V1 does not have login, cloud sync, Supabase backup, or server upload of health data.
- Copy warns that local data may not be recoverable after app deletion, device change, or in-app delete-all-data.
- Acceptance: user can understand that V1 has no cloud backup.
- Result: completed.

## Phase 5: Safety Guidance
Status: Completed

### Task 5.1: Add Emergency Warning Screen
- Added a Vietnamese screen for `Dấu hiệu cần đi khám ngay`.
- Covered warning signs for pregnancy, postpartum recovery, and mental health.
- Added clear safety copy that MomCare+ does not replace doctors, medical facilities, or emergency services.
- Added CTA guidance to contact the current doctor, go to the nearest medical facility, or call local emergency services for urgent situations.
- Acceptance: content is clear and does not diagnose or replace emergency/medical care.
- Result: completed.

### Task 5.2: Add Emergency Entry Points
- Added a prominent one-tap emergency card on pregnancy Home.
- Added the same one-tap emergency card on pre-pregnancy Home.
- Added an emergency tab under Tools/Công cụ.
- Added a supporting link under Settings > Thông tin.
- Acceptance: Home can open the emergency warning screen in one tap.
- Result: completed.

## Later Phases
- Phase 6: Medical references and source metadata.
- Phase 7: Health sync permission rationale.
- Phase 8: Store readiness tests and QA checklist.

## Verification Log
- `C:\Users\PC\Development\flutter\bin\flutter.bat test` passed.
- `C:\Users\PC\Development\flutter\bin\flutter.bat build apk --debug` passed.
- Debug APK output: `build\app\outputs\flutter-apk\app-debug.apk`.
- Phase 2: `C:\Users\PC\Development\flutter\bin\flutter.bat gen-l10n` passed.
- Phase 2: `C:\Users\PC\Development\flutter\bin\dart.bat format lib` passed.
- Phase 2: `C:\Users\PC\Development\flutter\bin\flutter.bat test` passed.
- Phase 2: `C:\Users\PC\Development\flutter\bin\flutter.bat build apk --debug` passed.
- Phase 2 debug APK output: `build\app\outputs\flutter-apk\app-debug.apk`.
- Phase 3: `C:\Users\PC\Development\flutter\bin\flutter.bat pub get` passed.
- Phase 3: `C:\Users\PC\Development\flutter\bin\dart.bat format ...` passed for changed Phase 3 files.
- Phase 3: `C:\Users\PC\Development\flutter\bin\flutter.bat test` passed.
- Phase 3: `C:\Users\PC\Development\flutter\bin\flutter.bat build apk --debug` passed.
- Phase 3 debug APK output: `build\app\outputs\flutter-apk\app-debug.apk`.
- Phase 4: `C:\Users\PC\Development\flutter\bin\cache\dart-sdk\bin\dart.exe format ...` passed for changed Phase 4 files.
- Phase 4: `C:\Users\PC\Development\flutter\bin\flutter.bat test` passed.
- Phase 4: `C:\Users\PC\Development\flutter\bin\flutter.bat build apk --debug` passed.
- Phase 4 debug APK output: `build\app\outputs\flutter-apk\app-debug.apk`.
- Phase 5: `C:\Users\PC\Development\flutter\bin\cache\dart-sdk\bin\dart.exe format ...` passed for changed Phase 5 files.
- Phase 5: `C:\Users\PC\Development\flutter\bin\flutter.bat test` passed.
- Phase 5: `C:\Users\PC\Development\flutter\bin\flutter.bat build apk --debug` passed.
- Phase 5 debug APK output: `build\app\outputs\flutter-apk\app-debug.apk`.
- Phase 5: `flutter run -d emulator-5554 --no-resident` could not run because the emulator was not available to Flutter at verification time.
