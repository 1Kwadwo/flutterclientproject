import 'package:flutter/foundation.dart';
import '../models/appointment.dart';
import '../services/simple_storage.dart';
import '../services/notification_service.dart';

class AppointmentProvider with ChangeNotifier {
  final SimpleStorage _storage = SimpleStorage();
  final NotificationService _notificationService = NotificationService();

  List<Appointment> _appointments = [];
  bool _isLoading = false;

  List<Appointment> get appointments => _appointments;
  bool get isLoading => _isLoading;

  Future<void> loadAppointments() async {
    _isLoading = true;
    notifyListeners();

    try {
      _appointments = await _storage.getAppointmentsWithClients();
    } catch (e) {
      debugPrint('Error loading appointments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAppointment(Appointment appointment) async {
    try {
      final id = await _storage.insertAppointment(appointment);
      final newAppointment = appointment.copyWith(id: id);
      _appointments.add(newAppointment);
      _appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      // Schedule notification for the new appointment
      await _notificationService.scheduleAppointmentReminder(newAppointment);

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding appointment: $e');
      rethrow;
    }
  }

  Future<void> updateAppointment(Appointment appointment) async {
    try {
      await _storage.updateAppointment(appointment);

      // Cancel existing notifications and schedule new ones
      if (appointment.id != null) {
        await _notificationService.cancelAppointmentReminders(appointment.id!);
        await _notificationService.scheduleAppointmentReminder(appointment);
      }

      final index = _appointments.indexWhere((a) => a.id == appointment.id);
      if (index != -1) {
        _appointments[index] = appointment;
        _appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating appointment: $e');
      rethrow;
    }
  }

  Future<void> deleteAppointment(int id) async {
    try {
      debugPrint('Deleting appointment with ID: $id');
      await _storage.deleteAppointment(id);
      await _notificationService.cancelAppointmentReminders(id);
      // Reload all appointments to ensure UI is in sync
      await loadAppointments();
      debugPrint(
        'Appointment deleted successfully. Remaining appointments: ${_appointments.length}',
      );
    } catch (e) {
      debugPrint('Error deleting appointment: $e');
      rethrow;
    }
  }

  Future<List<Appointment>> getAppointmentsForDate(DateTime date) async {
    try {
      return await _storage.getAppointmentsForDate(date);
    } catch (e) {
      debugPrint('Error getting appointments for date: $e');
      return [];
    }
  }

  List<Appointment> getUpcomingAppointments() {
    final now = DateTime.now();
    return _appointments
        .where((appointment) => appointment.dateTime.isAfter(now))
        .toList();
  }

  List<Appointment> getTodayAppointments() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _appointments
        .where(
          (appointment) =>
              appointment.dateTime.isAfter(today) &&
              appointment.dateTime.isBefore(tomorrow),
        )
        .toList();
  }

  Appointment? getAppointmentById(int id) {
    try {
      return _appointments.firstWhere((appointment) => appointment.id == id);
    } catch (e) {
      return null;
    }
  }
}
