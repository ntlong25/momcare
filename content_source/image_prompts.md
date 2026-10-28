# MomCare+ – Prompt ảnh minh hoạ tuần thai (tuần 0–42)

Trạng thái: **bản nháp, cần bác sĩ duyệt từng ảnh trước khi phát hành.**
Ảnh dùng cho `assets/content/weeks_v2.json`, field `image` (`assets/images/weeks/week_XX.webp`).
Agent nội dung không tạo ảnh; tài liệu này dành cho người tạo ảnh bằng công cụ AI.

## 1. Style guide (áp dụng cho mọi ảnh)

**Phong cách:** minh hoạ phẳng / 2.5D mềm mại, kiểu sách tranh thiếu nhi hiện đại. **Không** chân thực như ảnh chụp, **không** giống ảnh siêu âm, ảnh y khoa hay mô hình giải phẫu. Không máu, không dây rốn bị cắt, không nội tạng lộ ra, không chữ, không logo, không watermark.

**Bố cục (giống nhau cho cả 43 ảnh):**
- Khung vuông 1:1. Nền là một vòng tròn màu kem lớn ở giữa, gợi cảm giác "bọc trong bụng mẹ" (túi ối nhìn trừu tượng).
- Bé (hoặc hình ảnh tượng trưng ở tuần 0–3) nằm trong vòng tròn, lệch trái khoảng 1/3.
- Trái cây/rau củ so sánh kích thước đặt bên phải, ngoài vòng tròn, trên một "kệ" bóng đổ nhẹ. Trái cây vẽ cùng phong cách, không vẽ to nhỏ theo tỉ lệ thật với bé; chỉ cần dễ nhận ra.
- Khoảng trống 8% ở mỗi cạnh để app có thể bo góc.

**Bảng màu (dùng cố định):**
| Vai trò | Mã màu |
|---|---|
| Nền ngoài | `#FFF7F2` (kem hồng rất nhạt) |
| Vòng tròn trong | `#FCE4EC` → `#F8BBD0` (gradient nhẹ) |
| Da bé | `#F6C9B4`, đổ bóng `#E8A98F` |
| Dây rốn (nếu có) | `#E1A6B5`, nét mềm |
| Đường viền | `#8D6E63`, nét 2–3px, bo tròn |
| Điểm nhấn | `#80CBC4` (xanh bạc hà) |

**Ánh sáng:** sáng dịu từ phía trên bên trái, bóng mềm, không tương phản gắt.

**Prompt nền (ghép vào đầu mọi prompt):**
> Soft flat 2.5D children's book illustration, pastel palette (cream #FFF7F2 background, pink circle #FCE4EC to #F8BBD0, baby skin #F6C9B4, soft brown outlines #8D6E63, mint accent #80CBC4), gentle top-left light, rounded shapes, calm and warm mood, centered composition in a square frame, a large soft pink circle like a cozy womb in the middle, NOT photorealistic, NOT ultrasound, NOT medical diagram, no text, no logo, no watermark, no blood.

**Negative prompt (nếu công cụ hỗ trợ):**
> photorealistic, 3d render realistic skin, ultrasound, x-ray, anatomy diagram, gore, blood, scary, text, letters, watermark, extra limbs, extra fingers, deformed face, adult features on baby, gender cues, pink-vs-blue gender coding

**Lưu ý giới tính:** không dùng chi tiết thể hiện giới tính (không nơ, không màu "trai/gái", không vẽ bộ phận sinh dục).

## 2. Thông số xuất file
- Kích thước: **768 × 768 px**, WebP, chất lượng khoảng 75–80, **≤ 80 KB** mỗi ảnh.
- Tên file: `week_XX.webp` với XX hai chữ số (`week_00.webp` … `week_42.webp`).
- Thư mục đích: `assets/images/weeks/` (dev agent sẽ khai báo trong `pubspec.yaml` khi ảnh có thật; **không** tạo thư mục rỗng trước).
- Lưu lại: tên công cụ, phiên bản model, seed, ngày tạo, prompt đầy đủ, và điều khoản sử dụng thương mại của công cụ vào `content_source/image_log.csv` (tạo khi bắt đầu làm ảnh).
- Nếu chưa có ảnh của một tuần, app fallback về icon trái cây.

## 3. Prompt từng tuần

Mỗi prompt dưới đây ghép sau **prompt nền**. Tỉ lệ đầu/thân mô tả theo hướng minh hoạ, không cần chính xác tuyệt đối, nhưng phải đúng xu hướng phát triển.

| Tuần | Nội dung chính của ảnh | Trái cây/rau so sánh |
|---|---|---|
| 00 | No baby. A small calendar page with a soft circled day and a tiny flower bud inside the pink circle, symbolising the start of a new cycle. | none (show a small sprouting seed instead) |
| 01 | No baby. A softly glowing round egg cell (simple circle with a halo) resting inside the pink circle, peaceful mood. | none (small seed packet) |
| 02 | No baby. One round egg cell with a few tiny stylised sperm shapes approaching from a distance, very abstract and cute, no anatomy. | none |
| 03 | A tiny round cluster of cells (like a soft raspberry-shaped ball, 8–16 bubbles) nestling into a cushiony pink wall. | a mustard seed (hạt cải) |
| 04 | A very small embryo shown as a soft curved disc/comma shape next to a tiny round yolk sac bubble, inside a small sac. No face. | a sesame seed |
| 05 | Tiny C-shaped embryo with a slightly larger head end, a small glowing dot for the heart, yolk sac nearby. No limbs yet. | a black peppercorn |
| 06 | C-shaped embryo, head clearly larger, small limb buds as tiny nubs, dark dots for future eyes, gentle heart glow. | a mung bean |
| 07 | Embryo curled, head about half of body length, paddle-like hand buds, small leg buds, tiny tail still visible. | a peanut |
| 08 | Embryo with webbed fingers and toes forming, tail almost gone, simple face with closed eyelid lines, umbilical cord soft. | a green grape |
| 09 | Early fetus, rounder body, head still large (≈ half of length), arms bent at elbows, fingers separated, eyes closed. | a kumquat (quả quất) |
| 10 | Fetus with clear human shape, short legs, small hands near face, large forehead, eyes closed. | a lychee |
| 11 | Fetus with hands opening, head ≈ half of body, slender limbs, slight smile, eyes closed, floating calmly. | a fig |
| 12 | Fetus with complete simple facial profile, hand near mouth, legs longer, curled comfortably. | a lime |
| 13 | Fetus bringing thumb close to mouth, body lengthening, head ≈ one third of length. | a passion fruit |
| 14 | Fetus with expressive face (squint/grimace hint), very fine lanugo suggested by soft sparkle, arms moving. | a sapodilla (hồng xiêm) |
| 15 | Fetus stretching legs, visible soft bone shapes not shown, just slimmer proportions, ears lower on the head. | a red apple |
| 16 | Fetus holding head more upright, eyes closed, hands open, small kick pose. | an avocado |
| 17 | Fetus slightly chubbier, umbilical cord thicker and soft, peaceful sleeping pose. | a pomegranate |
| 18 | Fetus with one hand near ear (listening), small musical notes floating softly around the circle. | a sweet potato |
| 19 | Fetus with soft creamy layer hint (vernix as subtle white sheen), relaxed pose, thumb near mouth. | a small mango |
| 20 | Halfway: fetus longer, legs extended, sucking thumb, head ≈ one third of length. Small star sparkle. | a banana |
| 21 | Fetus swallowing / mouth slightly open, eyebrows visible, long limbs. | a large carrot |
| 22 | Fetus resembling a tiny newborn with slightly wrinkled skin, eyes closed, hand grasping cord gently. | a luffa / sponge gourd (mướp) |
| 23 | Fetus turning slightly, one hand reaching out, startled-but-cute pose (reacting to sound). | a large mango (xoài cát) |
| 24 | Fetus with eyelashes, eyebrows, hair wisps, leaner body, eyes still closed. | an ear of corn |
| 25 | Fetus a bit plumper, hands holding the umbilical cord loosely, face calm. | a white radish (củ cải trắng) |
| 26 | Fetus with eyes just opening, soft light beam reaching the circle, curious expression. | a large jicama (củ đậu) |
| 27 | Fetus sleeping in curled position, regular breathing feel, peaceful. | a cabbage |
| 28 | Fetus blinking, eyes half open, body filling more of the circle, head ≈ one quarter of length. | a green coconut |
| 29 | Fetus stretching arms and kicking, visible movement lines very subtle. | a small pumpkin |
| 30 | Fetus rounder with more body fat, less lanugo, calm smile. | a pomelo |
| 31 | Fetus turning head to one side, hand under cheek, sleeping. | a pineapple |
| 32 | Fetus starting to turn head-down, legs folded, fingernails reach fingertips (not detailed). | a large papaya |
| 33 | Fetus head-down, curled, chubby cheeks, cosy pose. | a small durian |
| 34 | Fetus head-down, nearly filling the circle, relaxed hands. | a cantaloupe / rockmelon |
| 35 | Fetus head-down, snug in the circle, gentle wiggling pose. | a winter melon (bí đao) |
| 36 | Fetus head-down, full round cheeks, filling most of the circle, head ≈ one quarter of length. | a small watermelon |
| 37 | Fetus head-down, practising sucking (thumb near mouth), full-term look. | a small jackfruit |
| 38 | Fetus head-down, peaceful, smooth skin, little hair. | a pumpkin |
| 39 | Fetus head-down, ready-to-be-born calm expression, circle feels snug. | a watermelon |
| 40 | Fetus head-down, newborn-like proportions, tiny soft heart icon floating near the circle (due date). | a jackfruit |
| 41 | Same as week 40 with slightly drier skin texture hint, patient calm expression, small clock icon in mint. | a large watermelon |
| 42 | Same proportions as week 41, peaceful, soft glow around the circle signalling "almost meeting". | a large pumpkin |

## 4. Checklist bác sĩ duyệt từng ảnh
Đánh dấu cho từng ảnh `week_XX.webp`:
- [ ] Tỉ lệ đầu/thân phù hợp với tuần (đầu rất lớn ở tuần 7–12, khoảng 1/3 ở tuần 20, khoảng 1/4 khi đủ tháng).
- [ ] Không có chi thừa/thiếu, đúng 5 ngón mỗi bàn tay/chân khi đã thấy ngón (từ khoảng tuần 9).
- [ ] Đặc điểm không xuất hiện quá sớm (ví dụ: không có mắt mở trước khoảng tuần 26, không có tóc rõ trước khoảng tuần 20, không có ngón tay rời trước tuần 8).
- [ ] Tuần 0–3 không vẽ "em bé" vì chưa có phôi/thai hình người.
- [ ] Tư thế ngôi đầu chỉ xuất hiện từ khoảng tuần 32 trở đi; không gợi ý rằng mọi thai đều phải quay đầu sớm.
- [ ] Dây rốn nối đúng vị trí bụng bé, không quấn cổ.
- [ ] Không có chi tiết thể hiện giới tính.
- [ ] Không giống ảnh siêu âm hay ảnh y khoa thật; không gây sợ hãi.
- [ ] Trái cây khớp với `sizeCompare` trong `weeks_v2.json`.
- [ ] File đúng tên, 768×768, ≤ 80 KB.
