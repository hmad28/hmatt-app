enum CalendarEventType { payday, reminder, custom }

class CalendarEvent {
  static const Object _unset = Object();

  const CalendarEvent({
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
  final DateTime date;
  final CalendarEventType type;
  final DateTime createdAt;
  final String? notes;

  CalendarEvent copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? date,
    CalendarEventType? type,
    DateTime? createdAt,
    Object? notes = _unset,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      date: date ?? this.date,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      notes: notes == _unset ? this.notes : notes as String?,
    );
  }
}
