import 'package:app_2/features/finance/data/models/finance_category_model.dart';
import 'package:hive/hive.dart';

class CategoryLocalDataSource {
  CategoryLocalDataSource(this._box);

  static const boxName = 'categories_box';

  final Box<Map> _box;

  Future<List<FinanceCategoryModel>> getAll({required String userId}) async {
    final values = _box.values
        .map(
          (raw) => FinanceCategoryModel.fromJson(Map<dynamic, dynamic>.from(raw)),
        )
        .where((item) => item.userId == userId)
        .toList();
    values.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return values;
  }

  Future<void> add(FinanceCategoryModel item) async {
    await _box.put(item.id, item.toJson());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> deleteByUser(String userId) async {
    final keysToDelete = <dynamic>[];
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw == null) {
        continue;
      }
      final item = FinanceCategoryModel.fromJson(Map<dynamic, dynamic>.from(raw));
      if (item.userId == userId) {
        keysToDelete.add(key);
      }
    }
    if (keysToDelete.isEmpty) {
      return;
    }
    await _box.deleteAll(keysToDelete);
  }
}
