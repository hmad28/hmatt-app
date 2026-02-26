import 'package:app_2/features/finance/domain/entities/calendar_event.dart';

class CalendarEventModel {
  const CalendarEventModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.date,
    required this.type,
    required this.createdAt,
    this.notes,
  });

  final String id;
  final String userId;
  final String title;
  final String date;
  final String type;
  final String createdAt;
  final String? notes;

  factory CalendarEventModel.fromEntity(CalendarEvent entity) {
    return CalendarEventModel(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      date: entity.date.toIso8601String(),
      type: entity.type.name,
      createdAt: entity.createdAt.toIso8601String(),
      notes: entity.notes,
    );
  }

  CalendarEvent toEntity() {
    return CalendarEvent(
      id: id,
      userId: userId,
      title: title,
      date: DateTime.parse(date),
      type: CalendarEventType.values.firstWhere(
        (item) => item.name == type,
        orElse: () => CalendarEventType.custom,
      ),
      createdAt: DateTime.parse(createdAt),
      notes: notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'date': date,
      'type': type,
      'createdAt': createdAt,
      'notes': notes,
    };
  }

  factory CalendarEventModel.fromJson(Map<dynamic, dynamic> json) {
    return CalendarEventModel(
      id: json['id'] as String,
      userId: (json['userId'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      date: (json['date'] as String?) ?? DateTime.now().toIso8601String(),
      type: (json['type'] as String?) ?? CalendarEventType.custom.name,
      createdAt: (json['createdAt'] as String?) ?? DateTime.now().toIso8601String(),
      notes: json['notes'] as String?,
    );
  }
}
