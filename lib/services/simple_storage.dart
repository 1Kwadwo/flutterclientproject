import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/client.dart';
import '../models/appointment.dart';

class SimpleStorage {
  static final SimpleStorage _instance = SimpleStorage._internal();
  factory SimpleStorage() => _instance;
  SimpleStorage._internal();

  static const String _clientsKey = 'clients';
  static const String _appointmentsKey = 'appointments';

  // Client operations
  Future<int> insertClient(Client client) async {
    final prefs = await SharedPreferences.getInstance();
    final clientsJson = prefs.getStringList(_clientsKey) ?? [];

    final newId = clientsJson.isEmpty ? 1 : _getNextId(clientsJson);
    final newClient = client.copyWith(id: newId);

    clientsJson.add(jsonEncode(newClient.toMap()));
    await prefs.setStringList(_clientsKey, clientsJson);

    return newId;
  }

  Future<List<Client>> getAllClients() async {
    final prefs = await SharedPreferences.getInstance();
    final clientsJson = prefs.getStringList(_clientsKey) ?? [];

    return clientsJson.map((json) => Client.fromMap(jsonDecode(json))).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<Client?> getClient(int id) async {
    final clients = await getAllClients();
    try {
      return clients.firstWhere((client) => client.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<int> updateClient(Client client) async {
    final prefs = await SharedPreferences.getInstance();
    final clientsJson = prefs.getStringList(_clientsKey) ?? [];

    final index = clientsJson.indexWhere((json) {
      final clientMap = jsonDecode(json);
      return clientMap['id'] == client.id;
    });

    if (index != -1) {
      clientsJson[index] = jsonEncode(client.toMap());
      await prefs.setStringList(_clientsKey, clientsJson);
      return 1;
    }
    return 0;
  }

  Future<int> deleteClient(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final clientsJson = prefs.getStringList(_clientsKey) ?? [];

    final newClientsJson = clientsJson.where((json) {
      final clientMap = jsonDecode(json);
      return clientMap['id'] != id;
    }).toList();

    await prefs.setStringList(_clientsKey, newClientsJson);

    // Also delete all appointments for this client
    final appointmentsJson = prefs.getStringList(_appointmentsKey) ?? [];
    final newAppointmentsJson = appointmentsJson.where((json) {
      final appointmentMap = jsonDecode(json);
      return appointmentMap['clientId'] != id;
    }).toList();

    await prefs.setStringList(_appointmentsKey, newAppointmentsJson);
    return 1;
  }

  // Appointment operations
  Future<int> insertAppointment(Appointment appointment) async {
    final prefs = await SharedPreferences.getInstance();
    final appointmentsJson = prefs.getStringList(_appointmentsKey) ?? [];

    final newId = appointmentsJson.isEmpty ? 1 : _getNextId(appointmentsJson);
    final newAppointment = appointment.copyWith(id: newId);

    appointmentsJson.add(jsonEncode(newAppointment.toMap()));
    await prefs.setStringList(_appointmentsKey, appointmentsJson);

    return newId;
  }

  Future<List<Appointment>> getAllAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final appointmentsJson = prefs.getStringList(_appointmentsKey) ?? [];

    return appointmentsJson
        .map((json) => Appointment.fromMap(jsonDecode(json)))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Future<List<Appointment>> getAppointmentsWithClients() async {
    final appointments = await getAllAppointments();
    final clients = await getAllClients();

    return appointments.map((appointment) {
      final client = clients.firstWhere(
        (c) => c.id == appointment.clientId,
        orElse: () =>
            Client(id: 0, name: 'Unknown', email: '', phoneNumber: ''),
      );
      return appointment.copyWith(client: client);
    }).toList();
  }

  Future<List<Appointment>> getAppointmentsForDate(DateTime date) async {
    final appointments = await getAppointmentsWithClients();
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return appointments
        .where(
          (appointment) =>
              appointment.dateTime.isAfter(startOfDay) &&
              appointment.dateTime.isBefore(endOfDay),
        )
        .toList();
  }

  Future<Appointment?> getAppointment(int id) async {
    final appointments = await getAllAppointments();
    try {
      return appointments.firstWhere((appointment) => appointment.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<int> updateAppointment(Appointment appointment) async {
    final prefs = await SharedPreferences.getInstance();
    final appointmentsJson = prefs.getStringList(_appointmentsKey) ?? [];

    final index = appointmentsJson.indexWhere((json) {
      final appointmentMap = jsonDecode(json);
      return appointmentMap['id'] == appointment.id;
    });

    if (index != -1) {
      appointmentsJson[index] = jsonEncode(appointment.toMap());
      await prefs.setStringList(_appointmentsKey, appointmentsJson);
      return 1;
    }
    return 0;
  }

  Future<int> deleteAppointment(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final appointmentsJson = prefs.getStringList(_appointmentsKey) ?? [];

    final newAppointmentsJson = appointmentsJson.where((json) {
      final appointmentMap = jsonDecode(json);
      return appointmentMap['id'] != id;
    }).toList();

    await prefs.setStringList(_appointmentsKey, newAppointmentsJson);
    return 1;
  }

  int _getNextId(List<String> items) {
    if (items.isEmpty) return 1;

    int maxId = 0;
    for (final item in items) {
      final map = jsonDecode(item);
      final id = map['id'] as int? ?? 0;
      if (id > maxId) maxId = id;
    }
    return maxId + 1;
  }
}
