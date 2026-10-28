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

## Known issues (pre-existing, backlog)
- Chu kỳ calendar shows an English month header ('October 2026'), format button ('2 weeks') and weekday names; needs a Vietnamese locale/format labels. Found in Phase 14 test round 1 (P14-R1-04).
- `FlutterSecureStorage: Could not decrypt key` is logged at each launch (library startup check); data is unaffected. Found in Phase 14 test round 1.
- The old Tuần thai header rows (`tracking_screen.dart` ~164/210) and `weight_gain_chart.dart:79` overflow with Flutter's wide test font at 390px logical width; this was not seen on device at 1080x2400. Found in the Phase 14 dev round.

## Proposed Phases 15-20 (not active)
Details in `FEATURE_BRAINSTORM.md`. Do not start until the user activates a phase.
- Phase 15: "Hôm nay" daily card with daily prenatal activities (thai giáo) and daily tips.
- Phase 16: Standard prenatal visit timeline and pregnancy vaccinations linked to appointments/reminders.
- Phase 17: Pre-pregnancy preparation hub, early pregnancy signs, "Tôi đã có thai" mode switch.
- Phase 18: Weekly nutrition + "Bầu ăn được không?" food lookup.
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
