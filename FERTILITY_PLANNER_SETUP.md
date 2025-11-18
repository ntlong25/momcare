# Fertility Planner Feature - Setup Guide

## 📋 Overview

Fertility Planner là một feature hoàn chỉnh giúp người dùng:
- Theo dõi chu kỳ kinh nguyệt
- Tính toán ngày rụng trứng và cửa sổ thụ thai
- Đồng bộ dữ liệu từ Apple Health (iOS) hoặc Google Fit (Android)
- Nhập dữ liệu thủ công
- Xem thông tin về phương pháp chọn giới tính thai nhi (với disclaimer)
- Thống kê chu kỳ có đều hay không

---

## 🚀 Các bước Setup

### 1. **Chạy build_runner để generate Hive adapter**

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

File sẽ được tạo:
- `lib/core/models/menstrual_cycle_model.g.dart`

### 2. **Cấu hình iOS Permissions (Info.plist)**

Mở file `ios/Runner/Info.plist` và thêm các permission sau:

```xml
<key>NSHealthShareUsageDescription</key>
<string>MomCare+ needs access to your menstrual cycle data to help track your fertility and predict ovulation dates</string>

<key>NSHealthUpdateUsageDescription</key>
<string>MomCare+ would like to save your menstrual data to the Health app for your records</string>
```

**Lưu ý:** Nếu chỉ đọc dữ liệu (READ only), chỉ cần `NSHealthShareUsageDescription`.

### 3. **Cấu hình Android Permissions (AndroidManifest.xml)**

Mở file `android/app/src/main/AndroidManifest.xml` và thêm:

```xml
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
<uses-permission android:name="android.permission.health.READ_HEALTH_DATA" />
```

Thêm vào trong `<application>` tag:

```xml
<activity
    android:name="com.google.android.gms.auth.api.signin.internal.SignInHubActivity"
    android:theme="@android:style/Theme.Translucent.NoTitleBar" />
```

### 4. **Cấu hình Android Health Connect (Optional - Android 14+)**

Nếu target Android 14+, thêm vào `AndroidManifest.xml`:

```xml
<queries>
    <package android:name="com.google.android.apps.healthdata" />
</queries>
```

---

## 📂 Files Created

### Models:
- `lib/core/models/menstrual_cycle_model.dart` - Data model cho chu kỳ kinh nguyệt

### Services:
- `lib/core/services/health_service.dart` - Service tích hợp HealthKit/Google Fit

### Screens:
- `lib/features/fertility/screens/fertility_planner_screen.dart` - Màn hình chính với calendar
- `lib/features/fertility/screens/add_period_screen.dart` - Màn hình nhập dữ liệu thủ công
- `lib/features/fertility/screens/gender_selection_screen.dart` - Thông tin chọn giới tính

### Updated Files:
- `pubspec.yaml` - Thêm `health` và `permission_handler` packages
- `lib/core/constants/app_constants.dart` - Thêm `menstrualCycleBox` constant
- `lib/core/services/database_service.dart` - Thêm operations cho menstrual cycle
- `lib/core/utils/navigation_helper.dart` - Thêm `toFertilityPlanner()` method
- `lib/features/home/widgets/quick_actions_grid.dart` - Thêm Fertility Planner quick action

---

## 🎯 Tính năng chính

### 1. **Fertility Calendar**
- Hiển thị lịch với các ngày được đánh dấu:
  - 🔴 Đỏ: Ngày kinh nguyệt (period days)
  - 🔵 Xanh dương: Ngày rụng trứng (ovulation day)
  - 🟢 Xanh lá: Cửa sổ thụ thai (fertile window - 5 ngày trước + 1 ngày sau ovulation)
  - 🔴 Đỏ nhạt: Dự đoán kỳ kinh tiếp theo

### 2. **Cycle Statistics**
- **Average Cycle:** Độ dài chu kỳ trung bình (tính từ tất cả các chu kỳ đã lưu)
- **Status:** Regular (đều) hoặc Irregular (không đều)
  - Regular: Nếu ≥70% các chu kỳ trong vòng ±3 ngày so với trung bình
- **Tracked:** Số lượng chu kỳ đã theo dõi

### 3. **Predictions**
- **Next Period:** Dự đoán kỳ kinh tiếp theo (dựa vào chu kỳ trung bình)
- **Next Ovulation:** Dự đoán ngày rụng trứng tiếp theo (14 ngày trước kỳ kinh)
- **Fertile Window:** Cửa sổ thụ thai (6-7 ngày)

### 4. **Manual Input**
Người dùng có thể nhập:
- Start Date (ngày bắt đầu kinh nguyệt) - Bắt buộc
- End Date (ngày kết thúc) - Tùy chọn
- Flow Intensity: Light / Medium / Heavy
- Symptoms: Cramps, Headache, Mood swings, Fatigue, etc.
- Notes: Ghi chú thêm

### 5. **HealthKit/Google Fit Sync**
- Nút "Sync" trên AppBar
- Tự động request permission
- Fetch dữ liệu 365 ngày gần nhất
- Lưu vào database với flag `isFromHealthKit = true`
- Hiển thị số lượng cycles đã sync

### 6. **Gender Selection Info**
- ⚠️ **Disclaimer rõ ràng:** Không có phương pháp tự nhiên nào đảm bảo 100%
- **Phương pháp cho con trai:**
  - Timing: Gần ngày rụng trứng
  - Diet: Alkaline (thực phẩm giàu natri, kali)
  - Position: Deep penetration
  - Abstinence: 4-5 ngày trước ovulation
  - Temperature tips

- **Phương pháp cho con gái:**
  - Timing: 2-4 ngày trước rụng trứng
  - Diet: Acidic (thực phẩm giàu canxi, magie)
  - Position: Shallow penetration
  - Frequency: Thường xuyên
  - pH level info

- **Scientific Evidence:** Giải thích về Shettles Method và độ tin cậy
- **Medical Options:** PGD, Sperm Sorting (cho ai muốn 100% accuracy)
- **Final Note:** Nhấn mạnh "healthy baby" quan trọng hơn giới tính

---

## 🧮 Thuật toán tính toán

### Ovulation Date
```dart
ovulationDate = startDate + (averageCycleLength - 14) days
```
- Rụng trứng thường xảy ra 14 ngày TRƯỚC kỳ kinh tiếp theo

### Fertile Window
```dart
fertileWindow = [ovulation - 5 days, ovulation - 4, ..., ovulation, ovulation + 1]
```
- 5 ngày trước ovulation
- Ngày ovulation
- 1 ngày sau ovulation
- Tổng: 7 ngày

### Cycle Regularity
```dart
isRegular = (số cycles trong vòng ±3 ngày / tổng số cycles) >= 0.7
```
- Nếu ≥70% cycles nằm trong khoảng [avg - 3, avg + 3] → Regular

---

## 📊 Database Schema

### MenstrualCycleModel
```dart
{
  id: String,                    // UUID
  startDate: DateTime,           // Ngày bắt đầu kỳ kinh (bắt buộc)
  endDate: DateTime?,            // Ngày kết thúc kỳ kinh (optional)
  cycleLengthDays: int?,         // Độ dài chu kỳ (tự động tính)
  periodLengthDays: int?,        // Độ dài kỳ kinh (số ngày bleeding)
  flowIntensity: String?,        // "light", "medium", "heavy"
  symptoms: List<String>?,       // ["Cramps", "Headache", ...]
  notes: String?,                // Ghi chú
  isFromHealthKit: bool,         // true nếu sync từ Health app
  createdAt: DateTime,
  updatedAt: DateTime,
}
```

**Encryption:** Có (sensitive health data - sử dụng AES-256)

---

## 🔒 Privacy & Security

### Lưu trữ dữ liệu:
- Tất cả dữ liệu lưu local trên thiết bị
- Encrypted bằng AES-256
- Không gửi lên server
- Có thể xóa hoàn toàn từ Settings

### Permissions:
- **iOS:** Chỉ đọc dữ liệu menstruation từ HealthKit
- **Android:** Đọc dữ liệu từ Google Fit / Health Connect
- User phải chấp thuận explicitly
- Có thể revoke bất cứ lúc nào từ Settings của OS

### HealthKit Data:
- Không thể biết user có dữ liệu hay không (privacy by design)
- Chỉ có thể request permission và fetch
- Nếu user deny → fallback về manual input

---

## 🎨 UX Features

### Calendar Indicators:
- Dots dưới mỗi ngày với màu khác nhau
- Legend giải thích ý nghĩa các màu
- Có thể select ngày để xem chi tiết (future enhancement)

### Empty State:
- Nếu chưa có dữ liệu: Hiển thị message khuyến khích add period hoặc sync

### Loading States:
- CircularProgressIndicator khi loading cycles
- CircularProgressIndicator trên sync button khi đang sync
- Disable sync button khi đang process

### Error Handling:
- Permission denied → SnackBar với hướng dẫn vào Settings
- No data found → SnackBar thông báo
- Sync error → SnackBar với error message
- Network errors (Google Fit) → Graceful fallback

---

## 🧪 Test Checklist

### Manual Input:
- [ ] Có thể thêm period mới với đầy đủ thông tin
- [ ] Validation cho start date (bắt buộc)
- [ ] End date phải sau start date
- [ ] Flow intensity selection hoạt động
- [ ] Symptoms multi-select hoạt động
- [ ] Notes lưu đúng
- [ ] Cycle length tự động tính khi có previous cycle

### HealthKit Sync (iOS):
- [ ] Request permission dialog hiện đúng
- [ ] Sync thành công khi có dữ liệu
- [ ] Hiển thị số lượng cycles synced
- [ ] Handle permission denied gracefully
- [ ] Handle no data found
- [ ] Không duplicate data khi sync nhiều lần

### Calendar:
- [ ] Hiển thị đúng period days (đỏ)
- [ ] Hiển thị đúng ovulation day (xanh dương)
- [ ] Hiển thị đúng fertile window (xanh lá)
- [ ] Hiển thị đúng predicted next period (đỏ nhạt)
- [ ] Legend hiển thị đúng

### Statistics:
- [ ] Average cycle length tính đúng
- [ ] Regular/Irregular status chính xác
- [ ] Tracked cycles count đúng
- [ ] Predictions hiển thị khi có đủ dữ liệu

### Gender Selection:
- [ ] Disclaimer hiển thị nổi bật
- [ ] Tất cả methods cho boy hiển thị đầy đủ
- [ ] Tất cả methods cho girl hiển thị đầy đủ
- [ ] Scientific evidence section rõ ràng
- [ ] Medical options info chính xác
- [ ] Final note về healthy baby

---

## 🚀 Future Enhancements

### Phase 2:
1. **Detailed Day View**
   - Tap vào ngày → Xem chi tiết symptoms, notes
   - Edit/Delete cycle data
   - Add notes cho ngày cụ thể

2. **Charts & Graphs**
   - Cycle length over time (line chart)
   - Symptom frequency (bar chart)
   - Flow intensity patterns

3. **Reminders**
   - Notification trước predicted period 3 ngày
   - Notification khi vào fertile window
   - Reminder to log period data

4. **Export Data**
   - Export to CSV
   - Share với doctor
   - Backup/Restore

5. **Advanced Predictions**
   - Machine learning để improve accuracy
   - Consider multiple factors (stress, weight, etc.)
   - Pregnancy detection hints

6. **Community Features**
   - Anonymous tips sharing
   - Success stories (nếu có consent)

### Phase 3:
1. **BBT (Basal Body Temperature) Tracking**
   - Manual input hoặc sync từ smart thermometer
   - Chart BBT để detect ovulation chính xác hơn

2. **Cervical Mucus Tracking**
   - Log consistency daily
   - Combine với BBT cho accuracy cao

3. **LH Test Integration**
   - Log ovulation test results
   - Photo recognition (future: scan test strip)

4. **Partner Mode**
   - Share calendar với partner
   - Notifications cho cả 2
   - Private notes vs shared notes

---

## 📚 References

### Shettles Method:
- Shettles, L. B., & Rorvik, D. M. (2006). "How to Choose the Sex of Your Baby"
- Whelan, E. M. (1977). "Boy or Girl?"

### Scientific Research:
- Wilcox, A. J., et al. (1995). "Timing of sexual intercourse in relation to ovulation"
- Gray, R. H. (1991). "Natural family planning and sex selection"

### Medical Resources:
- ASRM (American Society for Reproductive Medicine) guidelines
- ACOG (American College of Obstetricians and Gynecologists) recommendations

---

## ⚠️ Legal & Ethical Disclaimer

**Quan trọng:**
- Feature này chỉ mang tính chất thông tin và giáo dục
- Không thay thế tư vấn y tế chuyên nghiệp
- Không đảm bảo kết quả
- Một số quốc gia cấm gender selection for non-medical reasons
- Developer không chịu trách nhiệm về kết quả sử dụng
- Luôn khuyến khích healthy baby > desired gender

**Recommendations:**
- Tham khảo bác sĩ trước khi áp dụng bất kỳ phương pháp nào
- Không nên quá kỳ vọng vào natural methods
- Focus vào prenatal health và baby health
- Chuẩn bị tinh thần đón nhận bất kỳ giới tính nào

---

## 🎯 Success Metrics

### Adoption:
- % users mở Fertility Planner
- % users thêm ít nhất 1 period
- % users sync từ HealthKit/Google Fit

### Engagement:
- Average số cycles tracked per user
- Retention rate (users quay lại sau 1 tháng)
- % users xem Gender Selection info

### Accuracy:
- User feedback về prediction accuracy
- % predictions đúng (self-reported)

---

**End of Setup Guide**

✅ Feature đã hoàn thành và sẵn sàng sử dụng!

Để test:
1. `flutter pub get`
2. `flutter pub run build_runner build --delete-conflicting-outputs`
3. Thêm iOS permissions vào Info.plist
4. Run app
5. Tap vào "Fertility Planner" trong Quick Actions
6. Thử add period hoặc sync từ Health app
