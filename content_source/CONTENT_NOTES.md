# MomCare+ – Ghi chú nội dung cho bác sĩ duyệt và dev

Ngày soạn: 2026-10-29. Mọi item đều có `reviewStatus: draft_requires_medical_review`.
Người soạn: agent nội dung (không phải bác sĩ). Nội dung **chưa được duyệt y khoa**.

## 0. Ghi chú cho dev
- **pubspec.yaml:** Flutter không khai báo thư mục con theo kiểu đệ quy. Hiện `pubspec.yaml` chỉ có `assets/content/`. Cần thêm `assets/content/guides/` và `assets/content/daily/` thì app mới đọc được các file này. Agent nội dung không sửa `pubspec.yaml`.
- **Ảnh tuần thai:** `weeks_v2.json` trỏ đến `assets/images/weeks/week_XX.webp`, nhưng ảnh **chưa tồn tại** và thư mục chưa được tạo (theo yêu cầu). App cần fallback khi không có ảnh.
- **Build nội dung:** file JSON được sinh từ các module trong `content_source/build/` bằng `node content_source/build/build_all.js`. Muốn sửa nội dung thì sửa file `.js` rồi build lại, hoặc sửa thẳng JSON nếu bỏ hẳn bước build.
- **Kiểm tra:** `dart run content_source/validate.dart` (chạy từ thư mục gốc repo). File có `// ignore_for_file` để `flutter analyze` không báo info.
- **Những chỗ schema chưa nói rõ, đã chọn như sau:**
  - `foods[].group` không có enum. Đang dùng: `vegetable`, `fruit`, `meat`, `seafood`, `egg`, `dairy`, `grain`, `legume_nut`, `drink`, `dish`, `herb_spice`, `sweet`, `supplement`.
  - `weeks[].lengthCm` / `weightG` là `null` ở tuần 0–3 (chưa có phôi để đo). `weightG` cũng là `null` ở tuần 4–7 (dưới 1 g). `sizeCompare` là `null` ở tuần 0–2.
  - `daily_tips.json`: item **không có** `durationMin`; field này chỉ có ở thai giáo.
  - Daily items có `sources: []`. Nguồn nằm ở guide và week tương ứng.
  - `sources.json` có thêm `lastUpdated` ở cấp gốc.
  - Thứ tự hiển thị guide theo `index.json`: `pre` trước, `pregnant` sau. Trong mỗi stage sắp theo `order`; `pregnant_warning_signs` có `order: 5` để lên đầu.
  - Checklist có `actionType: addAppointment` nhưng `weekDue: null` (khám tiền thai, tư vấn tiêm) thì app cần tự chọn ngày mặc định hoặc để người dùng chọn.
  - Tuần 0 = ngày 1–7 tính từ ngày đầu kỳ kinh cuối (`day = week*7 + dow + 1`).

## 1. Mười điểm cần bác sĩ ưu tiên xem
1. **Lịch khám thai** (`pregnant_checkups`, timeline). Các mốc 6–8, 11–13w6d, 16–18, 20–22, 24–28, 30–32, 34–35, rồi hằng tuần từ 36 là thực hành thường gặp ở bệnh viện Việt Nam. Chúng **không** trùng với lịch 8 lần tiếp xúc của WHO 2016 (khoảng 12, 20, 26, 30, 34, 36, 38, 40 tuần), cũng không trùng mức "tối thiểu 4 lần trong 3 giai đoạn" của Bộ Y tế. Cần chốt cách trình bày.
2. **Axit folic 400 microgam/ngày** (`pre_micronutrients`). Đây là con số duy nhất về liều trong toàn bộ nội dung, lấy từ hướng dẫn công khai của WHO và CDC, kèm câu "hỏi bác sĩ mức phù hợp". Nếu không muốn có con số nào thì xoá.
3. **Thời gian chờ sau tiêm MMR / thủy đậu:** CDC ghi 28 ngày (khoảng 1 tháng). Một số cơ sở ở Việt Nam khuyên chờ 3 tháng. Đã ghi "làm theo hướng dẫn nơi tiêm".
4. **Tdap 27–36 tuần, RSV 32–36 tuần** (theo CDC 2025). Cần xác nhận vắc xin RSV cho thai phụ đã có ở Việt Nam chưa. Cần đối chiếu lịch uốn ván (VAT/Td) với Chương trình TCMR hiện hành.
5. **Chế độ thai sản:**
   - Luật BHXH 2024 (41/2024/QH15, hiệu lực 01/7/2025): điều kiện đủ 6 tháng trong 12 tháng (đủ 3 tháng nếu nghỉ dưỡng thai); khám thai 5 lần × tối đa 2 ngày; nghỉ sinh 6 tháng; trợ cấp một lần 2 lần mức tham chiếu; mức hưởng 100% bình quân 6 tháng.
   - Luật Dân số 2025 (113/2025/QH15): sinh con thứ hai được nghỉ 7 tháng, chồng được nghỉ 10 ngày làm việc khi vợ sinh con thứ hai hoặc sinh đôi. Hiệu lực 01/7/2026 theo thuvienphapluat; các khoản hỗ trợ tài chính tại điểm c, d khoản 1 Điều 14 có hiệu lực từ 01/01/2027.
   - **Chưa xác minh từ văn bản gốc:** số ngày nghỉ của lao động nam theo Luật BHXH 2024 (5/7/10 ngày), và mức trợ cấp thai sản cho người tham gia BHXH tự nguyện (nội dung chỉ nói chung chung). Cần người có chuyên môn pháp lý hoặc BHXH đối chiếu.
6. **Thủ tục liên thông khai sinh – thường trú – BHYT cho trẻ dưới 6 tuổi** qua Cổng DVC/VNeID, và thời hạn đăng ký khai sinh 60 ngày. Cần kiểm tra quy trình hiện hành.
7. **Thực phẩm dựa trên quan niệm dân gian, bằng chứng yếu** (đều để `limit` kèm "hỏi bác sĩ", trừ đu đủ xanh): dứa, rau răm, ngải cứu, mướp đắng, rau má, nhãn, vải, atiso, bột sắn dây, yến sào, đông trùng hạ thảo, trứng vịt lộn, óc lợn. **Rau ngót nấu chín để `ok`**, còn **nước ép rau ngót sống để `avoid`** (căn cứ: ca bệnh phổi tắc nghẽn ở Đài Loan liên quan nước ép sống, ở người lớn không mang thai). Đu đủ xanh để `avoid` dựa trên nghiên cứu động vật về nhựa/papain.
8. **Gan động vật để `avoid`** theo NHS (vitamin A). Điều này trái với thói quen ăn gan "bổ máu" ở Việt Nam. Bác sĩ có thể muốn hạ xuống `limit`.
9. **Cá:** ngưỡng thủy ngân theo FDA/NHS (cá ngừ đóng hộp tối đa 4 hộp/tuần, cá nhiều dầu 2 bữa/tuần). Cần xác nhận "cá thu" bán ở Việt Nam (thường là *Scomberomorus commerson*) nên để `limit` hay `avoid`.
10. **Dấu hiệu nguy hiểm và mốc thai máy:** "từ khoảng tuần 28 theo dõi cử động thai mỗi ngày"; quy tắc 5-1-1 cho cơn co; sốt ≥ 38°C. Cần thống nhất với hướng dẫn của bệnh viện đối tác.

## 2. Các điểm khác cần xem
- **Caffeine < 200 mg/ngày** (NHS/ACOG). Nội dung có câu "cà phê phin Việt Nam có thể chứa nhiều caffeine hơn": đây là nhận định định tính, chưa có số liệu.
- **Sàng lọc:** NIPT từ khoảng tuần 10; triple test 15–20 tuần; GBS khoảng tuần 36–37 "theo chỉ định của cơ sở". Ở Việt Nam, GBS không phải nơi nào cũng làm thường quy.
- **Đái tháo đường thai kỳ:** tầm soát 24–28 tuần theo Quyết định 6173/QĐ-BYT (2018). Không ghi ngưỡng đường huyết.
- **Mẹ Rh âm:** chỉ ghi "được tư vấn theo dõi, dự phòng", không nêu thời điểm tiêm anti-D.
- **Vận động:** 150 phút/tuần (ACOG/NHS); tránh nằm ngửa lâu sau khoảng tuần 16. Bài thai giáo có các động tác mèo – bò, child's pose mở gối, ngồi xổm có vịn (tuần 34, kèm câu "chỉ làm nếu bác sĩ không dặn tránh"), bóng tập, thở mũi luân phiên không nín thở, thở hộp "giữ nhẹ 2 nhịp". Cần xác nhận không có động tác nào chống chỉ định cho thai kỳ bình thường.
- **Vệ sinh cát mèo / Toxoplasma; xông hơi, tắm nước quá nóng ở đầu thai kỳ:** nội dung mức chung.
- **Khế:** cảnh báo cho người bệnh thận (độc tố thần kinh). Cần bác sĩ xác nhận cách diễn đạt.
- **Thai giáo:** đã viết với mục đích gắn kết và thư giãn, không hứa hẹn "bé thông minh hơn". Tuần 18 ghi "tai trong đã phát triển, bé có thể bắt đầu cảm nhận âm thanh"; mốc này khác nhau giữa các nguồn (khoảng 16–25 tuần).
- **Truyện cổ tích:** "Tấm Cám" có kết thúc bạo lực, nên nội dung gợi ý kể phiên bản nhẹ nhàng.
- **Tuần 34:** câu "bé sinh từ tuần này trở đi, nếu khỏe mạnh, thường ít gặp vấn đề nặng hơn bé sinh sớm hơn" cần bác sĩ chỉnh câu chữ cho an toàn.

## 3. Số liệu tăng trưởng thai (weeks_v2)
- Số liệu chiều dài và cân nặng là **giá trị gần đúng** lấy từ bảng tăng trưởng thai được công bố rộng rãi:
  - tuần 8–19: chiều dài đầu – mông (CRL);
  - từ tuần 20: chiều dài đầu – gót;
  - cân nặng theo ước tính siêu âm kiểu Hadlock.
- Số liệu không lấy trực tiếp từ một bài báo gốc. Bác sĩ nên đối chiếu với bảng mà bệnh viện đối tác đang dùng, ví dụ INTERGROWTH-21st hoặc WHO fetal growth charts 2017.
- Vì đổi cách đo, chiều dài nhảy từ 15,3 cm (tuần 19) lên 25,6 cm (tuần 20). App nên có chú thích về điểm này.
- Tuần 42 có cân nặng 3685 g và chiều dài 51,5 cm (thấp hơn tuần 41), giữ nguyên như bảng nguồn.
- Trái cây so sánh chỉ mang tính minh hoạ. Có chọn loại quen thuộc ở Việt Nam: quất, vải, hồng xiêm, củ đậu, dừa xiêm, bưởi, mít.

## 4. Nguồn đã dùng (chi tiết trong `assets/content/sources.json`)
- **Bộ Y tế, cơ quan Việt Nam:** Cục BM-TE; Hướng dẫn quốc gia CSSKSS (QĐ 4128/QĐ-BYT 2016); QĐ 6173/QĐ-BYT 2018 về đái tháo đường thai kỳ; TCMR; Viện Dinh dưỡng; BHXH Việt Nam; Cổng DVC.
- **Văn bản luật:** Luật BHXH 2024; Luật Dân số 2025.
- **Quốc tế:**
  - WHO: ANC 2016, MMN, maternal mortality;
  - CDC: Vaccinating Pregnant Women (cập nhật 22/8/2025), Safer Food Choices (cập nhật 31/01/2025), preconception, folic acid, Hear Her;
  - FDA: fish advice;
  - ACOG: prenatal care, screening, exercise;
  - NHS: foods to avoid, week by week, mental health, hospital bag, signs, vaccinations, planning, exercise;
  - UNICEF Việt Nam.

## 5. Chưa xác minh được
- **URL bị chặn hoặc không truy cập được khi kiểm tra:**
  - `mch.moh.gov.vn` và `dichvucong.gov.vn` hết thời gian chờ từ máy kiểm tra.
  - Các URL của CDC trả 403 khi gọi bằng curl, nhưng 2 trang đã đọc được qua công cụ web.
  - URL của Quyết định 4128 chưa tìm được bản chính thức trên mạng, nên `MOH-RH-2016` tạm trỏ về trang chủ Cục BM-TE. Cần thay bằng link văn bản.
  - Link QĐ 6173 là bản PDF trên luatvietnam (không chính thức).
- **Chưa đọc trực tiếp văn bản gốc:** Luật BHXH 2024 và Luật Dân số 2025. Thông tin lấy qua bài tổng hợp của thuvienphapluat, lsvn.vn và kết quả tìm kiếm.
- **Chưa kiểm tra:** QĐ 4128/QĐ-BYT còn hiệu lực hay đã được thay thế.
- **Chưa có:** hướng dẫn chính thức của Việt Nam về RSV cho thai phụ và giới hạn caffeine.
