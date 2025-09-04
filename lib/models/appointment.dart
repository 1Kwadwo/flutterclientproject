import 'client.dart';

class Appointment {
  final int? id;
  final int clientId;
  final String title;
  final String description;
  final DateTime dateTime;
  final bool isCompleted;
  final DateTime createdAt;
  final Client? client; // For joining with client data

  Appointment({
    this.id,
    required this.clientId,
    required this.title,
    required this.description,
    required this.dateTime,
    this.isCompleted = false,
    DateTime? createdAt,
    this.client,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map, {Client? client}) {
    return Appointment(
      id: map['id'],
      clientId: map['clientId'],
      title: map['title'],
      description: map['description'],
      dateTime: DateTime.parse(map['dateTime']),
      isCompleted: map['isCompleted'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      client: client,
    );
  }

  Appointment copyWith({
    int? id,
    int? clientId,
    String? title,
    String? description,
    DateTime? dateTime,
    bool? isCompleted,
    DateTime? createdAt,
    Client? client,
  }) {
    return Appointment(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      client: client ?? this.client,
    );
  }

  @override
  String toString() {
    return 'Appointment(id: $id, clientId: $clientId, title: $title, description: $description, dateTime: $dateTime, isCompleted: $isCompleted, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Appointment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
