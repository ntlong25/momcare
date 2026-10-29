# MomCare+ Content Schema (v2)

Đây là hợp đồng dữ liệu giữa **nội dung** (`assets/content/**`) và **code** (`ContentPackService` / content engine). Nếu cần đổi schema thì cập nhật file này trước.

## Quy ước chung
- Encoding UTF-8. Toàn bộ text hiển thị là tiếng Việt có dấu.
- Field `sources`: mảng mã nguồn. Đã có `MOH-MCH`, `WHO-ANC`, `CDC-WARNING`. Mã mới được thêm vào `assets/content/sources.json`.
- Field `reviewStatus`: `draft_requires_medical_review` | `approved`. **Nội dung mới luôn là `draft_requires_medical_review`.**
- Field `lastUpdated`: định dạng `YYYY-MM-DD`.
- `id`: chữ thường, dùng `_`, duy nhất trong phạm vi file. Riêng id của mục checklist/timeline phải **duy nhất toàn cục**, vì app lưu trạng thái tick theo id.
- Viết thận trọng, không chẩn đoán, không kê liều thuốc. Với thuốc hoặc vắc xin, luôn ghi "theo chỉ định của bác sĩ / nhân viên y tế".

## Phân chia quyền sở hữu file
| Đường dẫn | Chủ sở hữu |
|---|---|
| `assets/content/guides/**`, `assets/content/daily/**`, `assets/content/weeks_v2.json`, `assets/content/foods.json`, `assets/content/sources.json`, `assets/images/weeks/**`, `content_source/**` | Agent nội dung |
| `lib/**`, `test/**`, `android/**`, `ios/**`, `pubspec.yaml`, `PLAN.md`, `assets/content/pregnancy_weeks.json`, `assets/content/nutrition_guides.json` | Agent dev |

## 1. Sources: `assets/content/sources.json`
```json
{ "version": 1, "sources": [
  { "id": "WHO-ANC", "title": "WHO recommendations on antenatal care", "organization": "World Health Organization", "url": "https://..." }
]}
```

## 2. Guides: `assets/content/guides/index.json` + một file cho mỗi bài
```json
{ "version": 1, "guides": ["pre_health.json", "pregnant_checkups.json"] }
```
File bài viết:
```json
{
  "id": "pregnant_checkups",
  "stage": "pre",
  "category": "checkup",
  "title": "Lịch khám thai định kỳ",
  "summary": "1–2 câu mô tả ngắn hiển thị trên thẻ.",
  "order": 10,
  "weekFrom": null,
  "weekTo": null,
  "sections": [
    { "heading": "Vì sao cần khám định kỳ", "body": "Đoạn văn...", "bullets": ["..."] }
  ],
  "checklist": [
    { "id": "chk_pre_folic", "text": "Bắt đầu bổ sung axit folic theo tư vấn", "weekDue": null,
      "actionType": "none", "actionLabel": null, "actionValue": null }
  ],
  "timeline": [
    { "id": "tl_nt_scan", "weekFrom": 11, "weekTo": 13, "title": "Siêu âm đo độ mờ da gáy",
      "description": "...", "actionType": "addAppointment" }
  ],
  "sources": ["WHO-ANC", "MOH-MCH"],
  "lastUpdated": "2026-10-29",
  "reviewStatus": "draft_requires_medical_review"
}
```
Ràng buộc giá trị:
- `stage`: `pre` | `pregnant` | `postpartum`.
- `category`: `health` | `nutrition` | `vaccination` | `mental` | `finance` | `lifestyle` | `partner` | `signs` | `checkup` | `shopping` | `documents` | `hospital_bag` | `warning`.
- `actionType`:
  - `none`
  - `addAppointment`: app mở màn thêm lịch hẹn, điền sẵn `title` và ngày dự kiến theo `weekFrom`.
  - `openMaps`: `actionValue` là từ khoá tìm kiếm, ví dụ "bệnh viện phụ sản".
  - `call`: `actionValue` là số điện thoại, ví dụ "115".
- `sections`, `checklist`, `timeline` có thể là mảng rỗng.

## 3. Daily: `assets/content/daily/thai_giao.json` và `assets/content/daily/daily_tips.json`
```json
{
  "version": 1, "type": "thai_giao", "lastUpdated": "2026-10-29",
  "reviewStatus": "draft_requires_medical_review",
  "items": [
    { "day": 1, "week": 0, "category": "talk", "title": "...", "body": "...", "durationMin": 5, "sources": [] }
  ]
}
```
- `day`: 1–294 (tuần 0–41, tính `day = week*7 + dayOfWeek + 1`). Nếu thiếu ngày thì app fallback về item cùng `category` gần nhất.
- `type`: `thai_giao` | `daily_tip`.
- `category`:
  - thai giáo: `talk` | `music` | `movement` | `reading` | `breathing` | `partner` | `journal`
  - mẹo: `nutrition` | `body` | `mental` | `prep` | `safety`

## 4. Weeks v2: `assets/content/weeks_v2.json`
Phase 14 mới dùng file này. Phase 13 chưa đọc.
```json
{
  "version": 2, "lastUpdated": "2026-10-29", "reviewStatus": "draft_requires_medical_review",
  "weeks": [
    { "week": 20, "image": "assets/images/weeks/week_20.webp", "sizeCompare": "quả chuối",
      "lengthCm": 25.6, "weightG": 300, "babyDevelopment": "...", "motherChanges": "...",
      "commonSymptoms": ["..."], "todoThisWeek": ["..."], "examsThisWeek": ["..."],
      "nutritionFocus": ["..."], "redFlags": ["..."], "sources": ["WHO-ANC"] }
  ]
}
```

## 5. Foods: `assets/content/foods.json`
```json
{ "version": 1, "lastUpdated": "2026-10-29", "reviewStatus": "draft_requires_medical_review",
  "foods": [
    { "id": "pate", "name": "Pa tê", "aliases": ["pate gan"], "group": "meat",
      "verdict": "avoid", "reason": "...", "tip": "...", "sources": ["CDC-..."] }
  ]}
```
- `verdict`: `ok` | `limit` | `avoid`.
