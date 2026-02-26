import 'package:app_2/features/finance/domain/entities/calendar_event.dart';
import 'package:app_2/features/finance/domain/repositories/calendar_event_repository.dart';

class AddCalendarEventUseCase {
  const AddCalendarEventUseCase(this._repository);

  final CalendarEventRepository _repository;

  Future<void> call(CalendarEvent item) {
    return _repository.add(item);
  }
}
