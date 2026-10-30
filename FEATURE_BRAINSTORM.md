# MomCare+ Feature Brainstorm theo hành trình mẹ

Ngày: 2026-10-28
Trạng thái: **Đề xuất, chưa implement.**

Tài liệu này mở rộng mục P1 trong [FEATURE_REVIEW.md](FEATURE_REVIEW.md). Nó bổ sung các nhóm feature đã thấy khi khảo sát app đối thủ:
- thai giáo theo ngày
- thông tin từng tuần thai, có hình minh hoạ
- cẩm nang chuẩn bị mang thai
- cẩm nang khi đang mang thai: lịch khám, bác sĩ gần đây, mua sắm, tiêm phòng, dinh dưỡng

## 1. Quyết định đã chốt
| Chủ đề | Quyết định | Để sau |
|---|---|---|
| Hình bé theo tuần | Ảnh minh hoạ AI-generated, bundle offline | Bộ 3D chuyên nghiệp |
| Thai giáo | Text + hoạt động hằng ngày | Audio (nhạc, truyện kể) ở V2 |
| Bác sĩ / bệnh viện gần đây | Mở Google Maps bằng từ khoá, không xin quyền vị trí | Danh bạ bác sĩ có backend (V2) |
| Mua sắm chuẩn bị | Chỉ có checklist, không gắn link bán hàng | Affiliate Shopee/Tiki/Lazada |

## 2. Ý tưởng cốt lõi: một content engine dùng chung

Phần lớn các feature mới có cùng dạng: **bài kiến thức + checklist + mốc theo tuần thai**. Ví dụ: chuẩn bị mang thai, tiêm phòng, mua sắm, giấy tờ, đồ đi sinh, lịch khám.

Vì vậy không nên viết từng màn hình riêng. Nên xây **một engine nội dung chung**:
- Mở rộng `ContentPackService` hiện có ([lib/core/data/content_pack_service.dart](lib/core/data/content_pack_service.dart)) để đọc thêm các file JSON chủ đề trong `assets/content/`.
- Dùng một renderer chung cho 3 dạng: **Guide** (bài viết theo section), **Checklist** (tick + % tiến độ), **Timeline** (mốc theo tuần).
- Tái dùng code sẵn có:
  - UI `SourceMetadata` (nguồn + "Cập nhật lần cuối", Phase 6)
  - pattern lưu trạng thái tick theo ngày của [maternal_habit_service.dart](lib/core/services/maternal_habit_service.dart)
  - `AddAppointmentScreen` + `NotificationService`, để biến một mốc thành lịch hẹn có nhắc (cần thêm tham số prefill)

Khi đó thêm một chủ đề mới chỉ cần thêm một file JSON, không cần code màn hình mới.

**Model nội dung đề xuất:**
```text
GuideArticle  { id, stage: pre | pregnant | postpartum, category, title,
                weekFrom?, weekTo?, sections[], checklist[], sources[],
                lastUpdated, reviewStatus, reviewer? }
ChecklistItem { id, text, weekDue?, actionType?: addAppointment | openMaps | call | none }
DailyItem     { day: 1–280, type, title, body, sources[], reviewStatus }
WeekContent   { week: 0–42, image, sizeCompare, lengthCm, weightG, babyDev,
                motherChanges, commonSymptoms[], todoThisWeek[], examsThisWeek[],
                nutritionFocus[], redFlags[], sources[], reviewStatus }
FoodItem      { id, name, aliases[], verdict: ok | limit | avoid, reason, trimesterNote?, sources[] }
```

## 3. Danh mục feature

### A. Chuẩn bị mang thai (chế độ pre-pregnancy)
| # | Feature | Nội dung chính | Tận dụng |
|---|---|---|---|
| A1 | **Cẩm nang chuẩn bị mang thai**, gồm 6 chủ đề | Xem chi tiết bên dưới bảng | Content engine |
| A2 | Checklist **"Sẵn sàng mang thai"** có % tiến độ | Gom các mục checklist từ A1 | Pattern tick của habit |
| A3 | **Dấu hiệu mang thai sớm + khi nào nên thử thai** | Dựa vào dự đoán kỳ kinh: "Trễ kinh X ngày → nên thử thai" | `HealthService.predictNextPeriod` |
| A4 | Nút **"Tôi đã có thai"** | Chuyển sang chế độ mang thai và mở ngay bước thiết lập thai kỳ | `PregnancySetupScreen`, `appModeProvider` |

6 chủ đề của A1:
- **Sức khoẻ:** khám tiền thai, xét nghiệm cơ bản, răng miệng, bệnh nền.
- **Vi chất:** acid folic từ 1–3 tháng trước khi mang thai, sắt, iốt.
- **Tiêm phòng trước khi có thai:** rubella/MMR (cần chờ một thời gian trước khi thụ thai), thuỷ đậu, viêm gan B, cúm, HPV.
- **Tinh thần.**
- **Tài chính:** chi phí khám/sinh, BHXH thai sản, quỹ dự phòng.
- **Lối sống và cân nặng.**

Ngoài ra có thêm một phần **dành cho người chồng**.

### B. Đang mang thai
| # | Feature | Nội dung chính | Tận dụng / ghi chú |
|---|---|---|---|
| B1 | **Trang tuần thai chi tiết**, lướt qua lại từ tuần 0 đến 42 | Xem chi tiết bên dưới bảng | Viết lại `pregnancy_weeks.json` cho riêng từng tuần (hiện chỉ có 3 template theo tam cá nguyệt). Thay dialog "sắp ra mắt" ở `tracking_screen.dart`. |
| B2 | **Hôm nay** (đầu trang Home) | Ngày thai X/280, **thai giáo hôm nay**, mẹo hôm nay, việc cần làm tuần này, checklist thói quen | Thay mẹo cố định ở `home_screen.dart` |
| B3 | **Thai giáo theo ngày** (text + hoạt động) | Mỗi ngày một hoạt động, tick "đã làm", có streak. Xem 7 dạng bên dưới bảng. | `DailyItem` + pattern habit |
| B4 | **Lịch khám thai chuẩn** (timeline) | Các mốc dự kiến xem bên dưới bảng. Mỗi mốc có nút **"Thêm vào lịch hẹn"**, điền sẵn tiêu đề và ngày dự kiến. | `AddAppointmentScreen` (prefill), `NotificationService`. **Cần bác sĩ duyệt các mốc.** |
| B5 | **Tiêm phòng khi mang thai** | Cúm (mọi giai đoạn), Tdap/ho gà (27–36 tuần), uốn ván tuỳ tiền sử tiêm. Tick đã tiêm, ghi ngày tiêm, có nhắc. Luôn ghi rõ "theo chỉ định bác sĩ". | Content engine + appointments |
| B6 | **Dinh dưỡng theo tuần + "Bầu ăn được không?"** | Tra cứu khoảng 150 thực phẩm và món ăn Việt, mỗi mục xếp nhóm **Nên ăn / Hạn chế / Tránh**, kèm lý do ngắn và nguồn. Đồng thời sửa bug bộ lọc tam cá nguyệt. | Màn nutrition sẵn có + `foods.json` |
| B7 | **Mua sắm chuẩn bị** (checklist) | Xem các nhóm bên dưới bảng. Tick đã mua, ghi giá tuỳ chọn, xem tổng chi phí. | Content engine (checklist) |
| B8 | **Tìm bệnh viện / bác sĩ gần tôi** | Nút mở Google Maps với từ khoá "bệnh viện phụ sản" hoặc "phòng khám sản" gần đây. Thêm mục **"Nơi khám của tôi"** (tên BV, bác sĩ, SĐT, địa chỉ) lưu trên máy, gọi nhanh được từ Home và màn "Cần khám". | `url_launcher` (Maps URL, `tel:`) |
| B9 | **Giấy tờ & quyền lợi** | Chế độ thai sản BHXH (thời gian nghỉ, trợ cấp, điều kiện hưởng), giấy tờ mang đi sinh, thủ tục khai sinh/BHYT cho bé qua dịch vụ công. Ghi rõ ngày cập nhật vì quy định có thể thay đổi. | Content engine |
| B10 | Công cụ (từ P1) | Đếm cử động thai, đếm cơn co (quy tắc 5-1-1), nhật ký ảnh bụng bầu, thẻ cột mốc chia sẻ, xuất PDF, nút 115, widget | Xem [FEATURE_REVIEW.md](FEATURE_REVIEW.md) |

Mỗi tuần trong B1 gồm:
- ảnh AI minh hoạ bé
- so sánh kích thước với trái cây, chiều dài, cân nặng
- bé đang phát triển gì
- cơ thể mẹ thay đổi gì, triệu chứng thường gặp
- **việc nên làm tuần này**, xét nghiệm/khám trong tuần
- dinh dưỡng của tuần
- dấu hiệu cần đi khám

7 dạng hoạt động thai giáo trong B3, xoay vòng trong tuần:
- trò chuyện với bé
- âm nhạc (gợi ý bài, không kèm audio)
- vận động nhẹ
- đọc truyện
- hít thở / thư giãn
- hoạt động cùng bố
- viết nhật ký cho bé

Các mốc khám dự kiến trong B4:
- 6–8 tuần: siêu âm tim thai
- 11–13 tuần 6 ngày: đo độ mờ da gáy, double test
- 16–18 tuần: triple test
- 20–22 tuần: siêu âm hình thái
- 24–28 tuần: tầm soát tiểu đường thai kỳ
- 30–32 tuần: siêu âm tăng trưởng
- từ 36 tuần: khám hằng tuần

Các nhóm checklist mua sắm trong B7:
- **TCN2:** đồ bầu.
- **TCN3:** đồ sơ sinh, đồ dùng cho bé.
- **Túi đồ đi sinh:** đồ cho mẹ, đồ cho bé, giấy tờ (CCCD, BHYT, sổ khám thai, kết quả xét nghiệm).

### C. Sau sinh
Giữ nguyên mục P2 trong [FEATURE_REVIEW.md](FEATURE_REVIEW.md): hồ sơ bé, nhật ký bú/ngủ/tã, tiêm chủng mở rộng, hồi phục của mẹ, sàng lọc EPDS.

## 4. Cấu trúc điều hướng (IA) đề xuất

Hiện tại: Trang chủ / Theo dõi / Công cụ / Cài đặt. Đề xuất:

| Tab | Chế độ mang thai | Chế độ chuẩn bị mang thai |
|---|---|---|
| **Hôm nay** | B2: thẻ ngày thai, thai giáo, việc tuần này, thói quen, lịch hẹn sắp tới | Thẻ chu kỳ, A3, A2 |
| **Tuần thai** / **Chu kỳ** | B1: lướt tuần + theo dõi sức khoẻ (nhật ký, cân nặng) | Lịch chu kỳ (giữ màn hiện có) |
| **Cẩm nang** | Lưới chủ đề: lịch khám, tiêm phòng, dinh dưỡng, mua sắm, giấy tờ, cần khám | Lưới 6 chủ đề A1 |
| **Công cụ** | Lịch hẹn, đếm cử động, đếm cơn co, ảnh bụng bầu, tìm BV | Lịch hẹn, tìm BV |
| **Cài đặt** | Như hiện tại, thêm "Nơi khám của tôi" | Như hiện tại |

Ở chế độ mang thai thì ẩn lối tắt "Theo dõi chu kỳ" và sub-tab "Chu kỳ" (lỗi UX đã nêu trong review).

## 5. Ảnh AI-generated: lưu ý bắt buộc
- Dùng **phong cách minh hoạ**, mềm mại và **nhất quán** cho cả 43 tuần. Không làm giống ảnh siêu âm hay ảnh y khoa thật.
- Bác sĩ cần duyệt tỉ lệ và hình dạng của bé ở từng tuần, vì ảnh AI dễ sai giải phẫu.
- Kiểm tra **điều khoản sử dụng thương mại** của công cụ tạo ảnh. Lưu lại prompt, công cụ và ngày tạo để truy vết.
- Dùng WebP, khoảng 50–80KB mỗi ảnh (tổng khoảng 3MB), bundle trong `assets/images/weeks/`.
- Nếu thiếu ảnh của một tuần thì fallback về icon trái cây.

## 6. Khối lượng nội dung: rủi ro lớn nhất
Phần code của các feature trên khá gọn nhờ dùng chung engine. Phần tốn công là **viết nội dung và duyệt y khoa**.

| Hạng mục | Ước tính |
|---|---|
| Tuần thai chi tiết | 43 tuần × khoảng 8 trường |
| Thai giáo + mẹo hằng ngày | 280 + 280 mục ngắn (có thể bắt đầu với 40 tuần × 7 dạng) |
| Cẩm nang (A1, B4, B5, B7, B9) | 25–35 bài + khoảng 150 mục checklist |
| "Bầu ăn được không?" | Khoảng 150 thực phẩm |
| Ảnh AI | 43 ảnh |

Quy trình đề xuất:
1. Soạn nội dung trên Google Sheet.
2. Dùng script chuyển sang JSON trong `assets/content/`.
3. Mỗi mục có `reviewStatus` và người duyệt.
4. Bản release **chỉ hiển thị mục đã duyệt**. Mục chưa duyệt thì fallback về nội dung chung an toàn (cơ chế fallback đã có sẵn trong `ContentPackService`).

## 7. Lộ trình chia phase (nối tiếp Phase 11 trong PLAN.md)
| Phase | Nội dung | Phụ thuộc / ghi chú |
|---|---|---|
| 12 | Sửa các bug P0 trong [FEATURE_REVIEW.md](FEATURE_REVIEW.md) | Bắt buộc làm trước |
| 13 | Content engine (Guide/Checklist/Timeline/Daily) + tab Cẩm nang + IA mới | Nền tảng cho các phase sau |
| 14 | Tuần thai chi tiết + lướt tuần + ảnh AI (B1) | Cần nội dung 43 tuần + ảnh |
| 15 | Hôm nay + thai giáo + mẹo theo ngày (B2, B3) | Đòn bẩy retention hằng ngày |
| 16 | Lịch khám chuẩn + tiêm phòng, nối với lịch hẹn và nhắc nhở (B4, B5) | Cần bug notification ở Phase 12 đã được sửa |
| 17 | Hub chuẩn bị mang thai + dấu hiệu có thai + nút "Tôi đã có thai" (A1–A4) | |
| 18 | Dinh dưỡng theo tuần + "Bầu ăn được không?" (B6) | |
| 19 | Mua sắm/đồ đi sinh + giấy tờ & quyền lợi + tìm BV + nơi khám của tôi (B7–B9) | |
| 20 | Công cụ P1: đếm cử động, đếm cơn co, ảnh bụng bầu, thẻ chia sẻ, PDF, 115, widget | |
| Sau | P2 Sau sinh, rồi V2 | Xem FEATURE_REVIEW.md |

Phase 13 chỉ cần 1–2 chủ đề mẫu. Nội dung của các phase sau có thể được viết song song trong lúc code.

## 8. Câu hỏi còn mở
- Ai là người duyệt y khoa (bác sĩ sản khoa hoặc nữ hộ sinh), và họ có bao nhiêu thời gian cho việc duyệt?
- Dùng công cụ tạo ảnh AI nào? Điều khoản thương mại của công cụ đó có cho phép dùng trong app không?
- Mục "Giấy tờ & quyền lợi" cần người cập nhật định kỳ khi luật BHXH thay đổi.

## 9. Canh ngày thụ thai (chế độ chuẩn bị mang thai)
Kết luận: nên làm. Giá trị chính là dự đoán trung thực và tín hiệu rụng trứng thật, không phải bản thân việc đồng bộ.

Nguồn dữ liệu:
- iPhone: app Sức khỏe (HealthKit).
- Android: Health Connect, có kỳ kinh, que thử rụng trứng, chất nhầy cổ tử cung, thân nhiệt nền, hoạt động tình dục. Cần có app khác ghi dữ liệu vào, nên nhập tay phải là luồng chính.
- Plugin `health` 13.3.2 chỉ đọc được `MENSTRUATION_FLOW`. Các loại khác cần thư viện khác hoặc platform channel.

| Đợt | Phase | Nội dung |
|---|---|---|
| 1 | 24 | Dự đoán dạng khoảng ngày kèm mức tin cậy, cửa sổ 6 ngày kết thúc ở ngày rụng trứng, thẻ "Khả năng thụ thai hôm nay", gợi ý tần suất mỗi 1–2 ngày trong cửa sổ |
| 2 | 25 | Nhập tay que LH, chất nhầy, thân nhiệt nền, ngày quan hệ; que dương tính cập nhật cửa sổ; nhắc kín đáo; thẻ "Nên đi khám khi nào" |
| 3 | 26 | Làm thử rồi đọc thêm dữ liệu từ Health Connect và HealthKit; quyền hoạt động tình dục mặc định không xin |

Không làm: xác suất % có thai, gợi ý chọn giới tính bé, dùng như biện pháp tránh thai, đưa dữ liệu ra khỏi máy.

Nguồn: [ASRM, Optimizing natural fertility (2021)](https://www.asrm.org/practice-guidance/practice-committee-documents/optimizing-natural-fertility-a-committee-opinion-2021), [Bull et al. 2019](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6710244/) (do Natural Cycles tài trợ), [Health Connect data types](https://developer.android.com/health-and-fitness/guides/health-connect/plan/data-types?hl=pl).

## Nguồn tham khảo
- Vinmec – [Lịch khám thai định kỳ](https://www.vinmec.com/vie/bai-viet/lich-kham-thai-dinh-ky-day-du-trong-suot-thai-ky-vi), [Vắc xin trước và trong khi mang thai](https://www.vinmec.com/vie/bai-viet/nhung-mui-vac-xin-can-tiem-truoc-trong-khi-mang-thai-va-lich-tiem-cu-vi)
- Long Châu – [Tiêm vắc xin cho bà bầu](https://nhathuoclongchau.com.vn/bai-viet/tiem-vacxin-cho-ba-bau-vao-thang-thu-may.html)
- Listing đối thủ:
  - [Ovia](https://apple.co/2NBcKNX): minh hoạ 3D, so sánh kích thước, cộng đồng
  - [The Bump](https://apple.co/2SWdVrq): bài viết hằng ngày, album ảnh theo tuần
  - [PregnanPlus](https://apps.apple.com/app/id6792898425): checklist theo tam cá nguyệt, quiz dấu hiệu sớm
  - [Pregnancy Tracker Pro](https://apps.apple.com/us/app/-/id6745613768): checklist theo tuần, đếm cử động thai, đếm cơn co
  - [GestaPlena](https://apps.apple.com/cd/app/gestaplena/id6760492597): offline, không cần tài khoản, mục xét nghiệm
  - [Babiuni](https://apps.apple.com/app/id1583681447): thai giáo theo ngày, chuyên gia
- Lưu ý: nguồn y khoa ở trên là bài viết của bệnh viện tư và nhà thuốc. Trước khi đưa vào app cần đối chiếu với hướng dẫn của **Bộ Y tế, WHO và CDC** (đã có trong [medical_references.dart](lib/core/data/medical_references.dart)).
