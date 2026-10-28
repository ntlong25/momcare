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

## Known issues (pre-existing, backlog)
- Chu kỳ calendar shows an English month header ('October 2026'), format button ('2 weeks') and weekday names; needs a Vietnamese locale/format labels. Found in Phase 14 test round 1 (P14-R1-04).
- `FlutterSecureStorage: Could not decrypt key` is logged at each launch (library startup check); data is unaffected. Found in Phase 14 test round 1.
- The old Tuần thai header rows (`tracking_screen.dart` ~164/210) and `weight_gain_chart.dart:79` overflow with Flutter's wide test font at 390px logical width; this was not seen on device at 1080x2400. Found in the Phase 14 dev round.
- Old Hôm nay widgets (`PregnancyProgressCard` rows ~21/70, `QuickActionsGrid` cards, `UpcomingAppointmentsCard` header) overflow with Flutter's wide test font at 360-390 dp; not seen on device. Phase 15 content widget tests run at 600 dp for this reason. Found in the Phase 15 dev round.
- `MaternalHabitsCard` reminder time picker (`maternal_habits_card.dart:152`) likely has the same keyboard-mode 12h/24h parse issue as P15-R1-02 (typed morning hour saved as PM on 12-hour devices). Found in Phase 15 test round 1.
- ARB keys `dailyTip` / `dailyTipMessage` are unused since Phase 15 (left in place).
- The Hôm nay "Lịch hẹn sắp tới" card (`UpcomingAppointmentsCard`) keeps old content after an appointment is added or deleted, until the app restarts. It is a `StatelessWidget` with no Hive listener, built as `const UpcomingAppointmentsCard()` in `home_screen.dart`, so the `HiveBoxesListener` rebuild skips it. Possible fix: drop the `const` or make the card listen to the appointments box. Found in Phase 16 test round 1 (P16-R1-01).

## Proposed Phases 17-20 (not active)
Details in `FEATURE_BRAINSTORM.md`. Do not start until the user activates a phase.
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
- Phase 15 round 1: `dart format` on changed files; `flutter analyze` 0 errors/0 warnings (16 pre-existing infos); `flutter test` passed with 102 tests (33 new in `test/daily_content_test.dart`); `flutter build apk --debug` passed; installed on Pixel_7 emulator with `adb install -r` (data kept), logcat clean. Content build/validate not run (generators untouched). Verdict: fix (P15-R1-01..03 accepted).
- Phase 15 round 2: `dart format` left changed files unchanged; `flutter analyze` 0 errors/0 warnings (16 pre-existing infos); `flutter test` passed with 106 tests (4 new `TodayThaiGiaoCard` tests); `flutter build apk --debug` passed; installed on emulator-5554 with `adb install -r` (data kept), logcat clean. Content build/validate not run (generators untouched). Verdict: pass (no accepted issues).
- Phase 16 round 1: `dart format` on changed files; `flutter analyze` 0 errors/0 warnings (16 pre-existing infos); `flutter test` passed with 134 tests (28 new in `test/milestone_schedule_test.dart`); `flutter build apk --debug` passed; `node content_source/build/build_all.js` completed and `dart run content_source/validate.dart` printed 'OK: all content files valid.' (21 guides, 132 checklist/timeline items); installed on emulator-5554 with `adb install -r` (data kept), logcat clean. Verdict: pass (P16-R1-01 rejected as pre-existing, moved to Known issues); Phase 16 completed.
