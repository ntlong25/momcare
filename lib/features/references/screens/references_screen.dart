import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/data/medical_references.dart';

class ReferencesScreen extends StatelessWidget {
  const ReferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = MedicalReferenceGroup.values;

    return Scaffold(
      appBar: AppBar(title: const Text('Nguồn tham khảo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildIntro(context),
          const SizedBox(height: 16),
          ...groups.map((group) => _ReferenceGroupCard(group: group)),
        ],
      ),
    );
  }

  Widget _buildIntro(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cách MomCare+ dùng nguồn',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Các nội dung sức khỏe trong app được viết theo hướng tham khảo, ưu tiên nguồn từ Bộ Y tế Việt Nam, WHO và CDC. Nội dung không thay thế tư vấn, chẩn đoán hoặc điều trị từ nhân viên y tế.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Cập nhật lần cuối: ${MedicalReferenceData.lastUpdated}',
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferenceGroupCard extends StatelessWidget {
  final MedicalReferenceGroup group;

  const _ReferenceGroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final references = MedicalReferenceData.byGroup(group);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Icon(MedicalReferenceData.iconForGroup(group)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      MedicalReferenceData.labelForGroup(group),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...references.map(
              (reference) => ListTile(
                title: Text(reference.title),
                subtitle: Text(reference.organization),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _openUrl(reference.url),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
