# Hồ sơ duyệt nội dung y khoa

Sáu file CSV trong thư mục này chứa toàn bộ nội dung y khoa của app, mở được bằng Excel.
Nội dung do AI soạn, **chưa được bác sĩ duyệt**. Tất cả đang có `reviewStatus: draft_requires_medical_review`.

## Cách duyệt
1. Đọc trước mục "Mười điểm cần bác sĩ ưu tiên xem" trong `content_source/CONTENT_NOTES.md`.
2. Với mỗi dòng, điền cột **Kết luận**: `Duyệt`, `Sửa` hoặc `Bỏ`. Nếu chọn `Sửa`, ghi nội dung mới vào cột kế bên.
3. Điền người duyệt và ngày duyệt.

Chỉ đổi `reviewStatus` thành `approved` cho phần đã có bác sĩ ký duyệt. Trước khi đó app vẫn hiện ghi chú nội dung nháp.

Tạo lại các file sau khi nội dung thay đổi: `node content_source/build/export_review.js`
