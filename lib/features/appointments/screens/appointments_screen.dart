import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/services/database_service.dart';
import '../../../core/models/appointment_model.dart';
import '../../../core/utils/date_formatter.dart';
import '../widgets/appointment_card.dart';
import 'add_appointment_screen.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDay = _focusedDay;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month), text: 'Calendar'),
            Tab(icon: Icon(Icons.list), text: 'List'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalendarView(),
          _buildListView(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddAppointmentScreen(),
            ),
          );
          if (result == true && mounted) {
            setState(() {});
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Appointment'),
      ),
    );
  }

  Widget _buildCalendarView() {
    final appointments = DatabaseService.getAllAppointments();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              eventLoader: (day) {
                return appointments.where((apt) {
                  return isSameDay(apt.dateTime, day);
                }).toList();
              },
              calendarStyle: CalendarStyle(
                markersMaxCount: 3,
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).primaryColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                formatButtonTextStyle: TextStyle(
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildAppointmentsForSelectedDay(appointments),
        ],
      ),
    );
  }

  Widget _buildAppointmentsForSelectedDay(List<AppointmentModel> allAppointments) {
    final selectedAppointments = allAppointments.where((apt) {
      return isSameDay(apt.dateTime, _selectedDay);
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appointments on ${DateFormatter.formatDate(_selectedDay!)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (selectedAppointments.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No appointments on this day',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...selectedAppointments.map((apt) {
                return AppointmentCard(
                  appointment: apt,
                  onTap: () => _viewAppointment(apt),
                  onDelete: () async {
                    await DatabaseService.deleteAppointment(apt.id);
                    setState(() {});
                  },
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    final appointments = DatabaseService.getAllAppointments();
    final upcomingAppointments = appointments
        .where((apt) => apt.dateTime.isAfter(DateTime.now()))
        .toList();
    final pastAppointments = appointments
        .where((apt) => apt.dateTime.isBefore(DateTime.now()))
        .toList();

    if (appointments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 100,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'No Appointments Yet',
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Add your first appointment to get started',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (upcomingAppointments.isNotEmpty) ...[
              Text(
                'Upcoming',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ...upcomingAppointments.map((apt) {
                return AppointmentCard(
                  appointment: apt,
                  onTap: () => _viewAppointment(apt),
                  onDelete: () async {
                    await DatabaseService.deleteAppointment(apt.id);
                    setState(() {});
                  },
                );
              }),
              const SizedBox(height: 24),
            ],
            if (pastAppointments.isNotEmpty) ...[
              Text(
                'Past Appointments',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 12),
              ...pastAppointments.map((apt) {
                return AppointmentCard(
                  appointment: apt,
                  isPast: true,
                  onTap: () => _viewAppointment(apt),
                  onDelete: () async {
                    await DatabaseService.deleteAppointment(apt.id);
                    setState(() {});
                  },
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _viewAppointment(AppointmentModel appointment) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddAppointmentScreen(appointment: appointment),
      ),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }
}
