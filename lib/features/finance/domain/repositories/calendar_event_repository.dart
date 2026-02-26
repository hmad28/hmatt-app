import 'package:app_2/features/finance/domain/entities/calendar_event.dart';

abstract class CalendarEventRepository {
  Future<List<CalendarEvent>> getAll(String userId);

  Future<void> add(CalendarEvent item);

  Future<void> update(CalendarEvent item);

  Future<void> delete(String id);
}
