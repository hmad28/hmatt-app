import 'package:app_2/features/finance/data/models/calendar_event_model.dart';
import 'package:hive/hive.dart';

class CalendarEventLocalDataSource {
  CalendarEventLocalDataSource(this._box);

  static const boxName = 'calendar_events_box';

  final Box<Map> _box;

  Future<List<CalendarEventModel>> getAll({required String userId}) async {
    final values = _box.values
        .map((raw) => CalendarEventModel.fromJson(Map<dynamic, dynamic>.from(raw)))
        .where((item) => item.userId == userId)
        .toList();
    values.sort((a, b) => a.date.compareTo(b.date));
    return values;
  }

  Future<void> add(CalendarEventModel item) async {
    await _box.put(item.id, item.toJson());
  }

  Future<void> update(CalendarEventModel item) async {
    await _box.put(item.id, item.toJson());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> deleteByUser(String userId) async {
    final keys = <dynamic>[];
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw == null) {
        continue;
      }
      final item = CalendarEventModel.fromJson(Map<dynamic, dynamic>.from(raw));
      if (item.userId == userId) {
        keys.add(key);
      }
    }
    if (keys.isNotEmpty) {
      await _box.deleteAll(keys);
    }
  }
}
