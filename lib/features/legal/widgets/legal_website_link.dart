import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';

/// Button that opens the published copy of a legal page, with its address.
/// Shows nothing until [url] is a real address, so a placeholder never
/// reaches users; the in-app text stays readable either way.
class LegalWebsiteLink extends StatelessWidget {
  final String url;
  final String label;

  const LegalWebsiteLink({super.key, required this.url, required this.label});

  @override
  Widget build(BuildContext context) {
    if (!AppConstants.isPublishedUrl(url)) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => _open(context),
          icon: const Icon(Icons.open_in_new),
          label: Text(label),
        ),
        const SizedBox(height: 8),
        Text(
          url,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _open(BuildContext context) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không thể mở liên kết')));
    }
  }
}
