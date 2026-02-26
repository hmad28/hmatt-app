import 'package:app_2/features/finance/data/datasources/calendar_event_local_datasource.dart';
import 'package:app_2/features/finance/data/models/calendar_event_model.dart';
import 'package:app_2/features/finance/domain/entities/calendar_event.dart';
import 'package:app_2/features/finance/domain/repositories/calendar_event_repository.dart';

class CalendarEventRepositoryImpl implements CalendarEventRepository {
  CalendarEventRepositoryImpl(this._localDataSource);

  final CalendarEventLocalDataSource _localDataSource;

  @override
  Future<List<CalendarEvent>> getAll(String userId) async {
    final raw = await _localDataSource.getAll(userId: userId);
    return raw.map((item) => item.toEntity()).toList();
  }

  @override
  Future<void> add(CalendarEvent item) async {
    await _localDataSource.add(CalendarEventModel.fromEntity(item));
  }

  @override
  Future<void> update(CalendarEvent item) async {
    await _localDataSource.update(CalendarEventModel.fromEntity(item));
  }

  @override
  Future<void> delete(String id) async {
    await _localDataSource.delete(id);
  }
}
