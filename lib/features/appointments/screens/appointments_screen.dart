import 'package:flutter/material.dart';
import '../../../core/theme/app_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/appointment_reminder_service.dart';
import '../../../core/services/database_service.dart';
import '../../../core/widgets/hive_boxes_listener.dart';
import '../../../core/models/appointment_model.dart';
import '../../../core/utils/calendar_style.dart';
import '../../../core/utils/date_formatter.dart';
import '../widgets/appointment_card.dart';
import 'add_appointment_screen.dart';
import '../../../core/widgets/empty_state.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  final bool showAppBar;

  const AppointmentsScreen({super.key, this.showAppBar = true});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen>
    with SingleTickerProviderStateMixin, HiveRefreshMixin {
  @override
  List<String> get watchedBoxes => const [AppConstants.appointmentBox];

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
    final tabBar = TabBar(
      controller: _tabController,
      tabs: const [
        Tab(icon: Icon(Icons.calendar_month), text: 'Lịch'),
        Tab(icon: Icon(Icons.list), text: 'Danh sách'),
      ],
    );
    final tabBarView = TabBarView(
      controller: _tabController,
      children: [_buildCalendarView(), _buildListView()],
    );

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(title: const Text('Lịch hẹn'), bottom: tabBar)
          : null,
      body: widget.showAppBar
          ? tabBarView
          : Column(
              children: [
                tabBar,
                Expanded(child: tabBarView),
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
        label: const Text('Thêm lịch hẹn'),
      ),
    );
  }

  Widget _buildCalendarView() {
    final appointments = DatabaseService.getAllAppointments();

    return SingleChildScrollView(
      padding: AppSpacing.fabPagePadding,
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
              calendarStyle: AppCalendarStyle.calendar(
                context,
                markersMaxCount: 3,
              ),
              daysOfWeekStyle: AppCalendarStyle.daysOfWeek(context),
              headerStyle: AppCalendarStyle.header(context),
            ),
          ),
          const SizedBox(height: 16),
          _buildAppointmentsForSelectedDay(appointments),
        ],
      ),
    );
  }

  Widget _buildAppointmentsForSelectedDay(
    List<AppointmentModel> allAppointments,
  ) {
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
              'Lịch hẹn ngày ${DateFormatter.formatDate(_selectedDay!)}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Không có lịch hẹn trong ngày này',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    await AppointmentReminderService.delete(apt.id);
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
      return const Center(
        child: SingleChildScrollView(
          child: AppEmptyState(
            icon: Icons.calendar_today_outlined,
            title: 'Chưa có lịch hẹn',
            message: 'Thêm lịch hẹn đầu tiên để bắt đầu',
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
        padding: AppSpacing.fabPagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (upcomingAppointments.isNotEmpty) ...[
              Text(
                'Sắp tới',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...upcomingAppointments.map((apt) {
                return AppointmentCard(
                  appointment: apt,
                  onTap: () => _viewAppointment(apt),
                  onDelete: () async {
                    await AppointmentReminderService.delete(apt.id);
                    setState(() {});
                  },
                );
              }),
              const SizedBox(height: 24),
            ],
            if (pastAppointments.isNotEmpty) ...[
              Text(
                'Lịch hẹn đã qua',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              ...pastAppointments.map((apt) {
                return AppointmentCard(
                  appointment: apt,
                  isPast: true,
                  onTap: () => _viewAppointment(apt),
                  onDelete: () async {
                    await AppointmentReminderService.delete(apt.id);
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
