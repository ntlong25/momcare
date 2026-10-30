import 'package:flutter/material.dart';
import '../../../core/services/database_service.dart';
import '../../../core/models/appointment_model.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';

class UpcomingAppointmentsCard extends StatelessWidget {
  const UpcomingAppointmentsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final appointments = DatabaseService.getUpcomingAppointments();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Lịch hẹn sắp tới',
          trailing: TextButton(
            onPressed: () => NavigationHelper.toAppointments(context),
            child: const Text('Xem tất cả'),
          ),
        ),
        appointments.isEmpty
            ? SizedBox(
                width: double.infinity,
                child: AppCard(
                  child: AppEmptyState(
                    key: const ValueKey('home-upcoming-empty'),
                    icon: Icons.event_available,
                    title: 'Chưa có lịch hẹn nào',
                    iconSize: 48,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    action: TextButton.icon(
                      onPressed: () =>
                          NavigationHelper.toAddAppointment(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm lịch hẹn'),
                    ),
                  ),
                ),
              )
            : Column(
                children: appointments.take(3).map((appointment) {
                  return _AppointmentCard(appointment: appointment);
                }).toList(),
              ),
      ],
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;

  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.calendar_today,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          appointment.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(DateFormatter.formatDateTime(appointment.dateTime)),
            if (appointment.location != null) ...[
              const SizedBox(height: 2),
              Text(appointment.location!),
            ],
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        isThreeLine: appointment.location != null,
        onTap: () => NavigationHelper.toAppointments(context),
      ),
    );
  }
}
