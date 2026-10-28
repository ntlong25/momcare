# MomCare+ Manual QA Checklist

Use this checklist before each Android/iOS store submission.

## Install and First Run
- [ ] Fresh install opens splash screen, then onboarding.
- [ ] Onboarding is Vietnamese-only.
- [ ] Medical disclaimer appears in onboarding flow.
- [ ] Mode selection shows only pre-pregnancy and pregnancy modes.
- [ ] Selecting pregnancy mode opens pregnancy setup.
- [ ] Selecting pre-pregnancy mode opens main navigation without requiring pregnancy data.
- [ ] After app relaunch, completed onboarding is not shown again.
- [ ] After app relaunch, app opens Home for the current app mode.

## Core Navigation
- [ ] Bottom navigation shows: Trang chủ, Theo dõi, Công cụ, Cài đặt.
- [ ] Home opens without overflow on common small Android screen sizes.
- [ ] Tracking tabs collapse/fall out while scrolling and return when scrolling upward.
- [ ] Tools tabs collapse/fall out while scrolling and return when scrolling upward.
- [ ] Settings opens and current app mode matches the active user state.
- [ ] Re-selecting the current app mode does not delete existing data.

## Data and Offline-First Behavior
- [ ] App works with airplane mode enabled after first install.
- [ ] Pregnancy week content renders from local bundled content for weeks 0-42.
- [ ] Nutrition guidance renders from local bundled content without network.
- [ ] Settings includes local-data explanation.
- [ ] Local-data explanation says V1 has no login, no cloud sync, and no server backup.
- [ ] Add/edit pregnancy data persists after app restart.
- [ ] Add health diary entry persists after app restart.
- [ ] Add menstrual cycle entry persists after app restart.
- [ ] Add appointment persists after app restart.

## Delete All Data
- [ ] Settings contains “Xóa toàn bộ dữ liệu”.
- [ ] Delete flow requires two-step confirmation.
- [ ] Final confirmation requires typing `XOA`.
- [ ] Delete all data clears pregnancy, health diary, appointments, menstrual cycles, settings, and onboarding state.
- [ ] Scheduled local notifications are cancelled after delete all data.
- [ ] After delete all data, app returns to onboarding/fresh-start state.

## Permissions
- [ ] Notification permission is not requested on app startup.
- [ ] Notification permission is requested only after a user action that needs reminders.
- [ ] If notification permission is denied, appointment/reminder flows do not crash.
- [ ] Health sync permission is requested only after tapping sync and confirming the rationale dialog.
- [ ] Health sync rationale says cycle data is read-only, stored locally, and not uploaded in V1.
- [ ] If Health Connect is unavailable on Android, app offers install or manual entry.
- [ ] If HealthKit/Health Connect permission is denied, Fertility Planner still supports manual entry.

## Health and Safety Content
- [ ] Privacy Policy is accessible from Settings > Thông tin.
- [ ] Medical Disclaimer is accessible from Settings > Thông tin.
- [ ] Emergency warning screen is accessible from Home in one tap.
- [ ] Emergency warning screen is accessible from Tools and Settings.
- [ ] References screen is accessible from Settings.
- [ ] Nutrition detail and pregnancy advice screens show source metadata and last updated date.
- [ ] Home health habits show water, iron, prenatal vitamin, and appointment review.
- [ ] Health habit reminders are off by default.
- [ ] Enabling a health habit reminder shows rationale and time picker.
- [ ] Denying notification permission keeps the health habit checklist usable.
- [ ] Health advice copy does not claim diagnosis, treatment, cure, or guaranteed outcomes.

## Visual QA
- [ ] Light mode text is readable.
- [ ] Dark mode text is readable.
- [ ] Vietnamese diacritics render correctly.
- [ ] No visible English copy appears in the primary user flows.
- [ ] No bottom overflow warnings appear on Home, Tracking, Tools, Fertility Planner, Nutrition, Appointments, Health Diary, Settings.

## Platform Checks
- [ ] Android debug/release build installs and launches.
- [ ] Android Health Connect permission review/rationale screen opens correctly where supported.
- [ ] iOS build has HealthKit usage descriptions in Vietnamese.
- [ ] iOS notification permission copy is consistent with reminder usage.
- [ ] App version/build number matches the store submission.
