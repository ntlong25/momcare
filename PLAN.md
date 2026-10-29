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

## Phase 6: Medical References and Source Metadata
Status: Completed

### Task 6.1: Add References Screen
- Added a Vietnamese `Nguồn tham khảo` screen.
- Grouped references by pregnancy, nutrition, growth/vitals/maternal care, fertility/preconception, and urgent warning signs.
- Prioritized official/public health sources: Cục Bà mẹ và Trẻ em - Bộ Y tế Việt Nam, WHO, and CDC.
- Added external URL opening for each reference.
- Added Settings > Thông tin entry for the references screen.
- Acceptance: references are accessible from Settings and grouped by health topic.
- Result: completed.

### Task 6.2: Attach Source Metadata to Advice Content
- Added reusable source metadata UI with source group, source organizations, last updated date, and link to references.
- Attached metadata to nutrition detail content.
- Attached metadata to pregnancy week advice cards: baby development, mother changes, and weekly tips.
- Attached metadata to emergency warning/red-flag content.
- Acceptance: users can view source metadata and `Cập nhật lần cuối` for key health advice content.
- Result: completed.

## Phase 7: Permissions and Health Sync
Status: Completed

### Task 7.1: Add Health Sync Rationale
- Added an in-app Vietnamese rationale dialog before requesting Apple Health/Health Connect permission.
- Copy states that MomCare+ only reads menstrual cycle data, stores it locally on the device, does not send it to a server in V1, and still supports manual entry.
- Added a visible sync action inside the Fertility Planner content so permission is only requested after a deliberate user action, including embedded/no-app-bar usage.
- Configured the health plugin during `HealthService.init`.
- Acceptance: permission prompt only appears after the user chooses to continue from the rationale flow.
- Result: completed.

### Task 7.2: Improve Permission Failure UX
- Added Health Connect availability handling on Android before requesting permission.
- If Health Connect is unavailable, the app offers to install Health Connect or enter cycle data manually.
- If permission is denied, the app explains that Fertility Planner still works with manual entry and offers the manual entry flow.
- Acceptance: denying permission does not block Fertility Planner or leave the user without a next action.
- Result: completed.

### Task 7.3: Verify Store Permission Copy
- Added Android Health Connect menstruation read permission and Android notification permission declaration.
- Added Android Health Connect permission rationale intent and permission usage alias required for Health Connect permission review flows.
- Updated Android MainActivity to use `FlutterFragmentActivity`, which is required by the current health plugin registration flow.
- Added Vietnamese iOS HealthKit usage descriptions for reading cycle data and clarifying that V1 does not write health data.
- Acceptance: native permission configuration has clear health-data purpose copy and builds successfully.
- Result: completed.

## Phase 8: Store Readiness and QA
Status: Completed

### Task 8.1: Replace Default Widget Test
- Kept the MomCare splash smoke test and expanded widget coverage for first-run onboarding and mode selection.
- Added a primary navigation destination smoke test for the V1 bottom navigation labels.
- Avoided the old Flutter counter template test.
- Acceptance: `flutter test` covers startup/onboarding/mode-selection/navigation smoke paths and passes.
- Result: completed.

### Task 8.2: Add Core Logic Tests
- Added unit tests for pregnancy week/trimester calculation.
- Added unit tests for BMI calculation and recommended pregnancy weight-gain range.
- Added unit tests for weight and blood pressure validators.
- Added unit tests for cycle average, regularity, next period, ovulation date, and fertile window prediction.
- Acceptance: important health tracking logic has independent tests.
- Result: completed in `test/core_logic_test.dart`.

### Task 8.3: Manual QA Checklist
- Added `RELEASE_QA_CHECKLIST.md`.
- Checklist covers fresh install, onboarding, mode selection, core navigation, offline-first behavior, delete-all-data, notifications, health sync permission denied/granted paths, Vietnamese UI, dark mode, overflow checks, references, disclaimer, and emergency guidance.
- Acceptance: checklist can be used before each Android/iOS submission.
- Result: completed.

### Task 8.4: Store Metadata Checklist
- Added `STORE_METADATA_CHECKLIST.md`.
- Checklist covers Google Play Data Safety, Health Apps Declaration, App Store Privacy Nutrition Label, supported V1 feature claims, claims to avoid, listing copy, and pre-submit URL/support checks.
- Explicitly excludes unsupported V1 claims: cloud sync, account login, AI, diagnosis/treatment, wearable sync, medication reminders, ads, analytics, and expert chat.
- Acceptance: store copy can be checked against the app's real V1 behavior.
- Result: completed.

## Phase 9: Startup Persistence Regression
Status: Completed

### Result
- Confirmed V1 startup behavior: completed onboarding and selected app mode persist locally.
- Confirmed V1 default relaunch destination remains Home (`navigationIndexProvider` starts at `0`).
- Added regression test for persisted pregnancy mode and Home navigation default.
- Acceptance: relaunch simulation keeps mode state and does not restore deep tabs/forms/modals.

## Phase 10: Offline Medical Content Pack
Status: Completed

### Result
- Added bundled local content assets under `assets/content/`.
- Added a content pack loader that parses pregnancy/nutrition JSON offline and falls back to safe generic copy if assets are missing or invalid.
- Pregnancy content now covers weeks `0-42` and includes nutrition focus, red flags, source refs, and last updated metadata.
- Nutrition content now supports week-range categories, natural food sources, foods to avoid, and supplement-vs-natural comparison copy.
- Nutrition screen now seeds guides from the local content pack instead of visible sample nutrition data.
- Weekly tracking UI now surfaces nutrition focus and urgent warning signs from the content pack.
- Acceptance: bundled offline content covers weeks `0-42` and nutrition guidance renders from local assets.

### Medical Review Note
- Current content is draft copy and remains marked for medical review before store submission.
- Final publish should not occur until you or a qualified medical reviewer approve the pregnancy/nutrition content.

## Phase 11: Home Health Habits and Opt-In Reminders
Status: Completed

### Result
- Added local maternal habit model/service with SharedPreferences persistence.
- Added Home `Chăm sóc hôm nay` checklist for water, iron, prenatal vitamin, and appointment review habits.
- Habit completion resets naturally by date because only today's completion counts.
- Added opt-in reminder flow with rationale dialog and time picker.
- Notifications are no longer requested during app startup; permission is requested only when scheduling a reminder.
- Delete-all-data flow now removes saved habit state.
- Acceptance: Home shows today's habit checklist, reminders are off by default, and denied notification permission leaves checklist usage available.

## Later Phases
- No remaining phases in the current Publish Readiness V1 plan.

## Phase 12: P0 Bug Fixes (FEATURE_REVIEW.md section 2)
Status: Completed

### Task 12.1: Health Sync
- `HealthService.init()` is called at startup (non-blocking, errors logged, skipped on unsupported platforms) and lazily before every health call.
- Synced cycles use a stable id per start date (`health_YYYY-MM-DD`); import skips cycles whose start date already exists locally.
- Acceptance: re-sync does not duplicate cycles. Result: completed (`buildCyclesFromPeriodDays`, `DatabaseService.importMenstrualCycles`).

### Task 12.2: Notifications
- AndroidManifest: `RECEIVE_BOOT_COMPLETED`, `ScheduledNotificationReceiver`, `ScheduledNotificationBootReceiver` (BOOT_COMPLETED / MY_PACKAGE_REPLACED / QUICKBOOT_POWERON) and `ActionBroadcastReceiver` per flutter_local_notifications 19.5.0.
- Habit reminders repeat daily (`DateTimeComponents.time`); `tz.local` now resolved from device offset (was UTC).
- Stable FNV notification ids replace `String.hashCode` (legacy ids are also cancelled).
- Enabled habit reminders and upcoming appointment reminders are rescheduled on app start without a permission prompt.
- Notification tap just opens the app (handler logs only). iOS init no longer requests permission at startup.
- Result: completed.

### Task 12.3: Nutrition Filter and Content Refresh
- Chips are derived from content: trimester chips match week-range categories by overlap (`NutritionFilter`); chips with no items (e.g. "Ăn dặm", "Sau sinh" for guides) are hidden; recipes keep trimester labels.
- `NutritionSeedService` re-seeds guides when bundled `lastUpdated`/count changes; recipes (and favourites) are untouched.
- Result: completed.

### Task 12.4: Date Pickers
- `DatePickerUtils.pickDate` widens/clamps ranges. Applied in add appointment, settings due date, pregnancy setup, add period (start/end) and health diary.
- Result: completed.

### Task 12.5: Appointment Notifications
- `AppointmentReminderService` cancels reminders on delete (list + edit screen), reminder off, and mark-as-done; reschedules on save.
- Result: completed.

### Task 12.6: Cycles
- Regularity is tri-state; fewer than 3 cycles shows "Chưa đủ dữ liệu".
- Cycle lengths are recomputed from sorted start dates on save/delete (no negative values).
- Recorded periods list in Fertility Planner; `AddPeriodScreen(cycle:)` supports edit and delete; duplicate start dates rejected.
- Predictions roll forward past today.
- Result: completed.

### Task 12.7: Onboarding and Pregnancy Dates
- Intro slides now go to mode selection.
- Due date is the single source of truth: week and days-left both derive from it; setup links LMP <-> due date (+/-280 days); Settings due-date edit updates LMP.
- `saveNewActivePregnancy` deactivates previous active pregnancies; `getActivePregnancy` prefers the latest active one.
- Result: completed.

### Task 12.8: Cross-Tab Refresh
- Hive `listenable()` based: `HiveBoxesListener` widget (Home, Tracking) and `HiveRefreshMixin` (Health diary, Appointments, Settings); Fertility Planner and pre-pregnancy Home listen to the cycle box.
- Result: completed.

### Task 12.9: Health Diary
- Empty entries are blocked; decimal comma ("55,5") accepted (`HealthValidators.parseDecimal`) in diary, setup and settings weight.
- Result: completed.

### Task 12.10: Encryption Fallback
- Fallback is logged as a SECURITY warning, exposed via `EncryptionService.isFallbackActive` and shown in Settings.
- `resetOnError` set to false so a read error no longer wipes the key; key read retried once.
- Encryption state remembered (`hive_boxes_encrypted`): previously-encrypted data is never opened unencrypted (startup shows a "restart" screen instead); previously-unencrypted data is not reopened with a cipher.
- Result: completed. Trade-off: if the keystore fails permanently the app stays on the restart screen instead of silently losing data.

### Task 12.11: UX
- Pregnancy mode: "Theo dõi chu kỳ" quick action replaced by "Dấu hiệu cần khám"; "Chu kỳ" sub-tab removed.
- Days-left stat shows "ngày". Benefit/food chips use contrast-aware colours in dark mode (`ChipColors`).
- "Hồ sơ" coming-soon entry removed from Settings; notification dialogs now describe the real reminder controls. Week history dialog on Tracking left as-is (Phase 14).
- Result: completed.

### Task 12.12: Dependencies
- Removed unused `dio` and `flutter_svg`. Kept `image_picker` (planned Phase 20 bump photos) and `permission_handler` (no current use; kept to avoid churn with the health plugin, review before release).
- `pubspec.yaml` description updated.

### Store TODOs (need user input)
- TODO: replace `AppConstants.privacyPolicyUrl` / `medicalDisclaimerUrl` (`example.com`) with real public URLs.
- TODO: native splash / launcher branding (`launch_background.xml`, iOS LaunchScreen) still Flutter default.
- TODO: Android `android:label="momcare"` should be reviewed for store display name.

## Phase 13: Content Engine + Cẩm nang + Navigation
Status: Completed

### Task 13.1: Content Engine Parser
- `lib/core/models/guide_models.dart` + `lib/core/data/guide_content_parser.dart`, exposed through `ContentPackService` (`guides`, `sources`, `loadGuides`, `loadSources`, `parseGuide`, ...).
- Parses `sources.json` and `guides/index.json` + per-guide files per CONTENT_SCHEMA.md. Missing/invalid files -> empty list; invalid guide (missing id/title or unknown stage/category) skipped; unknown `actionType` -> `none`; non-`approved` -> draft. Duplicate item ids logged.
- `pubspec.yaml` declares `assets/content/guides/`.
- Daily / weeks_v2 / foods parsing intentionally not implemented (Phases 14-18).

### Task 13.2: Guide Renderer
- `GuideDetailScreen`: sections, checklist with persisted ticks (`GuideProgressService` + `guideChecklistProvider`, SharedPreferences key `guide_checklist_ticks`, cleared in delete-all-data), timeline, actions (`addAppointment` -> prefilled `AddAppointmentScreen(initialTitle, initialDate)` from active pregnancy + week; `openMaps` -> Google Maps search URL; `call` -> `tel:`), source metadata via `SourceMetadataCard.custom`, draft note "Nội dung đang chờ bác sĩ duyệt".

### Task 13.3: Cẩm nang Tab and Navigation
- `GuidesScreen`: guides for current mode (pre -> `pre`, pregnancy -> `pregnant`), grouped by category with Vietnamese labels, checklist progress %, empty state.
- Bottom navigation: Hôm nay / Tuần thai (Chu kỳ in pre-pregnancy) / Cẩm nang / Công cụ / Cài đặt. Existing screens reused.

### Task 13.4: Tests
- `test/content_engine_test.dart` with fixtures in `test/fixtures/content/` (valid, missing fields, invalid JSON, unknown enum, unsafe index names), bundled-pack schema check, checklist persistence, prefill date, Cẩm nang/detail widget tests.
- Phase 12 regressions in `test/core_logic_test.dart`; navigation smoke test updated.

## Phase 14: Detailed Week Pages (B1) + Warning Guide Checklist Fix
Status: Completed
Scope: FEATURE_BRAINSTORM.md B1 + Phase 13 carry-over (warning guides). Activated by the user (Phases 14-21). Content files are owned by the content author: do not hand-edit `assets/content/**` JSON or `assets/images/weeks/**` images.

### Task 14.1: Weeks v2 Model and Parser
- Add `WeekDetail` model (e.g. `lib/core/models/week_detail_models.dart`): `week`, `image` (String?), `sizeCompare` (String?), `lengthCm` (double?), `weightG` (double?), `babyDevelopment`, `motherChanges`, `commonSymptoms`, `todoThisWeek`, `examsThisWeek`, `nutritionFocus`, `redFlags`, `sources` (lists default empty), plus pack-level `lastUpdated` and `reviewStatus` (`isDraft`).
- Parser (`lib/core/data/week_content_parser.dart` or inside `ContentPackService`): `parseWeeksV2(String raw)` and `loadWeeksV2(AssetBundle)` for `assets/content/weeks_v2.json` (CONTENT_SCHEMA §4). Never throws. Invalid JSON / missing file -> empty map; entries without a valid int `week` in 0..42 are skipped; `lengthCm`/`weightG` accept int or double or null; non-string list entries dropped; unknown `reviewStatus` -> draft.
- `ContentPackService.init()` loads it into `ContentPackService.weekDetails` (Map<int, WeekDetail>). Add a resolver `weekDetail(int week)` that clamps 0..42 and, when weeks_v2 has no entry for that week, builds a `WeekDetail` from the existing `PregnancyWeeksDatabase.getWeekData(week)` (`development`, `motherChanges` joined, `tips` -> todo, `redFlags`, `nutritionFocus`, `babySize`, `sourceRefs`), so the page never renders empty.
- Acceptance: the bundled `weeks_v2.json` yields 43 entries (weeks 0-42); weeks 0-3 have null `sizeCompare`/`lengthCm`/`weightG` and parse without error; malformed/missing input returns empty and the resolver falls back to `pregnancy_weeks` data. Existing `content_pack_test.dart` tests still pass.
- Result: Done. `WeekDetail` model (`lib/core/models/week_detail_model.dart`) + never-throwing parser (`lib/core/data/week_content_parser.dart`); `ContentPackService.weekDetails` / `weekDetail()` / `resolveWeekDetail()` clamp 0..42 and fall back to `PregnancyWeeksDatabase`. Bundled pack yields 43 weeks; unit tests pass. Round 3: `_developmentForWeek` no longer embeds the legacy size (unused `size` parameter removed), so fallback text cannot contradict weeks_v2.

### Task 14.2: Week Image With Default Placeholder
- Widget `WeekImage` (e.g. `lib/features/tracking/widgets/week_image.dart`): renders `Image.asset(detail.image)` with an `errorBuilder` that shows a polished placeholder (themed rounded gradient card using `Theme` colors, a fruit/baby icon such as `Icons.child_care` / `Icons.spa`, and text "Tuần N" + size compare e.g. "To bằng quả chuối", or "Đang chuẩn bị" when `sizeCompare` is null). Null/empty `image` path -> placeholder directly, no asset lookup.
- `assets/images/weeks/` does not exist yet. Create the folder with a small placeholder file (e.g. `assets/images/weeks/.gitkeep` or `README.md` noting naming `week_XX.webp`, owned by the content author) and declare `- assets/images/weeks/` in `pubspec.yaml`, so dropping `week_XX.webp` files in later needs no code change. Do not add any images or new image packages.
- Acceptance: with no image files present, every week shows the placeholder and no exception / red error box / "Unable to load asset" crash appears in tests or logcat; `flutter build apk --debug` succeeds with the new asset folder declared.
- Result: Functionally done (`lib/features/tracking/widgets/week_image.dart`; `assets/images/weeks/.gitkeep` + `README.txt` declared in `pubspec.yaml`; no asset errors on device). Round 2: P14-R1-02 fixed (placeholder uses `AppTheme.primaryTint` with `onSurface` text/icon, >= 4.5:1 in both themes; verified on device). Round 3: regression-checked on device (placeholder at weeks 0/17, no asset errors).

### Task 14.3: Week Detail Screen With Swipe 0-42
- New `WeekDetailScreen` (e.g. `lib/features/tracking/screens/week_detail_screen.dart`) with `initialWeek` parameter: `PageView` over weeks 0..42 with a `PageController(initialPage: initialWeek.clamp(0, 42))`; AppBar title "Tuần N" updates on swipe; prev/next arrow buttons (disabled at 0 and 42); "Tuần hiện tại" chip/badge on the current pregnancy week; button to jump back to the current week when away from it.
- Each page shows, in order: `WeekImage`; size compare + length ("x cm") + weight ("x g") — each stat hidden or shown as "—" when null, never "null"; "Bé đang phát triển"; "Cơ thể mẹ thay đổi"; "Triệu chứng thường gặp"; "Việc nên làm tuần này"; "Khám / xét nghiệm trong tuần"; "Dinh dưỡng tuần này"; "Dấu hiệu cần đi khám ngay" (highlighted warning style, with link to the existing emergency/safety screen via `NavigationHelper` if one exists); `SourceMetadataCard.custom` with source titles resolved from `ContentPackService.sources` (unknown id -> show id) and `lastUpdated`; draft note "Nội dung đang chờ bác sĩ duyệt" when `isDraft`. Empty list sections are hidden.
- Keep it read-only: no checklist ticking on week pages in this phase.
- Acceptance: opening the screen with `initialWeek: 20` shows "Tuần 20", "quả chuối", "25.6 cm"/"300 g"; swiping left shows week 21; week 0 shows no length/weight/null text; all 43 pages build without overflow at phone width.
- Result: Done (`lib/features/tracking/screens/week_detail_screen.dart`). Verified on device: week 20 content, week 0 no 'null', bounds at 0/42, emergency link, source names, draft note, no overflow. Round 2: 'Tuần hiện tại' chip contrast fixed (P14-R1-02) and verified on device. Round 3: re-verified week 20 (quả chuối / 25.6 cm / 300 g), swipe to 21, week 0/42 bounds, no overflow.

### Task 14.4: Entry Points From Tuần thai Tab
- In `tracking_screen.dart`, remove the "Lịch sử theo tuần ... sẽ được bổ sung trong bản cập nhật sau" placeholder dialog; the history `IconButton` (only shown when `showAppBar: true`) now pushes `WeekDetailScreen(initialWeek: pregnancy.currentWeek)`.
- Because `MainNavigation` uses `TrackingScreen(showAppBar: false)`, add a visible entry point in the tab body: make the week header tappable and add a button "Xem chi tiết tuần N" (or "Xem theo từng tuần") below it, opening `WeekDetailScreen` on the current week. Optionally, the week header size/weight stats may read from the resolver (`ContentPackService.weekDetail`) for consistency; keep the existing cards otherwise unchanged (no broad rewrite).
- Acceptance: no "sắp ra mắt"/"bản cập nhật sau" week-history text remains in `lib/features/tracking`; from the Tuần thai tab one tap opens the detail screen on the current pregnancy week; back returns to the tab.
- Result: Entry points done (dialog removed; AppBar history button, tappable header, 'Xem chi tiết tuần N' button). Round 2: stat rows (header + BabyDevelopmentCard) now read from `ContentPackService.weekDetail` via `WeekDetail.statText` and match the detail page. Round 3: P14-R2-01 fixed (`BabyDevelopmentCard` renders `weekDetail.babyDevelopment`, falling back to `weekData.development`); verified on device that the week 17 tab text equals the detail page and 'quả lê' no longer appears. Done.

### Task 14.5: Warning Guides Without Checklist Progress (Phase 13 carry-over)
- For guides with `category == GuideCategory.warning` (bundled: `pregnant_warning_signs.json`), `GuidesScreen` must not show a progress bar / percentage, and `GuideDetailScreen` must render checklist items as a non-tickable bullet list of danger signs (no checkbox, no progress bar, no %), keeping any actions (e.g. call 115) working. Implement via a single helper (e.g. `GuideArticle.tracksProgress` / `progress()` returning null for warning) so both screens agree. Do not edit the guide JSON.
- Acceptance: the "Dấu hiệu nguy hiểm cần đi khám ngay" card shows no 0% bar in Cẩm nang; its detail page shows the signs without checkboxes; other guides (e.g. checkup) still show and persist ticks.
- Result: Done via `GuideArticle.tracksProgress` / `progress()`; verified on device (no bar/%, no Checkbox, 115 dialer, normal guide ticks persist). Round 2: P14-R1-03 fixed (heading 'Việc nên làm', shared `_Bullet` with bodyMedium); verified on device. Round 3: re-verified (no bar, no Checkbox, 115 dialer; normal guide tick persists after force-stop).

### Task 14.6: Tests
- Unit (`test/week_content_test.dart` + fixtures in `test/fixtures/content/weeks_v2/`): valid fixture parse; null length/weight; int vs double numbers; invalid JSON -> empty; entry with missing/out-of-range `week` skipped; resolver fallback to `pregnancy_weeks` when a week is missing; bundled `assets/content/weeks_v2.json` has 43 weeks 0..42 and all `sources` ids exist in `sources.json` (or are tolerated).
- Widget: `WeekDetailScreen(initialWeek: 20)` shows week 20 content and the placeholder (no asset present) without exceptions; swipe (`tester.drag`/`fling` on `PageView`) moves to week 21; week 0 renders without "null"; draft note visible.
- Widget: Tuần thai tab with an active pregnancy -> tapping the new "Xem chi tiết" entry opens `WeekDetailScreen` on the current week.
- Widget/unit: warning guide has no progress (`progress()`/`tracksProgress`) and no `Checkbox` in detail; a non-warning guide still has checkboxes.
- All existing tests still pass.
- Result: Done. `test/week_content_test.dart` (14 tests) + fixtures in `test/fixtures/content/weeks_v2/`; full suite 63 tests pass; analyze 0 errors/0 warnings. Round 2: added tab/detail stat consistency tests (weeks 17, 20), light/dark contrast tests and the updated warning-heading test; 69 tests pass. Round 3: the consistency test now asserts the legacy size is absent from the tab and the tab development text equals `weekDetail.babyDevelopment` / WeekDetailScreen; new test 'content pack development text carries no legacy size' (weeks 5-36); 70 tests pass.

### Verification and On-Device Test Plan (tester)
- Run `dart format` on changed files, `flutter analyze` (no new errors/warnings), `flutter test`, `flutter build apk --debug`; install on emulator with `adb install -r` (keep data).
- With an active pregnancy (e.g. week 17): open tab Tuần thai -> header still shows "Tuần 17"; tap "Xem chi tiết tuần" -> detail opens on Tuần 17 with "Tuần hiện tại" marker; placeholder image card shows week + size text (no broken image icon).
- Swipe left/right and use arrows: title changes 17 -> 18 -> 16; go to week 0 (prev arrow disabled, no length/weight/"null"); go to week 42 (next arrow disabled); "Về tuần hiện tại" returns to 17.
- On week 20 verify all sections: size "quả chuối", 25.6 cm, 300 g, phát triển, mẹ thay đổi, triệu chứng, việc nên làm, khám (siêu âm hình thái), dinh dưỡng, dấu hiệu cần đi khám (warning style), nguồn with readable names, draft note.
- Scroll long pages to the bottom; check no overflow stripes; rotate/narrow if possible.
- Back navigation returns to the Tuần thai tab; switch tabs and back — no errors.
- Cẩm nang: "Dấu hiệu nguy hiểm cần đi khám ngay" card has no progress bar/%; detail shows signs as bullets without checkboxes; 115 action still opens dialer. Another guide (Lịch khám thai) still ticks and persists after app restart.
- Pre-pregnancy mode / no active pregnancy: Tuần thai/Chu kỳ tab behaves as before (no crash, no detail entry when there is no pregnancy).
- Logcat: no Flutter exceptions / "Unable to load asset" errors.

### Test round 1 (2026-10-29)
- Dev: committed 66fa9d4 and pushed `feature/v1-content-and-fixes`. The PR was not opened automatically (no `gh`/token); open it at https://github.com/ntlong25/momcare/compare/main...feature/v1-content-and-fixes?expand=1 (contains 85a6f30 Phases 6-13 + 66fa9d4 Phase 14). `flutter test` 63 pass, `flutter analyze` 0 errors/0 warnings (16 pre-existing infos), `flutter build apk --debug` passed.
- Tester: installed on emulator-5554 with `adb install -r` (data kept, week 17). All test-plan checks passed: entry points, swipe/arrows/bounds, week 20 content, week 0 no 'null', placeholder without asset errors, no overflow, back navigation, warning guide with no progress/no Checkbox + 115 dialer, normal guide tick persists after restart ('Chọn nơi khám và nơi sinh' was used because 'Lịch khám thai định kỳ' has no checklist), pre-pregnancy mode OK, logcat clean.
- Accepted P14-R1-01 (major): the Tuần thai tab (week 17) shows 'quả lê' / 20.4cm / 210g from `PregnancyWeeksDatabase` while the detail page shows 'quả lựu' / 13 cm / 140 g from `weeks_v2.json`. Fix: in `lib/features/tracking/screens/tracking_screen.dart` (line ~45 and stat row ~227/238) and `lib/features/tracking/widgets/baby_development_card.dart` (size/length/weight rows), read size/length/weight from `ContentPackService.weekDetail(currentWeek)` and format them like the detail screen ('13 cm', '140 g'; null -> hidden or '—', never 'null'). Fall back to the legacy strings only when the resolver value is null. Share one formatter with `week_detail_screen.dart`. Add a widget test asserting the tab and the detail page show the same size/length/weight for the same week.
- Accepted P14-R1-02 (minor): in light mode the `WeekImage` placeholder and the 'Tuần hiện tại' chip have white text on pale pink. Fix: in `lib/features/tracking/widgets/week_image.dart` use `colorScheme.primaryContainer` with `onPrimaryContainer` text/icon (or a gradient opaque enough for white text); in `week_detail_screen.dart` (~line 108-117) the chip should use `colorScheme.primary` with `colorScheme.onPrimary`, or primaryContainer/onPrimaryContainer. Text must reach >= 4.5:1 contrast in both themes.
- Accepted P14-R1-03 (minor): the warning-guide checklist heading 'Dấu hiệu cần lưu ý' sits over action items. Fix: in `lib/features/guides/screens/guide_detail_screen.dart` (~line 63) use 'Việc nên làm' for non-progress guides, and render the bullets in the same text style as the section bullets. Update any test expectation that uses the old heading.
- Rejected P14-R1-04: the English labels in the Chu kỳ calendar are pre-existing and outside Phase 14; moved to Known issues.
- Verdict: fix.

### Test round 2 (2026-10-29)
- Dev: fixed P14-R1-01..03 (`content_pack_service.dart`, `week_detail_model.dart`, `app_theme.dart`, `guide_detail_screen.dart`, `tracking_screen.dart`, `week_detail_screen.dart`, `baby_development_card.dart`, `week_image.dart`, `test/week_content_test.dart`). `flutter test` 69 pass, `flutter analyze` 0 errors/0 warnings (16 pre-existing infos), `flutter build apk --debug` passed. No content JSON edited.
- Tester: debug APK installed on emulator-5554 with `adb install -r` (data kept, week 17). Passed: stat rows match the detail page (quả lựu / 13 cm / 140 g, no 'null'); placeholder and 'Tuần hiện tại' chip readable in light and dark mode; warning guide heading 'Việc nên làm' with matching bullets, no Checkbox, no progress bar, 115 dialer; normal guide tick persists after force-stop; entry points, arrows/swipes, jump back, week 0 and week 20 content, no overflow, back navigation, pre-pregnancy mode, logcat clean. User state restored.
- Accepted P14-R2-01 (major, P14-R1-01 only partly fixed): on the Tuần thai tab the BabyDevelopmentCard 'Điều đang diễn ra' text says 'Kích thước tham khảo tuần này khoảng quả lê' while the stat rows right above it and the detail page say 'quả lựu' (weeks 5-36 affected). Cause: `ContentPackService._developmentForWeek(week, size)` (`lib/core/data/content_pack_service.dart` ~265-281) embeds the legacy `PregnancyWeeksDatabase.getBabySizeComparison` size, and `lib/features/tracking/widgets/baby_development_card.dart` (~line 81) renders `weekData.development`. Fix: in `BabyDevelopmentCard`, render `weekDetail.babyDevelopment` when `weekDetail` is non-null and that text is non-empty, else fall back to `weekData.development`. Also drop the size clause from `_developmentForWeek` (or build it from the weeks_v2 `sizeCompare`) so legacy size text cannot reach the tab via the fallback either. Extend the 'tab and detail page show the same baby stats' test in `test/week_content_test.dart` to assert the legacy size (e.g. 'quả lê' for week 17) appears nowhere on the Tuần thai tab and that the tab's development text equals the one on WeekDetailScreen. No content JSON edits.
- Verdict: fix.

### Test round 3 (2026-10-29)
- Dev: fixed P14-R2-01 (`lib/features/tracking/widgets/baby_development_card.dart`, `lib/core/data/content_pack_service.dart`, `test/week_content_test.dart`). `flutter test` 70 pass, `flutter analyze` 0 errors/0 warnings (16 pre-existing infos in unchanged files), `flutter build apk --debug` passed. No content JSON edited.
- Tester: APK (newer than the source edits) installed on emulator-5554 with `adb install -r` (data kept, week 17). P14-R2-01 verified fixed: the 'Điều đang diễn ra' text for week 17 matches 'Sự phát triển của bé' on WeekDetailScreen, 'quả lê' appears nowhere, stats show quả lựu / 13 cm / 140 g. Regression checks passed: entry button, arrows/swipe, jump back to current week, week 0 (prev disabled, 'Đang chuẩn bị', no length/weight/'null'), week 20 (quả chuối / 25.6 cm / 300 g, draft note), swipe to week 21, week 42 (next disabled, all sections, warning-style red flags, readable source names, no overflow), back navigation, warning guide (no bar, no Checkbox, 115 dialer), normal guide tick persists after force-stop, logcat clean. Test data restored.
- Accepted issues: none. Rejected issues: none.
- Verdict: pass. Phase 14 completed.

## Phase 15: Hôm nay Daily Card (B2) + Daily Thai Giáo and Tips (B3)
Status: Completed
Scope: FEATURE_BRAINSTORM.md B2 + B3, activated by the user (Phases 14-21). Pregnancy-mode `HomeScreen` only; `PrePregnancyHomeScreen` is unchanged. Content files are owned by the content author: do not hand-edit `assets/content/**` JSON (only if content is truly wrong, fix the generators in `content_source/build/*.js`, rerun `node content_source/build/build_all.js` and `dart run content_source/validate.dart`). No new packages; no analytics/AI/backend.
Grounding (verified 2026-10-29): `daily/thai_giao.json` and `daily/daily_tips.json` each have 294 items, days 1..294 with none missing, `day == week*7 + dayOfWeek + 1`, `reviewStatus: draft_requires_medical_review`, all `sources` empty. Thai giáo categories rotate by weekday (talk, music, movement, reading, breathing, partner, journal); tips have no `durationMin`. `pubspec.yaml` declares `assets/content/` and `assets/content/guides/` but not `assets/content/daily/` (Flutter asset folders are not recursive). The current tip is the hard-coded `l10n.dailyTipMessage` in `HomeScreen._buildDailyTip`. Delete-all is `SettingsScreen._deleteAllDataAndRestart` (cancels all notifications, removes the listed prefs keys). Daily-repeat pattern: `NotificationService.scheduleNotification(..., matchDateTimeComponents: DateTimeComponents.time)` + `nextInstanceOf` + `stableId`, re-registered in `main.dart` `_rescheduleReminders()`.

### Task 15.1: Daily Item Model and Parser
- Add `DailyItem` (e.g. `lib/core/models/daily_item_model.dart`): `day`, `week`, `category` (String), `title`, `body`, `durationMin` (int?), `sources` (List<String>, default empty); and `DailyPack` with `type`, `lastUpdated` (String?), `isDraft` (any `reviewStatus` other than `approved` -> draft), `items` sorted by day.
- Add `lib/core/data/daily_content_parser.dart` following `WeekContentParser`: `parseDailyPack(String raw, {required String expectedType})` and `loadDailyPack(AssetBundle, String path, ...)`. Never throws. Invalid JSON / missing file / wrong root shape -> empty pack. Skip items whose `day` is not an int in 1..294, with empty `title`/`body`, or whose `category` is not in the CONTENT_SCHEMA §3 list for that type (thai giáo: talk/music/movement/reading/breathing/partner/journal; tip: nutrition/body/mental/prep/safety). Duplicate day -> keep the first, log the duplicate. `durationMin` accepts int or whole double, otherwise null; non-string `sources` entries dropped.
- Resolver `DailyPack.itemForDay(int day)`: clamp day to 1..294; exact match first; otherwise the expected category is the category most used by the pack's items on the same weekday slot (`(day - 1) % 7`), and return the nearest item of that category (ties -> earlier day); if there is none, the nearest item of any category; empty pack -> null.
- Pregnancy day helper on `PregnancyModel`: `pregnancyDayAt(DateTime now)` = `calendarDaysBetween(pregnancyStartDate, now) + 1` (raw, for display) and a content day = that value clamped to 1..294. Must agree with `currentWeekAt(now)` (content day `d` belongs to week `(d - 1) ~/ 7`).
- `ContentPackService.init()` loads `thaiGiaoPack` and `dailyTipsPack` (getters + `@visibleForTesting` setters like `debugWeekDetails`); add `- assets/content/daily/` to `pubspec.yaml`.
- Acceptance: the bundled packs each yield 294 items with no skipped entries and `isDraft == true`; a fixture with day 10 removed resolves day 10 to the nearest item with day 10's weekday category (thai giáo `movement`: day 3 or 17 -> 3 by the tie rule); invalid JSON / unknown category / out-of-range day are handled without exceptions; existing tests still pass.

### Task 15.2: Thai Giáo Completion and Streak Service
- `lib/core/services/thai_giao_progress_service.dart` following `GuideProgressService`: SharedPreferences key `AppConstants.thaiGiaoDoneKey = 'thai_giao_done_dates'` storing a sorted JSON list of local dates `yyyy-MM-dd`; corrupt value -> empty set. API: `loadDone()`, `setDone(DateTime day, bool done)`, `clear()`, and a pure `streakAt(Set<String> done, DateTime now)`: if today is done, count consecutive days back from today; else count back from yesterday (the streak is not lost until a whole day is missed); 0 when neither today nor yesterday is done.
- A Riverpod `StateNotifierProvider` (`thaiGiaoProgressProvider`) with `ready` and `resetLocal()`, like `guideChecklistProvider`, so the card updates immediately.
- Delete-all: `_deleteAllDataAndRestart` removes `thaiGiaoDoneKey` and the reminder key from Task 15.4, and calls `resetLocal()`.
- Acceptance: unit tests for streak (no data -> 0; today only -> 1; yesterday + day before with today not done -> 2; a gap breaks the streak; unticking today lowers it); done state survives a new notifier instance (persisted); after delete-all both prefs keys are gone.

### Task 15.3: Hôm nay Top Section
- New widgets under `lib/features/home/widgets/` (e.g. `pregnancy_day_card.dart`, `today_thai_giao_card.dart`, `today_tip_card.dart`, `week_todo_card.dart`), inserted at the top of `HomeScreen._buildPregnancyView` after the greeting in this order: pregnancy day card, thai giáo card, tip card, "Việc tuần này"; then the existing `PregnancyProgressCard`, `MaternalHabitsCard`, `EmergencyEntryCard`, `QuickActionsGrid`, `UpcomingAppointmentsCard`. Remove `_buildDailyTip` and its use of `l10n.dailyTipMessage` (ARB keys may stay).
- Pregnancy day card: "Ngày X/280" with "Tuần W · ngày D" (D = 1..7) and a progress bar X/280. When X > 280 show "Ngày X" plus "Đã qua ngày dự sinh" (bar capped at 100%); when X < 1 show "Ngày 1/280".
- Thai giáo card: Vietnamese category label (Trò chuyện / Âm nhạc / Vận động nhẹ / Đọc truyện / Hít thở / Cùng bố / Nhật ký), title, body, "~N phút" when `durationMin` is set; a "Đã làm" toggle for today; "Chuỗi N ngày" when N > 0; draft note "Nội dung đang chờ bác sĩ duyệt" when the pack is draft.
- Tip card: heading "Gợi ý hôm nay", item title + body, draft note when draft.
- "Việc tuần này": `ContentPackService.weekDetail(pregnancy.currentWeek).todoThisWeek` as bullets (max 5, then "Xem tất cả" opening `WeekDetailScreen(initialWeek: currentWeek)`); hidden when empty.
- Empty/failed pack -> that card is hidden (no crash, no hard-coded fallback text). Never show "null". Cards follow the existing `HiveBoxesListener` rebuild so a due date edit updates the day.
- Acceptance: with a pregnancy at week 17, weekday slot 2 (content day 122) the tab shows "Ngày 122/280", the thai giáo item with `day == 122`, the tip with `day == 122` and the week 17 todos from weeks_v2; ticking "Đã làm" updates the streak immediately and persists after restart; no overflow at 360-390 dp width.

### Task 15.4: Opt-In Daily Thai Giáo Reminder
- In the thai giáo card, a reminder control (switch/bell, off by default) with a time picker (default 20:00), following `MaternalHabitsCard`'s reminder UX. Persist `{enabled, hour, minute}` in SharedPreferences key `AppConstants.thaiGiaoReminderKey = 'thai_giao_reminder'`.
- Schedule with `NotificationService.scheduleNotification` at `nextInstanceOf(hour, minute)`, `matchDateTimeComponents: DateTimeComponents.time`, id `NotificationService.stableId('thai_giao:daily')`, title "Thai giáo hôm nay", fixed body "Dành vài phút cho hoạt động thai giáo hôm nay cùng bé." (a repeating notification cannot carry per-day text). Permission denied -> switch stays off with a SnackBar. Disabling cancels the id. `_rescheduleReminders()` in `main.dart` re-registers it when enabled (`requestPermission: false`). Delete-all already cancels all notifications; also remove the key.
- Acceptance: enabling schedules exactly one daily notification at the chosen time; disabling removes it; the setting survives restart; nothing is scheduled unless the user turns it on.

### Task 15.5: Tests
- Unit (`test/daily_content_test.dart` + fixtures in `test/fixtures/content/daily/`): valid parse; invalid JSON -> empty; unknown category / out-of-range day / empty title skipped; duplicate day keeps first; `durationMin` int/double/null; missing-day fallback to the nearest same-category item and to the nearest any item; clamp below 1 / above 294; bundled packs have 294 items, days 1..294, valid categories, `day == week*7 + dow + 1`; `pregnancyDayAt` agrees with `currentWeekAt` across weeks 0..41.
- Unit: streak cases from Task 15.2; persistence through `SharedPreferences.setMockInitialValues`; reminder settings save/load and default off.
- Widget: `HomeScreen` with an active pregnancy (Hive/prefs set up as in existing tests, packs set via the debug setters) shows the day card, thai giáo title, tip title and week todos, and not the old `dailyTipMessage` text; tapping "Đã làm" shows "Chuỗi 1 ngày"; with empty packs the cards are hidden and the screen builds without exceptions.
- All existing tests still pass (update `widget_test.dart` smoke test only if the new cards need it).

### Verification and On-Device Test Plan (tester)
- Run `dart format` on changed files, `flutter analyze` (no new errors/warnings), `flutter test`, `flutter build apk --debug`; install on the emulator with `adb install -r` (keep data). Run the content build + validate only if generators were touched.
- Pregnancy mode with an active pregnancy (e.g. week 17): open Hôm nay -> top shows "Ngày X/280" consistent with the Tuần thai week (X = week*7 + weekday slot + 1), then today's thai giáo (category, title, body, minutes), "Gợi ý hôm nay" with a content tip (not "Hãy uống đủ nước mỗi ngày..."), and "Việc tuần này" bullets equal to "Việc nên làm tuần này" on the week 17 detail page; "Xem tất cả" opens WeekDetailScreen on week 17. Habits, emergency card, quick actions and appointments still appear below.
- Draft note "Nội dung đang chờ bác sĩ duyệt" is visible on the thai giáo and tip cards.
- Tap "Đã làm" -> state changes and "Chuỗi 1 ngày" appears; force-stop and reopen -> still done. Untick -> streak disappears. Optional: set the emulator date +1 day -> new activity and tip, not done, streak still 1; tick -> 2.
- Edit the due date so the week changes -> day card, activity, tip and todos update without restart.
- Reminder: enable with a time 2 minutes ahead -> permission prompt (first time) -> notification "Thai giáo hôm nay" arrives; disable -> no further notification; restart keeps the setting. Deny permission -> switch stays off with a message.
- Settings > delete all data -> after re-onboarding with a new pregnancy, today is not done, no streak, reminder off, no thai giáo notification fires.
- Pre-pregnancy mode: Hôm nay is the unchanged PrePregnancyHomeScreen; no active pregnancy -> setup prompt, no crash.
- Light and dark mode readable; scroll the whole tab with no overflow stripes; logcat has no Flutter exceptions or "Unable to load asset" errors.

### Results (round 1)
- 15.1 Result: done. `lib/core/models/daily_item_model.dart` and `lib/core/data/daily_content_parser.dart` (never throws; skip rules, duplicate keeps first, `durationMin` int/double/null, weekday-slot category fallback with earlier-day ties); `PregnancyModel.pregnancyDayAt` + `contentDayAt`; `ContentPackService` loads `thaiGiaoPack`/`dailyTipsPack`; `assets/content/daily/` added to `pubspec.yaml`. Bundled packs: 294 draft items each. Verified on device (day 121 items shown).
- 15.2 Result: done. `ThaiGiaoProgressService` (`thai_giao_done_dates`) + `thaiGiaoProgressProvider` (`ready`, `resetLocal`); delete-all removes both keys and calls `resetLocal()`. Streak/persistence unit-tested; tick persists after force-stop on device. Delete-all not run on device (user data); covered by `clear()` unit tests.
- 15.3 Result: done, with a fix needed. `PregnancyDayCard`, `TodayThaiGiaoCard`, `TodayTipCard`, `WeekTodoCard` at the top of `_buildPregnancyView`; `_buildDailyTip` removed; existing cards below; pre-pregnancy unchanged. Device: 'Ngày 121/280 · Tuần 17 · ngày 2', content-pack items, week 17 todos, 'Xem tất cả' -> Tuần 17, due date edit updates without restart, no overflow. Open: P15-R1-01 (dark-mode chip), P15-R1-03 (stale date).
- 15.4 Result: done, with a fix needed. `ThaiGiaoReminderService` (`thai_giao_reminder`), off by default, 20:00 default, exactly one alarm, notification arrives, survives restart without duplicates, disable cancels, denied permission keeps switch off with SnackBar. Open: P15-R1-02 (keyboard-mode time entry).
- 15.5 Result: done. `test/daily_content_test.dart` (33 tests) + fixtures; suite 102/102 pass. Content widget tests run at 600 dp because of the old cards' test-font overflow (see Known issues); 360/390 dp tests assert no error comes from the four new card files.

### Test round 1 (2026-10-29)
- Dev: all of 15.1-15.5 implemented. `flutter test` 102 pass, `flutter analyze` 0 errors/0 warnings (16 pre-existing infos), `flutter build apk --debug` passed. No content JSON or generators touched. Nothing committed.
- Tester: APK (newer than all source changes) installed on Pixel_7 emulator with `adb install -r` (data kept, week 17). Passed: day card 'Ngày 121/280 · Tuần 17 · ngày 2' (consistent with week 17), day-121 thai giáo ('Âm nhạc', 'Für Elise', '~4 phút') and tip ('Mất thăng bằng'), water tip gone, week 17 todos match weeks_v2, 'Xem tất cả' -> Tuần 17, draft notes on both cards, old cards still below, no overflow; 'Đã làm' -> 'Chuỗi 1 ngày', persists after force-stop, untick hides streak; reminder off by default / 20:00 default / exactly one alarm / notification arrived / survives restart / disable removes alarm / permission denied keeps switch off with SnackBar; due-date edit updates all cards live; light mode readable; pre-pregnancy unchanged; other tabs OK; logcat clean. Not tested on device: delete-all (user data), next-day streak (no root to change date).
- Accepted P15-R1-01 (major): in dark mode the selected 'Đã làm' FilterChip label and checkmark are unreadable (light pink on light pink). Fix: in `lib/features/home/widgets/today_thai_giao_card.dart` (FilterChip ~line 111) set `selectedColor: theme.primaryColor.withValues(alpha: 0.3)` and `checkmarkColor: theme.primaryColor` like the Nutrition FilterChip (or `colorScheme.primaryContainer` + `labelStyle` with `onPrimaryContainer`), so the label and checkmark reach >= 4.5:1 contrast in both themes. Recheck dark and light on device.
- Accepted P15-R1-02 (minor): in the time picker's keyboard-input mode on a 12-hour device, typing 02:30 saves 14:30 (Vietnamese picker shows a 24h dial but input parsing follows `MediaQuery.alwaysUse24HourFormat == false` and keeps the PM period of 20:00). Fix: in `today_thai_giao_card.dart` `_pickTimeAndEnable` pass `builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!)` to `showTimePicker`. The same pattern in `lib/features/home/widgets/maternal_habits_card.dart:152` is pre-existing (added to Known issues); applying the same one-line builder there is allowed but optional.
- Accepted P15-R1-03 (minor, code review): `TodayThaiGiaoCard.build` captures `DateTime.now()` and the 'Đã làm' `onSelected` closure calls `progress.setDone(now, value)` with it, and nothing rebuilds the Hôm nay cards at midnight or on resume, so after a day rollover the card can show yesterday's item and tick yesterday's date. Fix: (a) in `today_thai_giao_card.dart` call `progress.setDone(DateTime.now(), value)` inside `onSelected`; (b) in `lib/features/home/screens/home_screen.dart` make the pregnancy view rebuild on `AppLifecycleState.resumed` (e.g. a `WidgetsBindingObserver` in the screen state calling `setState` when the calendar date differs from the date of the last build) so `_buildPregnancyView` recomputes the content day. Add a unit/widget test that the toggle marks the date at tap time (e.g. inject a clock or verify `setDone` uses the current date).
- Rejected issues: none.
- Verdict: fix.

### Results (round 2)
- 15.1 Result: done (unchanged since round 1). Bundled packs have 294 draft items each; parser/fallback/clamp tests pass.
- 15.2 Result: done. Streak and persistence tests pass; device: tick persists after force-stop, next-day streak 1 -> 2 verified by changing the emulator date. Delete-all key removal covered by unit tests (not run on device to keep user data).
- 15.3 Result: done. P15-R1-01 fixed (`FilterChip` uses `AppTheme.primaryTint` with `onSurface` label/checkmark; readable in dark and light). P15-R1-03 fixed (`TodayThaiGiaoCard` reads an injectable `clock` at tap time; `HomeScreen` is now a `ConsumerStatefulWidget` with a `WidgetsBindingObserver` that rebuilds on resume when the date changed; device: resume after a date change shows day 122 with a new activity).
- 15.4 Result: done. P15-R1-02 fixed (`showTimePicker` builder forces `alwaysUse24HourFormat: true`; device: typed 02:46 on a 12-hour device scheduled 02:46). Notification arrived and turning it off cancelled it.
- 15.5 Result: done. 4 new `TodayThaiGiaoCard` tests (chip contrast light/dark, date at tap time, 24h picker); suite 106/106 pass. The `HomeScreen` resume rebuild has no automated test (verified on device).

### Test round 2 (2026-10-29)
- Dev: fixed P15-R1-01..03 (`lib/features/home/widgets/today_thai_giao_card.dart`, `lib/features/home/screens/home_screen.dart`, `test/daily_content_test.dart`). `flutter test` 106 pass, `flutter analyze` 0 errors/0 warnings (16 pre-existing infos in other files), `flutter build apk --debug` passed. `maternal_habits_card.dart` left as is (Known issue). No content JSON or generators touched. Nothing committed.
- Tester: APK (02:41, newer than the last edit at 02:40) installed on emulator-5554 with `adb install -r` (data kept, week 17). All three fixes verified on device: chip readable in dark and light; on a 12-hour device keyboard entry 02:46 -> alarm at 02:46; date change + resume -> 'Ngày 122/280 · Tuần 17 · ngày 3', new activity not done, streak 1 -> 2 on tick, back to day 121 with tick kept after restoring auto time. Regression passed: day card 'Ngày 121/280 · Tuần 17 · ngày 2', thai giáo card (Âm nhạc, ~4 phút, toggle, streak, reminder, draft note), content tip with draft note (water tip gone), week 17 todos + 'Xem tất cả' -> Tuần 17 and back, old cards below, tick persists after force-stop and untick hides streak, reminder arrives/reschedules/cancels/survives restart, no 'null'/overflow, other tabs OK, logcat clean. Not re-run on device this round: delete-all (unit-tested), pre-pregnancy mode, due-date edit, permission denied (all passed on device in round 1 and untouched by the round 2 changes). Device state restored.
- Accepted issues: none. Rejected issues: none.
- Verdict: pass. Phase 15 completed.

## Phase 16: Personal Checkup Schedule (B4) + Pregnancy Vaccinations (B5)
Status: Completed
Scope: FEATURE_BRAINSTORM.md B4 + B5, activated by the user (Phases 14-21). Turn the timelines of `pregnant_checkups` and `pregnant_vaccination` into a personal schedule for the active pregnancy (upcoming / due now / past / done with a date), add a "Mốc khám tiếp theo" card on Hôm nay, and offer the prefilled "Thêm vào lịch hẹn" only for milestones that are not past. Reminders come only from appointments the user creates (existing `AppointmentReminderService`); no new notification type. No new packages; no analytics/AI/backend. Pre-pregnancy mode (`pre_vaccination`, `PrePregnancyHomeScreen`) is unchanged. Content files are owned by the content author: do not hand-edit `assets/content/**` JSON; the only content change in this phase goes through `content_source/build/guides_pregnant.js` (Task 16.1).
Grounding (verified 2026-10-29): `pregnant_checkups.json` (category `checkup`, draft, no checklist) has 13 timeline items, all `actionType: addAppointment`: `tl_chk_first_visit` (6-8), `tl_chk_nt_scan` (11-13), `tl_chk_triple` (16-18), `tl_chk_anomaly` (20-22), `tl_chk_gdm` (24-28), `tl_chk_growth` (30-32), `tl_chk_34` (34-35), `tl_chk_36`..`tl_chk_41` (single weeks). `pregnant_vaccination.json` (category `vaccination`, weeks 0-40, draft) has **no timeline** (`timeline: []`); vaccines exist only as checklist items `chk_preg_vax_flu` (weekDue null), `chk_preg_vax_tdap` (27, text says 27-36), `chk_preg_vax_tetanus` (16), `chk_preg_vax_rsv` (32, action none), plus `chk_preg_vax_record` and `chk_preg_vax_family`. A checklist item has only `weekDue`, so a window such as Tdap 27-36 cannot be expressed; `content_source/validate.dart` requires timeline items to have int `weekFrom <= weekTo`. Existing code: `GuideTimelineItem` (`weekFrom`, `weekTo`, `weekLabel`) in `lib/core/models/guide_models.dart`; `_TimelineTile` in `lib/features/guides/screens/guide_detail_screen.dart` always shows the action button; `GuideActions.estimatedDateForWeek(pregnancy, week)` = `pregnancyStartDate + week*7` days, moved to today when in the past, and `GuideActions.run(addAppointment)` pushes `AddAppointmentScreen(initialTitle, initialDate)` (time 08:00; its date picker has `firstDate: DateTime.now()`). `ContentPackService.guides` has no lookup by id and no debug setter. `PregnancyModel` has `pregnancyStartDate`, `calendarDaysBetween`, `currentWeekAt(now)` (clamped 0..42). Ticks use `GuideProgressService` / `guideChecklistProvider` (`guide_checklist_ticks`). Delete-all is `SettingsScreen._deleteAllDataAndRestart` (removes prefs keys, calls notifier `resetLocal()`). `HomeScreen._buildPregnancyView` order: PregnancyDayCard, TodayThaiGiaoCard, TodayTipCard, WeekTodoCard, PregnancyProgressCard, MaternalHabitsCard, EmergencyEntryCard, QuickActionsGrid, UpcomingAppointmentsCard.

### Task 16.1: Vaccination Timeline Content (generator only)
- In `content_source/build/guides_pregnant.js` (`pregnant_vaccination`) add timeline items with `t(...)`, keeping `reviewStatus` draft and the existing sources: `tl_vax_flu` (0-40, flu, inactivated vaccine, can be given at any stage, especially before flu season), `tl_vax_tetanus` (16-36, uốn ván VAT/Td, number of doses depends on vaccination history, ask the commune health station), `tl_vax_tdap` (27-36, Tdap bạch hầu – uốn ván – ho gà), `tl_vax_rsv` (32-36, ask the doctor about RSV; `actionType` `none` because availability varies). Every description contains "theo chỉ định của bác sĩ / nhân viên y tế". Week ranges come from the existing guide text and stay draft for medical review.
- Remove the four duplicated vaccine checklist entries (`chk_preg_vax_flu`, `chk_preg_vax_tdap`, `chk_preg_vax_tetanus`, `chk_preg_vax_rsv`) so a vaccine is not shown twice with two different done states; keep `chk_preg_vax_record` and `chk_preg_vax_family`. Old persisted ticks for the removed ids become unused and are harmless.
- Run `node content_source/build/build_all.js` and `dart run content_source/validate.dart`; record both outputs in the round notes.
- Acceptance: validate passes with 0 errors; the bundled `pregnant_vaccination.json` has exactly those 4 timeline items (ids unique across all guides) and 2 checklist items; `git diff` shows no other content file change apart from `pregnant_vaccination.json` and the generator.

### Task 16.2: Schedule Model (pure logic)
- New `lib/core/models/milestone_schedule.dart`: `enum MilestoneStatus { upcoming, dueNow, past, done }` and `ScheduledMilestone` with `item` (`GuideTimelineItem`), `guideId`, `isVaccination` (guide category `vaccination`), `startDate`, `endDate`, `status`, `doneDate` (DateTime?), `daysUntilStart`, and `canAddAppointment` (= `item.actionType == addAppointment` and status is `upcoming` or `dueNow`).
- `MilestoneSchedule.build({required GuideArticle guide, required PregnancyModel pregnancy, required DateTime now, required Map<String, DateTime> done})`: for each timeline item use `from = weekFrom ?? weekTo`, `to = weekTo ?? weekFrom` (items with neither are skipped); `startDate = pregnancyStartDate + from*7` days and `endDate = pregnancyStartDate + (to + 1)*7 - 1` days (date-only, local, built with `DateTime(y, m, d + n)` like `estimatedDateForWeek`). Status: `done` if the id is in `done`; else `upcoming` if today < startDate; `dueNow` if startDate <= today <= endDate; `past` if today > endDate. Sort by `startDate`, then `endDate`. Uses raw days (no 0..42 clamp).
- `MilestoneSchedule.next(List<ScheduledMilestone>)`: the not-done `dueNow` item with the earliest `endDate`, otherwise the earliest `upcoming` item, otherwise null.
- Appointment prefill date = `GuideActions.estimatedDateForWeek(pregnancy, item.weekFrom, now: now)` (window start, or today when the window is already open); never a date before today.
- Acceptance: unit tests with a fixed `now`: day before start -> upcoming, first day -> dueNow, last day -> dueNow, day after end -> past; done overrides every status; `next()` prefers due-now over upcoming and returns null when everything is past/done; a single-week item (36-36) spans exactly 7 days; changing the due date shifts all dates.

### Task 16.3: Done-With-Date Persistence
- `lib/core/services/milestone_progress_service.dart` following `GuideProgressService`: SharedPreferences key `AppConstants.milestoneDoneKey = 'milestone_done_dates'` storing a JSON object `{itemId: 'yyyy-MM-dd'}`; a corrupt value -> empty map, an unparsable date -> that entry dropped (never throws). API: `loadDone()`, `setDone(String id, DateTime date)`, `clearDone(String id)`, `clear()`.
- `MilestoneProgressNotifier` + `milestoneProgressProvider` (`StateNotifierProvider<..., Map<String, DateTime>>`) with `ready`, `markDone(id, date)`, `unmark(id)`, `resetLocal()`, like `guideChecklistProvider`, so the guide page and the Hôm nay card update immediately.
- Delete-all: `_deleteAllDataAndRestart` removes `milestoneDoneKey` and calls `ref.read(milestoneProgressProvider.notifier).resetLocal()`.
- Acceptance: unit tests: mark/unmark round-trip; state survives a new notifier instance (persisted); corrupt JSON and an invalid date string do not throw; after `clear()` the key is gone.

### Task 16.4: Schedule in the Guide Detail Timeline
- Add `ContentPackService.guideById(String id)` (null when missing) and `@visibleForTesting set debugGuides(List<GuideArticle>)` like `debugWeekDetails`.
- In `GuideDetailScreen`, when the guide stage is `pregnant`, an active pregnancy exists (`DatabaseService.getActivePregnancy()`, guarded like `GuideActions.run`) and the timeline is not empty, render the timeline from `MilestoneSchedule.build` (section title stays "Các mốc theo tuần"). Each `_TimelineTile` additionally shows:
  - the date range "dd/MM – dd/MM/yyyy" (`intl` `DateFormat`);
  - a status chip: "Sắp tới · còn N ngày" / "Đến lúc rồi" / "Đã qua" / "Đã khám dd/MM/yyyy" (checkup) or "Đã tiêm dd/MM/yyyy" (vaccination), readable in light and dark (same tint approach as the P15-R1-01 fix);
  - for vaccination items, always the line "Theo chỉ định của bác sĩ" (app text, independent of the content description);
  - the "Thêm vào lịch hẹn" button only when `canAddAppointment` (hidden for past, done and `actionType: none` items);
  - a "Đánh dấu đã khám" / "Đánh dấu đã tiêm" button that opens `DatePickerUtils.pickDate` with `initialDate` today, `firstDate` `pregnancyStartDate`, `lastDate` today (no future dates); confirming calls `markDone`. A done item shows "Bỏ đánh dấu", which calls `unmark`.
- Without an active pregnancy, or for non-pregnant guides, the tile renders as before (no status/done controls), so `pre_*` guides and the Phase 13/14 tests are unchanged.
- Acceptance: widget test with a pregnancy at week 17 and a fixture checkup guide: the 16-18 item shows "Đến lúc rồi" and the add button; the 6-8 item shows "Đã qua" and no add button; the 20-22 item shows "Sắp tới" and the add button; marking 6-8 done shows "Đã khám <date>" and survives a rebuild. The vaccination fixture shows "Theo chỉ định của bác sĩ" on every item, and its `none` item has no add button.

### Task 16.5: "Mốc khám tiếp theo" Card on Hôm nay
- New `lib/features/home/widgets/next_milestone_card.dart`, inserted in `_buildPregnancyView` right after `WeekTodoCard` (before `PregnancyProgressCard`). It rebuilds with the existing `HiveBoxesListener` / resume logic and watches `milestoneProgressProvider`.
- Content: heading "Mốc khám tiếp theo"; the `MilestoneSchedule.next` item of `pregnant_checkups` with title, week label, date range and the Task 16.4 status chip; a "Thêm vào lịch hẹn" button (only when `canAddAppointment`, via `GuideActions.run` with `week: item.weekFrom`) and "Xem lịch khám", which opens `GuideDetailScreen(guide: pregnant_checkups)`. Below it, when at least one vaccination item is `dueNow` and not done, a line "Tiêm phòng: N mũi nên hỏi bác sĩ lúc này" that opens `GuideDetailScreen(guide: pregnant_vaccination)`. Draft note when the guide is draft (reuse `DraftContentNote`).
- Hidden when the checkup guide is missing/empty, or when `next()` is null and no vaccine is due (e.g. after week 41). No "null" text, no overflow at 360-390 dp.
- Acceptance: widget test (guides via `debugGuides`): pregnancy at week 17 -> the card shows the 16-18 triple-test milestone with "Đến lúc rồi"; after marking it done the card moves to the 20-22 anomaly scan ("Sắp tới · còn N ngày"); at week 17 the vaccine line counts flu + tetanus = 2 (Tdap not yet due); at week 43 with everything past the card is hidden; with no guides the card is hidden and the screen builds without exceptions.

### Task 16.6: Tests
- Unit (`test/milestone_schedule_test.dart`, fixtures under `test/fixtures/content/` if needed): the Task 16.2 boundaries and `next()`; the Task 16.3 persistence/corrupt data/clear cases; bundled `pregnant_checkups` builds 13 milestones and bundled `pregnant_vaccination` builds 4, `isVaccination` correct, ids unique; no prefill date is before `now` for any item that is not past.
- Widget: the Task 16.4 and 16.5 cases. Existing `GuideDetailScreen` tests in `content_engine_test.dart` and `week_content_test.dart` still pass (no pregnancy -> old rendering).
- All existing tests still pass. Content widget tests may use 600 dp width because of the old cards (Known issue), but must assert that the new card has no overflow at 360 dp.

### Verification and On-Device Test Plan (tester)
- Dev: `dart format` on changed files, `flutter analyze` (no new errors/warnings), `flutter test`, `flutter build apk --debug`, content `build_all.js` + `validate.dart` (Task 16.1). Install with `adb install -r` (keep data).
- Pregnancy mode, active pregnancy at week 17: Hôm nay shows "Mốc khám tiếp theo" below "Việc tuần này" with the 16-18 triple-test milestone, its date range, "Đến lúc rồi", "Thêm vào lịch hẹn" and "Xem lịch khám"; the vaccine line says 2 vaccines (cúm, uốn ván). Tap "Thêm vào lịch hẹn" -> AddAppointmentScreen with the milestone title, today's date (window already open) and 08:00; save with a reminder -> the appointment appears in UpcomingAppointmentsCard and the Lịch hẹn tab, and the reminder notification fires as before.
- "Xem lịch khám" opens the Lịch khám thai guide: 6-8 and 11-13 show "Đã qua" with no add button; 16-18 shows "Đến lúc rồi"; 20-22 onwards show "Sắp tới · còn N ngày" with dates that match the due date (week 20 starts on due date - 140 days). Tap "Thêm vào lịch hẹn" on 20-22 -> the date is prefilled to the window start (a future date), not today.
- Mark 6-8 done -> the date picker only allows dates from the LMP to today; pick a date -> "Đã khám dd/MM/yyyy"; "Bỏ đánh dấu" reverts it. Mark 16-18 done -> back on Hôm nay the card shows 20-22. Force-stop and reopen -> done states are kept.
- Cẩm nang > Tiêm phòng khi đang mang thai: 4 vaccine items, each with "Theo chỉ định của bác sĩ"; at week 17 cúm and uốn ván show "Đến lúc rồi", Tdap and RSV "Sắp tới"; RSV has no add button; the checklist shows only 2 items (sổ tiêm chủng, người thân). Mark cúm done with a date -> "Đã tiêm dd/MM/yyyy" and the Hôm nay vaccine count drops to 1.
- Edit the due date so the pregnancy is at week 30 -> statuses, dates and the Hôm nay card update without a restart (Tdap and uốn ván due; the 30-32 growth scan is next). Set it so the pregnancy is past week 41 -> no milestone offers adding an appointment, and the card is hidden if nothing is due.
- Settings > delete all data -> after re-onboarding with a new pregnancy, no milestone or vaccine is marked done.
- No active pregnancy -> guides render without status controls and Hôm nay shows the setup prompt. Pre-pregnancy mode: `pre_vaccination` and PrePregnancyHomeScreen are unchanged.
- Light and dark mode are readable (status chips, done labels); no overflow at phone width; logcat has no Flutter exceptions.

### Results (round 1)
- 16.1 Result: done. Only `content_source/build/guides_pregnant.js` was edited. `pregnant_vaccination` now has 4 timeline items: `tl_vax_flu` 0-40, `tl_vax_tetanus` 16-36, `tl_vax_tdap` 27-36 and `tl_vax_rsv` 32-36 (`none`). Each says "theo chỉ định của bác sĩ / nhân viên y tế" and stays draft. 2 checklist items remain (`chk_preg_vax_record`, `chk_preg_vax_family`). `node content_source/build/build_all.js` completed. `dart run content_source/validate.dart` printed "guides: 21 articles, 132 checklist/timeline items" and "OK: all content files valid." `pregnant_vaccination.json` is the only content JSON that changed.
- 16.2 Result: done. `lib/core/models/milestone_schedule.dart` is pure: it uses raw days with no clamp, skips items without a week, and sorts by start then end. `next()` returns the earliest-ending item due now, else the earliest upcoming one. `canAddAppointment` is true only for addAppointment items that are upcoming or due now. Boundary, done-override, 36-36 span and due-date-shift tests pass.
- 16.3 Result: done. `lib/core/services/milestone_progress_service.dart` stores `milestone_done_dates` (`AppConstants.milestoneDoneKey`) with strict date parsing; corrupt JSON, overflowing dates and non-strings are ignored. It adds `milestoneProgressProvider` (`ready`, `markDone`, `unmark`, `resetLocal`). Delete-all removes the key and calls `resetLocal()`. This is unit-tested; delete-all was not run on the device, to keep the user's data. On the device, done states survived a force-stop.
- 16.4 Result: done. `ContentPackService.guideById` and `debugGuides` added. `GuideDetailScreen` timeline tiles show the date range and a status chip, built in the shared `lib/features/guides/widgets/milestone_status_chip.dart`; contrast is tested at 4.5:1 or more in light and dark. Vaccination tiles show "Theo chỉ định của bác sĩ". The add button appears only when `canAddAppointment`. Mark-done uses a date picker limited to LMP..today, and "Bỏ đánh dấu" undoes it. Without a pregnancy, and for pre-pregnancy guides, tiles render as before. Verified on the device.
- 16.5 Result: done. `lib/features/home/widgets/next_milestone_card.dart` sits after `WeekTodoCard`. On the device at week 17 it showed the triple test, "Đến lúc rồi" and a 2-vaccine line. After the triple test was marked done it moved to 20-22 "Sắp tới · còn 20 ngày". The vaccine count dropped to 1 after cúm was marked done. At week 30 it showed the growth scan. After week 41 it was hidden with no gap. No overflow at 360 dp.
- 16.6 Result: done. `test/milestone_schedule_test.dart` adds 28 tests, and the suite passes 134/134. `flutter analyze` reports 0 errors and 0 warnings (16 infos, all pre-existing). `flutter build apk --debug` passed.

### Test round 1 (2026-10-29)
- Dev: 16.1-16.6 are implemented. `flutter test` passed 134 tests, `flutter analyze` reported 0 errors and 0 warnings, and `flutter build apk --debug` passed. The content build and validate passed. Nothing was committed.
- Tester: installed the APK on emulator-5554 with `adb install -r` (data kept, week 17, pregnancy mode). Every test-plan step passed:
  - Card content and placement.
  - Prefill: today, 08:00. The appointment saved and its alarm is scheduled; the notification firing was not observed.
  - Guide statuses, dates (week 20 = due date - 140 days = 18/11/2026) and the year-crossing range.
  - The 20-22 prefill is the window start.
  - Date picker limits, mark and unmark, and persistence after a force-stop and a mode switch.
  - Vaccination guide: 4 items with the doctor label, RSV has no add button, 2 checklist items, the cúm done label and the count dropping to 1.
  - Live due-date edits at week 30 and after week 41 (card hidden).
  - Pre-pregnancy mode unchanged; light and dark mode readable; no overflow at 360 dp; logcat clean.
  Delete-all and "no active pregnancy" were covered by unit and widget tests, not on the device. The device state was restored.
- Rejected P16-R1-01 (minor): the "Lịch hẹn sắp tới" card on Hôm nay does not refresh after an appointment is added or deleted until restart. This is not caused by Phase 16. `UpcomingAppointmentsCard` is a `StatelessWidget` with no listener, and `home_screen.dart` already built it as `const UpcomingAppointmentsCard()` in HEAD. The Phase 16 acceptance criteria do not cover it, and the appointment does appear in the Lịch hẹn tab. Moved to Known issues.
- Accepted issues: none.
- Verdict: pass. Phase 16 completed.

## Phase 17: Pre-Pregnancy Hôm nay Hub (A1-A4)
Status: Completed
Scope: FEATURE_BRAINSTORM.md A1-A4, activated by the user (Phases 14-21). Pre-pregnancy mode `PrePregnancyHomeScreen` only: add a "Sẵn sàng mang thai" readiness card (A2, built from the `pre` guide checklists that A1 already ships in Cẩm nang), a late-period card (A3), an early-signs entry (A3, `pre_early_signs`) and a "Tôi đã có thai" switch (A4). Pregnancy-mode `HomeScreen`, the Cẩm nang grid, `GuideDetailScreen` and the Settings mode switch stay as they are. No content change: the 8 `pre_*` guides are used as shipped; do not hand-edit `assets/content/**`. No new packages, no new prefs key, no notifications; no analytics/AI/backend. Wording is neutral and non-diagnostic: the app never says the user is or is not pregnant.
Grounding (verified 2026-10-29): `assets/content/guides/` has 8 stage `pre` guides, all `draft_requires_medical_review`, none with a timeline: `pre_health` (7 checklist items), `pre_micronutrients` (5), `pre_vaccination` (8), `pre_mental` (4), `pre_finance` (5), `pre_lifestyle` (6), `pre_partner` (5), `pre_early_signs` (category `signs`, 3: `chk_pre_signs_track`, `chk_pre_signs_test`, `chk_pre_signs_book`), 43 items in total. `GuideArticle.tracksProgress` / `progress(ticked)` exist; ticks live in `guideChecklistProvider` (`guide_checklist_ticks`) and are already cleared by delete-all. `ContentPackService.guides`, `guideById(id)` and `debugGuides` exist. `GuidesScreen.stageForMode` already shows the `pre` guides in Cẩm nang for pre-pregnancy mode (A1 hub, Phase 13). `HealthService.predictNextPeriod(cycles, today:)` rolls forward by whole cycles so it is **never in the past**; it cannot tell how late a period is. `calculateAverageCycleLength` defaults to 28; `cycleRegularity` returns `insufficientData` below 3 cycles. `PrePregnancyHomeScreen` calls `DatabaseService.getAllMenstrualCycles()` directly (throws when the Hive box is not open, so widget tests have no Hive), shows greeting, `EmergencyEntryCard`, `_FertileWindowWidget`, `_OvulationCountdownWidget` (with a "Kỳ kinh tiếp theo" line from the rolled-forward prediction), `_DailyTipsWidget`, quick actions. `AppModeNotifier.setMode` persists `app_mode`. `PregnancySetupScreen` sets `AppMode.pregnancy` only in `_savePregnancy` and then `pushReplacement(MainNavigation)`; its "Bỏ qua lúc này" also `pushReplacement(MainNavigation)`; back with unsaved data asks "Bỏ thay đổi?". `SettingsScreen` mode switch: confirm dialog, `setMode`, opens setup only when `DatabaseService.getActivePregnancy()` is null. `navigationIndexProvider` holds the selected tab.

### Task 17.1: Readiness Aggregation (pure logic)
- New `lib/core/models/pre_readiness.dart`: `PreReadiness.compute(List<GuideArticle> guides, Set<String> ticked)` uses guides with `stage == GuideStage.pre && tracksProgress`, sorted by `order`, and returns `done`, `total`, `percent` (int, `(done * 100 / total).round()`, 0 when total is 0), `isEmpty` (total == 0), `isDraft` (any guide is draft) and per-guide `entries` (`guide`, `done`, `total`). Ticks for ids that are not in a `pre` checklist (pregnant guides, removed ids) are ignored.
- `nextUp` (or a helper) returns up to 3 entries that are not complete, ordered by `order`.
- Acceptance: unit tests: fixture with 2 pre guides (3 + 2 items) and 1 pregnant guide: no ticks -> 0/5, 0%; 1 tick -> 1/5, 20%; a tick on a pregnant item does not count; all ticked -> 100% and `nextUp` is empty; no pre guides -> `isEmpty`, 0%, no division by zero. Bundled content: 8 pre guides, total 43, and all checklist ids are unique.

### Task 17.2: Late-Period Calculation (pure logic)
- Add `HealthService.expectedPeriodDate(cycles)` = date-only (last recorded start + `calculateAverageCycleLength`), with no roll-forward (null when there are no cycles), and `HealthService.daysLate(cycles, {DateTime? today})` = days from that date to today when > 0, otherwise 0 (0 when there are no cycles). Use the existing `_dateOnly` / `_daysBetween` (DST-safe). `predictNextPeriod` is unchanged.
- Add a "stale data" rule: when `daysLate > 2 * averageLength` (e.g. more than 56 days on a 28-day cycle), the card asks the user to update their cycle data instead of showing the late-period message.
- Acceptance: unit tests with a fixed `today`: last start 1/10 with a 28-day average -> expected 29/10; on 29/10 `daysLate` is 0, on 30/10 it is 1, on 3/11 it is 5; a future last start -> 0; unsorted input gives the same result; one cycle uses the 28-day default; the stale threshold boundary (56 -> late, 57 -> stale on 28 days); `predictNextPeriod` results are unchanged (existing tests pass).

### Task 17.3: "Sẵn sàng mang thai" Card
- New `lib/features/home/widgets/pre_readiness_card.dart` (`ConsumerWidget`, optional `guides` override for tests, defaults to `ContentPackService.guides`). It watches `guideChecklistProvider`, so ticks made in Cẩm nang update it right away.
- Content: title "Sẵn sàng mang thai", a `LinearProgressIndicator`, "X/Y việc · Z%", and up to 3 `nextUp` rows (guide title + "a/b"), each opening `GuideDetailScreen(guide: ...)`. A "Xem tất cả" button switches to the Cẩm nang tab (`navigationIndexProvider` = 2). At 100% it shows a short neutral message ("Bạn đã hoàn thành danh sách chuẩn bị") and no rows. Reuse `DraftContentNote` when `isDraft`.
- Hidden (`SizedBox.shrink`) when `isEmpty`. No overflow at 360 dp; readable in light and dark mode.
- Acceptance: widget test with fixture guides: shows "0/5 việc · 0%" and 2 rows; toggling a tick through `guideChecklistProvider` updates the text to "1/5 việc · 20%" without a rebuild of the parent; tapping a row pushes `GuideDetailScreen` for that guide; tapping "Xem tất cả" sets `navigationIndexProvider` to 2; with no pre guides the card is not shown and no exception is thrown.

### Task 17.4: Late-Period Card and Early-Signs Entry
- New `lib/features/home/widgets/late_period_card.dart`, built from the cycles list and `today` passed in (pure inputs, testable without Hive). Shown only when cycles exist and `daysLate >= 1`:
  - not stale: "Trễ kinh X ngày → có thể thử thai", the line "Kỳ kinh dự kiến: dd/MM/yyyy (theo chu kỳ trung bình N ngày)", and a neutral note "Đây chỉ là ước tính từ dữ liệu bạn ghi. Chu kỳ có thể thay đổi; nếu chưa chắc, hãy hỏi bác sĩ." When `cycleRegularity` is `irregular` or `insufficientData` add "Chu kỳ chưa đều hoặc chưa đủ dữ liệu nên ước tính kém chính xác hơn." Buttons: "Xem dấu hiệu & cách thử thai" (opens `pre_early_signs` via `guideById`, hidden when the guide is missing), "Tôi đã có thai" (Task 17.5) and "Ghi kỳ kinh mới" (opens the fertility planner like `onAddPeriod`).
  - stale: "Đã lâu bạn chưa ghi kỳ kinh mới" with "Ghi kỳ kinh mới"; no late-period text.
- Never shows "null", negative days, or wording such as "bạn đã có thai" / "bạn không có thai".
- While the late-period card is shown (not stale), `_OvulationCountdownWidget` hides its "Kỳ kinh tiếp theo" line (pass `nextPeriod: null`), so the screen does not show a rolled-forward date next to "Trễ kinh".
- New early-signs entry card (in the same file or `early_signs_entry_card.dart`): always visible when `pre_early_signs` exists, title "Dấu hiệu mang thai sớm", the guide summary, tap -> `GuideDetailScreen(pre_early_signs)`. Hidden when the guide is missing.
- Acceptance: widget tests with a fixed `today`: last start 30 days ago on a 28-day average -> "Trễ kinh 2 ngày → có thể thử thai" and the expected date; 1 cycle -> the irregular/insufficient note is shown; not late -> card hidden; no cycles -> card hidden; stale (70 days) -> the update prompt, no "Trễ kinh"; "Xem dấu hiệu & cách thử thai" opens the guide; with no `pre_early_signs` the button and entry card are hidden and nothing throws.

### Task 17.5: "Tôi đã có thai" Switch
- New `lib/features/home/widgets/pregnant_switch_card.dart` (a card at the bottom of `PrePregnancyHomeScreen`, plus the same action used by the button in the late-period card), sharing one function e.g. `confirmAndSwitchToPregnancy(BuildContext, WidgetRef)`.
- Flow: confirm dialog "Chuyển sang chế độ mang thai?" with text that cycle data and ticks are kept, buttons "Hủy" / "Tiếp tục". Cancel or dismiss -> nothing changes (mode stays pre-pregnancy, no navigation).
  - No active pregnancy (`DatabaseService.getActivePregnancy()`, guarded with try/catch): push `PregnancySetupScreen(fromModeSwitch: true)`; the mode is **not** changed before saving. In setup, saving sets `AppMode.pregnancy` (existing code), resets `navigationIndexProvider` to 0 and returns to a single `MainNavigation` (`pushAndRemoveUntil`, so no old MainNavigation stays under it). Back (including the "Bỏ thay đổi?" dialog) and "Bỏ qua lúc này" just pop when `fromModeSwitch` is true, so the user is back on pre-pregnancy Hôm nay with mode unchanged.
  - Active pregnancy exists (the user switched back earlier): call `setMode(AppMode.pregnancy)`, set `navigationIndexProvider` to 0 and show the snackbar "Đã chuyển sang chế độ Đang mang thai" (same as Settings); no new pregnancy is created.
- `PregnancySetupScreen()` without the flag behaves exactly as today (onboarding, Settings, `NavigationHelper.toPregnancySetup`).
- Acceptance: widget tests (SharedPreferences mock, no Hive): tapping "Tôi đã có thai" then "Hủy" leaves `appModeProvider` at `prePregnancy` and pushes nothing; "Tiếp tục" with no pregnancy pushes `PregnancySetupScreen` while the mode is still `prePregnancy`; in setup with `fromModeSwitch: true`, "Bỏ qua lúc này" pops back and the mode is still `prePregnancy`; the existing onboarding/setup tests still pass.

### Task 17.6: Wire Into PrePregnancyHomeScreen
- Order: greeting, `EmergencyEntryCard`, late-period card (when shown), "Sẵn sàng mang thai" card, `_FertileWindowWidget`, `_OvulationCountdownWidget`, early-signs entry, `_DailyTipsWidget`, quick actions, "Tôi đã có thai" card. Existing widgets keep their content; no other layout rewrite.
- Guard `_loadCycles` (`getAllMenstrualCycles` in try/catch -> empty list) so the screen builds in widget tests without Hive; the existing box listener keeps updating the late-period card after a period is added.
- Acceptance: widget test: `PrePregnancyHomeScreen` in a `ProviderScope` with `debugGuides` fixtures builds without exceptions at 360 dp and shows "Sẵn sàng mang thai", "Dấu hiệu mang thai sớm" and "Tôi đã có thai"; no late-period card without cycles.

### Task 17.7: Tests
- Unit: new `test/pre_pregnancy_test.dart` with Task 17.1 and 17.2 cases (fixtures in the test or under `test/fixtures/content/`), including the bundled-content totals.
- Widget: the Task 17.3-17.6 cases; new cards are checked for overflow at 360 dp.
- All existing tests still pass (`flutter test`), including `core_logic_test.dart` cycle predictions and `widget_test.dart` mode selection/navigation.

### Verification and On-Device Test Plan (tester)
- Dev: `dart format` on changed files, `flutter analyze` (no new errors/warnings), `flutter test`, `flutter build apk --debug`. No content build needed (no generator change). Install with `adb install -r` (keep data); record the device's current mode and data and restore them at the end.
- Pre-pregnancy mode (Settings > chế độ, or fresh onboarding "Chuẩn bị mang thai"), no cycles: Hôm nay shows "Sẵn sàng mang thai" with "0/43 việc · 0%" (or the current ticks), up to 3 guide rows, the early-signs card and the "Tôi đã có thai" card; no late-period card; no "null"; no overflow.
- Tap a readiness row -> that guide opens; tick 2 items, go back -> the count and % went up at once. "Xem tất cả" -> Cẩm nang tab with the pre guides. Untick -> the count goes back down. Force-stop and reopen -> the same %.
- Chu kỳ tab: add one period that started 30 days ago -> back on Hôm nay "Trễ kinh 2 ngày → có thể thử thai", the expected date (start + 28), the estimate note and the irregular/insufficient-data note; the ovulation card no longer shows "Kỳ kinh tiếp theo". "Xem dấu hiệu & cách thử thai" opens "Dấu hiệu mang thai sớm và khi nào nên thử thai".
- Add a period that started today -> the late-period card disappears and "Kỳ kinh tiếp theo" is back. Set up data whose last period started 70 days ago (only that cycle) -> the card shows "Đã lâu bạn chưa ghi kỳ kinh mới" instead. Delete the test cycles afterwards.
- "Tôi đã có thai" -> confirm dialog; "Hủy" -> still pre-pregnancy Hôm nay (Chu kỳ tab label still "Chu kỳ"). Again -> "Tiếp tục" -> Thiết lập thai kỳ; press back (and "Bỏ thay đổi" if data was entered) -> back on pre-pregnancy Hôm nay, mode unchanged; "Bỏ qua lúc này" -> the same. Again -> fill in a due date and "Tiếp tục" -> pregnancy-mode Hôm nay (tab "Tuần thai", day card for the new pregnancy); system back does not return to the old pre-pregnancy screen. Force-stop and reopen -> still pregnancy mode.
- With an existing active pregnancy, switch to pre-pregnancy in Settings, then tap "Tôi đã có thai" -> "Tiếp tục" switches straight to pregnancy mode with the snackbar and the old pregnancy data; no setup screen.
- Pregnancy-mode Hôm nay, Cẩm nang and Settings mode switch behave as before. Light and dark mode readable; logcat has no Flutter exceptions.

### Results (round 1)
- 17.1 Result: done. `lib/core/models/pre_readiness.dart` (`PreReadiness.compute`: done/total/percent/ratio/isEmpty/isComplete/isDraft/entries/nextUp). Unit tests pass, including the bundled check (8 pre guides, 43 items, unique ids). On device the count went 0/43 -> 2/43 · 5% -> 1/43 · 2%.
- 17.2 Result: done. Added `HealthService.expectedPeriodDate`, `daysLate` and `isCycleDataStale`; `predictNextPeriod` is unchanged. PM clarification of the spec: data is stale when more than 2 x the average cycle length has passed since the last recorded start (the same as `daysLate > avg`), not literally `daysLate > 2 * avg`. This matches the 70-day stale case. On a 28-day average, 56 days since the start still shows the late card and 57 shows the stale prompt. On device, 30 days showed "Trễ kinh 2 ngày" and 70 days showed the stale prompt.
- 17.3 Result: done. `pre_readiness_card.dart`. Verified on device: live updates, row navigation, "Xem tất cả" -> Cẩm nang, and the % surviving a force-stop.
- 17.4 Result: done. `late_period_card.dart` (`LatePeriodCard`, `EarlySignsEntryCard`). Verified on device: texts, expected date, estimate and insufficient-data notes, guide button, "Ghi kỳ kinh mới", the card hiding after a new period, the stale prompt, and the hidden "Kỳ kinh tiếp theo" line. Follow-up fix: P17-R1-02.
- 17.5 Result: needs fix (P17-R1-01). "Hủy" and the switch with an active pregnancy change the mode correctly. However, `ref` is used after `await setMode`, when the card has already been disposed, so it throws an unhandled exception and the tab reset and snackbar are usually skipped. The setup path with no active pregnancy (`fromModeSwitch`) is covered only by widget tests. It was not run on the device because that would have meant deleting the user's pregnancy data.
- 17.6 Result: done. Card order and the guarded `_loadCycles` verified on device in light and dark mode, with no overflow. Follow-up fix: P17-R1-02.
- 17.7 Result: done. `test/pre_pregnancy_test.dart` (27 tests). The suite passes 161/161, analyze shows 0 errors and 0 warnings, and the debug APK builds.

### Test round 1 (2026-10-29)
- Tester summary: the debug APK was installed with `adb install -r` (data kept) on emulator-5554 and launched. The device state (pregnancy mode, mother An, week 17, dark mode, no cycles) was restored at the end. Every on-device step passed except the "Tôi đã có thai" switch with an active pregnancy, which threw an exception and showed the snackbar in only 1 of 3 attempts. The path with no active pregnancy was not run on the device. Regression checks (pregnancy Hôm nay, Tuần thai, Cẩm nang, Settings mode switch) passed, with no overflow.
- Accepted P17-R1-01 (major): `confirmAndSwitchToPregnancy` (`lib/features/home/widgets/pregnant_switch_card.dart:51-56`) throws 'Cannot use "ref" after the widget was disposed'. `await setMode(...)` rebuilds `MainNavigation` and removes the pre-pregnancy Hôm nay before `ref.read(navigationIndexProvider.notifier)` runs. Fix:
  - After the confirm dialog and the `context.mounted` check, and before any `await`, capture `final modeNotifier = ref.read(appModeProvider.notifier);`, `final navIndex = ref.read(navigationIndexProvider.notifier);` and `final messenger = ScaffoldMessenger.maybeOf(context);`. The root messenger from `MaterialApp` survives the rebuild.
  - Then set `navIndex.state = 0`, `await modeNotifier.setMode(AppMode.pregnancy)` and show the snackbar through the captured `messenger`. Do not use `ref` or `context` after the await.
  - Add a widget test that removes the card from the tree when `appModeProvider` changes (a host that builds the card only in pre-pregnancy mode, plus a way to inject an active pregnancy, e.g. an optional lookup parameter or a test hook). Assert: no exception, index 0 and the snackbar text.
- Accepted P17-R1-02 (minor): while the late-period card is shown (late or stale), the fertile-window and ovulation cards still show rolled-forward predictions ("11 ngày nữa", fertile window 5/11-11/11, or "Hôm nay" in the stale case). These contradict "có thể thử thai" and "data is too old". PM decision:
  - In `lib/features/home/screens/pre_pregnancy_home_screen.dart`, when `showLatePeriod` is true, do not render `_FertileWindowWidget`, `_OvulationCountdownWidget` or the spacing after them. Both come back as soon as a new period is logged.
  - The `nextPeriod: showLatePeriod ? null : nextPeriod` workaround then becomes redundant and can go.
  - Add a widget test: with one cycle from 30 days ago, the screen shows the late card and neither the fertile-window nor the ovulation card. With a cycle that started today, both are back.
- Note for the round 2 tester: also run the path with no active pregnancy (setup with `fromModeSwitch`: back, "Bỏ qua lúc này", save -> pregnancy mode, system back does not return) if it can be done without losing user data, e.g. on a fresh install in a second AVD. Otherwise record it as covered by widget tests only.
- Verdict: fix.

### Results (round 2)
- 17.1 Result: done (unchanged from round 1). Unit tests pass, including the bundled totals (8 pre guides, 43 items, unique ids).
- 17.2 Result: done (unchanged). `expectedPeriodDate`, `daysLate` and `isCycleDataStale` verified on device: 30 days -> "Trễ kinh 2 ngày" with expected date 27/10/2026; 70 days -> stale prompt.
- 17.3 Result: done (unchanged). On device: "0/43 việc · 0%", 3 rows, draft note.
- 17.4 Result: done. P17-R1-02 fixed: while the late or stale card is shown, `_FertileWindowWidget` and `_OvulationCountdownWidget` are not built (keys `pre-fertile-window-card` / `pre-ovulation-card`); both return after a period is logged today. Verified on device and by new widget tests.
- 17.5 Result: done. P17-R1-01 fixed: `confirmAndSwitchToPregnancy` captures the mode notifier, the `navigationIndexProvider` notifier and the root `ScaffoldMessenger` before the await and does not use `ref`/`context` afterwards. On device the active-pregnancy switch worked 4 of 4 times with the snackbar and no logcat exceptions; "Hủy" changes nothing. The no-active-pregnancy setup path (`fromModeSwitch`: back, "Bỏ qua lúc này", save) is covered by widget tests only; it was not run on the device to avoid deleting the user's pregnancy data.
- 17.6 Result: done. Card order verified on device. `PrePregnancyHomeScreen` gained `@visibleForTesting debugCycles` / `debugToday` for tests; production behaviour is unchanged.
- 17.7 Result: done. `test/pre_pregnancy_test.dart` has 30 tests. The 3 new ones are: the switch while the card is disposed, using a slow-save mode notifier (fails on the old code); the late card hiding the prediction cards; and a period started today bringing them back. Suite 164/164 passes, analyze 0 errors/0 warnings, debug APK builds. The "period started today" screen test runs at 480 dp because the old prediction-card rows overflow with the test font at 360 dp (see Known issues). The new cards are checked at 360 dp.

### Test round 2 (2026-10-29)
- Tester summary: QA re-ran `flutter test` (164/164 pass). The debug APK, newer than the last source edits, was installed on emulator-5554 with `adb install -r` (data kept) and launched. P17-R1-01 and P17-R1-02 are fixed on device. These all passed: the late, stale and new-period cases, the no-cycle readiness view, card order, cleanup of test cycles, persistence after force-stop, and the regression checks (pregnancy Hôm nay, Tuần thai, Cẩm nang, Settings mode switch, dark mode). Logcat showed no Flutter exceptions or overflow for the whole session. The device was restored to pregnancy mode, dark mode and no test cycles.
- Issues filed: none. Accepted: none. Rejected: none.
- Tester notes not filed as defects, moved to Known issues: the old fertile-window date row and the "Kỳ kinh tiếp theo" row overflow at 360 dp with the test font (not seen on device), and the English splash subtitle "Your Pregnancy Companion". The English Chu kỳ calendar labels are already listed.
- Verdict: pass. Phase 17 completed.

## Phase 18: "Bầu ăn được không?" Food Lookup + Weekly Nutrition Focus (B6)
Status: Completed
Scope: FEATURE_BRAINSTORM.md B6, activated by the user (Phases 14-21). Add an offline food lookup built from `assets/content/foods.json` (CONTENT_SCHEMA §5): search on `name` + `aliases` that ignores Vietnamese diacritics, verdict chips (Nên ăn / Hạn chế / Tránh), group chips, and a detail sheet (reason, tip, sources, draft note). Entry points: a new tab in Công cụ > Dinh dưỡng (`NutritionScreen`) and an entry card at the top of Cẩm nang (`GuidesScreen`). Show the current week's `nutritionFocus` from `weeks_v2.json` at the top of the Dinh dưỡng "Hướng dẫn" tab. The trimester filter bug listed under B6 was already fixed in Phase 12 (Task 12.3). The existing Hướng dẫn / Công thức tabs, `NutritionFilter`, `NutritionSeedService` and the Hive nutrition data stay as they are. No content change: do not hand-edit `assets/content/**` (if content needs a fix, change `content_source/build/*.js`, run `node content_source/build/build_all.js` and `dart run content_source/validate.dart`). No new packages, prefs keys, Hive boxes or notifications; no analytics/AI/backend. Wording stays neutral and refers the user to the doctor; the app gives no personal diet prescriptions.
Grounding (verified 2026-10-29): `assets/content/foods.json` has `version` 1, `lastUpdated` 2026-10-29, file-level `reviewStatus` `draft_requires_medical_review` (no per-item `reviewStatus`) and 198 foods with unique ids. Verdicts: `ok` 103, `limit` 64, `avoid` 31. Groups (no enum; see `content_source/CONTENT_NOTES.md`): `vegetable` 27, `fruit` 28, `meat` 20, `seafood` 27, `egg` 6, `dairy` 9, `grain` 9, `legume_nut` 9, `drink` 19, `dish` 19, `herb_spice` 10, `sweet` 6, `supplement` 9. Every item has `reason` and `tip`; 57 items have an empty `sources` list. The source ids used (`VN-NIN`, `NHS-FOODS`, `CDC-FOOD-PREG`, `WHO-ANC`, `FDA-FISH`) all exist in `sources.json`. Names and aliases contain `đ`/`Đ` (e.g. "Đậu bắp", "Bí đỏ"), so normalisation must map `đ` -> `d` as well as strip tone marks. `pubspec.yaml` already bundles `assets/content/`. `ContentPackService.init()` loads sources, guides, `weeks_v2` and the daily packs; it has no foods loader yet. `ContentPackService.weekDetail(week)` / `resolveWeekDetail` return a `WeekDetail` with `nutritionFocus` (`List<String>`) and `reviewStatus`; `weeks_v2.json` has weeks 0-42 (draft), all with a non-empty `nutritionFocus`. `PregnancyModel.currentWeekAt(now)` returns 0-42; the active pregnancy comes from `DatabaseService.getActivePregnancy()` (Hive; throws in widget tests without Hive). `NutritionScreen({initialTab, showAppBar})` has a 2-tab `TabController` (Hướng dẫn, Công thức) and is embedded in `_ToolsTabScreen` (`main_navigation.dart`, `showAppBar: false`) and pushed by `NavigationHelper` with `initialTab`. `GuidesScreen` (Cẩm nang tab, index 2) has an optional `guides` override and lists guides by category. Reusable: `DraftContentNote`, `SourceMetadataCard.custom(sourceNames:, lastUpdated:, note:)`, `GuideDetailScreen.sourceNames(ids, sources)`, `ContentPackService.sources`. There is no Vietnamese diacritics helper in `lib/` yet.

### Task 18.1: Food Model and Parser (pure logic)
- New `lib/core/models/food_model.dart`: `FoodVerdict { ok, limit, avoid }` with labels "Nên ăn" / "Hạn chế" / "Tránh" and one colour per verdict (green / amber / red, readable in dark mode); `FoodItem` (`id`, `name`, `aliases`, `group`, `verdict`, `reason`, `tip`, `sources`); `FoodPack` (`version`, `lastUpdated`, `reviewStatus` via `GuideEnums.reviewFromJson`, `foods`, `isDraft`, `const FoodPack.empty()`).
- Group labels live in one map (unknown group -> "Khác"): vegetable "Rau củ", fruit "Trái cây", meat "Thịt", seafood "Hải sản", egg "Trứng", dairy "Sữa & chế phẩm", grain "Ngũ cốc", legume_nut "Đậu & hạt", drink "Đồ uống", dish "Món ăn", herb_spice "Gia vị & thảo mộc", sweet "Đồ ngọt", supplement "Thực phẩm bổ sung".
- New `lib/core/data/food_content_parser.dart`: `parseFoods(String rawJson)` and `loadFoods(AssetBundle)`. It never throws: a missing or invalid file gives `FoodPack.empty()` and is logged with `AppLogger`. Items with an empty id or name, or an unknown `verdict`, are skipped; for duplicate ids the first is kept; missing `aliases`/`sources` become empty lists; a missing `tip` becomes an empty string.
- `ContentPackService`: add `foodsAssetPath`, `static FoodPack get foodPack` and `@visibleForTesting set debugFoodPack`, and load the pack in `init()` (same pattern as the daily packs).
- Acceptance: unit tests: a fixture with 1 valid item per verdict parses with all fields; an unknown verdict, an empty name and a duplicate id are skipped; invalid JSON and a missing `foods` key return an empty pack without throwing. The bundled `foods.json` (read from disk) parses to 198 items with unique ids and verdict counts 103/64/31; every group has a label (no "Khác"); every source id exists in `sources.json`.

### Task 18.2: Vietnamese Search and Filters (pure logic)
- New `lib/core/utils/vietnamese_text.dart`: `normalizeVi(String)` lowercases, strips all Vietnamese tone and vowel marks (à á ả ã ạ, ă ằ ắ ẳ ẵ ặ, â ..., ê ..., ô ..., ơ ..., ư ..., ỳ ý ỷ ỹ ỵ, upper and lower case), maps `đ`/`Đ` -> `d`, collapses whitespace and trims. No new package.
- New `lib/core/utils/food_filter.dart`: `FoodFilter.apply(List<FoodItem>, {String query, FoodVerdict? verdict, String? group})`. The query matches when the normalised query is a substring of the normalised `name` or of any alias; a blank query matches everything. Verdict and group filters combine with AND. Order: items whose name or an alias starts with the query come first, then other matches; within each part, sort by normalised name, ties by `id`, so results are stable. `FoodFilter.groupsIn(items)` returns the groups present, in label-map order.
- Acceptance: unit tests: `normalizeVi('Đậu Bắp')` == `'dau bap'`; `normalizeVi('  Rau   NGÓT ')` == `'rau ngot'`; the queries "rau ngot", "RAU NGÓT" and "bo ngot" (alias "bồ ngót") all find `rau_ngot`; "dau bap" finds "Đậu bắp"; verdict `avoid` + group `meat` returns only avoid meat items; a blank query with no filters returns all items; a query with no match returns an empty list; a prefix match is listed before a contains match. On bundled content: "pa te" finds "Pa tê", and the 3 verdict filters together cover all 198 items with no overlap.

### Task 18.3: Food Lookup Screen and Detail Sheet
- New `lib/features/nutrition/screens/food_lookup_screen.dart`: `FoodLookupScreen({showAppBar = true, FoodPack? pack, Map<String, ContentSource>? sources})` (overrides for tests; defaults are `ContentPackService.foodPack` / `.sources`). Title "Bầu ăn được không?".
  - A search `TextField` (hint "Tìm món ăn, thực phẩm...", with a clear button when not empty), a verdict chip row ("Tất cả", "Nên ăn", "Hạn chế", "Tránh") and a horizontally scrollable group chip row ("Tất cả nhóm" + groups from `FoodFilter.groupsIn`). Tapping a selected chip again resets that row to "Tất cả". A count line "N kết quả". `DraftContentNote` when the pack is draft.
  - Each row shows the name, the aliases (if any, one line with ellipsis), the group label and a verdict badge (colour plus text, never colour alone).
  - No results: "Chưa có thông tin về món này. Hãy hỏi bác sĩ hoặc chuyên gia dinh dưỡng." Empty pack (file missing): "Chưa có dữ liệu thực phẩm", with no exception.
  - Tapping a row opens `showModalBottomSheet` (`isScrollControlled`, scrollable) with `FoodDetailSheet`: name, aliases, verdict badge, group, "Vì sao" (reason), "Lời khuyên" (tip, hidden when empty), sources via `SourceMetadataCard.custom` (names from `GuideDetailScreen.sourceNames`, `lastUpdated` from the pack), `DraftContentNote` when draft, and the note "Thông tin mang tính tham khảo, không thay thế tư vấn của bác sĩ hoặc nhân viên y tế." When the item has no sources, show "Nguồn: tổng hợp, đang chờ bác sĩ duyệt" instead of an empty source list. For `avoid` and `limit` items also show "Nếu đã lỡ ăn và thấy bất thường, hãy liên hệ bác sĩ."
  - The search text and chips are screen state only (not saved). No overflow at 360 dp; it works with the keyboard open; it is readable in light and dark mode.
- Acceptance: widget tests with a fixture pack (5-6 items, 2 groups, all 3 verdicts) and fixture sources: all items are listed with "N kết quả"; typing "dau bap" (no marks) shows only "Đậu bắp"; typing an alias finds its item; tapping "Tránh" shows only avoid items and tapping it again shows all; a group chip and a verdict chip combine; the no-match text is shown; tapping a row opens the sheet with reason, tip, the source organisation name and the draft note; an item with no sources shows the fallback source line; an empty pack shows "Chưa có dữ liệu thực phẩm" without exceptions; no overflow at 360x640.

### Task 18.4: Weekly Nutrition Focus Card
- New `lib/features/nutrition/widgets/weekly_nutrition_focus_card.dart`: `WeeklyNutritionFocusCard({int? week, Map<int, WeekDetail>? details})` shows "Dinh dưỡng tuần X" and the week's `nutritionFocus` as bullet lines, plus a compact `DraftContentNote` when the week is draft. Week 0 is titled "Dinh dưỡng khi chuẩn bị mang thai". Hidden (`SizedBox.shrink`) when `week` is null or the focus list is empty. Details default to `ContentPackService.weekDetails` through `resolveWeekDetail`.
- The week is resolved in `NutritionScreen`, not in the card: pregnancy mode -> the active pregnancy's `currentWeekAt(DateTime.now())` (`DatabaseService.getActivePregnancy()` in try/catch -> null); pre-pregnancy mode (`appModeProvider`) -> week 0; pregnancy mode with no active pregnancy -> no card. Add a `@visibleForTesting` week override so widget tests do not need Hive.
- The card sits at the top of the "Hướng dẫn" tab, above the category chips, inside the scrollable area so it does not squeeze the list on small screens. The week is re-read when the tab rebuilds (e.g. after the pregnancy is edited); no new provider is needed.
- Acceptance: widget tests: week 12 with fixture details shows "Dinh dưỡng tuần 12" and both fixture focus lines; week 0 shows the pre-pregnancy title; `week: null` and an empty focus list hide the card; draft details show the draft note. Unit test: in the bundled `weeks_v2.json`, every week 0-42 has at least one focus line.

### Task 18.5: Entry Points (Công cụ > Dinh dưỡng and Cẩm nang)
- `NutritionScreen`: `TabController` length 3 with tabs "Hướng dẫn", "Công thức", "Ăn được không?" (icon `Icons.fact_check` or `Icons.search`); the third tab is `FoodLookupScreen(showAppBar: false)`. `initialTab` clamps to 0-2; existing callers with `initialTab` 0/1 keep working. Labels must fit at 360 dp (use `isScrollable` only if they do not).
- `GuidesScreen`: an entry card at the top of the list in both modes (also shown when the guide list is empty), titled "Bầu ăn được không?" with the subtitle "Tra cứu nhanh N thực phẩm, món ăn" (N = pack size). The card is hidden when the pack is empty. Tap -> push `FoodLookupScreen()` with an AppBar and back button. Add an optional `foodPack` override for tests, like `guides`.
- The Hôm nay "Dinh dưỡng" quick action and other existing navigation are unchanged.
- Acceptance: widget tests: `NutritionScreen(showAppBar: false)` shows 3 tabs and tapping "Ăn được không?" shows the search field; `NutritionScreen(initialTab: 2)` opens on the lookup; `GuidesScreen` with fixture guides and a fixture food pack shows the entry card, tapping it pushes `FoodLookupScreen`, and back returns to Cẩm nang; with an empty food pack the card is hidden; existing guides-screen tests still pass.

### Task 18.6: Tests and Verification
- New `test/food_lookup_test.dart` with the unit and widget tests from 18.1-18.5 (inline fixtures; bundled-file checks read `assets/content/*.json` from disk like the existing content tests). `NutritionScreen` tests must not need Hive: guard `DatabaseService.getAllNutrition` / `getAllRecipes` / `NutritionSeedService.ensureSeeded` in try/catch (-> empty list / no-op), or test the lookup through `FoodLookupScreen` and only check the `NutritionScreen` tab bar.
- Run `dart format` on changed files, `flutter analyze` (0 errors / 0 warnings; pre-existing infos only), `flutter test` (all pass: the previous 164 plus the new ones) and `flutter build apk --debug`. Run the content build/validate only if a generator was changed.
- Acceptance: all commands pass and the results are recorded in the Verification Log.

### On-device test plan (emulator-5554, `adb install -r`, data kept)
1. Pregnancy mode with an active pregnancy (e.g. week 17). Công cụ > Dinh dưỡng: three tabs "Hướng dẫn", "Công thức", "Ăn được không?" fit on screen. Hướng dẫn tab: the card "Dinh dưỡng tuần 17" shows the week-17 focus lines from `weeks_v2.json` and the draft note; the category chips and guide list still work below it (trimester chips still return items).
2. "Ăn được không?" tab: 198 items, "198 kết quả", draft note visible. "rau ngot" (no marks) -> "Rau ngót"; "bo ngot" -> "Rau ngót" (alias); "dau bap" -> "Đậu bắp"; "pa te" -> "Pa tê"; "xyzxyz" -> the no-match text with the ask-the-doctor line. The clear button empties the search and the full list returns.
3. Verdict chips: "Tránh" -> 31 results, all with the red "Tránh" badge; "Hạn chế" -> 64; "Nên ăn" -> 103; tapping the selected chip again -> 198. Group "Hải sản" + "Tránh" -> only avoid seafood. Search and chips combine.
4. Tap "Pa tê": the sheet shows the "Tránh" badge, "Vì sao", "Lời khuyên", source organisation names, last updated 2026-10-29, the draft note, the reference disclaimer and the "Nếu đã lỡ ăn..." line. Tap an item with no sources: the fallback source line, no empty list. The sheet scrolls and closes with a swipe or back.
5. With the keyboard open, and with a large system font: no overflow stripes; the list scrolls.
6. Cẩm nang tab: the "Bầu ăn được không?" card at the top with "Tra cứu nhanh 198 thực phẩm, món ăn"; tap -> the lookup screen with an AppBar; back returns to Cẩm nang; guide cards and checklist ticks are unchanged.
7. Settings: switch to pre-pregnancy mode. Công cụ > Dinh dưỡng shows "Dinh dưỡng khi chuẩn bị mang thai" with the week-0 focus lines; the lookup tab works; Cẩm nang shows the entry card above the pre guides. Switch back to pregnancy mode.
8. Change the pregnancy start date in Settings so the week changes; reopen Công cụ > Dinh dưỡng: the card shows the new week.
9. Dark mode: verdict badges, chips, the sheet and the cards are readable.
10. Regression: the Hôm nay "Dinh dưỡng" quick action opens nutrition; the Công thức tab and favourites work; the Tuần thai week detail still shows "Dinh dưỡng trọng tâm"; after force-stop and relaunch there is no crash and logcat has no Flutter exceptions.

Required automated tests: `test/food_lookup_test.dart` (parser; bundled foods schema, counts and source ids; `normalizeVi`; `FoodFilter`; `FoodLookupScreen` and the detail sheet; `WeeklyNutritionFocusCard`; `NutritionScreen` tabs; the `GuidesScreen` entry card). All existing tests still pass.

### Results (round 1)
- 18.1 Result: done. `lib/core/models/food_model.dart` (`FoodVerdict` labels/colours/icons, `FoodItem`, `FoodPack`, `FoodGroups` with 13 labels and a "Khác" fallback) and `lib/core/data/food_content_parser.dart` (never throws; skips invalid items and unknown verdicts; keeps the first duplicate id). `ContentPackService` has `foodsAssetPath`, `foodPack` and `debugFoodPack`, and loads foods in `init()`. Unit tests pass, including the bundled checks: 198 items, 103/64/31, every group labelled, every source id in `sources.json`.
- 18.2 Result: done. `lib/core/utils/vietnamese_text.dart` (`normalizeVi`, precomposed and decomposed input, đ -> d) and `lib/core/utils/food_filter.dart` (`apply` with named query/verdict/group, prefix matches first, stable order; `groupsIn`). On device "rau ngot", "bo ngot", "dau bap", "pa te" and "pho mai mem" all find the right item.
- 18.3 Result: done. `food_lookup_screen.dart`, `food_detail_sheet.dart`, `food_verdict_badge.dart`. On device: 198 results; verdict chips 103/64/31, reset to 198; Hải sản + Tránh; search + chips combine; clear button; no-match text; the Pa tê sheet with every part (date 2026-10-29, disclaimer, "Nếu đã lỡ ăn..."); the no-sources fallback (Atiso); no overflow at font scale 1.5 with the keyboard open; readable in light and dark mode. PM note: the no-match text is "Không tìm thấy thực phẩm phù hợp" plus a line that sends the user to the doctor or a nutritionist, not the planned wording. Accepted as equivalent.
- 18.4 Result: done. `weekly_nutrition_focus_card.dart`. `NutritionScreen` resolves the week (pre-pregnancy 0, pregnancy `currentWeekAt`, guarded) and has `@visibleForTesting focusWeek`. The card is the first scrollable item of the Hướng dẫn list, below the fixed category chips. The dev did this to keep the existing filter layout; accepted. On device: week 17, the week-0 title in pre-pregnancy mode, and week 15 after the due date was edited.
- 18.5 Result: needs fix (P18-R1-01). 3 tabs, `initialTab` clamped, Hive calls guarded. The Cẩm nang entry card works in both modes (198, AppBar, back, guide progress unchanged). However, the tab labels are clipped on device ("Ăn được không" without "?" at 411 dp and scale 1.0; "Hướng dẫ", "Công thứ" and "Ăn được k" at scale 1.5), so "labels fit at 360 dp" is not met.
- 18.6 Result: done. `test/food_lookup_test.dart` (31 tests) + `test/fixtures/content/foods.json`. Suite 195/195 pass, analyze 0 errors/0 warnings (16 pre-existing infos), debug APK builds. Content build/validate not run (generators untouched). The tab overflow test does not catch clipped `Tab` text because clipping raises no exception; see P18-R1-01.

### Test round 1 (2026-10-29)
- Tester summary: QA re-ran `flutter test` (195/195) and `flutter analyze` (0 errors/0 warnings). The up-to-date debug APK was installed on the Pixel 7 emulator with `adb install -r` (data kept) and launched. Every on-device step passed except the tab-label fit. That covers the lookup counts, search, chips, detail sheet, no-sources fallback, font scale 1.5 with the keyboard open, the Cẩm nang card, pre-pregnancy week 0, the week change after a due-date edit, light and dark mode, the Hôm nay quick action, Công thức and favourites, and a force-stop relaunch with clean logcat. Test data was restored: pregnancy mode, due date 07/04/2027, dark mode, font scale 1.0, no favourite left. The Tuần thai week page opened, but the tester did not scroll to the "Dinh dưỡng trọng tâm" section.
- Accepted P18-R1-01 (minor): the `NutritionScreen` tab labels are clipped (`lib/features/nutrition/screens/nutrition_screen.dart:90-97`). Three fixed-width tabs with icon + text do not leave room for the Vietnamese labels. Fix:
  - Keep the labels "Hướng dẫn", "Công thức" and "Ăn được không?" (spec wording). Set `isScrollable: true` and `tabAlignment: TabAlignment.center` on the `TabBar`; Task 18.5 allows this when labels do not fit. Each tab then takes the width of its label, and at large font scales the row scrolls sideways instead of clipping. Make no other visual change.
  - Add a widget test at 360x640, both at the default scale and with `MediaQuery` `textScaler: TextScaler.linear(1.5)`. For each of the 3 labels, find the label `Text` and get its `RenderParagraph`. Assert that `didExceedMaxLines` is false and that `size.width >= getMaxIntrinsicWidth(double.infinity) - 0.5` (the text is not truncated). Also assert that each label's rect lies inside its `Tab` rect. The current "no overflow exception" test is not enough.
  - The `GuidesScreen` card, the lookup screen and the other tab contents stay unchanged.
- Note for the round 2 tester: check that all 3 tab labels are fully visible at font scale 1.0 and 1.5 (sideways scrolling is fine at 1.5). Also scroll the current Tuần thai week page to confirm the "Dinh dưỡng trọng tâm" section still shows; regression step 10 was only partly checked in round 1.
- Rejected: none.
- Verdict: fix.

### Results (round 2)
- 18.1 Result: done (unchanged since round 1; parser and bundled-content unit tests still pass).
- 18.2 Result: done (unchanged; on device "rau ngot", "bo ngot", "dau bap", "pa te" and "xyzxyz" behave correctly).
- 18.3 Result: done (unchanged; on device 198 results, chips 31/64/103 with reset, Hải sản + Tránh = 7, search + chips combine, Pa tê sheet complete, no-sources fallback on Măng tươi, no overflow at font scale 1.5 with the keyboard open, dark mode readable).
- 18.4 Result: done (unchanged; on device "Dinh dưỡng tuần 17" with 2 focus lines and the draft note. Pre-pregnancy week 0 and the week change after a date edit passed in round 1 and were not repeated, since round 2 only touched the TabBar).
- 18.5 Result: done. P18-R1-01 fixed: the `NutritionScreen` `TabBar` has `isScrollable: true` and `tabAlignment: TabAlignment.center` (`nutrition_screen.dart:92-93`). On the Pixel 7, all 3 labels are complete at font scale 1.0. At 1.5 the row scrolls sideways and "Ăn được không?" shows in full. The Cẩm nang entry card (198, AppBar, back) works; the Hôm nay quick action opens the 3-tab screen with the week card.
- 18.6 Result: done. `test/food_lookup_test.dart` now has 33 tests. They include a truncation test at 360x640 at text scales 1.0 and 1.5, which checks `didExceedMaxLines`, intrinsic width and that each label lies inside its Tab. The dev confirmed this test fails without the fix. The existing tab test now calls `ensureVisible` before tapping the third tab. Suite 197/197 pass (re-run by QA), analyze 0 errors/0 warnings (16 pre-existing infos), debug APK builds. Content build/validate not run (generators untouched).

### Test round 2 (2026-10-29)
- Tester summary: QA re-ran `flutter test` (197/197) and `flutter analyze` (0 errors/0 warnings, 16 pre-existing infos). The current debug APK was installed on the Pixel 7 emulator with `adb install -r` (data kept) and launched. P18-R1-01 is verified fixed at font scale 1.0 and 1.5. These all passed again: lookup counts, search, chips, combined filters, the detail sheet, the no-sources fallback, large font with the keyboard open, the Cẩm nang card, the week-17 card, Tuần thai "Dinh dưỡng trọng tâm" (scrolled to and confirmed this round), Công thức, the Hôm nay quick action, dark mode, and a force-stop relaunch with clean logcat. The device was left in pregnancy mode at font scale 1.0, with no test data added.
- Accepted: none.
- Rejected P18-R2-01 (minor): the outer Công cụ tabs ("Dinh dưỡng", "Lịch hẹn", "Cần khám") are clipped at font scale 1.5, and the bottom nav "Cẩm nang" label wraps. This is pre-existing and outside Phase 18. The fixed-width `TabBar` in `_ToolsTabScreen` (`lib/features/home/screens/main_navigation.dart` ~136) has no changes in the working tree. Moved to Known issues.
- Verdict: pass. Phase 18 completed.

## Known issues (pre-existing, backlog)
- Chu kỳ calendar shows an English month header ('October 2026'), format button ('2 weeks') and weekday names; needs a Vietnamese locale/format labels. Found in Phase 14 test round 1 (P14-R1-04).
- `FlutterSecureStorage: Could not decrypt key` is logged at each launch (library startup check); data is unaffected. Found in Phase 14 test round 1.
- The old Tuần thai header rows (`tracking_screen.dart` ~164/210) and `weight_gain_chart.dart:79` overflow with Flutter's wide test font at 390px logical width; this was not seen on device at 1080x2400. Found in the Phase 14 dev round.
- Old Hôm nay widgets (`PregnancyProgressCard` rows ~21/70, `QuickActionsGrid` cards, `UpcomingAppointmentsCard` header) overflow with Flutter's wide test font at 360-390 dp; not seen on device. Phase 15 content widget tests run at 600 dp for this reason. Found in the Phase 15 dev round.
- `MaternalHabitsCard` reminder time picker (`maternal_habits_card.dart:152`) likely has the same keyboard-mode 12h/24h parse issue as P15-R1-02 (typed morning hour saved as PM on 12-hour devices). Found in Phase 15 test round 1.
- ARB keys `dailyTip` / `dailyTipMessage` are unused since Phase 15 (left in place).
- The Hôm nay "Lịch hẹn sắp tới" card (`UpcomingAppointmentsCard`) keeps old content after an appointment is added or deleted, until the app restarts. It is a `StatelessWidget` with no Hive listener, built as `const UpcomingAppointmentsCard()` in `home_screen.dart`, so the `HiveBoxesListener` rebuild skips it. Possible fix: drop the `const` or make the card listen to the appointments box. Found in Phase 16 test round 1 (P16-R1-01).
- On pre-pregnancy Hôm nay, two rows overflow with Flutter's wide test font at 360 dp: the `_FertileWindowWidget` date row and the `_OvulationCountdownWidget` "Kỳ kinh tiếp theo" row (`pre_pregnancy_home_screen.dart`). This was not seen on the 1080-wide device, but it could happen on narrow screens with large text. Found in the Phase 17 round 2 dev round.
- The splash screen subtitle is in English ("Your Pregnancy Companion"). Found in Phase 17 test round 2.
- At font scale 1.5, the outer Công cụ tabs (`_ToolsTabScreen` `TabBar`, `lib/features/home/screens/main_navigation.dart` ~136) are clipped to "Dinh dưỡr" and "Cần khár", and the bottom nav "Cẩm nang" label wraps to two lines. Possible fix: `isScrollable: true` + `tabAlignment: TabAlignment.center`, as in P18-R1-01. Found in Phase 18 test round 2 (P18-R2-01).

## Proposed Phases 19-20 (not active)
Details in `FEATURE_BRAINSTORM.md`. Do not start until the user activates a phase.
- Phase 19: Shopping/hospital bag checklist, documents & benefits, find nearby hospital via Maps, "Nơi khám của tôi".
- Phase 20: P1 tools: kick counter, contraction timer, bump photos, shareable milestone cards, PDF export, 115 button, widget.

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
- Phase 6: `C:\Users\PC\Development\flutter\bin\cache\dart-sdk\bin\dart.exe format ...` passed for changed Phase 6 files.
- Phase 6: `C:\Users\PC\Development\flutter\bin\flutter.bat test` passed.
- Phase 6: `C:\Users\PC\Development\flutter\bin\flutter.bat build apk --debug` passed.
- Phase 6 debug APK output: `build\app\outputs\flutter-apk\app-debug.apk`.
- Phase 7: `C:\Users\PC\Development\flutter\bin\cache\dart-sdk\bin\dart.exe format ...` passed for changed Phase 7 Dart files.
- Phase 7: `C:\Users\PC\Development\flutter\bin\flutter.bat test` passed.
- Phase 7: `C:\Users\PC\Development\flutter\bin\flutter.bat build apk --debug` passed.
- Phase 7 debug APK output: `build\app\outputs\flutter-apk\app-debug.apk`.
- Phase 8: `C:\Users\PC\Development\flutter\bin\cache\dart-sdk\bin\dart.exe format ...` passed for changed Phase 8 test files.
- Phase 8: `C:\Users\PC\Development\flutter\bin\flutter.bat test` passed with 11 tests.
- Phase 8: `C:\Users\PC\Development\flutter\bin\flutter.bat build apk --debug` passed.
- Phase 8 debug APK output: `build\app\outputs\flutter-apk\app-debug.apk`.
- Phase 9-11: `C:\Users\PC\Development\flutter\bin\cache\dart-sdk\bin\dart.exe format ...` passed for changed files.
- Phase 9-11: `C:\Users\PC\Development\flutter\bin\flutter.bat test` passed with 16 tests.
- Phase 9-11: `C:\Users\PC\Development\flutter\bin\flutter.bat build apk --debug` passed.
- Phase 9-11 debug APK output: `build\app\outputs\flutter-apk\app-debug.apk`.
- Feature review (2026-10-28): `flutter test` passed with 16 tests; `flutter build apk --debug` passed.
- Feature review: app installed and run on emulator `Pixel_7` (Android API 36); no Flutter exceptions in logcat for Home/Tracking/Tools/Nutrition/Cycle/Settings flows.
- Feature review: confirmed on emulator that Health Connect sync reports unavailable on API 36 (HealthService.init not called) and nutrition trimester filter chips return an empty list. Findings and roadmap in `FEATURE_REVIEW.md`.
- Phase 12-13: `dart format` passed for changed Dart files.
- Phase 12-13: `flutter analyze`: 0 errors, 0 warnings. 16 infos in `lib` (pre-existing `use_build_context_synchronously` / deprecated `DropdownButtonFormField.value` and `Radio.groupValue` patterns) plus 12 infos in `content_source/validate.dart` (content agent's script, out of dev scope).
- Phase 12-13: `flutter test` passed with 49 tests (incl. bundled guide pack schema check: all 21 guides in `assets/content/guides/index.json` parse).
- Phase 12-13: `flutter build apk --debug` passed.
- Phase 12-13: installed on emulator-5554 with `adb install -r` (data kept); existing encrypted data opened, Home shows week 17 / "Còn 22 tuần 6 ngày" (consistent), 5-tab navigation, Cẩm nang list and guide detail render; no Flutter errors in logcat.
- Phase 14 round 1: `dart format` on changed files; `flutter analyze` 0 errors/0 warnings (16 pre-existing infos); `flutter test` passed with 63 tests (14 new in `test/week_content_test.dart`); `flutter build apk --debug` passed; installed on emulator-5554 with `adb install -r` (data kept), logcat clean. Verdict: fix (P14-R1-01..03 accepted).
- Phase 14 round 2: `dart format` on changed files; `flutter analyze` 0 errors/0 warnings (16 pre-existing infos); `flutter test` passed with 69 tests (re-run by QA); `flutter build apk --debug` passed; installed on emulator-5554 with `adb install -r` (data kept), logcat clean. Verdict: fix (P14-R2-01 accepted).
- Phase 14 round 3: `dart format` on changed files; `flutter analyze` 0 errors/0 warnings (16 pre-existing infos); `flutter test` passed with 70 tests; `flutter build apk --debug` passed; installed on emulator-5554 with `adb install -r` (data kept), logcat clean. Verdict: pass (no issues); Phase 14 completed.
- Phase 15 round 1: `dart format` on changed files; `flutter analyze` 0 errors/0 warnings (16 pre-existing infos); `flutter test` passed with 102 tests (33 new in `test/daily_content_test.dart`); `flutter build apk --debug` passed; installed on Pixel_7 emulator with `adb install -r` (data kept), logcat clean. Content build/validate not run (generators untouched). Verdict: fix (P15-R1-01..03 accepted).
- Phase 15 round 2: `dart format` left changed files unchanged; `flutter analyze` 0 errors/0 warnings (16 pre-existing infos); `flutter test` passed with 106 tests (4 new `TodayThaiGiaoCard` tests); `flutter build apk --debug` passed; installed on emulator-5554 with `adb install -r` (data kept), logcat clean. Content build/validate not run (generators untouched). Verdict: pass (no accepted issues).
- Phase 16 round 1: `dart format` on changed files; `flutter analyze` 0 errors/0 warnings (16 pre-existing infos); `flutter test` passed with 134 tests (28 new in `test/milestone_schedule_test.dart`); `flutter build apk --debug` passed; `node content_source/build/build_all.js` completed and `dart run content_source/validate.dart` printed 'OK: all content files valid.' (21 guides, 132 checklist/timeline items); installed on emulator-5554 with `adb install -r` (data kept), logcat clean. Verdict: pass (P16-R1-01 rejected as pre-existing, moved to Known issues); Phase 16 completed.
- Phase 17 round 1: `dart format` on changed files; `flutter analyze` 0 errors/0 warnings (16 pre-existing infos); `flutter test` passed with 161 tests (27 new in `test/pre_pregnancy_test.dart`); `flutter build apk --debug` passed; installed on emulator-5554 with `adb install -r` (data kept). Content build not run (generators untouched). Logcat: 4x 'Cannot use "ref" after the widget was disposed' from `pregnant_switch_card.dart:53`. Verdict: fix (P17-R1-01, P17-R1-02 accepted).
- Phase 17 round 2: `dart format` on changed files; `flutter analyze` 0 errors/0 warnings (16 pre-existing infos); `flutter test` passed with 164 tests (30 in `test/pre_pregnancy_test.dart`, re-run by QA); `flutter build apk --debug` passed; installed on emulator-5554 with `adb install -r` (data kept), logcat clean. Content build not run (generators untouched). Verdict: pass (no issues); Phase 17 completed.
- Phase 18 round 1: `dart format` on changed files; `flutter analyze` 0 errors/0 warnings (16 pre-existing infos); `flutter test` passed with 195 tests (31 new in `test/food_lookup_test.dart`, re-run by QA); `flutter build apk --debug` passed; installed on emulator-5554 (Pixel 7) with `adb install -r` (data kept), logcat clean. Content build/validate not run (generators untouched). Verdict: fix (P18-R1-01 accepted).
- Phase 18 round 2: `dart format` on changed files; `flutter analyze` 0 errors/0 warnings (16 pre-existing infos); `flutter test` passed with 197 tests (33 in `test/food_lookup_test.dart`, re-run by QA); `flutter build apk --debug` passed; installed on emulator-5554 (Pixel 7) with `adb install -r` (data kept), logcat clean. Content build/validate not run (generators untouched). Verdict: pass (P18-R2-01 rejected as pre-existing, moved to Known issues); Phase 18 completed.
