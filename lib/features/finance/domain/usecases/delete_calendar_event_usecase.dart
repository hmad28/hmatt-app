import 'package:app_2/features/finance/domain/repositories/calendar_event_repository.dart';

class DeleteCalendarEventUseCase {
  const DeleteCalendarEventUseCase(this._repository);

  final CalendarEventRepository _repository;

  Future<void> call(String id) {
    return _repository.delete(id);
  }
}
