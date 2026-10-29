import 'package:flutter/material.dart';

/// Delete confirmation used by the counter tools. Returns true on "Xóa".
Future<bool> confirmToolDelete(
  BuildContext context, {
  required String title,
  String? message,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          key: const ValueKey('tool-confirm-delete'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
  return confirmed == true;
}
