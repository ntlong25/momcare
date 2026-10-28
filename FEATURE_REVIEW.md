# MomCare+ Feature Review & Roadmap Proposal

Ngày review: 2026-10-28
Phạm vi:
- Đọc toàn bộ `lib/`, `assets/content/` và cấu hình native.
- Chạy `flutter test` và `flutter build apk --debug`.
- Chạy thử trên emulator Pixel_7 (Android 16 / API 36), dùng dữ liệu test có sẵn: mẹ "An", tuần 17.

Tài liệu này chỉ là đề xuất. Chưa có thay đổi code nào.

## 1. Kết quả build & chạy thử
- `flutter test`: 16/16 pass.
- `flutter build apk --debug`: pass.
- App cài và chạy được trên emulator. Logcat không ghi nhận Flutter exception hay overflow trong các luồng đã thử: Home, Theo dõi, Công cụ, Dinh dưỡng, Chu kỳ, đồng bộ Health, Cài đặt.
- Chưa test onboarding trên bản cài mới, để không xoá dữ liệu test đang có trên emulator.

## 2. Bug cần sửa trước khi publish (P0)

| # | Bug | Bằng chứng | Vị trí |
|---|-----|-----------|--------|
| 1 | **Đồng bộ Health Connect/HealthKit không bao giờ chạy.** `HealthService.init()` không được gọi nên `_health` là null. | Emulator API 36 có sẵn Health Connect, nhưng app báo "Chưa có Health Connect". | `lib/main.dart:24-27`, `lib/core/services/health_service.dart:14-35` |
| 2 | Đồng bộ lại sẽ nhân đôi chu kỳ, vì mỗi lần sync sinh ID mới. | Đọc code | `health_service.dart` (fetch) |
| 3 | **Nhắc nhở Android có thể không hiện.** Manifest thiếu `ScheduledNotificationReceiver`, `ScheduledNotificationBootReceiver` và quyền `RECEIVE_BOOT_COMPLETED`. Nhắc thói quen chỉ bắn 1 lần vì thiếu `matchDateTimeComponents.time`. Không lên lịch lại khi mở app hoặc reboot. | Đọc code | `android/app/src/main/AndroidManifest.xml`, `lib/core/services/notification_service.dart:108` |
| 4 | **Bộ lọc dinh dưỡng luôn rỗng.** Chip "Tam cá nguyệt 1/2/3" không khớp category "Tuần 0-12 / 13-42" trong JSON. Chip "Ăn dặm" không có dữ liệu. | Emulator: chọn chip TCN1 thì hiện "Chưa có hướng dẫn dinh dưỡng" | `lib/core/constants/app_constants.dart:49`, `assets/content/nutrition_guides.json` |
| 5 | **Crash date picker:** `initialDate` nhỏ hơn `firstDate = now` khi sửa lịch hẹn đã qua, hoặc khi ngày dự sinh đã qua. | Đọc code (assert của Flutter) | `add_appointment_screen.dart:262-267`, `settings_screen.dart:227` |
| 6 | Xoá lịch hẹn, tắt nhắc hoặc đánh dấu "đã khám" không huỷ notification đã lên lịch. | Đọc code | `appointments_screen.dart`, `add_appointment_screen.dart:322` |
| 7 | Chu kỳ: 0 kỳ đã ghi nhưng vẫn hiện trạng thái "Không đều". Thêm kỳ cũ hơn sau kỳ mới thì ra chu kỳ âm. Không sửa/xoá được kỳ kinh. Dự đoán không tự tiến lên nên hiện ngày đã qua. | Emulator (mục "Không đều") và đọc code | `fertility_planner_screen.dart`, `add_period_screen.dart:53-57`, `health_service.dart:264-283` |
| 8 | Onboarding bỏ qua màn chọn chế độ và đi thẳng vào thiết lập thai kỳ. Tuần thai tính theo ngày kinh cuối, còn "ngày còn lại" tính theo ngày dự sinh, nên hai số có thể lệch nhau. Mỗi lần thiết lập lại tạo thêm một thai kỳ `isActive`. | Đọc code | `onboarding_screen.dart:206`, `pregnancy_model.dart:46-53`, `database_service.dart` |
| 9 | Các tab nằm trong `IndexedStack` và đọc Hive trực tiếp, nên sửa dữ liệu ở tab này thì tab khác không cập nhật. | Đọc code | `main_navigation.dart` |
| 10 | Nhật ký cho lưu bản ghi trống. Không nhận dấu thập phân kiểu Việt "55,5". | Đọc code | `add_health_log_screen.dart:298`, `health_validators.dart:25` |
| 11 | Nếu không đọc được key bảo mật, Hive mở dữ liệu ở chế độ không mã hoá mà không báo gì. Dữ liệu sức khoẻ cần ít nhất ghi log và cảnh báo. | Đọc code | `encryption_service.dart` |
| 12 | Store blockers: URL privacy/disclaimer vẫn là `example.com`. Màn khởi động native vẫn là logo Flutter mặc định. Description trong `pubspec.yaml` vẫn là "A new Flutter project". | Emulator (màn khởi động) | `app_constants.dart:5-8`, `android/app/src/main/res/drawable*/launch_background.xml` |

**UX nhỏ:**
- Home của chế độ mang thai vẫn có lối tắt "Theo dõi chu kỳ", và tab Theo dõi vẫn có sub-tab "Chu kỳ". Nên ẩn cả hai khi đang mang thai.
- Ô "160 / Còn lại" thiếu đơn vị "ngày".
- Chip lợi ích (chữ xanh trên nền tối) có độ tương phản thấp trong dark mode.
- Nút chuông ở Home, "Hồ sơ" và "Thông báo" trong Cài đặt đều chỉ mở dialog "sắp ra mắt". Nên ẩn đi hoặc làm thật.
- Dependency không dùng: `dio`, `image_picker`, `flutter_svg`, `permission_handler`.

## 3. Nội dung còn mỏng
- Tuần 0–42 được sinh từ 3 template theo tam cá nguyệt (`content_pack_service.dart`). Thực tế mọi tuần trong cùng tam cá nguyệt có cùng một đoạn "Điều đang diễn ra", chỉ khác tên trái cây.
- Nội dung viết tay cho 12 tuần trong `pregnancy_weeks_data.dart` hiện là dead code.
- Không xem được tuần trước hoặc tuần sau: nút lịch sử là "sắp ra mắt".
- Mẹo hằng ngày ở Home là 1 câu cố định. Có 4 hướng dẫn dinh dưỡng và 5 công thức. Toàn bộ vẫn mang nhãn `draft_requires_medical_review`.

## 4. Research: feature nào thu hút và giữ chân user?

**Bằng chứng chung (mHealth):**
- Tổng quan 62 nghiên cứu: các yếu tố giữ chân user là **phản hồi cá nhân hoá, nhắc nhở phù hợp, hỗ trợ từ cộng đồng hoặc coach**. Các yếu tố khiến user bỏ app là **lỗi kỹ thuật, app kém hữu ích, thiếu hỗ trợ**. User có xu hướng bỏ nhiều hơn ở lại. ([PMC9092233](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC9092233/))
- Nghiên cứu khả dụng của app thai kỳ (2026) cho thấy mức engagement thấp. Nghiên cứu khuyến nghị thêm **cột mốc cá nhân hoá** và **hỗ trợ đồng đẳng có kiểm duyệt**. ([PMC13059308](https://pmc.ncbi.nlm.nih.gov/articles/PMC13059308/))
- HealthyMoms (RCT, Thuỵ Điển): số lần **tự ghi nhận** (cân nặng, ăn uống, vận động) liên quan tới tăng cân thai kỳ thấp hơn và chất lượng ăn uống tốt hơn. Đây là cơ sở cho nhật ký và checklist thói quen. ([PMC9376088](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC9376088/))
- Tổng quan app sức khoẻ tinh thần chu sinh (2026): user đánh giá cao **tính ẩn danh, sự tiện lợi và hỗ trợ đồng đẳng**. ([PMC13187566](https://pmc.ncbi.nlm.nih.gov/articles/PMC13187566/))

**Rời bỏ sau sinh:**
- Khảo sát của Emagine Solutions cho biết khoảng **60% user app thai kỳ bỏ app ngay sau sinh**, vì thiếu tính năng hậu sản: sức khoẻ tinh thần, chuyên gia, chăm sóc bé. ([BusinessWire](https://www.businesswire.com/news/home/20240111481203/en/Emagine-Solutions-Technology-Announces-Maternal-Health-Study-What-Comes-After))
- Lưu ý: đây là thông cáo báo chí, phương pháp không rõ, nên chỉ dùng làm tín hiệu định hướng.
- Xu hướng này khớp với nhận định trên [mother.ly](https://mother.ly/?p=227967): app thai kỳ thường bỏ trống giai đoạn sau sinh.

**Thị trường Việt Nam:**
- Đối thủ nổi bật là **Babiuni**: miễn phí, có in-app purchase, thai giáo theo ngày, ảnh phát triển theo tuần, nhắc lịch khám, thực đơn, chuyên gia 24/7. ([App Store](https://apps.apple.com/app/id1583681447), [VOH](https://voh.com.vn/apps/ung-dung-theo-doi-thai-ky-498988.html))
- Khảo sát Q&Me (500 mẹ ở HN/HCM): **Facebook là nguồn thông tin phổ biến**, còn ông bà/cha mẹ là nguồn quan trọng nhất về chăm con. ([Q&Me](https://qandme.net/en/report/Vietnamese-mom-digital-usage-and-influence-factors.html))
- Hệ quả: nội dung có thể chia sẻ lên Facebook/Zalo là kênh tăng trưởng tự nhiên, và tính năng chia sẻ với người thân có giá trị.
- Bài viết của các nhà bán kit đếm cử động thai và đếm cơn co mô tả đây là tính năng "tiện ích" giúp giảm lo lắng. Chưa có số liệu retention độc lập, nhưng đây là feature mặc định mà user kỳ vọng ở mọi app thai kỳ lớn.

**Kết luận:**
- Thứ giữ chân user là **(1) lý do để mở app mỗi ngày** (nội dung theo ngày, checklist, nhắc nhở *hoạt động đúng*), **(2) app vẫn hữu ích sau khi sinh**, **(3) có kết nối con người** (người thân, cộng đồng, chuyên gia).
- MomCare+ hiện yếu ở cả ba điểm: nhắc nhở không chạy ổn định, chưa có giai đoạn sau sinh, chưa có tính năng xã hội.

## 5. Đề xuất lộ trình

> Cập nhật 2026-10-28: lộ trình chi tiết, đã bổ sung thai giáo, tuần thai có hình và cẩm nang chuẩn bị/đang mang thai, nằm trong [FEATURE_BRAINSTORM.md](FEATURE_BRAINSTORM.md) (Phase 12–20) và thay thế bảng P1 bên dưới.

Thang đánh giá: Thu hút / Giữ chân / Công sức / Rủi ro y tế (Cao–TB–Thấp).

### P0: Sửa trước khi publish (V1)
Toàn bộ mục 2. Riêng bug #1, #3, #4 ảnh hưởng trực tiếp tới cảm nhận "app hỏng", nên phải sửa trước tiên.

### P1: V1 offline, tăng retention (không cần backend)

| Feature | Thu hút | Giữ chân | Công sức | Rủi ro y tế | Ghi chú |
|---|---|---|---|---|---|
| Nội dung riêng cho từng tuần (0–42) + mẹo theo **từng ngày** thai | TB | **Cao** | TB (chủ yếu viết nội dung) | TB, cần duyệt y khoa | Lý do mở app hằng ngày. Tái dùng `ContentPackService` và JSON. |
| Xem tuần trước/sau (lướt tuần) | Thấp | TB | Thấp | Thấp | Thay dialog "sắp ra mắt" ở `tracking_screen.dart` |
| **Đếm cử động thai** (từ tuần 28) | TB | **Cao** (dùng hằng ngày ở TCN3) | Thấp–TB | TB, chỉ hướng dẫn kèm link "Cần khám" | Hive box mới, theo pattern `maternal_habit_service.dart` |
| **Đếm cơn co** (quy tắc 5-1-1) | TB | TB (cuối thai kỳ) | Thấp | TB, CTA tới cơ sở y tế | |
| Checklist đồ đi sinh (mẹ / bé / giấy tờ: CCCD, BHYT, sổ khám thai) | TB | TB | Thấp | Thấp | Nội dung bản địa VN |
| Nhắc thói quen lặp hằng ngày + thói quen tuỳ chỉnh + streak | Thấp | **Cao** | Thấp | Thấp | Sửa bug #3 trước |
| Nhật ký ảnh bụng bầu theo tuần + ảnh siêu âm | **Cao** | **Cao** | TB | Thấp | Dùng `image_picker` đã có trong pubspec. Lưu ảnh local. |
| **Thẻ cột mốc chia sẻ** (ảnh "Tuần 20 – bé to bằng quả chuối") lên Facebook/Zalo | **Cao** (viral) | TB | Thấp–TB | Thấp | Kênh tăng trưởng chính cho thị trường VN |
| Xuất PDF nhật ký sức khoẻ (cân nặng, huyết áp, triệu chứng) để đưa bác sĩ | TB | TB | TB | Thấp | Tăng tính hữu ích thực tế |
| Nút gọi 115 trên màn "Cần khám" | Thấp | Thấp | Rất thấp | Giảm rủi ro | `url_launcher` `tel:115` |
| Widget màn hình chính (tuần thai, số ngày còn lại) | TB | **Cao** | TB | Thấp | Nhắc thụ động hằng ngày |

### P2: V1.x, chống rời bỏ sau sinh

| Feature | Thu hút | Giữ chân | Công sức | Rủi ro y tế |
|---|---|---|---|---|
| **Chế độ "Sau sinh"** (`AppMode` thứ 3): khi đến ngày dự sinh thì hỏi "Bé đã chào đời?" | TB | **Rất cao** | Cao | TB |
| Hồ sơ bé + nhật ký bú / ngủ / tã / thay tã | TB | **Rất cao** (dùng nhiều lần mỗi ngày) | Cao | Thấp |
| Lịch tiêm chủng mở rộng VN + nhắc lịch | **Cao** | **Cao** | TB | TB, cần nguồn Bộ Y tế/VNVC |
| Biểu đồ tăng trưởng bé theo chuẩn WHO | TB | TB | TB | TB |
| Sàng lọc trầm cảm sau sinh EPDS (chỉ để tham khảo, có CTA tới chuyên gia) | Thấp | TB | Thấp | **Cao**, cần duyệt kỹ |
| Mẹo hồi phục cho mẹ (ở cữ, cho con bú) theo tuần sau sinh | TB | **Cao** | TB (nội dung) | TB |

### V2: Cần backend (Supabase), chỉ làm sau khi V1 ổn định

| Feature | Thu hút | Giữ chân | Công sức | Rủi ro / ghi chú |
|---|---|---|---|---|
| Đăng nhập + cloud backup/sync (opt-in) | Thấp | TB (đổi máy không mất dữ liệu) | Cao | Cập nhật Privacy Policy, Data Safety |
| **Chia sẻ với chồng/người thân** (xem tuần thai, lịch khám) | **Cao** (mỗi người dùng kéo thêm 1 người) | **Cao** | Cao | Quản lý quyền xem |
| Cộng đồng theo tháng dự sinh, có kiểm duyệt | **Cao** | **Rất cao** | Rất cao (kiểm duyệt) | Rủi ro thông tin sai, cần moderation |
| Hỏi đáp chuyên gia (bác sĩ/nữ hộ sinh) | **Cao** | **Cao** | Rất cao (vận hành) | Có thể thu phí. Pháp lý tư vấn y tế. |
| Trợ lý AI trả lời dựa trên nguồn đã duyệt, có guardrail và CTA "Cần khám" | **Cao** | TB–Cao | Cao | **Rủi ro cao**: không chẩn đoán, phải trích nguồn |
| Analytics có đồng ý (đo D1/D7/D30, funnel onboarding) | – | Gián tiếp | TB | Cần trước khi tối ưu retention |
| Push notification nội dung từ server | TB | **Cao** | TB | |
| Freemium: nội dung chuyên sâu, xuất PDF, chuyên gia | – | – | TB | Mô hình giống Babiuni |

## 6. Thứ tự khuyến nghị
1. **P0** (khoảng 1 sprint). Đây là bước bắt buộc: nhắc nhở hỏng và đồng bộ hỏng sẽ khiến user rời app ngay tuần đầu.
2. **P1, đợt a:** nhắc nhở lặp + streak, nội dung theo ngày, lướt tuần, đếm cử động thai, checklist đi sinh, nút 115.
3. **P1, đợt b:** nhật ký ảnh bụng bầu, thẻ cột mốc chia sẻ, xuất PDF, widget.
4. **P2:** chế độ Sau sinh và tiêm chủng. Đây là đòn bẩy retention lớn nhất về dài hạn.
5. **V2:** bắt đầu bằng analytics có đồng ý và cloud backup, sau đó là chia sẻ với người thân. Cộng đồng và chuyên gia làm sau cùng vì chi phí vận hành cao.
