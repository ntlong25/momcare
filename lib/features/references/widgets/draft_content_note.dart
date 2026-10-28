import 'package:flutter/material.dart';

/// Banner for content-engine items whose `reviewStatus` is not `approved`.
class DraftContentNote extends StatelessWidget {
  const DraftContentNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(child: Text('Nội dung đang chờ bác sĩ duyệt')),
        ],
      ),
    );
  }
}
