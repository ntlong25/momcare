import 'package:flutter/material.dart';
import '../../../core/services/database_service.dart';
import '../../../core/models/appointment_model.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/navigation_helper.dart';

class UpcomingAppointmentsCard extends StatelessWidget {
  const UpcomingAppointmentsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final appointments = DatabaseService.getUpcomingAppointments();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Appointments',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () => NavigationHelper.toAppointments(context),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        appointments.isEmpty
            ? Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No upcoming appointments',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => NavigationHelper.toAddAppointment(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Appointment'),
                        ),
                      ],
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
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.calendar_today,
            color: Theme.of(context).primaryColor,
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
          color: Colors.grey[400],
        ),
        isThreeLine: appointment.location != null,
        onTap: () => NavigationHelper.toAppointments(context),
      ),
    );
  }
}
