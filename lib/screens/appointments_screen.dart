import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/appointment_provider.dart';
import '../providers/client_provider.dart';
import '../models/appointment.dart';
import '../models/client.dart';
import 'appointment_form_screen.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AppointmentProvider>().loadAppointments();
            },
          ),
        ],
      ),
      body: Consumer<AppointmentProvider>(
        builder: (context, appointmentProvider, child) {
          if (appointmentProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (appointmentProvider.appointments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No appointments yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first appointment',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointmentProvider.appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointmentProvider.appointments[index];
              return AppointmentCard(appointment: appointment);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AppointmentFormScreen(),
            ),
          );
          if (result == true) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Appointment added successfully')),
              );
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;

  const AppointmentCard({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    final isPast = appointment.dateTime.isBefore(DateTime.now());
    final isToday = appointment.dateTime.day == DateTime.now().day &&
        appointment.dateTime.month == DateTime.now().month &&
        appointment.dateTime.year == DateTime.now().year;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: isPast
              ? Colors.grey
              : isToday
                  ? Colors.orange
                  : Colors.blue,
          child: Icon(
            isPast ? Icons.check : Icons.schedule,
            color: Colors.white,
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
              DateFormat('MMM dd, yyyy - HH:mm').format(appointment.dateTime),
              style: TextStyle(
                color: isPast ? Colors.grey : null,
              ),
            ),
            if (appointment.client != null) ...[
              const SizedBox(height: 4),
              Text(
                'With: ${appointment.client!.name}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (appointment.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                appointment.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AppointmentFormScreen(
                      appointment: appointment,
                    ),
                  ),
                );
                break;
              case 'complete':
                final updatedAppointment = appointment.copyWith(
                  isCompleted: !appointment.isCompleted,
                );
                await context.read<AppointmentProvider>().updateAppointment(updatedAppointment);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        updatedAppointment.isCompleted
                            ? 'Appointment marked as completed'
                            : 'Appointment marked as pending',
                      ),
                    ),
                  );
                }
                break;
              case 'delete':
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Appointment'),
                    content: const Text('Are you sure you want to delete this appointment?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await context.read<AppointmentProvider>().deleteAppointment(appointment.id!);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Appointment deleted')),
                    );
                  }
                }
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'complete',
              child: Row(
                children: [
                  Icon(appointment.isCompleted ? Icons.undo : Icons.check),
                  const SizedBox(width: 8),
                  Text(appointment.isCompleted ? 'Mark as Pending' : 'Mark as Completed'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
