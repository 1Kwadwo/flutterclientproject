import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../models/client.dart';
import '../models/appointment.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Initialize sqflite_ffi for desktop platforms (not web)
    if (!kIsWeb && Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path = join(await getDatabasesPath(), 'appointment_scheduler.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create clients table
    await db.execute('''
      CREATE TABLE clients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phoneNumber TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create appointments table
    await db.execute('''
      CREATE TABLE appointments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientId INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (clientId) REFERENCES clients (id) ON DELETE CASCADE
      )
    ''');
  }

  // Client operations
  Future<int> insertClient(Client client) async {
    final db = await database;
    return await db.insert('clients', client.toMap());
  }

  Future<List<Client>> getAllClients() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clients',
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Client.fromMap(maps[i]));
  }

  Future<Client?> getClient(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Client.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateClient(Client client) async {
    final db = await database;
    return await db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<int> deleteClient(int id) async {
    final db = await database;
    return await db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  // Appointment operations
  Future<int> insertAppointment(Appointment appointment) async {
    final db = await database;
    return await db.insert('appointments', appointment.toMap());
  }

  Future<List<Appointment>> getAllAppointments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'appointments',
      orderBy: 'dateTime ASC',
    );
    return List.generate(maps.length, (i) => Appointment.fromMap(maps[i]));
  }

  Future<List<Appointment>> getAppointmentsWithClients() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        a.*,
        c.id as client_id,
        c.name as client_name,
        c.email as client_email,
        c.phoneNumber as client_phone,
        c.createdAt as client_created_at
      FROM appointments a
      LEFT JOIN clients c ON a.clientId = c.id
      ORDER BY a.dateTime ASC
    ''');

    return List.generate(maps.length, (i) {
      final map = maps[i];
      final client = Client.fromMap({
        'id': map['client_id'],
        'name': map['client_name'],
        'email': map['client_email'],
        'phoneNumber': map['client_phone'],
        'createdAt': map['client_created_at'],
      });
      return Appointment.fromMap(map, client: client);
    });
  }

  Future<List<Appointment>> getAppointmentsForDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT 
        a.*,
        c.id as client_id,
        c.name as client_name,
        c.email as client_email,
        c.phoneNumber as client_phone,
        c.createdAt as client_created_at
      FROM appointments a
      LEFT JOIN clients c ON a.clientId = c.id
      WHERE a.dateTime >= ? AND a.dateTime < ?
      ORDER BY a.dateTime ASC
    ''',
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];
      final client = Client.fromMap({
        'id': map['client_id'],
        'name': map['client_name'],
        'email': map['client_email'],
        'phoneNumber': map['client_phone'],
        'createdAt': map['client_created_at'],
      });
      return Appointment.fromMap(map, client: client);
    });
  }

  Future<Appointment?> getAppointment(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'appointments',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Appointment.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateAppointment(Appointment appointment) async {
    final db = await database;
    return await db.update(
      'appointments',
      appointment.toMap(),
      where: 'id = ?',
      whereArgs: [appointment.id],
    );
  }

  Future<int> deleteAppointment(int id) async {
    final db = await database;
    return await db.delete('appointments', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
