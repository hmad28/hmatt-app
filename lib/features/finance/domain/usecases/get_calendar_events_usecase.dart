import 'package:app_2/features/finance/domain/entities/calendar_event.dart';
import 'package:app_2/features/finance/domain/repositories/calendar_event_repository.dart';

class GetCalendarEventsUseCase {
  const GetCalendarEventsUseCase(this._repository);

  final CalendarEventRepository _repository;

  Future<List<CalendarEvent>> call(String userId) {
    return _repository.getAll(userId);
  }
}
