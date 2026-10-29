import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/my_clinic.dart';
import '../../../core/services/my_clinic_service.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../guides/guide_actions.dart';
import '../../../core/widgets/app_card.dart';

/// Quick actions for "Nơi khám của tôi" on Hôm nay and the emergency screen
/// (B9). [emergency] adds "Tìm bệnh viện gần tôi" and a red call button.
class MyClinicCard extends ConsumerWidget {
  final bool emergency;

  const MyClinicCard({super.key, this.emergency = false});

  static Future<void> findNearbyHospital(BuildContext context) =>
      GuideActions.launchUri(
        context,
        GuideActions.mapsSearchUri(GuideActions.nearbyHospitalQuery),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clinic = ref.watch(myClinicProvider);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return AppCard(
      key: const ValueKey('my-clinic-card'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.local_hospital_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Nơi khám của tôi',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (clinic.isEmpty)
            Text(
              'Lưu tên và số điện thoại nơi khám để gọi nhanh khi cần',
              style: theme.textTheme.bodyMedium,
            )
          else
            ..._details(theme, clinic, muted),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _actions(context, theme, clinic),
          ),
        ],
      ),
    );
  }

  List<Widget> _details(ThemeData theme, MyClinic clinic, Color muted) {
    return [
      if (clinic.name.isNotEmpty)
        Text(
          clinic.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      if (clinic.doctor.isNotEmpty) ...[
        const SizedBox(height: 2),
        Text('BS. ${clinic.doctor}', style: theme.textTheme.bodyMedium),
      ],
      if (clinic.phone.isNotEmpty) ...[
        const SizedBox(height: 2),
        Text(
          clinic.phone,
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
        ),
      ],
      if (clinic.address.isNotEmpty) ...[
        const SizedBox(height: 2),
        Text(
          clinic.address,
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
      ],
    ];
  }

  List<Widget> _actions(
    BuildContext context,
    ThemeData theme,
    MyClinic clinic,
  ) {
    final mapsQuery = clinic.mapsQuery;
    return [
      if (clinic.isEmpty)
        FilledButton.tonalIcon(
          key: const ValueKey('my-clinic-add'),
          onPressed: () => NavigationHelper.toMyClinic(context),
          icon: const Icon(Icons.add),
          label: const Text('Thêm nơi khám'),
        )
      else ...[
        if (clinic.hasPhone)
          emergency
              ? FilledButton.icon(
                  key: const ValueKey('my-clinic-call'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: () => GuideActions.launchUri(
                    context,
                    GuideActions.phoneUri(clinic.phone),
                  ),
                  icon: const Icon(Icons.call),
                  label: const Text('Gọi'),
                )
              : FilledButton.tonalIcon(
                  key: const ValueKey('my-clinic-call'),
                  onPressed: () => GuideActions.launchUri(
                    context,
                    GuideActions.phoneUri(clinic.phone),
                  ),
                  icon: const Icon(Icons.call),
                  label: const Text('Gọi'),
                ),
        if (mapsQuery != null)
          OutlinedButton.icon(
            key: const ValueKey('my-clinic-map'),
            onPressed: () => GuideActions.launchUri(
              context,
              GuideActions.mapsSearchUri(mapsQuery),
            ),
            icon: const Icon(Icons.map_outlined),
            label: const Text('Bản đồ'),
          ),
        TextButton.icon(
          key: const ValueKey('my-clinic-edit'),
          onPressed: () => NavigationHelper.toMyClinic(context),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Sửa'),
        ),
      ],
      if (emergency)
        OutlinedButton.icon(
          key: const ValueKey('find-hospital-button'),
          onPressed: () => findNearbyHospital(context),
          icon: const Icon(Icons.local_hospital_outlined),
          label: const Text('Tìm bệnh viện gần tôi'),
        ),
    ];
  }
}
