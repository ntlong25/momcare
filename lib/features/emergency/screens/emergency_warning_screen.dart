import 'package:flutter/material.dart';
import '../../../core/data/medical_references.dart';
import '../../../core/theme/app_tokens.dart';
import '../../guides/guide_actions.dart';
import '../../references/widgets/source_metadata_card.dart';
import '../../settings/widgets/my_clinic_card.dart';

class EmergencyWarningScreen extends StatelessWidget {
  final bool showAppBar;

  const EmergencyWarningScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(title: const Text('Dấu hiệu cần đi khám ngay'))
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildCall115(context),
          const SizedBox(height: 16),
          _WarningGroup(
            icon: Icons.pregnant_woman,
            title: 'Trong thai kỳ',
            items: const [
              'Ra máu âm đạo hoặc rỉ nước âm đạo bất thường.',
              'Đau bụng dữ dội, đau tăng dần hoặc đau không giảm.',
              'Đau đầu dữ dội, nhìn mờ, hoa mắt hoặc sưng nhiều ở mặt, tay.',
              'Sốt cao, rét run hoặc quá mệt, không thể sinh hoạt bình thường.',
              'Co giật, ngất, khó thở, đau ngực hoặc tim đập bất thường.',
              'Thai máy ít hơn rõ rệt hoặc không cảm nhận được thai máy như thường lệ.',
            ],
          ),
          const SizedBox(height: 12),
          _WarningGroup(
            icon: Icons.healing,
            title: 'Sau sinh',
            items: const [
              'Chảy máu nhiều, máu thấm ướt băng nhanh hoặc có cục máu lớn.',
              'Sốt, đau bụng tăng, sản dịch có mùi hôi hoặc đau vùng chậu nhiều.',
              'Đau, đỏ, sưng một bên chân hoặc đau bắp chân.',
              'Khó thở, đau ngực, chóng mặt nhiều hoặc ngất.',
              'Vết mổ hoặc vết khâu sưng đỏ, chảy dịch, đau tăng hoặc có mùi lạ.',
            ],
          ),
          const SizedBox(height: 12),
          _WarningGroup(
            icon: Icons.psychology_alt,
            title: 'Sức khỏe tinh thần',
            items: const [
              'Có ý nghĩ làm hại bản thân, em bé hoặc người khác.',
              'Cảm thấy tuyệt vọng, hoảng loạn dữ dội hoặc mất kiểm soát.',
              'Không ngủ được nhiều ngày, lú lẫn, nghe hoặc thấy điều người khác không thấy.',
              'Buồn bã, lo âu hoặc sợ hãi kéo dài làm bạn không thể chăm sóc bản thân hoặc em bé.',
            ],
          ),
          const SizedBox(height: 16),
          _buildActionCard(context),
          const SizedBox(height: 16),
          const MyClinicCard(emergency: true),
          const SizedBox(height: 16),
          const SourceMetadataCard(
            group: MedicalReferenceGroup.urgentWarning,
            note:
                'Danh sách này không bao phủ mọi tình huống. Nếu bạn thấy có điều gì không ổn, hãy liên hệ nhân viên y tế.',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Weaker than the "Gọi 115" button, the strongest element here.
        color: semantic.emergencyContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: semantic.onEmergencyContainer,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đừng chờ nếu có dấu hiệu bất thường',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: semantic.onEmergencyContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nội dung này chỉ giúp bạn nhận biết dấu hiệu cần đi khám. MomCare+ không thay thế bác sĩ, cơ sở y tế hoặc dịch vụ cấp cứu.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: semantic.onEmergencyContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCall115(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          key: const ValueKey('emergency-call-115'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            backgroundColor: context.semantic.emergency,
            foregroundColor: context.semantic.onEmergency,
            textStyle: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () =>
              GuideActions.launchUri(context, GuideActions.phoneUri('115')),
          icon: const Icon(Icons.call),
          label: const Text('Gọi 115 (cấp cứu)'),
        ),
        const SizedBox(height: 6),
        Text(
          'Nút này chỉ mở màn hình gọi điện với số 115. Bạn cần tự bấm gọi.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn nên làm gì?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nếu bạn đang có một trong các dấu hiệu trên, hãy liên hệ bác sĩ đang theo dõi thai kỳ hoặc đến cơ sở y tế gần nhất. Nếu tình trạng có vẻ khẩn cấp, hãy gọi 115 hoặc số cấp cứu tại địa phương.',
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningGroup extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;

  const _WarningGroup({
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.circle, size: 7, color: theme.colorScheme.error),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
