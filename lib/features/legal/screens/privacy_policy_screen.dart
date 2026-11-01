import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../widgets/legal_website_link.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  /// Published copy of this page, see [AppConstants.isPublishedUrl].
  final String websiteUrl;

  const PrivacyPolicyScreen({
    super.key,
    this.websiteUrl = AppConstants.privacyPolicyUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chính sách bảo mật')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Chính sách bảo mật MomCare+',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Cập nhật lần cuối: 10/2026',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          const _PolicySection(
            title: '1. Dữ liệu được lưu trên thiết bị',
            body:
                'MomCare+ lưu dữ liệu thai kỳ, nhật ký sức khỏe, chu kỳ, tín hiệu thụ thai bạn tự ghi (que LH, chất nhầy cổ tử cung, thân nhiệt nền, ngày gần gũi), dinh dưỡng yêu thích, lịch hẹn, lịch sử đếm cử động thai, cơn co và ảnh bụng bầu trên thiết bị của bạn. '
                'Ảnh, thẻ cột mốc và file PDF chỉ rời khỏi thiết bị khi bạn tự chọn chia sẻ.',
          ),
          const _PolicySection(
            title: '2. Chưa có sao lưu trực tuyến',
            body:
                'Hiện tại ứng dụng chưa có tài khoản hoặc sao lưu trực tuyến. Nếu bạn gỡ ứng dụng, đổi thiết bị hoặc mất thiết bị, dữ liệu có thể không được khôi phục.',
          ),
          const _PolicySection(
            title: '3. Không quảng cáo hoặc theo dõi hành vi',
            body:
                'MomCare+ không dùng quảng cáo hoặc dịch vụ theo dõi hành vi người dùng bên thứ ba.',
          ),
          const _PolicySection(
            title: '4. Dữ liệu sức khỏe và bảo mật',
            body:
                'Dữ liệu sức khỏe là dữ liệu nhạy cảm. Ứng dụng lưu thông tin trên thiết bị của bạn và dùng cơ chế bảo vệ dữ liệu khi thiết bị hỗ trợ. Tín hiệu thụ thai bạn tự ghi không được gửi đến máy chủ hay dịch vụ phân tích nào. Nếu bạn bật thông báo ngày dễ thụ thai, lịch thông báo được đặt sẵn trên thiết bị và không gửi ra ngoài; nội dung có thể hiện trên màn hình khóa tùy lựa chọn của bạn và cài đặt điện thoại. Trong một số trường hợp, mức độ bảo vệ có thể phụ thuộc vào thiết bị và cài đặt khóa màn hình của bạn.',
          ),
          const _PolicySection(
            title: '5. Quyền truy cập',
            body:
                'Ứng dụng chỉ yêu cầu quyền khi cần cho chức năng bạn chủ động sử dụng, ví dụ quyền thông báo để nhắc lịch hẹn hoặc quyền dữ liệu sức khỏe khi bạn chọn đồng bộ chu kỳ từ ứng dụng sức khỏe.',
          ),
          const _PolicySection(
            title: '6. Kiểm soát dữ liệu',
            body:
                'Bạn có thể quản lý dữ liệu ngay trong ứng dụng. Khi chọn xóa toàn bộ dữ liệu, thông tin đã lưu trên thiết bị này sẽ bị xóa và ứng dụng trở về trạng thái ban đầu.',
          ),
          LegalWebsiteLink(
            url: websiteUrl,
            label: 'Mở chính sách trên website',
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;

  const _PolicySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
