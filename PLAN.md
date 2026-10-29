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

## Phase 19: Shopping Prices, Documents Date, "Nơi khám của tôi" and Find Hospital (B7-B9)
Status: Completed
Scope: FEATURE_BRAINSTORM.md B7-B9, activated by the user (Phases 14-21). There are four parts. (1) The shopping and hospital-bag guides get an optional price (VND) on each checklist item and a total for the bought (ticked) items. (2) The documents & benefits guide shows its `lastUpdated` date in a banner near the top. (3) "Nơi khám của tôi" is a local profile (clinic/hospital name, doctor, phone, address). It is edited from Cài đặt, can be called or opened in Maps from Hôm nay and from the emergency warning screen, and is removed by delete-all-data. (4) A "Tìm bệnh viện gần tôi" button opens a Google Maps search for "bệnh viện phụ sản" without asking for location permission. It appears in Công cụ and on the emergency screen. Out of scope: content/JSON edits, schema changes, a 115 button (Phase 20), backend doctor directory, location permission, new packages, changes to the Cẩm nang grid.
Grounding (verified 2026-10-29): the working branch is `feature/phase-18`; the task text says `feature/v1-content-and-fixes`. The work stays on the current branch, with no checkout.
- Content needs no change. `pregnant_shopping.json` (category `shopping`, 14 checklist items `chk_shop_*`, weeks 16-34), `pregnant_hospital_bag.json` (`hospital_bag`, 17 items `chk_bag_*`, weeks 34-36), `pregnant_documents.json` (`documents`, 4 sections, 7 items `chk_doc_*`, `lastUpdated` 2026-10-29, the "Lưu ý" section says rules can change) and `pregnant_find_hospital.json` (`checkup`, `chk_hosp_find`/`chk_hosp_clinic` with `openMaps` and values "bệnh viện phụ sản"/"phòng khám sản"; `chk_hosp_save` refers to "Nơi khám của tôi"). All four are `draft_requires_medical_review`, with no timeline.
- Existing code to reuse: `GuideCategory.shopping/documents/hospitalBag` and `GuideArticle.tracksProgress` (`lib/core/models/guide_models.dart`); `GuideActions.mapsSearchUri`, `GuideActions.phoneUri` and the private `_launch` (with the snackbar "Không mở được ứng dụng phù hợp") in `lib/features/guides/guide_actions.dart`; `_ChecklistTile` in `guide_detail_screen.dart`; the SharedPreferences + `StateNotifier` pattern of `GuideProgressService` / `MilestoneProgressService`; `MilestoneProgressService.parseDate` and `DateFormatter.formatDate` (dd/MM/yyyy). `url_launcher` is already a dependency, and `AndroidManifest.xml` already has `<queries>` for `VIEW https` and `DIAL tel`. Delete-all-data is `_deleteAllDataAndRestart` in `settings_screen.dart`, which removes prefs keys and calls `resetLocal()` on the notifiers. `EmergencyWarningScreen` is a `StatelessWidget`. It is used as the Công cụ "Cần khám" tab (`_ToolsTabScreen` in `main_navigation.dart`) and through `NavigationHelper.toEmergencyWarning`. `_ToolsTabScreen` uses `_CollapsibleTabScaffold`, which has no `actions` yet.

### Task 19.1: VND Price Formatting and Item Price Persistence (pure logic)
- New `lib/core/utils/vnd_format.dart`: `formatVnd(int amount)` returns dot thousands separators plus " đ": `0` -> "0 đ", `1250000` -> "1.250.000 đ". It is done by hand so it does not depend on intl locale data. `parseVndInput(String)` strips every non-digit and returns null for an empty result, 0, or more than 9 digits (the max is 999.999.999).
- New `lib/core/services/guide_price_service.dart`. It follows `GuideProgressService`. It stores a JSON map `{itemId: int}` under the new `AppConstants.guidePricesKey = 'guide_item_prices'`. `decode` never throws: corrupt JSON gives `{}`, and non-int or <= 0 values and empty ids are skipped. Also `load`, `save` and `clear`. A `GuidePriceNotifier` (`setPrice(id, int?)`; null or 0 removes the entry; `ready`; `resetLocal()`) and a `guidePriceProvider`.
- `GuideArticle`: add `bool get tracksPrices => tracksProgress && (category == GuideCategory.shopping || category == GuideCategory.hospitalBag)`. Add `int boughtTotal(Set<String> ticked, Map<String, int> prices)`, which sums the prices of ticked items in this guide's checklist (ids from other guides are ignored). Add `int pricedCount(Map<String, int> prices)`.
- Acceptance: unit tests cover these cases. `formatVnd` for 0, 999, 1000, 1250000 and 999999999. `parseVndInput` for "1.250.000" -> 1250000, "abc" -> null, "0" -> null and a 10-digit input -> null. A decode/encode round trip, and corrupt JSON -> `{}`. `setPrice(id, null)` removes the entry. `tracksPrices` is true only for shopping and hospital_bag (false for documents, warning and checkup). `boughtTotal` counts only ticked items that have a price.

### Task 19.2: Price Input and Total in Shopping / Hospital-Bag Guides
- In `GuideDetailScreen`, when `guide.tracksPrices`, each tickable item gets a compact price button below the title (`TextButton.icon`, key `price-<itemId>`, left padding 40 like the action button). It reads "Thêm giá" when no price is set and the formatted price (e.g. "350.000 đ") when one is set. A tap opens a dialog titled "Giá (VND)" with a digits-only `TextField` (`keyboardType: number`, max 9 digits). A live formatted preview sits under the field. The buttons are "Hủy", "Xóa giá" (only when a price exists) and "Lưu". Saving goes through `guidePriceProvider`.
- Above the checklist rows, under the progress bar, a summary line (key `guide-bought-total`) reads "Đã mua X/Y món · Đã chi Z" (Z from `formatVnd(boughtTotal)`). When no item has a price, it adds a hint "Ghi giá để xem tổng chi phí". Unticking an item keeps its price but removes it from the total.
- Other guides (documents, checkup, pre guides, warning) look exactly as before: no price button and no total.
- Acceptance: widget tests with a fixture shopping guide (3 items) and SharedPreferences mock values. Each item shows "Thêm giá". Entering "350000" and saving shows "350.000 đ". Ticking that item shows "Đã chi 350.000 đ". Unticking shows "Đã chi 0 đ" and the price stays. "Xóa giá" brings back "Thêm giá". A fixture documents guide has no `price-*` keys. No overflow at 360x640 at text scale 1.0 and 1.5. The price survives a rebuild after the provider is reloaded from prefs.

### Task 19.3: Documents Guide "Cập nhật" Banner
- New `lib/features/guides/widgets/guide_updated_banner.dart`: `GuideUpdatedBanner(lastUpdated: String?)`. It is a tinted container with `Icons.update` and the bold line "Cập nhật ngày dd/MM/yyyy", using `MilestoneProgressService.parseDate` + `DateFormatter.formatDate`. When the date is null or invalid, the line is "Chưa rõ ngày cập nhật". It also shows the text "Quy định về chế độ thai sản, BHXH và giấy tờ có thể thay đổi. Hãy kiểm tra lại trên cổng BHXH Việt Nam, Cổng Dịch vụ công hoặc hỏi cơ quan có thẩm quyền trước khi làm thủ tục." It must be readable in light and dark mode.
- `GuideDetailScreen` shows the banner right below the summary (above `DraftContentNote`) only when `guide.category == GuideCategory.documents`. The bottom `SourceMetadataCard` is unchanged.
- Acceptance: widget tests. A documents fixture with `lastUpdated: '2026-10-29'` shows "Cập nhật ngày 29/10/2026" above the first section heading (compare the rects). An invalid date shows "Chưa rõ ngày cập nhật" with no exception. A shopping fixture shows no banner. Unit test: the bundled `pregnant_documents.json` has category `documents` and a valid `lastUpdated`.

### Task 19.4: "Nơi khám của tôi" Model, Storage and Launch Helpers (pure logic)
- New `lib/core/models/my_clinic.dart`: an immutable `MyClinic` with `name`, `doctor`, `phone` and `address`. Every field is a trimmed string, empty when unset. It has `isEmpty` (all empty), `hasPhone` (phone has at least 3 digits), `mapsQuery` (the address when not empty, otherwise the name, otherwise null), `toJson`/`fromJson` (`fromJson` never throws; unknown or non-string values become empty), `copyWith` and `==`.
- New `lib/core/services/my_clinic_service.dart`: it stores JSON under `AppConstants.myClinicKey = 'my_clinic_profile'`, with `load`, `save` (saving an empty profile removes the key) and `clear`. A `MyClinicNotifier` (`save(MyClinic)`, `clear()`, `ready`, `resetLocal()`) and a `myClinicProvider`.
- `GuideActions`: make the launcher public as `launchUri(BuildContext, Uri)`, keeping the same snackbar on failure, and add `static const nearbyHospitalQuery = 'bệnh viện phụ sản'`. `run()` behaviour is unchanged.
- Acceptance: unit tests cover these cases. A `fromJson` round trip. Corrupt or partial JSON gives empty or partly filled fields. `mapsQuery` prefers the address, then the name, then null. `hasPhone` is false for "12" and true for "028 3829 5723". Saving an empty profile removes the prefs key. `GuideActions.phoneUri(clinic.phone)` gives `tel:02838295723`. `mapsSearchUri(nearbyHospitalQuery)` gives the same encoded URL as the existing `content_engine_test.dart` check.

### Task 19.5: Editor in Cài đặt + Delete-All-Data
- New `lib/features/settings/screens/my_clinic_screen.dart`: `MyClinicScreen` (AppBar "Nơi khám của tôi") with 4 `TextFormField`s: "Tên bệnh viện / phòng khám", "Bác sĩ theo dõi", "Số điện thoại" (`keyboardType: phone`) and "Địa chỉ" (multi-line). Each field is limited to 120 characters. The phone validator accepts an empty value, or digits, spaces and `+ - . ( )` with at least 3 digits. Otherwise it shows "Số điện thoại không hợp lệ". The buttons are "Lưu" (it saves, shows the snackbar "Đã lưu nơi khám" and pops) and "Xóa thông tin" (shown when a profile exists; it asks for confirmation, then clears). The screen also shows a note: "Thông tin chỉ lưu trên thiết bị này." It must work with the keyboard open at 360 dp.
- `SettingsScreen`: a new section "Nơi khám của tôi", shown in both modes and placed after "Thông tin thai kỳ" (or after "Giao diện" when there is no pregnancy). It has one `ListTile` (`Icons.local_hospital_outlined`) whose subtitle is the saved name (or "Chưa cài đặt"). A tap pushes `MyClinicScreen`. Add `NavigationHelper.toMyClinic`.
- `_deleteAllDataAndRestart` also removes `AppConstants.guidePricesKey` and `AppConstants.myClinicKey` and calls `resetLocal()` on `guidePriceProvider` and `myClinicProvider`. The first delete dialog text adds "nơi khám đã lưu, giá đồ mua sắm" to the list.
- Acceptance: widget tests cover these cases. Entering name/phone/address and pressing "Lưu" stores them in prefs. Reopening the screen shows them. An invalid phone ("ab") blocks the save and shows the error. "Xóa thông tin" after confirmation clears the profile. Both new keys are removed by delete-all-data: verify this in review and on device (step 12), or with a test if the removal is moved into a testable helper.

### Task 19.6: Quick Actions Card on Hôm nay + Emergency Screen + Find Hospital in Công cụ
- New `lib/features/settings/widgets/my_clinic_card.dart`: `MyClinicCard({bool emergency = false})`, a `ConsumerWidget` reading `myClinicProvider`.
  - With a saved profile, it shows the title "Nơi khám của tôi", the name (bold), the doctor ("BS. ...", if set) and the phone (if set). Buttons (`Wrap`, no overflow at 360 dp / text scale 1.5): "Gọi" (`Icons.call`, only when `hasPhone`, launches `tel:`), "Bản đồ" (`Icons.map_outlined`, only when `mapsQuery != null`, launches the Maps search for that query) and "Sửa" (pushes `MyClinicScreen`).
  - Without a profile, it shows the title and the text "Lưu tên và số điện thoại nơi khám để gọi nhanh khi cần", with the button "Thêm nơi khám" (pushes `MyClinicScreen`).
  - `emergency: true` always adds the button "Tìm bệnh viện gần tôi" (`Icons.local_hospital_outlined`, key `find-hospital-button`), which launches `mapsSearchUri(GuideActions.nearbyHospitalQuery)`. The call button is a filled red button when this is true.
- Hôm nay: in `HomeScreen._buildPregnancyView`, place `MyClinicCard()` right after `EmergencyEntryCard`. In `PrePregnancyHomeScreen`, place it after `EmergencyEntryCard` too. Both modes show the same card.
- `EmergencyWarningScreen`: insert `MyClinicCard(emergency: true)` right after the "Bạn nên làm gì?" action card (above the sources card). The screen can stay a `StatelessWidget`; the card brings its own Riverpod read.
- Công cụ: add an optional `actions` parameter to `_CollapsibleTabScaffold`. `_ToolsTabScreen` passes an `IconButton` (`Icons.local_hospital_outlined`, tooltip "Tìm bệnh viện gần tôi", key `tools-find-hospital`) that launches the same Maps search, so it can be reached from all 3 Công cụ tabs. The Tuần thai tab scaffold is unchanged.
- No location permission is requested, and `AndroidManifest.xml` is not changed (the queries already exist). When launching fails, the existing snackbar is shown.
- Acceptance: widget tests use an injectable launcher: add `@visibleForTesting static Future<bool> Function(Uri)? debugLauncher` to `GuideActions`, or override `UrlLauncherPlatform` with a fake. The tests cover these cases. The empty card shows "Thêm nơi khám" and a tap pushes `MyClinicScreen`. A saved profile with a phone and an address shows "Gọi" and "Bản đồ". Tapping "Gọi" launches `tel:<digits>`, and tapping "Bản đồ" launches a Maps URL with the address. A profile with only a name shows "Bản đồ" (with the name query) and no "Gọi". `MyClinicCard(emergency: true)` shows `find-hospital-button`, which launches the "bệnh viện phụ sản" URL. `EmergencyWarningScreen` inside a `ProviderScope` shows the card and the button. A failing launcher shows "Không mở được ứng dụng phù hợp". No overflow at 360x640 at text scale 1.0 and 1.5.

### Task 19.7: Tests and Verification
- New `test/my_clinic_and_prices_test.dart` with the unit and widget tests from 19.1-19.6 (inline fixtures, `SharedPreferences.setMockInitialValues`, no Hive: pass guides directly to `GuideDetailScreen`; Hôm nay integration is checked on device). All existing tests (197) still pass.
- Run `dart format` on changed files, `flutter analyze` (0 errors / 0 warnings, pre-existing infos only), `flutter test` and `flutter build apk --debug`. Content build/validate is not needed (no generator changes).
- Acceptance: all commands pass and the results are recorded in the Verification Log.

### On-device test plan (emulator-5554, `adb install -r`, data kept)
1. Cài đặt: the new section "Nơi khám của tôi" shows "Chưa cài đặt". Tap it, enter the phone "ab" and press "Lưu": the error "Số điện thoại không hợp lệ" appears. Enter the name "BV Từ Dũ", doctor "Nguyễn A", phone "028 5404 2829" and address "284 Cống Quỳnh, Quận 1, TP.HCM", then press "Lưu": the snackbar "Đã lưu nơi khám" appears and the subtitle shows "BV Từ Dũ". With the keyboard open there is no overflow.
2. Hôm nay (pregnancy mode): the "Nơi khám của tôi" card below the emergency card shows the name, "BS. Nguyễn A" and the phone. "Gọi" opens the dialer with 02854042829, and no call is placed. "Bản đồ" opens Google Maps (app or browser) searching for the address. "Sửa" opens the editor with the saved values.
3. Công cụ: the hospital icon in the AppBar has the tooltip "Tìm bệnh viện gần tôi" on a long-press. A tap opens Maps with "bệnh viện phụ sản", and no location permission dialog appears from MomCare+. The icon is present on the Dinh dưỡng, Lịch hẹn and Cần khám tabs.
4. Công cụ > Cần khám, and Hôm nay emergency card > "Dấu hiệu cần đi khám ngay": the clinic card (emergency style) sits below "Bạn nên làm gì?". "Gọi" opens the dialer, "Tìm bệnh viện gần tôi" opens Maps, and the sources card is still at the bottom.
5. Edit the profile and clear the phone and address (name only): the cards show "Bản đồ" (searching for the name) and no "Gọi". Then "Xóa thông tin" + confirm: Hôm nay shows the empty state "Thêm nơi khám". In the emergency screen, "Tìm bệnh viện gần tôi" still works.
6. Cẩm nang > "Mua sắm chuẩn bị" (shopping): every item has "Thêm giá". Give "Áo ngực bầu" 350000: the item shows "350.000 đ". Tick it: "Đã mua 1/14 món · Đã chi 350.000 đ". Add 1.200.000 to "Nôi hoặc cũi" and tick it: the total is "1.550.000 đ". Untick it: the total drops back and the price stays. "Xóa giá" restores "Thêm giá". A 10-digit input is not accepted. The progress % still matches the ticks.
7. Cẩm nang > "Túi đồ đi sinh": price buttons and the total work the same way. Other guides (Lịch khám thai, Giấy tờ, pre guides, Dấu hiệu nguy hiểm) have no price button.
8. Cẩm nang > "Giấy tờ & quyền lợi": the banner "Cập nhật ngày 29/10/2026" with the "Quy định ... có thể thay đổi" text sits right under the summary, above the draft note and the first section. The bottom source card still shows the last updated date.
9. Cẩm nang > the find-hospital guide: the "Mở bản đồ" actions still open Maps with "bệnh viện phụ sản" / "phòng khám sản".
10. Force-stop and relaunch: the clinic profile and prices persist. Switch to pre-pregnancy mode: Hôm nay shows the clinic card, and Cài đặt still has the section. Switch back.
11. Large font (scale 1.5) and dark mode: no overflow on the clinic cards, price buttons, total line or banner, and all text is readable.
12. Last (it wipes the emulator data; re-create the test pregnancy afterwards): Cài đặt > "Xóa toàn bộ dữ liệu". The dialog lists "nơi khám đã lưu, giá đồ mua sắm". After onboarding, Cài đặt shows "Chưa cài đặt" and the shopping guide has no prices. Logcat has no Flutter exceptions.

Required automated tests: `test/my_clinic_and_prices_test.dart` covers `formatVnd`/`parseVndInput`; `GuidePriceService` decode and the notifier; `tracksPrices`/`boughtTotal`; the price dialog and total in `GuideDetailScreen`; `GuideUpdatedBanner` and its placement; `MyClinic` JSON, `mapsQuery` and `hasPhone`; `MyClinicService`; `MyClinicScreen` validation, save and clear; `MyClinicCard` empty, full, name-only and emergency variants with a fake launcher; `EmergencyWarningScreen` with the card; and checks at 360 dp / text scale 1.5. All existing tests still pass.

### Results (round 1)
- 19.1 Result: done. `lib/core/utils/vnd_format.dart` (`formatVnd` formatted by hand, `parseVndInput` with null for empty, 0 or more than 9 digits), `lib/core/services/guide_price_service.dart` (`GuidePriceService`, `GuidePriceNotifier`, `guidePriceProvider` under `AppConstants.guidePricesKey = 'guide_item_prices'`), and `GuideArticle.tracksPrices` / `boughtTotal` / `pricedCount`. The unit tests pass.
- 19.2 Result: done. `price-<id>` buttons and the "Giá (VND)" dialog (digits only, 9-digit cap, live preview, Hủy / Xóa giá / Lưu, and Lưu stays disabled until the value is valid) plus the `guide-bought-total` line and its hint. On device: Mua sắm 350.000 đ, then 1.550.000 đ, untick drops the total and keeps the price, Xóa giá works, a 10-digit input is cut to 9, and the progress % is unchanged. Túi đồ đi sinh works the same way. Other guides have no price button. PM note: the dialog also shows the item name and "Nhập số tiền lớn hơn 0". Accepted, as it stays inside the phase.
- 19.3 Result: done. `lib/features/guides/widgets/guide_updated_banner.dart`. On device, "Cập nhật ngày 29/10/2026" sits under the summary and above the draft note, and it is readable in dark mode at scale 1.5. The tests cover the invalid-date fallback, the shopping guide with no banner, and the bundled `lastUpdated`.
- 19.4 Result: done. `lib/core/models/my_clinic.dart`, `lib/core/services/my_clinic_service.dart` (`myClinicKey = 'my_clinic_profile'`; an empty save removes the key, also seen on device), `GuideActions.launchUri`, `nearbyHospitalQuery` and the `debugLauncher` hook.
- 19.5 Result: done. `MyClinicScreen` handles validation, save with the snackbar and pop, and clear with confirmation. The Cài đặt section works in both modes and `NavigationHelper.toMyClinic` exists. Delete-all-data removes both keys and resets both notifiers, and its dialog text lists "nơi khám đã lưu, giá đồ mua sắm". This was checked in code review only; step 12 was not run on device. PM note: the ListTile title is "Bệnh viện / phòng khám" under the section header "Nơi khám của tôi". Accepted.
- 19.6 Result: needs fix (P19-R1-01). The card placement on Hôm nay (both modes) and on EmergencyWarningScreen, the Gọi / Bản đồ / Sửa / Tìm bệnh viện intents and the Công cụ AppBar icon (on all 3 tabs, no permission prompt) all work on device. In dark mode, however, the tonal "Thêm nơi khám" and non-emergency "Gọi" buttons are unreadable.
- 19.7 Result: done. `test/my_clinic_and_prices_test.dart` (42 tests). The suite passes 239/239. analyze has 0 errors/0 warnings (16 pre-existing infos), and the debug APK builds. Content build/validate was not run (no generators changed). `test/content_pack_test.dart` is not dart-formatted; it is pre-existing and outside scope.

### Test round 1 (2026-10-29)
- Tester summary: QA re-ran `flutter test` (239/239) and `flutter analyze` (0 errors/0 warnings, 16 pre-existing infos). The up-to-date debug APK was installed on emulator-5554 with `adb install -r` (data kept) and launched. Steps 1-11 passed: the clinic editor validation, save and clear; the clinic cards on Hôm nay (both modes) and on the emergency screen, with tel/Maps intents; the Công cụ find-hospital icon with no permission prompt; shopping and hospital-bag prices and totals; no price buttons on the other guides; the documents banner placement; the find-hospital guide Maps actions; persistence after force-stop; and font scale 1.5 in light and dark mode. The exception is the contrast of the dark-mode tonal buttons. Step 12 was checked by code review only. Logcat was clean. Device state was restored.
- Accepted P19-R1-01 (major): in dark mode, `FilledButton.tonalIcon` in `lib/features/settings/widgets/my_clinic_card.dart` (~113 "Thêm nơi khám" and ~132 non-emergency "Gọi") draws `onSecondaryContainer` (#E8E8E8) on the default `secondaryContainer` (#FAD0C4), which `AppTheme.darkColorScheme` does not set. The contrast is about 1.15:1. This is the same root cause as the Phase 15 thai-giáo chip (`today_thai_giao_card.dart:127`). Fix:
  - In `my_clinic_card.dart`, give both tonal buttons an explicit style: `FilledButton.styleFrom(backgroundColor: AppTheme.primaryTint(theme.colorScheme), foregroundColor: theme.colorScheme.onSurface)`. This reuses the existing helper in `lib/core/theme/app_theme.dart:27`. Another option is to switch them to `FilledButton.icon` (primary/onPrimary). Do not change `AppTheme.darkColorScheme` globally; that is a broader theme change outside this phase. Keep the emergency red "Gọi" and the outlined buttons as they are.
  - Add a widget test that pumps `MyClinicCard()` under `AppTheme.darkTheme` (empty state and a profile with a phone). It reads the resolved `ButtonStyle` background/foreground of `my-clinic-add` and `my-clinic-call` and asserts a contrast ratio of at least 4.5:1, using `Color.computeLuminance`. Run the same check in light theme.
- Rejected P19-R1-02 (minor): at font scale 1.5 on device, the `PregnancyProgressCard` row (RIGHT OVERFLOWED BY 71 px) and the `QuickActionsGrid` tiles (BOTTOM OVERFLOWED BY 12-13 px) overflow. These widgets are pre-existing, and Phase 19 does not touch them. The Known issues entry has been updated to say it does happen on device.
- Note for the round 2 tester: re-check step 11 in dark mode for the "Thêm nơi khám" and "Gọi" (non-emergency) buttons, in both pregnancy and pre-pregnancy mode. Also do a quick light-mode regression on the same buttons. Step 12 stays code review only unless you are told otherwise.
- Verdict: fix.

### Results (round 2)
- 19.1 Result: done (unchanged since round 1).
- 19.2 Result: done. Regression on device: Mua sắm prices, the dialog live preview, the 9-digit cap, the total after tick and untick, Xóa giá and the hint all pass.
- 19.3 Result: done. The Giấy tờ banner "Cập nhật ngày 29/10/2026" is still under the summary and above the draft note.
- 19.4 Result: done (unchanged since round 1). tel:digits and the Maps intents (address, name, "bệnh viện phụ sản") were re-checked on device.
- 19.5 Result: done. Validation, save with the snackbar, the Cài đặt subtitle, and clear with confirmation were re-checked on device. Delete-all-data was re-checked in code review: `settings_screen.dart` ~482-485 removes `guidePricesKey`/`myClinicKey` and calls both notifiers' `resetLocal`, and the dialog text (~430) lists "nơi khám đã lưu, giá đồ mua sắm". Step 12 was not run on device, as planned.
- 19.6 Result: done. P19-R1-01 is fixed. `lib/features/settings/widgets/my_clinic_card.dart` gives "Thêm nơi khám" and the non-emergency "Gọi" a shared `FilledButton.styleFrom(backgroundColor: AppTheme.primaryTint(cs), foregroundColor: cs.onSurface)`. Both are readable on device in dark mode and in light mode. The emergency red "Gọi" and the outlined/text buttons are unchanged.
- 19.7 Result: done. There are 4 new contrast tests (my-clinic-add and my-clinic-call, each in light and dark, asserting at least 4.5:1). They use `ThemeData(colorScheme: AppTheme.light/darkColorScheme)`, because GoogleFonts cannot load in tests. With the fix reverted, they fail at 1.15:1. The suite passes 243/243, analyze has 0 errors/0 warnings (16 pre-existing infos), and the debug APK builds.

### Test round 2 (2026-10-29)
- Tester summary: QA re-ran `flutter test` (243/243) and `flutter analyze` (0 errors/0 warnings, 16 pre-existing infos). The APK was newer than the sources and was installed on the emulator with `adb install -r` (data kept), then launched. P19-R1-01 is verified fixed in dark mode, with no light-mode regression. Regression steps 1-6, 8 and the persistence part of step 10 pass. Steps 7 and 11 were only partly re-checked (Tiêm phòng has no price button; the empty clinic card at scale 1.5). Steps 9 and 12 and the pre-pregnancy part of step 10 were not re-run. Those areas did not change in round 2, and round 1 passed them (step 12 by code review). The fix is theme-based, so it does not depend on the mode. Logcat was clean, and device state was restored.
- Accepted issues: none.
- Rejected (observations, not filed): the PregnancyProgressCard and QuickActionsGrid overflow at scale 1.5 is already in Known issues (P19-R1-02). In light mode, the unmodified `EmergencyEntryCard` (red at 6% alpha) looks muddy grey-mauve. It is pre-existing and not in the Phase 19 diff, so it was added to Known issues.
- Verdict: pass. Phase 19 completed.

## Phase 20: Kick Counter, Contraction Timer and "Gọi 115" (B10 part 1)
Status: Completed
Scope: FEATURE_BRAINSTORM.md B10 part 1, activated by the user (Phases 14-21). There are three parts. (1) "Đếm cử động thai": the user starts a session, taps once per movement, sees the count and elapsed time, stops the session and sees a history list. The screen shows guidance from content about when to see a doctor and links to "Dấu hiệu cần đi khám ngay". (2) "Đếm cơn co": the user starts and stops each contraction and sees its duration, the interval since the previous one and a history list. When the recent contractions match the 5-1-1 pattern, a neutral hint appears with buttons to call 115, call "Nơi khám của tôi" or find a hospital. (3) A prominent "Gọi 115" button (`tel:115`) near the top of the emergency warning screen. All data stays on the device and is removed by delete-all-data. The app never calls counts or contractions normal or abnormal. It only shows what was recorded and the general guidance from content. Out of scope: content/JSON and generator edits, schema changes, bump photos, shareable milestone cards, PDF export and the home-screen widget (the rest of B10, not active yet), notifications or reminders for the tools, a background service or ongoing notification while a session runs, new packages, Hôm nay changes, and changes to the Cẩm nang grid.
Grounding (verified 2026-10-29): the working branch is `feature/phase-19`; the task text says `feature/v1-content-and-fixes`. The work stays on the current branch, with no checkout.
- Content needs no change. The guidance comes from existing content:
  - `assets/content/daily/daily_tips.json` items (they have no ids, so they are matched by exact `title`): "Theo dõi thai máy mỗi ngày" (day 197, week 28: "Từ tuần 28, để ý cử động thai mỗi ngày. Thai máy giảm rõ hoặc không thấy là lý do đi khám ngay, không chờ đến hôm sau."), "Quy tắc 5-1-1" (day 262: "Một hướng dẫn thường dùng: cơn co cách nhau 5 phút, mỗi cơn 1 phút, kéo dài 1 giờ thì đến viện. Hãy hỏi bác sĩ về hướng dẫn riêng của bạn.") and "Khi nào đến viện" (day 254: "Đến viện khi vỡ ối, ra máu, thai máy giảm, đau bụng liên tục hoặc cơn co đều theo hướng dẫn của bác sĩ."). The pack is `draft_requires_medical_review`.
  - `assets/content/guides/pregnant_warning_signs.json` (category `warning`, sources CDC-WARNING / WHO-ANC / MOH-RH-2016): section 0 "Gọi 115 hoặc đến cấp cứu ngay" includes the bullets "Thai máy giảm rõ hoặc không thấy thai máy (từ khoảng tuần 28)" and "Cơn co tử cung đều đặn trước 37 tuần". Its checklist item `chk_warn_call` already has a `call` action to 115. The guide is not changed.
- Existing code to reuse: `ContentPackService.dailyTipsPack` (`DailyPack.items`, `DailyItem.title/body`) and `ContentPackService.debugDailyTipsPack` for tests; `DailyContentParser` for loading the bundled pack in tests; `GuideActions.phoneUri`, `GuideActions.launchUri` (snackbar "Không mở được ứng dụng phù hợp" on failure) and the `GuideActions.debugLauncher` test hook in `lib/features/guides/guide_actions.dart`; `MyClinicCard(emergency: true)` in `lib/features/settings/widgets/my_clinic_card.dart`; `NavigationHelper.toEmergencyWarning`; `DateFormatter.formatDate/formatTime/formatDateTime`; `SourceMetadataCard(group: MedicalReferenceGroup.urgentWarning)`; the SharedPreferences JSON + `StateNotifier` pattern of `MyClinicService` / `GuidePriceService` (`decode` never throws, `ready`, `resetLocal()`); `AppTheme.primaryTint` for tonal buttons (see P19-R1-01; do not rely on the default `secondaryContainer`). `url_launcher` is already a dependency, and `AndroidManifest.xml` already has `<queries>` for `DIAL tel`. Công cụ is `_ToolsTabScreen` in `lib/features/home/screens/main_navigation.dart` (a `StatelessWidget` with 3 tabs, Dinh dưỡng / Lịch hẹn / Cần khám, plus the `tools-find-hospital` action). `EmergencyWarningScreen` (`lib/features/emergency/screens/emergency_warning_screen.dart`) is a `StatelessWidget`, used both as a pushed route and as the Cần khám tab. Delete-all-data is `_deleteAllDataAndRestart` in `settings_screen.dart`.
- Storage decision: SharedPreferences JSON, the same as Phases 15-19 and `maternal_habit_service.dart`, so the logic stays testable without Hive. FEATURE_REVIEW.md suggested a new Hive box. An encrypted box is a possible later hardening item and is not part of this phase.

### Task 20.1: Kick Counter Model and Storage (pure logic)
- New `lib/core/models/kick_session.dart`: an immutable `KickSession` with `id` (String, from `startedAt.microsecondsSinceEpoch`), `startedAt`, `endedAt` (null while running), `count` (int >= 0) and `tenthKickAt` (DateTime?, set when the count first reaches 10). It has `isActive`, `Duration elapsed(DateTime now)` (end, or now, minus start; never negative), `Duration? timeToTen`, `addKick(DateTime at)` (count + 1; sets `tenthKickAt` on the 10th), `undoKick()` (count - 1, never below 0; clears `tenthKickAt` when the count drops below 10), `stop(DateTime at)`, `toJson`/`fromJson` (`fromJson` returns null for a missing or invalid `startedAt`; a negative count becomes 0) and `==`.
- New `lib/core/services/kick_counter_service.dart`: it stores a JSON list under the new `AppConstants.kickSessionsKey = 'kick_sessions'`. `decode` never throws: corrupt JSON gives `[]` and invalid entries are skipped. The list is kept newest first and capped at 100 completed sessions (the oldest are dropped) plus at most one active session. A `KickCounterNotifier` (`StateNotifier<List<KickSession>>`) has `start(now)` (does nothing when a session is already active), `kick(now)`, `undo()`, `stop(now)` (a session with count 0 is discarded instead of saved), `delete(id)`, `clearHistory()`, an `active` getter, `ready` and `resetLocal()`. Each change is saved right away, so an active session survives a force-stop. A `kickCounterProvider`.
- New `lib/core/utils/duration_format.dart`: `formatClock(Duration)` gives "mm:ss" ("01:05"), or "h:mm:ss" from one hour up ("1:02:03"). `formatMinutes(Duration)` gives "X phút" (rounded down), "dưới 1 phút" under 60 s, and "1 giờ 5 phút" from one hour up.
- Acceptance: unit tests cover these cases. `addKick` 10 times sets `tenthKickAt` to the 10th time, and `undoKick` after that clears it. `undoKick` at 0 stays 0. `elapsed` of an active session uses `now`, and a stopped one uses `endedAt`. A JSON round trip; corrupt JSON gives `[]`; an entry without `startedAt` is skipped. `start` twice keeps one active session. `stop` with count 0 leaves no history entry. The cap keeps the newest 100 sessions. `resetLocal()` empties the state. `formatClock` for 0 s, 65 s and 3723 s; `formatMinutes` for 30 s, 25 min and 65 min.

### Task 20.2: Contraction Model, Storage and 5-1-1 Check (pure logic)
- New `lib/core/models/contraction.dart`: an immutable `Contraction` with `startedAt` and `endedAt` (null while running). It has `isActive`, `Duration? duration`, `toJson`/`fromJson` (null for invalid data, or when `endedAt` is before `startedAt`) and `==`.
- New `lib/core/services/contraction_service.dart`: it stores a JSON list under the new `AppConstants.contractionsKey = 'contraction_log'`, kept oldest first and capped at the newest 300 entries. `decode` never throws. Pure helpers:
  - `Duration? intervalBefore(List<Contraction> list, int index)`: the start of this one minus the start of the previous one (start to start), null for the first.
  - `ContractionSummary summarize(List<Contraction> list, DateTime now)`: the number of completed contractions that started in the last 60 minutes, their average duration and their average interval (null when there are fewer than 2).
  - `bool matches511(List<Contraction> list)`: it takes the newest completed contractions as a run, going back while each interval is at most 5 minutes and each duration is at least 1 minute. It is true when that run spans at least 60 minutes (from the first start to the last end). The thresholds are named constants in one place (`fiveOneOneMaxInterval`, `fiveOneOneMinDuration`, `fiveOneOneMinSpan`), so they can be changed after medical review.
- A `ContractionNotifier` (`StateNotifier<List<Contraction>>`) has `toggle(now)` (starts a contraction, or ends the running one), `delete(startedAt)`, `clearHistory()`, `active`, `ready` and `resetLocal()`. Each change is saved right away. A `contractionProvider`.
- Acceptance: unit tests cover these cases. `toggle` twice gives one completed contraction with the right duration. `intervalBefore` is null for the first and start to start for the next. `matches511` is true for 13 contractions of 60 s every 5 min (span 61 min). It is false for the same at 6 min apart, false when one of the last ones lasts 40 s, and false when the run spans only 50 min. An active (running) contraction is ignored. `summarize` ignores contractions older than 60 minutes. A JSON round trip; corrupt JSON gives `[]`; an entry whose end is before its start is skipped. The cap keeps the newest 300. `resetLocal()` empties the state.

### Task 20.3: Guidance Text from Content
- New `lib/features/tools/tool_guidance.dart` with `ToolGuidance.kickGuidance(DailyPack)`, `ToolGuidance.fiveOneOne(DailyPack)` and `ToolGuidance.whenToGo(DailyPack)`. Each returns the `body` of the daily tip with the exact title "Theo dõi thai máy mỗi ngày", "Quy tắc 5-1-1" or "Khi nào đến viện". When the tip is missing (an empty pack in tests, or a changed title), it returns a built-in fallback with the same wording as the current content. The titles are constants in this file.
- New `lib/features/tools/widgets/tool_guidance_card.dart`: a tinted card, readable in light and dark mode, with `Icons.info_outline`, a title, the guidance text, the line "Thông tin tham khảo, không thay thế chẩn đoán hay tư vấn của bác sĩ." and a `TextButton` "Xem dấu hiệu cần đi khám" that calls `NavigationHelper.toEmergencyWarning`.
- Acceptance: unit tests show that the bundled `assets/content/daily/daily_tips.json` (loaded with `DailyContentParser`) contains all 3 titles, so the guidance comes from content and not from the fallback. With an empty pack, each helper returns its non-empty fallback.

### Task 20.4: "Đếm cử động thai" Screen
- New `lib/features/tools/screens/kick_counter_screen.dart`: `KickCounterScreen` (AppBar "Đếm cử động thai"), a `ConsumerStatefulWidget` reading `kickCounterProvider`.
  - With no active session: the intro text "Chọn lúc bé hay cựa quậy, ngồi hoặc nằm nghiêng thoải mái và bấm mỗi lần cảm nhận được cử động." and a large `FilledButton` "Bắt đầu đếm" (key `kick-start`).
  - With an active session: the elapsed time as `formatClock`, updated every second by a `Timer.periodic` that runs only while a session is active and is cancelled in `dispose`. A large round button (at least 160 dp, key `kick-tap`, label "Bé đạp" and the count in large digits); each tap calls `kick` and `HapticFeedback.lightImpact`. A "Hoàn tác" `TextButton` (key `kick-undo`, disabled at 0) and "Kết thúc" (key `kick-stop`). When `tenthKickAt` is set, a neutral line "Đã đếm 10 cử động sau <formatMinutes>" is shown. There are no words like "bình thường", "bất thường", "tốt" or "đạt".
  - `ToolGuidanceCard` titled "Khi nào cần đi khám" with `ToolGuidance.kickGuidance`, always shown under the counter.
  - History "Lịch sử" (newest first): each row shows `formatDateTime(startedAt)`, "<count> cử động · <formatMinutes(elapsed)>" and, when set, "10 cử động sau <formatMinutes>". Each row has a delete `IconButton` (key `kick-delete-<id>`, with a confirmation dialog). "Xóa lịch sử" (with a confirmation dialog) shows only when there is history. The empty state is "Chưa có lượt đếm nào."
  - `SourceMetadataCard(group: MedicalReferenceGroup.urgentWarning)` at the bottom.
  - Elapsed time is computed from the saved `startedAt`, so it is correct after the app is backgrounded, or force-stopped and opened again.
- Acceptance: widget tests (SharedPreferences mock, `ContentPackService.debugDailyTipsPack` set to a fixture or an empty pack) cover these cases. "Bắt đầu đếm" shows `kick-tap` with count 0. Three taps show 3, and "Hoàn tác" shows 2. "Kết thúc" adds a history row "2 cử động" and brings back "Bắt đầu đếm". Stopping at 0 adds no row. Deleting a row after confirming removes it. An active session stored in prefs is shown as active when the screen opens. The guidance text and "Xem dấu hiệu cần đi khám" are present. No overflow at 360x640 at text scale 1.0 and 1.5. No pending timers after the widget is disposed.

### Task 20.5: "Đếm cơn co" Screen
- New `lib/features/tools/screens/contraction_timer_screen.dart`: `ContractionTimerScreen` (AppBar "Đếm cơn co"), a `ConsumerStatefulWidget` reading `contractionProvider`.
  - A large toggle button (key `contraction-toggle`): "Bắt đầu cơn co" when idle, and "Kết thúc cơn co" with the running `formatClock` duration while a contraction runs (a 1 s ticker that runs only while needed and is cancelled in `dispose`). Below it, while idle and after at least one contraction, "Từ cơn trước: <formatClock>" counts up from the last start.
  - A summary line for the last 60 minutes: "<n> cơn trong 1 giờ qua · TB dài <mm:ss> · TB cách <mm:ss>", shown when n >= 1. An average that is not available shows "—".
  - When `matches511` is true, a hint card (key `contraction-511-hint`) titled "Cơn co có vẻ theo mẫu 5-1-1" with the text "Cơn co cách nhau khoảng 5 phút, mỗi cơn khoảng 1 phút, kéo dài khoảng 1 giờ. Đây là mốc thường được dùng để liên hệ bệnh viện. Hãy gọi nơi khám hoặc đến bệnh viện theo hướng dẫn của bác sĩ." Under it, a red `FilledButton.icon` "Gọi 115" (key `contraction-call-115`, `Icons.call`) launches `GuideActions.phoneUri('115')` through `GuideActions.launchUri`, followed by `MyClinicCard(emergency: true)` (call the saved clinic, or "Tìm bệnh viện gần tôi"). The hint uses no diagnostic words ("chuyển dạ", "sắp sinh", "bình thường").
  - `ToolGuidanceCard` titled "Khi nào cần đến viện", always shown, with `ToolGuidance.fiveOneOne` and `ToolGuidance.whenToGo`, plus the line "Nếu dưới 37 tuần mà có cơn co đều, hoặc ra nước, ra máu, đau bụng liên tục, thai máy giảm, hãy liên hệ cơ sở y tế ngay, không chờ đủ 5-1-1." (wording taken from the bullets in `pregnant_warning_signs.json`).
  - History "Lịch sử" grouped by day (header `formatDate`), newest first. Each row shows the start `formatTime`, "Dài <mm:ss>" and "Cách <mm:ss>" (or "—" for the first), with a delete `IconButton` (key `contraction-delete-<startedAtMillis>`, with confirmation). "Xóa lịch sử" with confirmation. The empty state is "Chưa có cơn co nào được ghi."
  - `SourceMetadataCard(group: MedicalReferenceGroup.urgentWarning)` at the bottom.
- Acceptance: widget tests cover these cases. Tapping `contraction-toggle` twice adds one history row. A prefs fixture of 13 contractions (60 s every 5 min, ending just now) shows `contraction-511-hint`, and tapping `contraction-call-115` with a fake `GuideActions.debugLauncher` launches `tel:115`. A fixture at 7 min apart shows no hint. A failing launcher shows "Không mở được ứng dụng phù hợp". Deleting a row after confirming removes it. A running contraction stored in prefs is shown as running when the screen opens. No overflow at 360x640 at text scale 1.0 and 1.5. No pending timers after dispose.

### Task 20.6: Công cụ "Bộ đếm" Tab and Navigation
- New `lib/features/tools/screens/counter_tools_screen.dart`: `CounterToolsScreen`, a list with two cards. "Đếm cử động thai" (`Icons.touch_app_outlined`, key `tools-kick`) has the subtitle "Thường bắt đầu theo dõi từ khoảng tuần 28" and, when there is history, "Lần gần nhất: <formatDateTime> · <count> cử động" ("Đang đếm..." while a session is active). "Đếm cơn co" (`Icons.timer_outlined`, key `tools-contraction`) has the subtitle "Ghi thời gian và khoảng cách giữa các cơn co" and, when there is history, "Lần gần nhất: <formatDateTime>" ("Đang ghi cơn co..." while one is running). A tap pushes the screen. Add `NavigationHelper.toKickCounter` and `NavigationHelper.toContractionTimer`.
- `_ToolsTabScreen` becomes a `ConsumerWidget` that reads `appModeProvider`. In pregnancy mode it has 4 tabs: Dinh dưỡng / Lịch hẹn / Bộ đếm (`Icons.timer_outlined`) / Cần khám. In pre-pregnancy mode it keeps the current 3 tabs. The `DefaultTabController` gets `key: ValueKey(isPrePregnancy)` and the matching `length`. The `TabBar` uses `isScrollable: true` and `tabAlignment: TabAlignment.center`, so 4 tabs are not clipped at 360 dp / scale 1.5 (this also fixes Known issue P18-R2-01 for this TabBar). The `tools-find-hospital` action stays. The Tuần thai tab scaffold is unchanged.
- Acceptance: widget tests cover these cases. `CounterToolsScreen` shows both cards, and a tap on each pushes the matching screen. With a kick history fixture, the "Lần gần nhất" subtitle shows the count. `mainDestinations` is unchanged. The Công cụ tab change is checked on device (steps 1 and 10).

### Task 20.7: Prominent "Gọi 115" on the Emergency Warning Screen
- `EmergencyWarningScreen`: right after `_buildHeader` (before the first `_WarningGroup`), add a full-width red `FilledButton.icon` (key `emergency-call-115`, `Icons.call`, label "Gọi 115 (cấp cứu)", minimum height 56, white text on `Colors.red.shade700`, so it is readable in light and dark mode). It runs `GuideActions.launchUri(context, GuideActions.phoneUri('115'))`. Under it, a small line: "Mở ứng dụng gọi điện với số 115. Bạn cần bấm gọi để kết nối." This only opens the dialer; the app never places a call itself. In "Bạn nên làm gì?", "hãy gọi số cấp cứu tại địa phương" becomes "hãy gọi 115 hoặc số cấp cứu tại địa phương". Everything else (the groups, `MyClinicCard(emergency: true)`, the sources card) stays in the same order.
- The button shows both on the pushed route and in the Công cụ > Cần khám tab.
- Acceptance: widget tests (inside a `ProviderScope`, with a fake `GuideActions.debugLauncher`) cover these cases. `emergency-call-115` is above the "Trong thai kỳ" group (compare the rects). A tap launches exactly `tel:115`. A failing launcher shows the snackbar. The contrast of the button text against its background is at least 4.5:1 under `AppTheme.lightColorScheme` and `AppTheme.darkColorScheme`. No overflow at 360x640 at text scale 1.5. The Phase 19 tests for this screen still pass.

### Task 20.8: Delete-All-Data and Privacy Text
- `_deleteAllDataAndRestart` also removes `AppConstants.kickSessionsKey` and `AppConstants.contractionsKey` and calls `resetLocal()` on `kickCounterProvider` and `contractionProvider`. The first delete dialog text adds "lịch sử đếm cử động thai và cơn co" to the list.
- Section 1 of `privacy_policy_screen.dart` and `_showLocalDataExplanation` in `settings_screen.dart` add "lịch sử đếm cử động thai, cơn co" to the list of data stored on the device. No other legal text changes.
- Acceptance: code review shows both keys removed and both notifiers reset. If the removal is moved into a testable helper, a unit test checks that both keys are gone after it runs. `test/legal_screens_test.dart` still passes. Checked on device in step 11.

### Task 20.9: Tests and Verification
- New `test/counter_tools_test.dart` with the unit and widget tests from 20.1-20.7 (inline fixtures, `SharedPreferences.setMockInitialValues`, no Hive, a fixed `now` passed into the pure helpers, `GuideActions.debugLauncher` reset in `tearDown`). All existing tests (243) still pass.
- Run `dart format` on changed files, `flutter analyze` (0 errors / 0 warnings, pre-existing infos only), `flutter test` and `flutter build apk --debug`. Content build/validate is not needed (no generator changes).
- Acceptance: all commands pass and the results are recorded in the Verification Log.

### On-device test plan (emulator-5554, `adb install -r`, data kept, pregnancy mode)
1. Công cụ: the tabs are Dinh dưỡng / Lịch hẹn / Bộ đếm / Cần khám, and the hospital icon is still in the AppBar. "Bộ đếm" shows two cards, "Đếm cử động thai" and "Đếm cơn co", with "Thường bắt đầu theo dõi từ khoảng tuần 28" on the first.
2. Open "Đếm cử động thai": the intro text, "Bắt đầu đếm", the "Khi nào cần đi khám" card with "Từ tuần 28, để ý cử động thai mỗi ngày..." and the empty history "Chưa có lượt đếm nào." Tap "Xem dấu hiệu cần đi khám": the emergency screen opens. Go back.
3. Tap "Bắt đầu đếm": the timer counts up every second. Tap "Bé đạp" 12 times: the count is 12 (with a light vibration if the emulator supports it). After the 10th tap, "Đã đếm 10 cử động sau ..." appears. "Hoàn tác" twice gives 10 and the line stays; once more gives 9 and the line goes away.
4. With the session running, press Home, wait about 1 minute and come back: the timer includes the time away. Force-stop the app and reopen Công cụ > Bộ đếm: the card says "Đang đếm..." and the screen shows the same count and the correct elapsed time.
5. Tap "Kết thúc": a history row "<date time> · 9 cử động · X phút" appears at the top and "Bắt đầu đếm" is back. Start and stop a session with no taps: no row is added. Delete a row (confirm): it disappears. The "Lần gần nhất" subtitle in Bộ đếm matches the newest row.
6. Open "Đếm cơn co": "Bắt đầu cơn co", the "Khi nào cần đến viện" card with the 5-1-1 text from content, the "Khi nào đến viện" text and the "dưới 37 tuần..." line, and the empty history. Tap "Bắt đầu cơn co": the label becomes "Kết thúc cơn co" with a running mm:ss. After about 20 s, tap it again: a history row with "Dài 00:2x" and "Cách —". Wait about 40 s and record a second one: it shows "Cách 01:0x", and "Từ cơn trước" counts up while idle. The summary shows "2 cơn trong 1 giờ qua". No 5-1-1 hint is shown.
7. The 5-1-1 hint cannot be produced by hand in a short test. Either seed prefs with a 13-entry `contraction_log` (60 s every 5 min, ending now) through `adb shell run-as` on the debug build, or record this step as covered by the widget test. If seeded: the hint "Cơn co có vẻ theo mẫu 5-1-1" appears with "Gọi 115" (the dialer opens with 115 and no call is placed) and the clinic card ("Gọi" for the saved clinic, or "Tìm bệnh viện gần tôi" opening Maps).
8. Force-stop during a running contraction and reopen: it is still running with the right duration. Delete a contraction row (confirm), then use "Xóa lịch sử" (confirm): the list becomes empty.
9. Cần khám (the Công cụ tab, and Hôm nay > emergency card): the red "Gọi 115 (cấp cứu)" button sits right under the red header, above "Trong thai kỳ". A tap opens the dialer with 115 and does not place a call. The clinic card and the sources card are still at the bottom. "Bạn nên làm gì?" says "hãy gọi 115 hoặc số cấp cứu tại địa phương".
10. Large font (scale 1.5) and dark mode: the Công cụ tabs scroll and are not clipped. The counter button, timers, history rows, hint card and 115 button have no overflow and are readable. Switch to pre-pregnancy mode: Công cụ has 3 tabs and no "Bộ đếm", and the emergency screen still has "Gọi 115". Switch back: the kick and contraction history is still there.
11. Last (it wipes the emulator data; re-create the test pregnancy afterwards): Cài đặt > "Xóa toàn bộ dữ liệu". The dialog lists "lịch sử đếm cử động thai và cơn co". After onboarding, both tools show an empty history and no active session. Logcat has no Flutter exceptions, and in particular no timer or "setState() called after dispose()" errors during steps 2-10.

Required automated tests: `test/counter_tools_test.dart` covers `KickSession` (add, undo, tenth kick, elapsed, JSON); `KickCounterService` decode, the cap and the notifier (one active session, empty sessions discarded, reset); `Contraction` JSON; `ContractionService` intervals, `summarize`, `matches511` (the positive case, the 3 negative cases and the ignored active one), the cap and the notifier; `formatClock`/`formatMinutes`; `ToolGuidance` with the bundled daily tips and the fallback; the `KickCounterScreen` and `ContractionTimerScreen` flows, restore from prefs, the 5-1-1 hint and the 115 launch with a fake launcher, no overflow at 360 dp / scale 1.5 and no pending timers; `CounterToolsScreen` navigation; and the `EmergencyWarningScreen` 115 button placement, `tel:115`, the failure snackbar and contrast. All existing tests still pass.

### Results (round 1)
- 20.1 Result: done. `KickSession` (immutable; `fromJson` returns null without `startedAt`), `KickCounterService` under `kick_sessions` (newest first, one active + newest 100 completed) and `KickCounterNotifier` (stop at 0 discards the session; injectable `now` for tests). `duration_format.dart` gives "00:00" / "01:05" / "1:02:03" and "dưới 1 phút" / "25 phút" / "1 giờ 5 phút".
- 20.2 Result: done. `Contraction` and `ContractionService` under `contraction_log` (oldest first, cap 300; an end before the start is skipped). `intervalBefore`, `summarize` (last 60 min) and `matches511` with named constants; a running contraction is ignored. Dev note: `matches511` does not depend on the current time, so an old 5-1-1 run keeps the hint until a newer contraction breaks the run; a recency check can be added later.
- 20.3 Result: done. `ToolGuidance` reads the 3 titled tips from `dailyTipsPack` with fallbacks; `ToolGuidanceCard` shows the disclaimer and "Xem dấu hiệu cần đi khám". The bundled `daily_tips.json` test finds all 3 titles.
- 20.4 Result: needs fix (P20-R1-01). The kick counter flow (10-kick line, undo, background time, restore after force-stop, history delete) passes on device, but "Kết thúc" (`kick-stop`, unstyled `FilledButton.tonalIcon`) is nearly unreadable in dark mode.
- 20.5 Result: done. Toggle, "Từ cơn trước", the summary, Dài/Cách rows (a gap over 2 h shows "Cách —"), history by day, the seeded 5-1-1 hint with "Gọi 115" opening the dialer and the clinic card all pass on device. "Xóa lịch sử" keeps a running entry.
- 20.6 Result: done. `CounterToolsScreen` with `tools-kick` / `tools-contraction`, `NavigationHelper.toKickCounter` / `toContractionTimer`; Công cụ has 4 tabs in pregnancy mode and 3 in pre-pregnancy mode, scrollable and not clipped at scale 1.5 (this also resolves P18-R2-01 for this TabBar). The tab layout is checked on device only (MainNavigation needs Hive).
- 20.7 Result: done. The red "Gọi 115 (cấp cứu)" button sits under the header and above "Trong thai kỳ" and opens the dialer with 115 from both entry points; contrast tests pass in light and dark.
- 20.8 Result: done. Code review: `settings_screen.dart` removes `kickSessionsKey` and `contractionsKey` and calls both `resetLocal()`; the dialog, privacy policy section 1 and `_showLocalDataExplanation` mention the counter histories. Step 11 was checked by code review and the dialog text only (dialog cancelled).
- 20.9 Result: done. `test/counter_tools_test.dart` has 46 tests; the suite passes 289/289, analyze has 0 errors/0 warnings (16 pre-existing infos), and the debug APK builds.

### Test round 1 (2026-10-29)
- Tester summary: QA re-ran `flutter test` (289/289) and installed the debug APK on emulator-5554 with `adb install -r` (data kept). Steps 1-10 passed, including the 5-1-1 hint seeded with `run-as` (13 x 65 s every 5 min), restore after force-stop for both tools, the 115 button from both entry points, scale 1.5 and the mode switch keeping history. Step 11 was checked by code review and the dialog text only. The clinic card "Gọi" was not tested (no clinic saved). Logcat was clean, and device state was restored.
- Accepted P20-R1-01 (major): in dark mode the kick counter "Kết thúc" (`kick-stop`, `FilledButton.tonalIcon` in `kick_counter_screen.dart` ~214) uses the stock `secondaryContainer`/`onSecondaryContainer` and is nearly unreadable (same root cause as P19-R1-01). Fix: add a shared `AppTheme.tonalButtonStyle(ColorScheme)` (primaryTint background, onSurface foreground), use it for `kick-stop` and in `my_clinic_card.dart`, and add light/dark contrast widget tests (at least 4.5:1).
- Verdict: fix.

### Results (round 2)
- 20.1-20.3, 20.5-20.8 Result: done (unchanged since round 1); regression on device passed for contraction start/stop/delete and the emergency 115 button.
- 20.4 Result: done. P20-R1-01 is fixed: `kick-stop` uses `AppTheme.tonalButtonStyle` and is readable in dark and light mode. `my_clinic_card.dart` now uses the same helper; no other tonal buttons exist in `lib/`.
- 20.9 Result: done. 2 new contrast tests (kick-stop, light and dark). The suite passes 291/291, analyze has 0 errors/0 warnings (16 pre-existing infos), and the debug APK builds.

### Test round 2 (2026-10-29)
- Tester summary: QA re-ran `flutter test` (291/291) and `flutter build apk --debug`, installed with `adb install -r` (data kept). P20-R1-01 is verified fixed in dark and light mode, and the MyClinicCard tonal buttons match. Kick history add/delete, contraction start/stop/delete, "Gọi 115" opening the dialer and Hôm nay in dark mode pass. Logcat was clean; test data was removed and device state was restored.
- Rejected P20-R2-01 (minor): white text on the pink primary buttons ("Bắt đầu đếm", default `FilledButton`, about 2:1) and pink-on-white outlined "Hoàn tác" in light mode have low contrast, and "Bắt đầu đếm" does not match "Bắt đầu cơn co" (dark text). This is an app-wide theme issue (`onPrimary` white), not a regression. Moved to Known issues, deferred to Phase 22.
- Rejected P20-R2-02 (minor): the Công cụ tabs share one scroll offset (`_CollapsibleTabScaffold` in `main_navigation.dart` uses `NestedScrollView` around a `TabBarView`), so Bộ đếm can open scrolled past its cards. Pre-existing layout. Moved to Known issues, deferred to Phase 22.
- Verdict: pass. Phase 20 completed.

## Phase 21: Bump Photo Journal, Shareable Milestone Card and Health Diary PDF (B10 part 2)
Status: Completed
Scope: FEATURE_BRAINSTORM.md B10 part 2 / FEATURE_REVIEW.md "P1, đợt b", activated by the user (Phases 14-21). There are three parts. (1) "Nhật ký ảnh bụng bầu": the user adds one or more photos to a pregnancy week (camera or gallery through `image_picker`), sees a gallery grouped by week, opens a photo full screen and deletes it. Photos are copied into the app documents directory and never leave the device unless the user shares them. (2) "Thẻ cột mốc": from a week page, the user previews a card "Tuần X – bé to bằng <sizeCompare>", which is rendered to a PNG and shared through `share_plus`. (3) "Xuất PDF cho bác sĩ": the user picks a date range and the app builds a PDF of the health diary (date, weight, blood pressure, symptoms, notes) with an embedded Vietnamese font and shares it through `share_plus`. Photos, metadata and generated files are removed by delete-all-data. The PDF and the card only show what the user recorded or what the content says; they never label values as normal or abnormal. Out of scope: the home-screen widget (deferred, see "Proposed phases"), putting a bump photo on the milestone card, ultrasound-specific fields, cloud backup/sync, `printing` preview, editing or rotating photos, saving to the system gallery, content/JSON or generator changes, Hive schema changes, Hôm nay changes.
Grounding (verified 2026-10-29 on `feature/phase-20`, Flutter 3.41.6 / Dart 3.11.4):
- Packages: `image_picker: ^1.1.2` is already a direct dependency (locked 1.2.0, `image_picker_android` 0.8.13+1, `image_picker_ios` 0.8.13) but is not used anywhere in `lib/`. `path_provider` 2.1.5 is only transitive. `share_plus` and `pdf` are not present. No `printing`. No `assets/fonts/` folder; the app font is Poppins through `google_fonts` (runtime fetch), so it cannot be relied on offline for the card or the PDF.
- Health diary data: `HealthLogModel` (`lib/core/models/health_log_model.dart`, Hive typeId 1): `date`, `weight` (kg, double?), `systolicBP` / `diastolicBP` (int?), `mood` (String?), `symptoms` (List<String>? of Vietnamese labels such as "Buồn nôn", "Đau lưng"), `notes` (String?). `DatabaseService.getAllHealthLogs()` returns newest first. `DatabaseService.getHealthLogsByDateRange` uses exclusive `isAfter`/`isBefore` and is not reused (left unchanged). `health_log_list.dart` formats weight as `toStringAsFixed(1) kg` and BP as `sys/dia`.
- `HealthDiaryScreen` (`lib/features/health_diary/screens/health_diary_screen.dart`) is pushed with an AppBar (`NavigationHelper` ~31) and embedded without one (`showAppBar: false`) in both "Sức khỏe" tabs of `main_navigation.dart` (~116/120), so the export entry must live in the body, not only in AppBar actions.
- Week data: `WeekDetail` (`lib/core/models/week_detail_model.dart`) has `week`, `sizeCompare` (e.g. "hạt lạc (đậu phộng)", "củ khoai lang"; null for early weeks such as 0), `lengthLabel` / `weightLabel` getters, `reviewStatus`. `WeekDetailScreen` (`lib/features/tracking/screens/week_detail_screen.dart`) is a `StatefulWidget` with a `PageView` of weeks 0-42, AppBar `Tuần $_week`, no actions, and test overrides `weeks` / `sources`. `PregnancyModel` has `dueDate`, `motherName`, `currentWeekAt(now)`. `TrackingScreen` lists cards (`BabyDevelopmentCard`, `MotherChangesCard`, `WeeklyTipsCard`, `WeightGainChart`, milestones).
- Delete-all-data is `_deleteAllDataAndRestart` in `settings_screen.dart` (~465), which removes prefs keys and calls `resetLocal()` on the notifiers; the first dialog (~432) and `_showLocalDataExplanation` (~412) list the stored data. `privacy_policy_screen.dart` section 1 lists the stored data too.
- Permissions: `ios/Runner/Info.plist` already has `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` and `NSPhotoLibraryAddUsageDescription` with generic Vietnamese text. `AndroidManifest.xml` has no CAMERA / READ_MEDIA_IMAGES permission and no `IMAGE_CAPTURE` query. minSdk 26.
- Storage decision: photo metadata as SharedPreferences JSON (same pattern as `KickCounterService` / `MyClinicService`: `decode` never throws, `resetLocal()`), image files under `<applicationDocumentsDirectory>/bump_photos/`. Only the file name is stored, never the absolute path, because the iOS container path changes between installs/updates.

### Task 21.1: Packages, Font and Platform Setup
- Add direct dependencies with `flutter pub add share_plus pdf path_provider`, accepting the versions the solver picks for Flutter 3.41.6 (expected `share_plus` >= 11 with the `SharePlus.instance.share(ShareParams(...))` API, `pdf` 3.11.x, `path_provider` ^2.1.5). Record the resolved versions in this section. Do not add `printing`. Keep `image_picker` as is.
- Bundle Be Vietnam Pro static TTFs (`assets/fonts/BeVietnamPro-Regular.ttf`, `assets/fonts/BeVietnamPro-Bold.ttf`, from google/fonts `ofl/bevietnampro`) with its `assets/fonts/OFL.txt`. Declare a `fonts:` family `BeVietnamPro` in `pubspec.yaml` and add `assets/fonts/` to the asset list (the PDF loads the TTF bytes through `rootBundle`). Mention the font and licence in the "Giới thiệu"/references screen only if such a licence list already exists; otherwise `OFL.txt` in the asset folder is enough (Flutter's `LicenseRegistry` entry is optional).
- iOS `Info.plist`: replace the camera and photo-library strings with specific Vietnamese text: camera "MomCare+ dùng camera để bạn chụp ảnh bụng bầu cho nhật ký ảnh. Ảnh chỉ được lưu trên thiết bị này.", photo library "MomCare+ cần truy cập thư viện ảnh để bạn chọn ảnh bụng bầu cho nhật ký ảnh. Ảnh được sao chép và lưu trên thiết bị này.", add-only "MomCare+ chỉ lưu ảnh khi bạn chọn lưu thẻ cột mốc." Do not touch other keys.
- Android: do NOT declare `android.permission.CAMERA` (image_picker uses the `IMAGE_CAPTURE` intent; declaring CAMERA without granting it makes that intent fail) and do not declare READ_MEDIA_IMAGES (the Android photo picker needs none). Add `<queries><intent><action android:name="android.media.action.IMAGE_CAPTURE"/></intent></queries>` next to the existing queries. Android has no permission rationale strings; the Vietnamese in-app messages are in Task 21.3.
- Acceptance: `flutter pub get` and `flutter build apk --debug` pass; `pubspec.lock` contains the three packages; a unit test loads `assets/fonts/BeVietnamPro-Regular.ttf` from disk and checks it is a non-empty TTF (first 4 bytes `00 01 00 00` or `true`), and `assets/fonts/OFL.txt` exists; `Info.plist` review shows the three new strings; the manifest has no CAMERA permission.

### Task 21.2: Bump Photo Model and Storage (pure logic + files)
- New `lib/core/models/bump_photo.dart`: `BumpPhoto {id, week (0-42), fileName, addedAt, DateTime? takenAt}` with `toJson` / `fromJson` (returns null on invalid entries: missing id/fileName, week out of range, bad date).
- New `lib/core/services/bump_photo_service.dart` with `AppConstants.bumpPhotosKey = 'bump_photos'` and folder name `bump_photos`. Static `decode` (never throws, skips invalid entries, sorted by week desc then `addedAt` desc), `encode`, `groupByWeek(List<BumpPhoto>) -> List<MapEntry<int, List<BumpPhoto>>>` (week desc). Injectable `static Future<Directory> Function() debugDocumentsDir` (default `getApplicationDocumentsDirectory`), `Future<File> fileFor(BumpPhoto)`.
- `BumpPhotoNotifier extends StateNotifier<List<BumpPhoto>>` + `bumpPhotoProvider`: `ready`, `addFiles(int week, List<XFile> files)` copies each file to `<docs>/bump_photos/<uuid>.<ext>` (`.jpg` default; keep `.png`/`.heic`/`.webp` extensions) and stores the metadata; a file that fails to copy is skipped and reported in the returned count; `delete(BumpPhoto)` deletes the file (a missing file is not an error) and the entry; `resetLocal()` clears state. Static `clearAll()` removes the prefs key and deletes the whole `bump_photos` folder.
- Acceptance: unit tests with a temp directory from `Directory.systemTemp.createTemp` as `debugDocumentsDir` and `SharedPreferences.setMockInitialValues`: JSON round-trip; corrupt JSON and invalid entries give an empty/filtered list without exceptions; `addFiles(20, [two XFiles])` creates two files under `bump_photos/` and two entries with week 20; `groupByWeek` orders weeks desc; `delete` removes file and entry; deleting an entry whose file is already gone succeeds; `clearAll()` removes the key and the folder; a fresh notifier reloads entries from prefs.

### Task 21.3: "Nhật ký ảnh bụng bầu" Screen
- New `lib/features/bump_journal/screens/bump_journal_screen.dart`: `BumpJournalScreen({int? initialWeek})` (AppBar "Nhật ký ảnh bụng bầu"), a `ConsumerStatefulWidget` reading `bumpPhotoProvider`. Default week = `initialWeek` ?? active pregnancy `currentWeekAt(DateTime.now())` (via `DatabaseService.getActivePregnancy()` in try/catch) clamped to 0-42, else 0; a `@visibleForTesting` override avoids Hive in tests.
- Top: a week selector row ("Tuần X" with chevrons, key `bump-week`) and two buttons, "Chụp ảnh" (`bump-camera`, `ImageSource.camera`, `imageQuality: 85`, `maxWidth: 2048`) and "Chọn từ thư viện" (`bump-gallery`, `pickMultiImage` with the same limits). Picking calls `addFiles(selectedWeek, files)`; a snackbar "Đã thêm N ảnh vào tuần X". Cancelling does nothing. A `PlatformException` (e.g. `camera_access_denied`, `photo_access_denied`) shows "Chưa có quyền dùng camera/thư viện ảnh. Bạn có thể bật quyền trong Cài đặt của máy." Other errors show "Không thêm được ảnh. Vui lòng thử lại." On Android, call `retrieveLostData()` once on open and add any recovered files to the selected week.
- The picker is injectable (`@visibleForTesting static ImagePicker Function()? debugPicker` or a small `BumpImageSource` interface) so widget tests use a fake.
- Gallery: one section per week ("Tuần X · N ảnh", week desc) with a 3-column grid of `Image.file(cacheWidth: 300, fit: cover)`; a missing/corrupt file shows a `Icons.broken_image` placeholder, never an exception. Empty state: "Chưa có ảnh nào. Chụp hoặc chọn ảnh để lưu lại hành trình của mẹ." plus the line "Ảnh chỉ lưu trên thiết bị này."
- Tap a thumbnail -> `BumpPhotoViewer` (full screen, `InteractiveViewer`, title "Tuần X · dd/MM/yyyy", actions "Xóa ảnh" (`bump-delete`, confirm with `confirmToolDelete` from `lib/features/tools/widgets/tool_confirm_dialog.dart`) and "Chia sẻ" (`bump-share`, shares the file through `share_plus`)).
- Entry points: a card "Nhật ký ảnh bụng bầu" (`tracking-bump-journal`, subtitle "N ảnh" or "Lưu ảnh bụng bầu theo tuần") in `TrackingScreen` after `WeeklyTipsCard`; and `NavigationHelper.toBumpJournal(context, {int? week})`. Pregnancy mode only (TrackingScreen is pregnancy-only).
- Acceptance: widget tests (prefs mock, temp docs dir, fake picker returning XFiles of a tiny PNG written in the test): empty state text shown; fake gallery pick of 2 files at week 20 shows "Tuần 20 · 2 ảnh" and the snackbar; changing the week to 21 and picking 1 file shows two sections, 21 above 20; a fake `PlatformException('camera_access_denied')` shows the permission text; cancel (null/empty) changes nothing; tapping a thumbnail opens the viewer, delete after confirm removes it and returns to a grid with 1 photo; an entry whose file is missing shows the placeholder without exceptions; no overflow at 360x640 at text scale 1.0 and 1.5; tonal buttons use `AppTheme.tonalButtonStyle` (contrast >= 4.5:1 light/dark, as P20-R1-01).

### Task 21.4: Shareable Milestone Card
- New `lib/features/milestone_card/milestone_card_text.dart` (pure): `MilestoneCardText.headline(WeekDetail)` -> "Tuần X – bé to bằng <sizeCompare>" when `sizeCompare` is non-empty, otherwise "Tuần X thai kỳ của mẹ"; `details(WeekDetail)` -> "Dài khoảng <lengthLabel> · Nặng khoảng <weightLabel>" from whichever exist (empty when none). Week 0-2 (`sizeCompare` null) still gets a card with the fallback headline.
- New `lib/features/milestone_card/widgets/milestone_card.dart`: a fixed 1080x1350 logical-ratio card (rendered at 360x450 with `pixelRatio: 3`), fontFamily `BeVietnamPro`, the app pink tint background, a large week number, the headline, the details line, a small heart/baby icon and the footer "MomCare+". No medical advice, no draft note, no personal data (no name, no due date).
- New `lib/features/milestone_card/screens/milestone_card_screen.dart`: `MilestoneCardScreen({required WeekDetail detail})` (AppBar "Thẻ cột mốc"), preview inside a `RepaintBoundary`, button "Chia sẻ thẻ" (`milestone-share`). Pure helper `MilestoneCardRenderer.toPng(GlobalKey, {double pixelRatio = 3})` -> `Uint8List`; the PNG is written to `getTemporaryDirectory()/momcare_tuan_<X>.png` and shared with `SharePlus.instance.share(ShareParams(files: [XFile(path, mimeType: 'image/png')], text: headline))`. The share call goes through an injectable `@visibleForTesting static Future<void> Function(ShareParams)? debugShare`. Errors show "Không tạo được thẻ. Vui lòng thử lại."
- Entry point: `WeekDetailScreen` AppBar action `week-share-card` (`Icons.ios_share`, tooltip "Chia sẻ thẻ cột mốc") pushes `MilestoneCardScreen` for the current page's detail; and a `week-bump-photos` action (`Icons.photo_camera_outlined`, tooltip "Ảnh bụng bầu tuần này") pushes `BumpJournalScreen(initialWeek: _week)`.
- Acceptance: unit tests: headline for a fixture week 20 with `sizeCompare: 'quả chuối'` is exactly "Tuần 20 – bé to bằng quả chuối"; null/blank sizeCompare gives "Tuần 3 thai kỳ của mẹ"; details with only length, only weight, both, none. Widget tests: `WeekDetailScreen(weeks: fixture)` shows both actions and tapping `week-share-card` opens the card with the headline of the visible week (swipe to the next page and check again); in `MilestoneCardScreen`, `milestone-share` (inside `tester.runAsync`) calls the fake `debugShare` once with one file whose name ends `momcare_tuan_20.png` and whose bytes start with the PNG signature; a throwing `debugShare` shows the error snackbar; no overflow at 360x640 at text scale 1.0 and 1.5 (the card itself scales its text with `FittedBox`, so long `sizeCompare` such as "quả đu đủ to" stays inside).

### Task 21.5: Health Diary PDF Builder (pure logic)
- New `lib/features/health_diary/export/health_report.dart`: `HealthReportRange {from, to}` (date-only, inclusive) with presets `last30Days(now)`, `sincePregnancyStart(pregnancy, now)`; `filterLogs(List<HealthLogModel>, range)` -> logs whose `date` falls on a day in [from, to], oldest first (does not use `getHealthLogsByDateRange`); `rowsFor(logs)` -> `List<List<String>>` with columns "Ngày" (dd/MM/yyyy, `DateFormatter.formatDate`), "Cân nặng (kg)" (`toStringAsFixed(1)` or "—"), "Huyết áp (mmHg)" (`sys/dia` only when both exist, else "—"), "Triệu chứng" (joined with ", " or "—"), "Ghi chú" (trimmed or "—"); `summary(logs)` -> count, first/last weight and their dates, BP min/max systolic & diastolic (only numbers, no judgement).
- `HealthReportPdf.build({required List<HealthLogModel> logs, required HealthReportRange range, PregnancyModel? pregnancy, required DateTime generatedAt, required pw.Font regular, required pw.Font bold}) -> Future<Uint8List>`: A4 `pw.MultiPage`, title "Nhật ký sức khỏe – MomCare+", "Khoảng thời gian: dd/MM/yyyy – dd/MM/yyyy", "Ngày tạo: dd/MM/yyyy HH:mm", and when a pregnancy is given "Ngày dự sinh: dd/MM/yyyy · Tuổi thai khi tạo: tuần X" (+ "Họ tên: ..." when `motherName` is set); the summary block; a `pw.TableHelper.fromTextArray` table with a repeated header row; footer on every page "Dữ liệu do người dùng tự ghi trong ứng dụng MomCare+, không phải kết quả chẩn đoán. · Trang x/y". Fonts are loaded once via `rootBundle.load('assets/fonts/BeVietnamPro-*.ttf')` -> `pw.Font.ttf` in a `HealthReportFonts.load()` helper (tests load from disk).
- Acceptance: unit tests: `filterLogs` includes logs on the first and last day (00:00 and 23:59) and excludes the day before/after, and sorts ascending; `rowsFor` gives "65.5", "120/80", "—" for missing BP or a half BP (only systolic), joined symptoms and trimmed notes; `summary` on fixtures; `build` with fonts loaded from disk returns bytes starting with `%PDF`; 80 fixture logs produce more than one page (count `/Type /Page` objects or build the `pw.Document` and check its page count); a log with notes containing Vietnamese text ("Đau lưng nhẹ, ngủ ít") builds without exceptions (no Helvetica fallback warning: the theme sets the base/bold fonts).

### Task 21.6: "Xuất PDF cho bác sĩ" UI
- New `lib/features/health_diary/screens/health_report_export_screen.dart`: `HealthReportExportScreen({List<HealthLogModel>? logs, PregnancyModel? pregnancy, DateTime Function()? now})` (AppBar "Xuất PDF cho bác sĩ"; defaults read `DatabaseService` in try/catch). Range choices as `ChoiceChip`s: "30 ngày qua" (default), "Từ đầu thai kỳ" (only with a pregnancy), "Tùy chọn" (`showDateRangePicker`, last date today, Vietnamese locale already configured). Shows "Từ dd/MM/yyyy đến dd/MM/yyyy · N ghi nhận" and a short preview of the first 3 rows. Note text: "File PDF được tạo trên máy và chỉ được gửi đi khi bạn chọn ứng dụng để chia sẻ."
- Button "Tạo và chia sẻ PDF" (`health-export-share`): disabled with the text "Không có ghi nhận trong khoảng thời gian này." when N = 0; otherwise shows a progress indicator, builds the PDF, writes `getTemporaryDirectory()/momcare_nhat_ky_<yyyyMMdd>_<yyyyMMdd>.pdf` and shares it with `mimeType: 'application/pdf'` through the same injectable `debugShare` hook (a shared `lib/core/utils/share_helper.dart` used by 21.3, 21.4 and 21.6). Errors show "Không tạo được file PDF. Vui lòng thử lại."
- Entry point: in `HealthDiaryScreen`'s "Nhật ký" tab, an `OutlinedButton.icon` "Xuất PDF cho bác sĩ" (`health-export-pdf`, `Icons.picture_as_pdf_outlined`) above the list, visible when there is at least one log (works with and without `showAppBar`). `NavigationHelper.toHealthReportExport(context)`.
- Acceptance: widget tests (fixture logs, fixture pregnancy, fixed `now`, temp dir, fake `debugShare`, fonts from disk via an injectable loader): default shows "30 ngày qua" and the right count; selecting "Từ đầu thai kỳ" updates the count; no pregnancy hides that chip; an empty range disables the button and shows the empty text; tapping the button (in `runAsync`) calls `debugShare` once with one file named `momcare_nhat_ky_<from>_<to>.pdf` whose bytes start with `%PDF`; a throwing share shows the error snackbar; no overflow at 360x640 at text scale 1.0 and 1.5. `HealthDiaryScreen` with logs shows `health-export-pdf` (test only if it can be pumped without Hive; otherwise checked on device, step 9).

### Task 21.7: Delete-All-Data, Temp Files and Privacy Text
- `_deleteAllDataAndRestart` also awaits `BumpPhotoService.clearAll()` (removes `bump_photos` key and folder) and calls `ref.read(bumpPhotoProvider.notifier).resetLocal()`, and deletes the generated share files (`momcare_tuan_*.png`, `momcare_nhat_ky_*.pdf`) from the temporary directory through a `ShareHelper.clearTempFiles()`; failures are logged, never block the reset.
- The first delete dialog adds "ảnh bụng bầu" to the list. `_showLocalDataExplanation` and section 1 of `privacy_policy_screen.dart` add "ảnh bụng bầu" to the data stored on the device, plus one sentence: "Ảnh, thẻ cột mốc và file PDF chỉ rời khỏi thiết bị khi bạn tự chọn chia sẻ." No other legal text changes.
- Acceptance: unit test of `BumpPhotoService.clearAll()` and `ShareHelper.clearTempFiles()` against a temp dir (other files in the temp dir are kept); code review shows both are called and the notifier reset; `test/legal_screens_test.dart` still passes (update expected strings if it asserts the list); checked on device in step 12.

### Task 21.8: Tests and Verification
- New `test/bump_card_pdf_test.dart` with the unit and widget tests from 21.1-21.7 (inline fixtures, `SharedPreferences.setMockInitialValues`, temp directories, fake picker and `debugShare` reset in `tearDown`, no Hive, no real platform channels; `path_provider` calls go through the injected directory hooks). All existing tests (291) still pass.
- Run `dart format` on changed files, `flutter analyze` (0 errors / 0 warnings, pre-existing infos only), `flutter test` and `flutter build apk --debug`. Content build/validate is not needed (no generator changes). iOS is not built in this environment; the Info.plist change is review-only.
- Acceptance: all commands pass and the results, plus the resolved package versions, are recorded in the Verification Log.

### On-device test plan (emulator-5554, `adb install -r`, data kept, pregnancy mode)
Prep: push 3 test images to the emulator gallery: `adb push bump1.jpg bump2.jpg bump3.png /sdcard/Pictures/` then `adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/bump1.jpg` (repeat per file, or reboot the emulator). Make sure the health diary has at least 5 entries over more than 30 days, including one with only weight, one with BP 120/80, symptoms and Vietnamese notes.
1. Tuần thai: the card "Nhật ký ảnh bụng bầu" with "Lưu ảnh bụng bầu theo tuần". Tap it: the empty state text, "Ảnh chỉ lưu trên thiết bị này.", the week selector on the current week, and "Chụp ảnh" / "Chọn từ thư viện".
2. "Chọn từ thư viện": the Android photo picker opens with no permission dialog. Select 2 images: snackbar "Đã thêm 2 ảnh vào tuần X", section "Tuần X · 2 ảnh" with 2 thumbnails. Cancel the picker once: nothing changes, no error.
3. Change the week with the chevrons (e.g. X-1) and add 1 image: two sections, the newer week on top.
4. "Chụp ảnh": the emulator camera opens (virtual scene or webcam; this is enough). Take a photo and accept: it appears under the selected week. If the emulator has no camera app, record that and check that the app shows an error snackbar, not a crash.
5. Tap a thumbnail: full-screen viewer with "Tuần X · dd/MM/yyyy", pinch-zoom works. "Chia sẻ" opens the Android share sheet with the image (cancel it). "Xóa ảnh" -> confirm: back to the gallery with one fewer photo. Check with `adb shell run-as <applicationId> ls files/bump_photos` (or `app_flutter/bump_photos`) that the file is gone.
6. Force-stop and reopen: the photos and weeks are still there. Delete the source image from the emulator gallery: the photo still shows in the app (it was copied).
7. Week page (Tuần thai > a week, e.g. 20): the AppBar has the camera and share icons. Camera icon opens the journal on that week. Share icon opens "Thẻ cột mốc" with "Tuần 20 – bé to bằng <the week's sizeCompare>" and the length/weight line; swipe to week 3 (no size) and open again: "Tuần 3 thai kỳ của mẹ". Vietnamese diacritics render correctly.
8. "Chia sẻ thẻ": the share sheet shows a PNG preview; share to an app that accepts images (e.g. Messages/Drive, or "Copy") or cancel. The image matches the preview, is sharp, and contains no name or due date.
9. Sức khỏe tab > Nhật ký: "Xuất PDF cho bác sĩ" above the list. Open it: "30 ngày qua" is selected with the right count and preview rows. "Từ đầu thai kỳ" shows all entries. "Tùy chọn": pick a range with no entries: the button is disabled and "Không có ghi nhận trong khoảng thời gian này." is shown.
10. Pick a range with entries and tap "Tạo và chia sẻ PDF": the share sheet offers `momcare_nhat_ky_<from>_<to>.pdf`. Save it to Drive/Files (or `adb pull` from the temp dir via `run-as`) and open it in a PDF viewer: title, range, due date and week, summary, the table with all chosen entries in date order, "—" for missing values, Vietnamese text (including notes) with correct diacritics, footer with the disclaimer and "Trang 1/1". With many entries the header row repeats on page 2.
11. Large font (scale 1.5) and dark mode: the journal, viewer, card screen and export screen have no overflow and the buttons are readable. Pre-pregnancy mode: Sức khỏe still shows "Xuất PDF cho bác sĩ" (no "Từ đầu thai kỳ" chip); the journal entry is not shown.
12. Last (wipes data; re-create the test pregnancy afterwards): Cài đặt > "Xóa toàn bộ dữ liệu". The dialog lists "ảnh bụng bầu". After onboarding, the journal is empty, and `run-as ... ls` shows no `bump_photos` folder and no `momcare_*` files in the cache. Logcat has no Flutter exceptions during steps 1-11 (in particular no `PlatformException`, `setState() called after dispose()` or image decode errors).

Required automated tests: `test/bump_card_pdf_test.dart` covers the font asset check; `BumpPhoto` JSON; `BumpPhotoService` decode/groupByWeek/addFiles/delete/clearAll with a temp dir and the notifier reload; the `BumpJournalScreen` flows with a fake picker (gallery, week change, permission error, cancel, viewer delete, missing file); `MilestoneCardText` headline/details; `WeekDetailScreen` actions and `MilestoneCardScreen` share with a fake `debugShare` (PNG signature, file name, error snackbar); `HealthReport` `filterLogs`/`rowsFor`/`summary` and `HealthReportPdf.build` (`%PDF`, multi-page, Vietnamese text); `HealthReportExportScreen` presets, empty state, share and error; `ShareHelper.clearTempFiles`; no overflow at 360 dp / scale 1.5 for the new screens; contrast of new tonal buttons. All existing tests still pass.

### Results (round 1)
- 21.1 Result: done. Resolved versions: `share_plus` 13.3.1 (`SharePlus.instance.share(ShareParams)` API), `pdf` 3.12.0, `path_provider` 2.1.6; `image_picker` 1.2.0 unchanged; no `printing`. Be Vietnam Pro Regular/Bold TTF and `OFL.txt` (SIL Open Font License) from google/fonts `ofl/bevietnampro` are in `assets/fonts/` and declared as family `BeVietnamPro`. Approved deviation: constraint-only direct dependency `image: ">=4.0.0 <4.11.0"` (resolves to 4.10.2), because `image` 4.11.0 (picked through `pdf`) does not compile with `archive` 4.0.9, which `pdf` 3.12 allows; nothing in `lib/` imports `image`. Info.plist has the 3 new strings; the manifest has the `IMAGE_CAPTURE` query and no CAMERA / READ_MEDIA_IMAGES permission.
- 21.2 Result: done. `BumpPhoto`, `BumpPhotoService` (key `bump_photos`, files in `<docs>/bump_photos/<uuid>.<ext>`, only the file name stored) and `BumpPhotoNotifier`. On device the photos persist after force-stop and survive deleting the gallery original.
- 21.3 Result: done, except P21-R1-04 (viewer title cut to "Tuần 18 · 29/10/…" at scale 1.5). Photo picker and camera open with no permission prompt; week sections, snackbar, cancel, viewer share/delete and the missing-file placeholder pass on device.
- 21.4 Result: done. "Tuần 20 – bé to bằng quả chuối", the week 0 fallback and the 1080x1350 PNG (correct diacritics, no name or due date) pass on device.
- 21.5 Result: needs fix (P21-R1-02). The PDF (A4, embedded Be Vietnam Pro, summary, "—", disclaimer footer, "Trang 1/1") is correct, but the 62 pt "Ngày" column wraps most dates ("25/08/202" + "6").
- 21.6 Result: needs fix (P21-R1-03). Presets, counts, preview, empty range and the pre-pregnancy chip hiding pass; in dark mode the selected ChoiceChip label is unreadable (about 1.15:1).
- 21.7 Result: needs fix (P21-R1-01). Dialog and privacy texts list "ảnh bụng bầu"; `clearAll()`, `resetLocal()` and `clearTempFiles()` are called, but image_picker and share_plus copies in `cache/` survive.
- 21.8 Result: done. `test/bump_card_pdf_test.dart` has 41 tests; the suite passes 332/332, analyze has 0 errors/0 warnings (16 pre-existing infos), and the debug APK builds.

### Test round 1 (2026-10-29)
- Dev summary: all of 21.1-21.8 implemented as specified; `flutter test` 332/332 (41 new), analyze 0 errors/0 warnings, debug APK OK. Not automated: the `health-export-pdf` button in `HealthDiaryScreen` (needs Hive) and the "Tùy chọn" range picker path (left to device steps 9-10). iOS not built.
- Tester summary: QA re-ran `flutter test` (332/332) and installed the debug APK on emulator-5554 (Pixel 7, API 36) with `adb install -r` (data kept). Steps 1-11 passed apart from the issues below. Not verifiable on device: pinch-zoom (no multi-touch over adb) and the PDF header repeating on page 2 (covered by the 80-log unit test). Step 12 was checked by the dialog text, code review and unit tests only (delete-all not run). Logcat was clean; QA data was removed and device state restored.
- Accepted P21-R1-01 (major): image_picker leaves full copies of picked and captured photos in `cache/` (`<uuid>/` folders, `scaled_*`), and share_plus keeps copies in `cache/share_plus/` (including the health PDF). Neither photo delete nor delete-all removed them (`clearTempFiles` only scanned the top level for `momcare_*`).
- Accepted P21-R1-02 (minor): the PDF "Ngày" column wraps the year.
- Accepted P21-R1-03 (minor), partly: the selected export chip is unreadable in dark mode; fix the chips locally. The date range picker in-range days have the same problem but come from the global dark theme; deferred to Phase 22.
- Accepted P21-R1-04 (minor): the viewer title loses the date at scale 1.5.
- Verdict: fix.

### Results (round 2)
- 21.1, 21.2, 21.4 Result: done (unchanged since round 1); regression on device passed.
- 21.3 Result: done. P21-R1-04 is fixed: the viewer title is two lines ("Tuần X" over dd/MM/yyyy) in a `FittedBox`, shown in full at scale 1.5.
- 21.5 Result: done. P21-R1-02 is fixed: `HealthReportPdf.dateColumnWidth` is 76 pt (worst-case date 61.6 pt bold); all dates are on one line on device.
- 21.6 Result: done. P21-R1-03 chip part is fixed: local chip style (selected `AppTheme.primaryTint` + onSurface label + primary border), readable in dark and light mode. The date range picker theme is unchanged (P21-R2-01, deferred).
- 21.7 Result: done. P21-R1-01 is fixed: `addFiles` deletes the image_picker temp copy and its `<uuid>/` folder and sweeps picker leftovers; `ShareHelper.share` deletes the generated `momcare_*` file after the sheet returns (also on error); delete-all `clearTempFiles` empties the app-owned temp dir recursively on Android/iOS (desktop: only `momcare_*` and `share_plus/`). On device `cache/` stays empty after gallery and camera picks. Limitation: share_plus keeps its copy of the last shared file in `cache/share_plus/` until the next share or delete-all.
- 21.8 Result: done. 12 net new tests (temp-dir clearing, picker source deletion and path guards, share cleanup, PDF date width, chip contrast, viewer title at 1.5); the suite passes 344/344, analyze has 0 errors/0 warnings (16 pre-existing infos), and the debug APK builds.

### Test round 2 (2026-10-29)
- Dev summary: fixed P21-R1-01 to P21-R1-04 as above; `flutter test` 344/344, analyze 0 errors/0 warnings, debug APK OK. Picker/share cache behaviour unit-tested on temp dirs.
- Tester summary: QA re-ran `flutter test` (344/344) and `flutter build apk --debug`, installed with `adb install -r` (data kept). P21-R1-01 is verified fixed on device (`cache/` empty after gallery and camera picks; `momcare_*` PDF/PNG gone after the share sheet returns; only the documented share_plus copy of the last shared file remains and is replaced on the next share). P21-R1-02, P21-R1-03 (chips) and P21-R1-04 are verified fixed. Regression (week actions, milestone card share, journal add/delete, Hôm nay, Công cụ tabs, kick counter, diary form) passed. Delete-all `clearTempFiles` was checked by code review and unit tests only. Logcat was clean; test data was removed and device state restored.
- Rejected P21-R2-01 (minor): in dark mode the "Tùy chọn" `showDateRangePicker` in-range day numbers are near-white on a light-pink band and practically unreadable. This comes from the global dark theme, not the Phase 21 scope. Moved to Known issues, deferred to Phase 22.
- Verdict: pass. Phase 21 completed.

## Phase 22: One-Colour Redesign, Light/Dark Contrast and App Icon

Status: In progress

Scope: the user asked to "choose ONE primary colour and redesign the UI/UX to be as easy to use as possible, paying attention to colours when switching light/dark, and create an app icon". This phase is a visual and layout redesign only: no new features, no behaviour changes, no Hive schema, content/JSON or generator changes, no Supabase/auth/analytics/ads/AI. It fixes P20-R2-01, P20-R2-02 and P21-R2-01, plus the font-scale 1.5 overflows already in Known issues (P18-R2-01, P19-R1-02).

Audit (2026-10-29, before Phase 22):
- `lib/core/theme/app_theme.dart` hand-builds `ColorScheme.light/dark` from pastel pink `#FF9A9E` with `onPrimary: Colors.white` (about 2:1, P20-R2-01) and `secondary: #FAD0C4` in both themes, which causes the unreadable dark date range band (P21-R2-01), the near-white dark NavigationBar indicator and the stock tonal buttons. `primaryTint()` / `tonalButtonStyle()` are local workarounds (used in 12 files). No `datePickerTheme`, `chipTheme`, `snackBarTheme`, `navigationBarTheme`, `filledButtonTheme`, `tabBarTheme` or `textButtonTheme`.
- Hard-coded colours in `lib/`: 28 `Color(0x..)` (20 in app_theme, 5 in onboarding_screen, 2 in milestone_card), about 310 `Colors.*` (grey 69, red 66, white 49, green 33, blue 29, orange 27, pink 9, purple 7, teal 6, others 9) across 45 files; top files: health_charts_card 33, pre_pregnancy_home_screen 30, fertility_planner_screen 20, weight_gain_chart 18, appointment_card 16, tracking_screen 15, recipe_detail_screen 11, settings_screen 10. 95 `Theme.of(context).primaryColor` uses in 36 files (splash 7, tracking_screen 7, pregnancy_progress_card 7, appointments_screen 6). 9 `AppTheme.*Color` uses (kick_counter, milestone_card, milestone_status_chip, contraction_timer). 111 `withValues(alpha:)` tints. `ChipColors` and `FoodModel` verdict colours use raw green/orange/red.
- Fonts: `google_fonts` Poppins is fetched at runtime (26 calls in app_theme only), so an offline first launch falls back to the system font; Poppins also stacks Vietnamese diacritics poorly. Be Vietnam Pro Regular/Bold TTF + OFL are already bundled in `assets/fonts/` (Phase 21 PDF).
- Layout: `_CollapsibleTabScaffold` (main_navigation.dart) puts a `TabBarView` inside a `NestedScrollView`, so all tabs share one outer scroll offset (P20-R2-02). Hôm nay (pregnancy) is a flat stack of 11 cards: greeting, day card, thai giáo, tip, week todo, next milestone, progress, habits, emergency, clinic, quick actions, appointments; the emergency card is 9th. Pre-pregnancy Hôm nay puts emergency + clinic first, before the cycle content. 31 `AppBar(` with mixed styles. 16 files with SnackBars, 6 date/time picker calls.
- Native: `android:label="momcare"`, iOS `CFBundleDisplayName` "Momcare", default Flutter launcher icons, white `launch_background.xml` (Store TODO in Phase 12). Splash subtitle is English (Known issues).

Decisions:
- Primary seed: `#A8577E` ("hồng mận", dusty plum-rose). It keeps the app's familiar pink identity but is deep enough that white text passes AA on the light primary, and dark tone-80 primary carries dark text. Its hue (about 330°) is about 55° away from the M3 error red (about 25°) and much less saturated, so warning/115 red stays clearly distinct. Calm and warm, not a "medical cold" blue, and not alarm-red.
- Schemes: `ColorScheme.fromSeed(seedColor: Color(0xFFA8577E), brightness: light|dark, dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot)`; no hand-tuned overrides of generated roles. Expected roles (approximate, the generated values are the source of truth and are snapshotted by a test): light primary ~#8B4A69 / onPrimary #FFFFFF / primaryContainer ~#FFD8E8 / onPrimaryContainer ~#6F3351, secondary ~#725763, tertiary ~#7F5539 (warm peach), surface ~#FFF8F8, onSurface ~#22191D, outline ~#837379, error #BA1A1A / onError #FFFFFF / errorContainer #FFDAD6; dark primary ~#FFB0D0 / onPrimary ~#541D3A / primaryContainer ~#6F3351 / onPrimaryContainer ~#FFD8E8, surface ~#191114, onSurface ~#EFDFE3, error #FFB4AB / onError #690005 / errorContainer #93000A.
- Semantic tokens (`ThemeExtension<AppSemanticColors>`, light / dark): success #2E6B30 on #FFFFFF, container #C8EBC4 / on #0A2E0D | #8FD68C on #003A07, container #1E5221 / on #C8EBC4; warning #7A5900 on #FFFFFF, container #FFE08A / on #261A00 | #F2BF48 on #3F2E00, container #5B4300 / on #FFDF9E; danger = scheme error roles; info #1F5FA8 on #FFFFFF, container #D5E3FF / on #001B3C | #A8C8FF on #003060, container #1A4A80 / on #D5E3FF. Draft-content note = warningContainer/onWarningContainer with the info icon in onWarningContainer. Food verdict chips ok/limit/avoid = success/warning/danger containers with their on-colours plus an icon and a text label (never colour alone). 115 / emergency CTA = `FilledButton` error/onError. Charts use primary, tertiary, info, success.
- Contrast rule: every text pair >= 4.5:1, large text (>= 18 sp or 14 sp bold) and icons/borders of controls >= 3:1, in both themes; enforced by tests (22.9).
- Typography: Be Vietnam Pro bundled as the app font (`fontFamily: 'BeVietnamPro'` in pubspec `fonts:`), add Medium (500) and SemiBold (600) TTFs from the same OFL family so titles are not faux-bold; remove `google_fonts`. M3 2021 type scale with Be Vietnam Pro, body line height 1.5 and titles 1.3 for stacked diacritics; minimum on-screen size 12 sp; text colours only from scheme roles (onSurface, onSurfaceVariant).
- Tokens: spacing 4/8/12/16/24/32 (`AppSpacing.xs..xxl`), radius 8/12/16/28 (`AppRadius.sm/md/lg/xl`), cards elevation 0 on `surfaceContainerLow` with radius 16, dialogs/sheets radius 28, buttons stadium with min size 48x48 (`minimumSize: Size(64, 48)`), `materialTapTargetSize: padded`, IconButtons 48 dp, list rows >= 56 dp.

### Task 22.1: Seed Colour, Schemes, Semantic Tokens and Component Themes
- Rebuild `app_theme.dart` as `AppTheme.light()` / `AppTheme.dark()` from one `seedColor` constant via `ColorScheme.fromSeed(... DynamicSchemeVariant.tonalSpot)`; add `lib/core/theme/app_tokens.dart` (`AppSemanticColors` ThemeExtension with light/dark values above, `AppSpacing`, `AppRadius`) and a `context.semantic` accessor.
- Component themes derived only from the scheme: AppBar (surface, `scrolledUnderElevation` 3, start-aligned titleLarge), Card, FilledButton, OutlinedButton (outline side, primary text), TextButton, ElevatedButton (mapped to tonal look), Chip/ChoiceChip/FilterChip (selected secondaryContainer/onSecondaryContainer, unselected outline), NavigationBar (indicator secondaryContainer, icons onSecondaryContainer/onSurfaceVariant), TabBar, InputDecoration, SnackBar (inverseSurface/onInverseSurface, action inversePrimary), Dialog, BottomSheet, DatePicker (range band primaryContainer, in-range text onPrimaryContainer), TimePicker, Switch, ProgressIndicator, FAB, ListTile.
- Keep `primaryTint()` / `tonalButtonStyle()` as thin wrappers returning scheme roles (secondaryContainer / onSecondaryContainer) so existing call sites keep compiling; they are removed in 22.4. Remove `ChipColors` raw colours by pointing them at semantic tokens. `main.dart` uses the new getters; theme mode handling unchanged.
- Acceptance: app builds; `flutter test` passes; the only literal colours in `lib/core/theme/` are the seed and the semantic token values; light/dark schemes are generated from the same seed; default `FilledButton` text is >= 4.5:1 in both themes (P20-R2-01) and the dark date range in-range day text is >= 4.5:1 (P21-R2-01), checked by the 22.9 contrast test written first for these two cases.

### Task 22.2a: Migrate Hard-Coded Colours — Hôm nay, Emergency, Splash, Onboarding, Settings
- Files: `home/` screens and widgets (pre_pregnancy_home_screen, quick_actions_grid, pre_readiness_card, late_period_card, upcoming_appointments_card, pregnancy_progress_card, today_thai_giao_card, pregnant_switch_card), `emergency/` (screen + entry card: errorContainer/onErrorContainer, 115 button error/onError), `splash/`, `onboarding/` (5 page colours -> primaryContainer/tertiaryContainer/secondaryContainer), `settings/`, `references/draft_content_note.dart` (warningContainer), `main.dart` fallback screen.
- Replace `Colors.*`, `Color(0x..)`, `AppTheme.*Color` and `Theme.of(context).primaryColor` with `colorScheme` roles or semantic tokens; tints become container roles instead of `withValues(alpha:)` over primary/red.
- Acceptance: `grep` finds no `Colors.` (except `Colors.transparent`) / `Color(0x` / `.primaryColor` / `AppTheme.*Color` in these folders; the 22.9 guard test allow-list shrinks accordingly; light-mode EmergencyEntryCard is a clear red-tinted container (Known issue "muddy grey-mauve" closed); tests pass.

### Task 22.2b: Migrate Hard-Coded Colours — Tuần thai, Sức khỏe, Chu kỳ
- Files: `tracking/` (tracking_screen, week_detail_screen, weight_gain_chart, weekly_tips_card, baby_development_card, mother_changes_card), `health_diary/` (health_charts_card, health_log_list, health_stats_card, add_health_log_screen, screens), `fertility/` (fertility_planner_screen, add_period_screen). Chart lines/areas/grid/axis labels use primary/tertiary/info/outlineVariant/onSurfaceVariant; period/fertile/ovulation calendar markers use error/tertiary/primary containers with icon or label distinctions.
- Acceptance: same grep rule passes for these folders; charts and the cycle calendar are readable in dark mode (axis labels >= 4.5:1, series >= 3:1 against the card surface, verified by token test); tests pass.

### Task 22.2c: Migrate Hard-Coded Colours — Công cụ, Dinh dưỡng, Lịch hẹn, Cẩm nang, Bump Journal, Milestone Card
- Files: `tools/`, `nutrition/` (incl. `food_model.dart` verdict colour -> a verdict enum mapped to semantic tokens in the UI layer), `appointments/` (appointment_card, screens), `guide/`, `guides/` (milestone_status_chip), `bump_journal/`, `health_diary/screens/health_report_export_screen.dart`, `milestone_card/`. The shareable milestone card PNG keeps a fixed light palette (it is an exported image, not themed), defined once as named brand constants derived from the seed in `app_tokens.dart`.
- Acceptance: grep rule passes for all of `lib/features/` and `lib/core/models/`; the guard test allow-list contains only `app_tokens.dart`/`app_theme.dart`; kick counter "Bắt đầu đếm" and contraction "Bắt đầu cơn co" use the same filled style; "Hoàn tác" and "Kết thúc" have the same height; tests pass.

### Task 22.3: Bundled Be Vietnam Pro Typography, Remove google_fonts
- Add `BeVietnamPro-Medium.ttf` and `BeVietnamPro-SemiBold.ttf` (OFL, same upstream as the bundled files) to `assets/fonts/`; declare family `BeVietnamPro` (400/500/600/700) under `flutter: fonts:`; build the `TextTheme` from the M3 scale with that family, line heights as above; remove every `GoogleFonts` call and the `google_fonts` dependency. The Phase 21 PDF font loading stays unchanged.
- Remove per-widget `fontSize:` overrides (45 in 8 files) where a text-theme style fits; keep sizes only for the big counters (kick/contraction numbers, day hero number).
- Acceptance: `google_fonts` is gone from pubspec.yaml and lib; with networking disabled on a fresh install, all screens render in Be Vietnam Pro with correct stacked diacritics ("Ngày", "Đếm cử động", "Thai giáo hôm nay"); a widget test asserts `Theme.of(context).textTheme.bodyMedium!.fontFamily == 'BeVietnamPro'`; tests pass.

### Task 22.4: Shared Components (Card, Section Header, Empty State, AppBar)
- Add `lib/core/widgets/app_card.dart` (`AppCard`: optional leading icon + title + trailing action, body, padding 16, radius 16; variants `standard` (surfaceContainerLow), `hero` (primaryContainer/onPrimaryContainer), `alert` (errorContainer/onErrorContainer), `notice` (warningContainer)), `section_header.dart`, and `empty_state.dart` (`AppEmptyState`: icon in onSurfaceVariant, title, one-sentence message, optional existing action button).
- Use `AppEmptyState` for the existing empty texts (appointments, health diary, kick/contraction history, bump journal, cycles, food lookup no result, upcoming appointments card) with their current strings; use `AppCard` on all Hôm nay cards (pregnancy and pre-pregnancy) and tool guidance cards. Remove `primaryTint()` / `tonalButtonStyle()` and their 12 call sites (use `FilledButton.tonal` defaults).
- AppBars: every screen uses the theme AppBar with no local colour/elevation/centerTitle overrides; back button and actions are 48 dp; long Vietnamese titles ellipsize on one line.
- Splash: brand colours from the scheme (no `Colors.white` gradient) and the English subtitle replaced with Vietnamese "Người bạn đồng hành thai kỳ" (Known issue).
- Acceptance: no screen sets AppBar colours locally (grep `backgroundColor:` inside `AppBar(` = 0); widget tests render AppCard variants and AppEmptyState in light and dark and pass `textContrastGuideline` and `androidTapTargetGuideline`; tests pass.

### Task 22.5: Hôm nay Hierarchy and Always-Reachable Emergency
- Both modes: add an emergency `IconButton` (`Icons.emergency_outlined`/`health_and_safety`, colour error, tooltip "Dấu hiệu cần đi khám") to the Hôm nay AppBar that opens the existing `EmergencyWarningScreen` (with its "Gọi 115" button). It is visible without scrolling at any scroll position.
- Pregnancy order: compact one-line greeting ("Chào buổi chiều, An") -> hero `PregnancyDayCard` (day/week, progress bar, "Còn X tuần Y ngày" moved in from the greeting) -> time-bound actions (`NextMilestoneCard`, `UpcomingAppointmentsCard`) -> today content (`TodayThaiGiaoCard`, `TodayTipCard`, `WeekTodoCard`) -> `MaternalHabitsCard` -> `QuickActionsGrid` -> `EmergencyEntryCard` (alert variant) + `MyClinicCard` -> `PregnancyProgressCard` last. Pre-pregnancy order: greeting -> late-period card (if shown) -> fertile window / ovulation -> readiness -> early signs -> daily tips -> quick actions -> emergency + clinic -> "Tôi đã có thai". Same widgets, same conditions; only order and styling change.
- Fix the font-scale 1.5 overflows of `PregnancyProgressCard` (wrap the 'Hoàn thành / Dự sinh' row), `QuickActionsGrid` (intrinsic-height tiles), and the pre-pregnancy fertile-window / "Kỳ kinh tiếp theo" rows.
- Acceptance: widget test finds the AppBar emergency button on both Hôm nay screens and that tapping it pushes `EmergencyWarningScreen`; widget tests assert the card order by keys; at 360 dp with `textScaler 1.5` both Hôm nay screens build with no overflow errors; existing Hôm nay tests updated only for order, not behaviour; tests pass.

### Task 22.6: Per-Tab Scrolling in Tuần thai / Công cụ
- Replace `_CollapsibleTabScaffold`'s `NestedScrollView` with a `Scaffold` + `AppBar(bottom: TabBar)` so each `TabBarView` child owns its scroll position (`PageStorageKey` per tab). Both TabBars are `isScrollable: true`, `tabAlignment: TabAlignment.start`, label-only height <= 72 with icon, so labels never clip at font scale 1.5 (P18-R2-01). The bottom NavigationBar uses `labelBehavior: onlyShowSelected` only if "Cẩm nang" still wraps at 1.5 (prefer single-line labels with `maxLines: 1`).
- Acceptance: widget test scrolls "Cần khám" to the bottom, switches to "Bộ đếm" and finds its first card on screen at offset 0, and switching back restores "Cần khám" offset (P20-R2-02); at textScaler 1.5 every tab label is fully visible (no ellipsis, verified by finding the full text in the tab bar); tests pass.

### Task 22.7: Pickers, Chips, Snackbars and Dialogs in Dark Mode
- Remove local per-screen chip/date-picker fixes that are now covered by the theme (e.g. the Phase 21 export chip style) where the theme gives the same or better contrast; keep the Vietnamese 24h `MediaQuery` builders. Ensure `showDatePicker`, `showDateRangePicker`, `showTimePicker`, `SnackBar`, `AlertDialog`, `ModalBottomSheet` and `SegmentedButton` take all colours from the theme.
- Acceptance: widget tests open `showDateRangePicker` with a 5-day range and `showDatePicker` in the dark theme and assert in-range day text vs band, selected day text vs circle, and header text are >= 4.5:1 (P21-R2-01); selected and unselected ChoiceChip/FilterChip labels are >= 4.5:1 in both themes; tests pass.

### Task 22.8: App Icon, Launcher Assets, Native Splash Colour and Display Name
- Design (original vector, no text): rounded-square/adaptive background flat primary `#8B4A69` (light primary tone); foreground in white: a heart whose left lobe is the mother's head-and-shoulder curve wrapping a small solid circle (baby) inside the heart, built from 3-4 simple shapes with >= 6% stroke weight so it reads at 48 px. Foreground content stays inside the 66/108 dp adaptive safe zone. Monochrome version = same foreground silhouette, single colour, transparent background.
- Sources in `assets/branding/`: `app_icon.svg` (full, for iOS/legacy), `app_icon_foreground.svg`, `app_icon_monochrome.svg`, plus rendered `app_icon_1024.png` (no alpha), `app_icon_foreground_432.png`, `app_icon_monochrome_432.png`. Render without Python: in a fresh empty scratch dir run `npx --yes @resvg/resvg-js-cli` (or a tiny Node script using `@resvg/resvg-js` installed there) on the SVGs; record the command in PLAN.md. Fallback: a `flutter test` script that paints the same paths with `dart:ui` Canvas and writes PNGs.
- Add `flutter_launcher_icons` as a dev_dependency with config (`android: true`, `ios: true`, `remove_alpha_ios: true`, `adaptive_icon_background: "#8B4A69"`, `adaptive_icon_foreground`, `adaptive_icon_monochrome`) and run it to generate all `mipmap-*` densities, `mipmap-anydpi-v26/ic_launcher.xml` (with `<monochrome>`) and the iOS `AppIcon.appiconset`.
- Native splash: `launch_background.xml` background -> brand surface colour resource (`values/colors.xml` light, `values-night/colors.xml` dark) with no logo bitmap; Android 12+ `windowSplashScreenBackground` set to the same colours in `values-v31` / `values-night-v31`. Display name: Android `android:label="MomCare+"`, iOS `CFBundleDisplayName` "MomCare+" (Phase 12 Store TODO; trivially safe, bundle id unchanged).
- Acceptance: `flutter build apk --debug` passes; the APK's launcher shows the new icon (round and squircle masks) and, with Android 13+ themed icons on, the monochrome glyph; launcher label reads "MomCare+"; cold start shows no white flash in dark mode; iOS AppIcon set has every size listed in Contents.json with no alpha (checked by file listing, iOS not built).

### Task 22.9: Contrast, Token and Guard Tests
- `test/theme_contrast_test.dart`: WCAG contrast helper (relative luminance via `Color.computeLuminance`); for both themes assert >= 4.5:1 for primary/onPrimary, primaryContainer/onPrimaryContainer, secondaryContainer/onSecondaryContainer, tertiaryContainer/onTertiaryContainer, errorContainer/onErrorContainer, error/onError, surface/onSurface, surface/onSurfaceVariant, surfaceContainerLow/onSurface, inverseSurface/onInverseSurface, inverseSurface/inversePrimary, and every semantic pair (success/warning/info/danger + containers); >= 3:1 for outline vs surface, primary vs surface (icons), error vs surface; error vs primary hue distance >= 40°. Snapshot the generated primary/surface/error hex per theme so seed changes are deliberate.
- `test/theme_widgets_contrast_test.dart`: a test-only gallery (FilledButton, FilledButton.tonal, OutlinedButton, TextButton, ChoiceChip/FilterChip selected and unselected, Card with body/caption text, SnackBar with action, NavigationBar selected, TabBar, AppCard variants, AppEmptyState, draft note, food verdict chips, 115 button) pumped in light and dark at textScaler 1.0 and 1.5, `expectLater(tester, meetsGuideline(textContrastGuideline))` and `androidTapTargetGuideline`; plus the date picker cases from 22.7.
- `test/no_hardcoded_colors_test.dart`: scans `lib/**/*.dart` and fails on `Colors.` (except `Colors.transparent`), `Color(0x`, `.primaryColor` or `GoogleFonts` outside `lib/core/theme/`.
- Acceptance: all three files pass along with the existing suite; `flutter analyze` 0 errors/0 warnings; `flutter build apk --debug` passes.

### Out of Scope
- New features, new screens or new entry points other than the Hôm nay AppBar emergency shortcut to the existing screen; "follow system" theme mode or a colour picker; Material You dynamic colour; Chu kỳ calendar Vietnamese locale (separate Known issue); home-screen widget; iOS build/signing; store screenshots and listing graphics; changing the bundle id/package name; content, JSON, generator or Hive changes; reworking the PDF export look; Supabase/auth/analytics/ads/AI/wearables/expert chat.

### Verification and On-Device Test Plan (tester)
Build: `flutter test`, `flutter analyze`, `flutter build apk --debug`, `adb install -r` on emulator-5554 (Pixel 7, API 36), data kept. Repeat steps 2-12 in light and dark mode (Cài đặt > Giao diện), and steps 2-8 again at system font scale 1.5. Capture screenshots `p22_r1_*`.
1. Launcher: new icon on home screen and app drawer, label "MomCare+"; long-press shows the icon in round and squircle masks; enable Wallpaper & style > Themed icons and confirm the monochrome glyph; cold start shows the brand-coloured background with no white flash in dark mode.
2. Splash and onboarding (clear data on a second emulator or after delete-all-data at the end): colours from the new scheme, Vietnamese subtitle, Be Vietnam Pro diacritics correct, buttons >= 48 dp.
3. Hôm nay, pregnancy mode: order hero day card -> next milestone/appointments -> thai giáo/tip/week todo -> habits -> quick actions -> emergency/clinic -> progress; AppBar emergency button visible at top and after scrolling to the bottom, opens Dấu hiệu cần đi khám with a red "Gọi 115" (do not place the call); thai giáo "Đã làm" chip, reminder switch, draft note readable; no overflow at 1.5.
4. Hôm nay, pre-pregnancy mode (Cài đặt > Chế độ): order greeting -> late-period (if any) -> fertile window/ovulation -> readiness -> early signs -> tips -> quick actions -> emergency/clinic -> "Tôi đã có thai"; emergency AppBar button works; switch back to pregnancy mode.
5. Tuần thai: Thai kỳ tab (week header, baby/mother cards, weight chart axes readable), open a week detail and swipe, milestone card preview, bump journal (empty state + one photo then delete); Sức khỏe tab (diary list, charts, add log date picker); scroll Thai kỳ down, switch to Sức khỏe: it starts at the top.
6. Chu kỳ (pre-pregnancy): calendar markers distinguishable in both themes, add period date picker readable.
7. Cẩm nang: list, a guide with checklist, a warning guide, a timeline guide with vaccination dates; chips and source card readable.
8. Công cụ: every tab (Dinh dưỡng incl. "Bầu ăn được không?" search + verdict chips ok/limit/avoid + detail sheet; Lịch hẹn incl. empty state and add-appointment date/time picker; Bộ đếm kick counter "Bắt đầu đếm"/"Bé đạp"/"Hoàn tác"/"Kết thúc" and contraction timer, same button styles; Cần khám with "Gọi 115"); scroll Cần khám to the bottom then open Bộ đếm: it starts at the top (P20-R2-02); tabs not clipped at 1.5; find-hospital action.
9. Cài đặt: all rows, switches, Nơi khám của tôi editor ("Lưu" readable, P20-R2-01), privacy, disclaimer, references, delete-all-data dialog (cancel).
10. Health diary PDF export: preset chips selected/unselected readable; "Tùy chọn" date range picker in dark mode, in-range day numbers readable (P21-R2-01); snackbars readable.
11. Snackbars and dialogs: trigger one snackbar (e.g. save a log) and one confirm dialog in both themes.
12. Offline: turn on airplane mode, force-stop and relaunch; fonts unchanged (no fallback font), all screens render.
13. Logcat: no Flutter exceptions or RenderFlex overflow during the whole session. Restore device state (pregnancy mode, dark mode, no test data).

## Known issues (pre-existing, backlog)
- Chu kỳ calendar shows an English month header ('October 2026'), format button ('2 weeks') and weekday names; needs a Vietnamese locale/format labels. Found in Phase 14 test round 1 (P14-R1-04).
- `FlutterSecureStorage: Could not decrypt key` is logged at each launch (library startup check); data is unaffected. Found in Phase 14 test round 1.
- The old Tuần thai header rows (`tracking_screen.dart` ~164/210) and `weight_gain_chart.dart:79` overflow with Flutter's wide test font at 390px logical width; this was not seen on device at 1080x2400. Found in the Phase 14 dev round.
- Old Hôm nay widgets (`PregnancyProgressCard` rows ~21/70, `QuickActionsGrid` cards, `UpcomingAppointmentsCard` header) overflow with Flutter's wide test font at 360-390 dp. Phase 15 content widget tests run at 600 dp for this reason. Found in the Phase 15 dev round. They also overflow on device at font scale 1.5: the `PregnancyProgressCard` 'Hoàn thành / Dự sinh' row is RIGHT OVERFLOWED BY 71 px, and the `QuickActionsGrid` tiles 'Nhật ký sức khỏe', 'Công thức nấu ăn' and 'Dấu hiệu cần khám' are BOTTOM OVERFLOWED BY 12-13 px (Phase 19 test round 1, P19-R1-02).
- `MaternalHabitsCard` reminder time picker (`maternal_habits_card.dart:152`) likely has the same keyboard-mode 12h/24h parse issue as P15-R1-02 (typed morning hour saved as PM on 12-hour devices). Found in Phase 15 test round 1.
- ARB keys `dailyTip` / `dailyTipMessage` are unused since Phase 15 (left in place).
- The Hôm nay "Lịch hẹn sắp tới" card (`UpcomingAppointmentsCard`) keeps old content after an appointment is added or deleted, until the app restarts. It is a `StatelessWidget` with no Hive listener, built as `const UpcomingAppointmentsCard()` in `home_screen.dart`, so the `HiveBoxesListener` rebuild skips it. Possible fix: drop the `const` or make the card listen to the appointments box. Found in Phase 16 test round 1 (P16-R1-01).
- On pre-pregnancy Hôm nay, two rows overflow with Flutter's wide test font at 360 dp: the `_FertileWindowWidget` date row and the `_OvulationCountdownWidget` "Kỳ kinh tiếp theo" row (`pre_pregnancy_home_screen.dart`). This was not seen on the 1080-wide device, but it could happen on narrow screens with large text. Found in the Phase 17 round 2 dev round.
- The splash screen subtitle is in English ("Your Pregnancy Companion"). Found in Phase 17 test round 2.
- At font scale 1.5, the outer Công cụ tabs (`_ToolsTabScreen` `TabBar`, `lib/features/home/screens/main_navigation.dart` ~136) are clipped to "Dinh dưỡr" and "Cần khár", and the bottom nav "Cẩm nang" label wraps to two lines. Possible fix: `isScrollable: true` + `tabAlignment: TabAlignment.center`, as in P18-R1-01. Found in Phase 18 test round 2 (P18-R2-01).
- In light mode, `EmergencyEntryCard` (`lib/features/emergency/widgets/emergency_entry_card.dart`, red background at 6% alpha) looks muddy grey-mauve instead of a clear warning tint. This is cosmetic. Found in Phase 19 test round 2.
- Primary `FilledButton`s use white `onPrimary` text on the pink primary (about 2:1), e.g. kick counter "Bắt đầu đếm" and "Lưu" on Nơi khám của tôi; in light mode the outlined "Hoàn tác" (pink on white) is also low. "Bắt đầu đếm" does not match "Bắt đầu cơn co" (dark text), and "Hoàn tác" is taller than "Kết thúc" in the same row. App-wide theme issue, deferred to Phase 22. Found in Phase 20 test round 2 (P20-R2-01).
- The Công cụ tabs share one scroll offset: `_CollapsibleTabScaffold` (`lib/features/home/screens/main_navigation.dart`) wraps a `TabBarView` in a `NestedScrollView` without per-tab overlap handling, so after scrolling Cần khám to the bottom, Bộ đếm opens scrolled past its cards. Deferred to Phase 22. Found in Phase 20 test round 2 (P20-R2-02).
- In dark mode the `showDateRangePicker` (export screen "Tùy chọn") draws the in-range day numbers near-white on a light-pink band (about #FAD0C4), which is practically unreadable; the header, start/end circles and month labels are fine. Comes from the global dark theme (no `datePickerTheme` / range colours). Possible local fix: a `builder` Theme with `rangeSelectionBackgroundColor` / `onSurface`. Deferred to Phase 22. Found in Phase 21 test round 2 (P21-R2-01, remaining part of P21-R1-03).

## Proposed Phases 19-20 (not active)
Details in `FEATURE_BRAINSTORM.md`. Do not start until the user activates a phase.
- Phase 19: activated, see "## Phase 19" above.
- Phase 20: activated (B10 part 1: kick counter, contraction timer, 115 button), see "## Phase 20" above. The rest of B10 is in Phase 21, except the home-screen widget.
- Phase 21: activated (B10 part 2: bump photo journal, shareable milestone card, health diary PDF), see "## Phase 21" above.
- Home-screen widget (B10): deferred, not scheduled. Needs a native widget package (e.g. `home_widget`) plus Android/iOS widget code; revisit after Phase 22.
- Phase 22: activated (one-colour redesign, light/dark contrast, app icon), see "## Phase 22" above.

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
- Phase 19 round 1: `dart format` on changed files; `flutter analyze` 0 errors/0 warnings (16 pre-existing infos); `flutter test` passed with 239 tests (42 new in `test/my_clinic_and_prices_test.dart`, re-run by QA); `flutter build apk --debug` passed; installed on emulator-5554 with `adb install -r` (data kept), logcat clean. Content build/validate not run (generators untouched). Delete-all-data (step 12) checked by code review only. Verdict: fix (P19-R1-01 accepted; P19-R1-02 rejected as pre-existing, Known issues updated).
- Phase 19 round 2: `dart format` left changed files unchanged; `flutter analyze` 0 errors/0 warnings (16 pre-existing infos); `flutter test` passed with 243 tests (4 new MyClinicCard contrast tests, re-run by QA); `flutter build apk --debug` passed; installed on emulator-5554 with `adb install -r` (data kept), logcat clean. Content build/validate not run (generators untouched). Delete-all-data (step 12) checked by code review only. Verdict: pass (P19-R1-01 verified fixed, no accepted issues); Phase 19 completed.
- Phase 20 round 1: `dart format` on changed files; `flutter analyze` 0 errors/0 warnings (16 pre-existing infos); `flutter test` passed with 289 tests (46 new in `test/counter_tools_test.dart`, re-run by QA); `flutter build apk --debug` passed; installed on emulator-5554 with `adb install -r` (data kept), logcat clean. Content build/validate not run (generators untouched). Delete-all-data (step 11) checked by code review and dialog only. Verdict: fix (P20-R1-01 accepted).
- Phase 20 round 2: `dart format` left changed files unchanged; `flutter analyze` 0 errors/0 warnings (16 pre-existing infos); `flutter test` passed with 291/291 tests (2 new kick-stop contrast tests, re-run by QA); `flutter build apk --debug` passed; installed on emulator-5554 with `adb install -r` (data kept), logcat clean. Verdict: pass (P20-R2-01 and P20-R2-02 rejected as pre-existing, moved to Known issues, deferred to Phase 22); Phase 20 completed.
- Phase 21 round 1: `flutter pub add share_plus pdf path_provider` resolved `share_plus` 13.3.1, `pdf` 3.12.0, `path_provider` 2.1.6 (`image_picker` 1.2.0 unchanged; `image` pinned `>=4.0.0 <4.11.0` -> 4.10.2, `archive` 4.0.9); Be Vietnam Pro TTFs + OFL.txt bundled; `dart format` on changed files; `flutter analyze` 0 errors/0 warnings (16 pre-existing infos); `flutter test` passed with 332 tests (41 new in `test/bump_card_pdf_test.dart`, re-run by QA); `flutter build apk --debug` passed; installed on emulator-5554 with `adb install -r` (data kept), logcat clean. iOS not built (Info.plist review only). Delete-all-data (step 12) checked by dialog text, code review and unit tests only. Verdict: fix (P21-R1-01..04 accepted; date range picker part of P21-R1-03 deferred to Phase 22).
- Phase 21 round 2: `dart format` on changed files; `flutter analyze` 0 errors/0 warnings (16 pre-existing infos); `flutter test` passed with 344/344 tests (12 net new, re-run by QA); `flutter build apk --debug` passed; installed on emulator-5554 with `adb install -r` (data kept), `cache/` checked with `run-as ls -R`, logcat clean. Verdict: pass (P21-R2-01 rejected as global dark theme, moved to Known issues, deferred to Phase 22); Phase 21 completed.
