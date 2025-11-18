# Fertility Planner Feature - Changelog

**Date:** 2025-11-18
**Branch:** `claude/review-source-code-01WXpodps87uC1qRdyoHKtXm`
**Feature Type:** Major New Feature
**Status:** ✅ Completed

---

## 📋 Feature Summary

Fertility Planner là một tính năng hoàn toàn mới giúp người dùng:
- ✅ Theo dõi chu kỳ kinh nguyệt và dự đoán ngày rụng trứng
- ✅ Tự động sync dữ liệu từ Apple Health (iOS) hoặc Google Fit (Android)
- ✅ Nhập dữ liệu thủ công với đầy đủ chi tiết
- ✅ Thống kê chu kỳ đều/không đều
- ✅ Dự đoán cửa sổ thụ thai (fertile window)
- ✅ Thông tin chi tiết về phương pháp chọn giới tính (với disclaimer đầy đủ)

---

## ✨ NEW FEATURES

### 1. **Fertility Calendar View** ✅
**Files:** `lib/features/fertility/screens/fertility_planner_screen.dart`

**Tính năng:**
- Calendar tương tác với TableCalendar package
- Đánh dấu các ngày quan trọng:
  - 🔴 **Period Days:** Ngày kinh nguyệt (từ dữ liệu đã lưu)
  - 🔵 **Ovulation Day:** Ngày rụng trứng dự đoán
  - 🟢 **Fertile Window:** Cửa sổ thụ thai (7 ngày)
  - 🔴 **Next Period:** Dự đoán kỳ kinh tiếp theo (màu nhạt)

**UI Components:**
- Month/Week/2-Week view switching
- Legend giải thích ý nghĩa các màu
- Smooth animations khi chuyển tháng

**Algorithms:**
```dart
// Ovulation: 14 ngày trước kỳ kinh tiếp theo
ovulationDate = lastPeriod.startDate + (avgCycle - 14)

// Fertile window: 5 ngày trước + ovulation + 1 ngày sau
fertileWindow = [ovulation-5, ..., ovulation, ovulation+1]

// Next period: Dựa vào chu kỳ trung bình
nextPeriod = lastPeriod.startDate + avgCycle
```

---

### 2. **Cycle Statistics Dashboard** ✅

**Thống kê hiển thị:**

**Average Cycle Length:**
- Tính từ tất cả các cycles đã track
- Formula: `sum(cycleLengths) / count(cycles)`
- Default: 28 ngày nếu chưa có dữ liệu

**Regularity Status:**
- **Regular:** ≥70% cycles trong vòng ±3 ngày so với average
- **Irregular:** <70% cycles đều
- Color coding: Green (regular) / Orange (irregular)

**Total Cycles Tracked:**
- Số lượng chu kỳ đã ghi lại
- Bao gồm cả manual input và HealthKit sync

**Visual Design:**
- Icon-based stats cards
- Color-coded indicators
- Clear, readable typography

---

### 3. **Predictions Section** ✅

**Next Period Prediction:**
- Dự đoán ngày kỳ kinh tiếp theo
- Hiển thị số ngày còn lại
- Format: "DD/MM/YYYY (X days)"

**Next Ovulation Prediction:**
- Dự đoán ngày rụng trứng tiếp theo
- Typically: 14 days before next period
- Quan trọng cho planning

**Fertile Window:**
- Hiển thị range dates
- Format: "DD/MM/YYYY - DD/MM/YYYY"
- Best days for conception

**Requirements:**
- Cần ít nhất 1 cycle để predict
- Accuracy tăng với số lượng cycles tracked

---

### 4. **Manual Period Input** ✅
**File:** `lib/features/fertility/screens/add_period_screen.dart`

**Input Fields:**

**Start Date** (Required):
- Date picker từ 365 ngày trước đến hôm nay
- Validation: Bắt buộc phải có

**End Date** (Optional):
- Date picker từ start date đến hôm nay
- Có nút clear để xóa
- Auto-disabled nếu chưa chọn start date

**Flow Intensity:**
- SegmentedButton với 3 options:
  - Light (nhẹ)
  - Medium (vừa) - Default
  - Heavy (nặng)
- Icon visual cho mỗi level

**Symptoms** (Multi-select):
- FilterChip widgets
- 9 symptoms phổ biến:
  - Cramps
  - Headache
  - Mood swings
  - Fatigue
  - Bloating
  - Breast tenderness
  - Back pain
  - Acne
  - Nausea
- Có thể chọn nhiều hoặc không chọn

**Notes** (Optional):
- TextField multiline (3 dòng)
- Free text cho ghi chú thêm

**Auto-calculations:**
- Cycle length: Tự động tính từ previous cycle
- Period length: Tự động tính từ start → end date

**Save Logic:**
```dart
periodLength = endDate - startDate + 1 (nếu có endDate)
cycleLength = startDate - lastCycle.startDate (nếu có lastCycle)
```

---

### 5. **HealthKit / Google Fit Integration** ✅
**File:** `lib/core/services/health_service.dart`

**Platform Support:**
- ✅ **iOS:** Apple HealthKit
- ✅ **Android:** Google Fit / Health Connect

**Features:**

**Permission Request:**
- Automatic permission dialog
- Clear usage description
- Graceful handling of denial

**Data Fetching:**
- Fetch menstrual data from last 365 days
- Group by dates to create cycles
- Automatic cycle detection (gap > 2 days = new cycle)

**Data Processing:**
```dart
1. Fetch all menstruation data points
2. Group by date
3. Detect cycle boundaries (gap > 2 days)
4. Calculate cycle lengths
5. Convert to MenstrualCycleModel
6. Mark as isFromHealthKit = true
7. Save to encrypted database
```

**Sync Button:**
- Located in AppBar
- Shows CircularProgressIndicator while syncing
- Disabled during sync process
- Success/Error SnackBars

**Error Handling:**
- Permission denied → Guide user to Settings
- No data found → Inform user
- Platform not supported → Fallback to manual input
- Network errors → Retry with user prompt

**Privacy:**
- Cannot check if user has data (HealthKit privacy)
- Can only request and attempt to fetch
- All data stored locally with encryption

---

### 6. **Gender Selection Information** ✅
**File:** `lib/features/fertility/screens/gender_selection_screen.dart`

**⚠️ DISCLAIMER (Prominent):**
```
IMPORTANT DISCLAIMER
The information below is for educational purposes only and based on
various theories like the Shettles Method. There is NO guaranteed
method to select baby gender naturally. These methods may increase
probability but are NOT scientifically proven to be 100% effective.
Always consult with your healthcare provider before trying any method.
```

**Content Structure:**

### **For Conceiving a Boy** 🔵

**1. Timing Method:**
- Have intercourse as close to ovulation as possible
- On ovulation day or 12 hours before
- Rationale: Y-sperm swim faster but die quicker

**2. Diet - Alkaline Environment:**
- Foods rich in sodium and potassium:
  - Red meat, fish, poultry
  - Salty foods (moderation)
  - Bananas, sweet potatoes
  - Mushrooms, broccoli
  - Citrus fruits

**3. Sexual Position:**
- Deep penetration positions (rear-entry)
- Deposits sperm closer to cervix
- Shorter distance for faster Y-sperm

**4. Abstinence Period:**
- Abstain 4-5 days before ovulation
- Increase sperm count
- Potentially increase Y-sperm concentration

**5. Temperature:**
- Keep testicles cool
- Loose underwear
- Avoid hot baths
- (Evidence limited)

### **For Conceiving a Girl** 🔴

**1. Timing Method:**
- Have intercourse 2-4 days BEFORE ovulation
- Abstain until 1 day after ovulation
- Rationale: X-sperm survive longer

**2. Diet - Acidic Environment:**
- Foods rich in calcium and magnesium:
  - Dairy products (milk, cheese, yogurt)
  - Eggs
  - Green leafy vegetables (spinach, kale)
  - Nuts and seeds (almonds, sunflower seeds)
  - Whole grains (oats, brown rice)

**3. Sexual Position:**
- Shallow penetration (missionary)
- Sperm farther from cervix
- Longer journey favors resilient X-sperm

**4. Frequency:**
- Intercourse every other day
- From period end until 2-3 days before ovulation
- Then stop
- May reduce Y-sperm concentration

**5. pH Level:**
- Slightly acidic vaginal pH may favor X-sperm
- Avoid alkaline douches
- Natural pH varies by diet

### **Scientific Evidence** 🔬
- Shettles Method claims 75-90% success
- Scientific studies show mixed results
- Some support timing effects
- Limited evidence for diet/position methods
- Natural probability: ~50/50 for each gender
- These methods may slightly shift probabilities

### **Medical Options** 🏥
**PGD (Preimplantation Genetic Diagnosis):**
- Used with IVF
- Tests embryos before implantation
- Nearly 100% accurate
- Expensive and ethically debated
- Primarily for medical reasons

**Sperm Sorting (MicroSort):**
- Separates X and Y sperm
- Used with IUI or IVF
- 70-90% accuracy
- May not be available/legal in all countries

### **Most Important** ❤️
```
Remember that the most important outcome is a healthy baby,
regardless of gender. Love and prepare for your baby no matter what.
Gender disappointment is real but healthy babies are a blessing.
Focus on your health, proper nutrition, and prenatal care for
the best pregnancy outcomes.
```

**UI Design:**
- Color-coded cards (Blue for boy, Pink for girl)
- Icon-based method presentation
- Clear section separators
- Highlighted disclaimer boxes
- Easy to read formatting

---

## 🗄️ DATABASE CHANGES

### New Model: MenstrualCycleModel
**File:** `lib/core/models/menstrual_cycle_model.dart`

**Hive Type ID:** 2

**Fields:**
```dart
id: String                    // UUID
startDate: DateTime           // Required - Ngày bắt đầu kỳ kinh
endDate: DateTime?            // Optional - Ngày kết thúc
cycleLengthDays: int?         // Auto-calculated từ previous cycle
periodLengthDays: int?        // Auto-calculated từ start → end
flowIntensity: String?        // "light", "medium", "heavy"
symptoms: List<String>?       // ["Cramps", "Headache", ...]
notes: String?                // Free text notes
isFromHealthKit: bool         // true nếu synced từ Health app
createdAt: DateTime           // Timestamp
updatedAt: DateTime           // Timestamp
```

**Methods:**
```dart
getEstimatedOvulationDate(avgCycleLength) → DateTime?
getFertileWindow(avgCycleLength) → List<DateTime>?
isRegular(avgCycleLength) → bool
```

**Encryption:** ✅ Yes (AES-256)
- Sensitive health data
- Encrypted using EncryptionService
- Keys stored in platform keychain

### DatabaseService Updates
**File:** `lib/core/services/database_service.dart`

**New Operations:**
```dart
static Box<MenstrualCycleModel> get menstrualCycleBox
static Future<void> saveMenstrualCycle(MenstrualCycleModel)
static List<MenstrualCycleModel> getAllMenstrualCycles()
static List<MenstrualCycleModel> getMenstrualCyclesByDateRange(start, end)
static MenstrualCycleModel? getLastMenstrualCycle()
static Future<void> deleteMenstrualCycle(String id)
static Future<void> clearMenstrualCycles()
```

**Box Name:** `menstrual_cycle_box`

**Initialization:**
- Registered adapter: `MenstrualCycleModelAdapter()`
- Opened with encryption
- Added to `clearAllData()` method

---

## 📦 DEPENDENCIES ADDED

### pubspec.yaml Changes:

**New Packages:**
```yaml
health: ^10.2.0              # HealthKit & Google Fit integration
permission_handler: ^11.3.1  # Permission management
```

**Existing Packages Used:**
```yaml
table_calendar: ^3.2.0       # Already existed - Used for calendar view
uuid: ^4.5.1                 # Already existed - For generating IDs
hive: ^2.2.3                 # Already existed - For data storage
```

---

## 🎨 UI/UX ENHANCEMENTS

### Home Screen - Quick Actions
**File:** `lib/features/home/widgets/quick_actions_grid.dart`

**Changes:**
- Increased from 4 to 6 quick action cards
- Added 2 new cards:
  1. **Fertility Planner** (Purple, calendar_month icon)
  2. **App Guide** (Teal, help_outline icon)
- Grid now shows 3 rows x 2 columns

**Visual:**
```
[Nutrition]        [Appointments]
[Health Diary]     [Recipes]
[Fertility]        [App Guide]     ← NEW
```

### Navigation Helper
**File:** `lib/core/utils/navigation_helper.dart`

**New Method:**
```dart
static Future<T?> toFertilityPlanner<T>(BuildContext context)
```

---

## 🛠️ TECHNICAL IMPLEMENTATION

### Architecture:
- **Pattern:** Feature-based architecture
- **State Management:** ConsumerStatefulWidget (Riverpod ready)
- **Data Layer:** Hive (encrypted NoSQL)
- **Platform Integration:** health package (cross-platform)

### Key Algorithms:

**1. Cycle Detection from HealthKit:**
```dart
// Group data points by date
Map<DateTime, List<HealthDataPoint>> grouped

// Detect cycle boundaries
for each date in sorted(grouped.keys):
  if gap > 2 days from last date:
    // New cycle detected
    create new MenstrualCycleModel
    calculate cycleLength = currentStart - previousStart
```

**2. Average Cycle Calculation:**
```dart
validCycles = cycles.where(c => c.cycleLengthDays != null)
total = sum(validCycles.map(c => c.cycleLengthDays))
average = round(total / validCycles.length)
default = 28 if no valid cycles
```

**3. Regularity Check:**
```dart
regularCycles = cycles.where(c =>
  abs(c.cycleLengthDays - avgLength) <= 3
)
isRegular = (regularCycles.length / cycles.length) >= 0.7
```

**4. Predictions:**
```dart
// Next Period
lastCycle = most recent cycle
nextPeriod = lastCycle.startDate + avgCycleLength

// Next Ovulation
nextOvulation = nextPeriod - 14 days

// Fertile Window
fertileStart = nextOvulation - 5 days
fertileEnd = nextOvulation + 1 day
```

### Performance Optimizations:
- Lazy loading of cycles
- Efficient date comparisons (normalized to day-level)
- Cached calculations where appropriate
- Minimal rebuilds with StatefulWidget

### Error Handling:
- Try-catch blocks for platform-specific code
- Graceful fallbacks for permission denials
- User-friendly error messages via SnackBars
- Logging with AppLogger

---

## 🔒 SECURITY & PRIVACY

### Data Protection:
- ✅ All data stored locally (no cloud)
- ✅ AES-256 encryption for menstrual data
- ✅ Encryption keys in platform keychain
- ✅ No third-party analytics
- ✅ No data transmission

### Permissions:
**iOS (Info.plist):**
```xml
NSHealthShareUsageDescription
NSHealthUpdateUsageDescription (if writing)
```

**Android (AndroidManifest.xml):**
```xml
ACTIVITY_RECOGNITION
health.READ_HEALTH_DATA
```

### Privacy Policy Update:
**Added to Privacy Policy dialog:**
```
6. Health Data
We may request access to your menstrual cycle data from
Apple Health (iOS) or Google Fit (Android) with your explicit
permission. This data is stored locally on your device with
encryption and is never transmitted to any servers.
```

---

## 📊 STATISTICS

### Code Changes:
- **New Files:** 6
  - 3 Screens (fertility_planner, add_period, gender_selection)
  - 1 Model (menstrual_cycle_model)
  - 1 Service (health_service)
  - 2 Documentation files

- **Modified Files:** 5
  - pubspec.yaml
  - app_constants.dart
  - database_service.dart
  - navigation_helper.dart
  - quick_actions_grid.dart

- **Total Lines Added:** ~2,500+
- **Packages Added:** 2
- **Database Models:** 1 new (encrypted)

### Feature Complexity:
- **Screens:** 3 full screens
- **Algorithms:** 6 calculation methods
- **Platform Integrations:** 2 (iOS HealthKit, Android Google Fit)
- **Data Points:** 11 fields per cycle
- **UI Components:** 20+ custom widgets

---

## ✅ TESTING CHECKLIST

### Unit Tests Needed:
- [ ] HealthService.calculateAverageCycleLength()
- [ ] HealthService.areCyclesRegular()
- [ ] HealthService.predictNextPeriod()
- [ ] HealthService.predictNextOvulation()
- [ ] HealthService.predictFertileWindow()
- [ ] MenstrualCycleModel.getEstimatedOvulationDate()
- [ ] MenstrualCycleModel.getFertileWindow()
- [ ] MenstrualCycleModel.isRegular()

### Integration Tests Needed:
- [ ] Add period manually → Save to DB → Load in calendar
- [ ] Sync from HealthKit → Display in calendar
- [ ] Calculate statistics with multiple cycles
- [ ] Predictions update when new cycle added
- [ ] Calendar markers appear correctly

### Manual Tests:
- [ ] iOS: HealthKit permission request
- [ ] iOS: Sync menstrual data successfully
- [ ] Android: Google Fit permission request
- [ ] Android: Sync data successfully
- [ ] Manual input all fields
- [ ] Calendar navigation (month/week view)
- [ ] Statistics calculation accuracy
- [ ] Predictions accuracy
- [ ] Gender selection screen content
- [ ] Quick action navigation

---

## 🚀 DEPLOYMENT CHECKLIST

### Before Release:
- [x] ✅ All code implemented
- [x] ✅ Documentation created
- [ ] Run `flutter pub run build_runner build`
- [ ] Add iOS permissions to Info.plist
- [ ] Add Android permissions to AndroidManifest.xml
- [ ] Test on real iOS device with HealthKit
- [ ] Test on real Android device with Google Fit
- [ ] Verify encryption works
- [ ] Test all error scenarios
- [ ] Update app version number
- [ ] Create release notes

### Post-Release:
- [ ] Monitor crash reports
- [ ] Gather user feedback
- [ ] Track adoption metrics
- [ ] Monitor prediction accuracy (self-reported)
- [ ] Plan Phase 2 enhancements

---

## 📖 USER GUIDE

### How to Use Fertility Planner:

**1. Access:**
- Tap "Fertility Planner" in Quick Actions on Home screen
- Or navigate via Settings (future)

**2. Add First Period:**
- Tap floating "+" button
- Select start date (required)
- Optionally add end date, flow, symptoms, notes
- Tap "Save Period"

**3. Sync from Health App (Optional):**
- Tap "Sync" icon in AppBar
- Allow permission when prompted
- Wait for sync to complete
- Data appears in calendar

**4. View Calendar:**
- Scroll through months
- See colored dots for:
  - Red: Your periods
  - Blue: Predicted ovulation
  - Green: Fertile days
  - Light red: Next period prediction

**5. Check Statistics:**
- View average cycle length
- See if cycles are regular
- Check total cycles tracked

**6. View Predictions:**
- Next period date and countdown
- Next ovulation date
- Fertile window dates

**7. Learn About Gender Selection:**
- Tap "Gender Selection Tips"
- Read disclaimer carefully
- Review methods for boy/girl
- Understand it's NOT guaranteed

---

## 🐛 KNOWN LIMITATIONS

### Current Limitations:
1. **Cannot edit existing cycles** (add in Phase 2)
2. **No detailed day view** (tap on date - future)
3. **No charts/graphs** (add in Phase 2)
4. **No notifications** (add in Phase 2)
5. **No data export** (add in Phase 2)
6. **Predictions based on simple average** (could use ML in future)
7. **Cannot track BBT or cervical mucus** (advanced features)
8. **No partner sharing** (future)

### Platform Limitations:
- **iOS:** Cannot know if user has HealthKit data before requesting
- **Android:** Google Fit API may vary by device
- **Permissions:** User can deny - app must handle gracefully

---

## 💡 FUTURE IMPROVEMENTS

### Short Term (Phase 2):
1. Edit/Delete cycles
2. Detailed day view with notes
3. Cycle length chart
4. Period reminders
5. Export to CSV

### Medium Term (Phase 3):
1. BBT tracking and charts
2. Cervical mucus logging
3. LH test results
4. Advanced predictions with ML
5. Symptom frequency analysis

### Long Term (Phase 4):
1. Partner mode with sharing
2. Doctor export/sharing
3. Pregnancy detection hints
4. Community features (anonymous)
5. Integration with wearables

---

## 📚 REFERENCES

### Medical Sources:
- Shettles Method research papers
- ASRM guidelines on fertility
- WHO reproductive health data

### Technical Resources:
- HealthKit Documentation (Apple)
- Google Fit API Documentation
- Flutter health package docs
- Hive database documentation

---

## ✅ COMPLETION STATUS

### Implementation: 100% ✅
- [x] Models & Database
- [x] Services & Logic
- [x] UI Screens
- [x] Navigation
- [x] Documentation

### Testing: Pending
- [ ] Build runner generation
- [ ] iOS permissions configuration
- [ ] Android permissions configuration
- [ ] Manual testing
- [ ] Integration testing

### Documentation: 100% ✅
- [x] Setup guide created
- [x] Changelog created
- [x] Code comments added
- [x] User guide included

---

**Feature Status:** ✅ **READY FOR TESTING**

**Next Steps:**
1. Run build_runner
2. Configure platform permissions
3. Test on real devices
4. Gather feedback
5. Iterate based on user needs

---

**Created by:** Claude AI Assistant
**Date:** November 18, 2025
**Version:** 1.0.0
**License:** Private - MomCare+ App

---

**End of Changelog**
