import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/appointment_provider.dart';
import '../models/appointment.dart';
import 'appointment_form_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Appointment>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  void _loadEvents() {
    final appointmentProvider = context.read<AppointmentProvider>();
    final appointments = appointmentProvider.appointments;
    
    _events.clear();
    for (final appointment in appointments) {
      final date = DateTime(
        appointment.dateTime.year,
        appointment.dateTime.month,
        appointment.dateTime.day,
      );
      if (_events[date] == null) _events[date] = [];
      _events[date]!.add(appointment);
    }
  }

  List<Appointment> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AppointmentProvider>().loadAppointments();
              setState(() {
                _loadEvents();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar<Appointment>(
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
            eventLoader: _getEventsForDay,
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: TextStyle(color: Colors.red),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer<AppointmentProvider>(
              builder: (context, appointmentProvider, child) {
                if (appointmentProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final selectedEvents = _selectedDay != null
                    ? _getEventsForDay(_selectedDay!)
                    : [];

                if (selectedEvents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedDay != null
                              ? 'No appointments on ${DateFormat('MMM dd, yyyy').format(_selectedDay!)}'
                              : 'Select a date to view appointments',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        if (_selectedDay != null) ...[
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AppointmentFormScreen(),
                                ),
                              );
                              if (result == true) {
                                setState(() {
                                  _loadEvents();
                                });
                              }
                            },
                            child: const Text('Add Appointment'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: selectedEvents.length,
                  itemBuilder: (context, index) {
                    final appointment = selectedEvents[index];
                    return CalendarAppointmentCard(appointment: appointment);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedDay != null
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AppointmentFormScreen(),
                  ),
                );
                if (result == true) {
                  setState(() {
                    _loadEvents();
                  });
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class CalendarAppointmentCard extends StatelessWidget {
  final Appointment appointment;

  const CalendarAppointmentCard({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    final isPast = appointment.dateTime.isBefore(DateTime.now());
    final isToday = appointment.dateTime.day == DateTime.now().day &&
        appointment.dateTime.month == DateTime.now().month &&
        appointment.dateTime.year == DateTime.now().year;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: isPast
              ? Colors.grey
              : isToday
                  ? Colors.orange
                  : Colors.blue,
          child: Icon(
            isPast ? Icons.check : Icons.schedule,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          appointment.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: appointment.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(appointment.dateTime),
              style: TextStyle(
                color: isPast ? Colors.grey : null,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (appointment.client != null) ...[
              const SizedBox(height: 2),
              Text(
                'With: ${appointment.client!.name}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AppointmentFormScreen(
                  appointment: appointment,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
