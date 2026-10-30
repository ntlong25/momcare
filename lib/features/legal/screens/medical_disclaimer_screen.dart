import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../widgets/legal_website_link.dart';

class MedicalDisclaimerScreen extends StatelessWidget {
  /// Published copy of this page, see [AppConstants.isPublishedUrl].
  final String websiteUrl;

  const MedicalDisclaimerScreen({
    super.key,
    this.websiteUrl = AppConstants.medicalDisclaimerUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tuyên bố miễn trừ y tế')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const MedicalDisclaimerBody(),
          LegalWebsiteLink(url: websiteUrl, label: 'Mở tuyên bố trên website'),
        ],
      ),
    );
  }
}

/// The disclaimer text, shared by this screen and the consent screen so
/// both always show the same wording.
class MedicalDisclaimerBody extends StatelessWidget {
  const MedicalDisclaimerBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MomCare+ không thay thế bác sĩ',
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
        const _DisclaimerSection(
          title: 'Thông tin chỉ để tham khảo',
          body:
              'Nội dung trong MomCare+ nhằm hỗ trợ ghi nhớ, theo dõi và tham khảo thông tin phổ biến về thai kỳ, dinh dưỡng, chu kỳ và sức khỏe.',
        ),
        const _DisclaimerSection(
          title: 'Không chẩn đoán hoặc điều trị',
          body:
              'Ứng dụng không đưa ra chẩn đoán, không kê đơn, không điều trị bệnh và không thay thế tư vấn trực tiếp từ bác sĩ, nữ hộ sinh hoặc nhân viên y tế có chuyên môn.',
        ),
        const _DisclaimerSection(
          title: 'Hãy liên hệ cơ sở y tế khi cần',
          body:
              'Nếu bạn có triệu chứng bất thường, đau nhiều, ra máu, sốt, khó thở, thay đổi cử động thai, dấu hiệu trầm cảm hoặc bất kỳ lo lắng nào về sức khỏe, hãy liên hệ bác sĩ hoặc đến cơ sở y tế gần nhất.',
        ),
        const _DisclaimerSection(
          title: 'Dữ liệu theo dõi có thể sai lệch',
          body:
              'Các chỉ số, dự đoán chu kỳ, ngày rụng trứng, ngày dự sinh và gợi ý dinh dưỡng chỉ mang tính hỗ trợ. Kết quả có thể không phù hợp với mọi người và cần được kiểm chứng bởi nhân viên y tế.',
        ),
      ],
    );
  }
}

class _DisclaimerSection extends StatelessWidget {
  final String title;
  final String body;

  const _DisclaimerSection({required this.title, required this.body});

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
