import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
            'Cập nhật lần cuối: 09/2026',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          const _PolicySection(
            title: '1. Dữ liệu được lưu trên thiết bị',
            body:
                'MomCare+ lưu dữ liệu thai kỳ, nhật ký sức khỏe, chu kỳ, dinh dưỡng yêu thích, lịch hẹn, lịch sử đếm cử động thai, cơn co và ảnh bụng bầu trên thiết bị của bạn. '
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
                'Dữ liệu sức khỏe là dữ liệu nhạy cảm. Ứng dụng lưu thông tin trên thiết bị của bạn và dùng cơ chế bảo vệ dữ liệu khi thiết bị hỗ trợ. Trong một số trường hợp, mức độ bảo vệ có thể phụ thuộc vào thiết bị và cài đặt khóa màn hình của bạn.',
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
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _openUrl(context, AppConstants.privacyPolicyUrl),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Mở chính sách trên website'),
          ),
          const SizedBox(height: 8),
          Text(
            AppConstants.privacyPolicyUrl,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không thể mở liên kết')));
    }
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
