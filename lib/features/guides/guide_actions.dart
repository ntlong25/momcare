import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/guide_models.dart';
import '../../core/models/pregnancy_model.dart';
import '../../core/services/database_service.dart';
import '../appointments/screens/add_appointment_screen.dart';

/// Handles content-engine actions (`addAppointment`, `openMaps`, `call`).
class GuideActions {
  /// Maps search used by "Tìm bệnh viện gần tôi" (no location permission).
  static const String nearbyHospitalQuery = 'bệnh viện phụ sản';

  /// Replaces `launchUrl` in tests; returns whether the URI opened.
  @visibleForTesting
  static Future<bool> Function(Uri uri)? debugLauncher;

  /// Estimated date for pregnancy [week] based on the active pregnancy:
  /// pregnancy start (due date - 280 days) + week * 7 days. Dates in the past
  /// are moved to today. Returns null without a pregnancy or week.
  static DateTime? estimatedDateForWeek(
    PregnancyModel? pregnancy,
    int? week, {
    DateTime? now,
  }) {
    if (pregnancy == null || week == null) return null;
    final start = pregnancy.pregnancyStartDate;
    final estimated = DateTime(start.year, start.month, start.day + week * 7);
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    return estimated.isBefore(today) ? today : estimated;
  }

  static Uri mapsSearchUri(String query) => Uri.https(
    'www.google.com',
    '/maps/search/',
    {'api': '1', 'query': query},
  );

  static Uri phoneUri(String number) =>
      Uri(scheme: 'tel', path: number.replaceAll(RegExp(r'[^0-9+]'), ''));

  static String defaultLabel(GuideActionType type) => switch (type) {
    GuideActionType.addAppointment => 'Thêm vào lịch hẹn',
    GuideActionType.openMaps => 'Tìm trên bản đồ',
    GuideActionType.call => 'Gọi',
    GuideActionType.none => '',
  };

  static IconData icon(GuideActionType type) => switch (type) {
    GuideActionType.addAppointment => Icons.event_available,
    GuideActionType.openMaps => Icons.map_outlined,
    GuideActionType.call => Icons.call,
    GuideActionType.none => Icons.chevron_right,
  };

  static Future<void> run(
    BuildContext context, {
    required GuideActionType type,
    required String title,
    String? value,
    int? week,
  }) async {
    switch (type) {
      case GuideActionType.none:
        return;
      case GuideActionType.addAppointment:
        PregnancyModel? pregnancy;
        try {
          pregnancy = DatabaseService.getActivePregnancy();
        } catch (_) {
          pregnancy = null;
        }
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddAppointmentScreen(
              initialTitle: title,
              initialDate: estimatedDateForWeek(pregnancy, week),
            ),
          ),
        );
        return;
      case GuideActionType.openMaps:
        final query = (value == null || value.isEmpty) ? title : value;
        await launchUri(context, mapsSearchUri(query));
        return;
      case GuideActionType.call:
        if (value == null || value.isEmpty) return;
        await launchUri(context, phoneUri(value));
        return;
    }
  }

  /// Opens [uri] in an external app; shows a snackbar when nothing opens.
  static Future<void> launchUri(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    var opened = false;
    try {
      final launcher = debugLauncher;
      opened = launcher != null
          ? await launcher(uri)
          : await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Không mở được ứng dụng phù hợp')),
      );
    }
  }
}
