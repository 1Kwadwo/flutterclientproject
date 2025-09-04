import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/appointment.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
  }

  Future<void> scheduleAppointmentReminder(Appointment appointment) async {
    // Schedule reminder 30 minutes before appointment
    final reminderTime = appointment.dateTime.subtract(const Duration(minutes: 30));
    
    // Only schedule if the reminder time is in the future
    if (reminderTime.isAfter(DateTime.now())) {
      await _notifications.zonedSchedule(
        appointment.id ?? 0,
        'Appointment Reminder',
        'You have an appointment with ${appointment.client?.name ?? 'Client'} in 30 minutes: ${appointment.title}',
        tz.TZDateTime.from(reminderTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'appointment_reminders',
            'Appointment Reminders',
            channelDescription: 'Notifications for appointment reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // Schedule reminder 1 hour before appointment
    final reminderTime1Hour = appointment.dateTime.subtract(const Duration(hours: 1));
    
    if (reminderTime1Hour.isAfter(DateTime.now())) {
      await _notifications.zonedSchedule(
        (appointment.id ?? 0) + 1000, // Different ID for 1-hour reminder
        'Appointment Reminder',
        'You have an appointment with ${appointment.client?.name ?? 'Client'} in 1 hour: ${appointment.title}',
        tz.TZDateTime.from(reminderTime1Hour, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'appointment_reminders',
            'Appointment Reminders',
            channelDescription: 'Notifications for appointment reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelAppointmentReminders(int appointmentId) async {
    await _notifications.cancel(appointmentId);
    await _notifications.cancel(appointmentId + 1000); // Cancel 1-hour reminder too
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
