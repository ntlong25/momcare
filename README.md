# MomCare+

MomCare+ là ứng dụng Flutter hỗ trợ người dùng tại Việt Nam theo dõi thai kỳ, chuẩn bị mang thai, ghi nhận sức khỏe, xem gợi ý dinh dưỡng và quản lý lịch hẹn.

## Trạng thái V1

- Offline-first: dữ liệu được lưu cục bộ trên thiết bị.
- Chưa có đăng nhập, cloud sync, Supabase, analytics hoặc quảng cáo trong V1.
- Giao diện phát hành V1 dùng tiếng Việt.
- Nội dung sức khỏe chỉ mang tính tham khảo và không thay thế tư vấn y tế chuyên môn.

## Tech Stack

- Flutter
- Riverpod
- Hive
- flutter_local_notifications
- table_calendar
- fl_chart
- health

## Chức Năng Chính

- Chọn chế độ sử dụng: đang mang thai hoặc chuẩn bị mang thai.
- Theo dõi thai kỳ theo tuần và ngày dự sinh.
- Ghi nhật ký sức khỏe gồm cân nặng, huyết áp, tâm trạng, triệu chứng và ghi chú.
- Theo dõi chu kỳ kinh nguyệt và dự đoán các mốc chu kỳ.
- Xem hướng dẫn dinh dưỡng và công thức món ăn mẫu.
- Quản lý lịch hẹn và nhắc lịch cục bộ.
- Chế độ sáng/tối.

## Publish Readiness

Kế hoạch publish readiness được theo dõi trong `PLAN.md`. Các yêu cầu sản phẩm và guardrail cho agent được ghi trong `requirements.md` và `AGENTS.md`.
