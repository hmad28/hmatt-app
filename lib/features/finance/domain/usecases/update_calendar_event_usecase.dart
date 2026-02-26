import 'package:app_2/features/finance/domain/entities/calendar_event.dart';
import 'package:app_2/features/finance/domain/repositories/calendar_event_repository.dart';

class UpdateCalendarEventUseCase {
  const UpdateCalendarEventUseCase(this._repository);

  final CalendarEventRepository _repository;

  Future<void> call(CalendarEvent item) {
    return _repository.update(item);
  }
}
