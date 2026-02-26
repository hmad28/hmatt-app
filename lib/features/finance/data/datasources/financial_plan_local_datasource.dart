import 'package:app_2/features/finance/data/models/financial_plan_model.dart';
import 'package:hive/hive.dart';

class FinancialPlanLocalDataSource {
  FinancialPlanLocalDataSource(this._planBox, this._realizationBox);

  static const planBoxName = 'financial_plans_box';
  static const realizationBoxName = 'financial_plan_realizations_box';

  final Box<Map> _planBox;
  final Box<Map> _realizationBox;

  Future<List<FinancialPlanModel>> getPlans({required String userId}) async {
    final values = _planBox.values
        .map((raw) => FinancialPlanModel.fromJson(Map<dynamic, dynamic>.from(raw)))
        .where((item) => item.userId == userId)
        .toList();
    values.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return values;
  }

  Future<void> addPlan(FinancialPlanModel item) async {
    await _planBox.put(item.id, item.toJson());
  }

  Future<void> updatePlan(FinancialPlanModel item) async {
    await _planBox.put(item.id, item.toJson());
  }

  Future<void> deletePlan(String id) async {
    await _planBox.delete(id);
    final keysToDelete = <dynamic>[];
    for (final key in _realizationBox.keys) {
      final raw = _realizationBox.get(key);
      if (raw == null) {
        continue;
      }
      final realization = FinancialPlanRealizationModel.fromJson(
        Map<dynamic, dynamic>.from(raw),
      );
      if (realization.planId == id) {
        keysToDelete.add(key);
      }
    }
    if (keysToDelete.isNotEmpty) {
      await _realizationBox.deleteAll(keysToDelete);
    }
  }

  Future<List<FinancialPlanRealizationModel>> getRealizations({
    required String userId,
    String? planId,
  }) async {
    final values = _realizationBox.values
        .map(
          (raw) => FinancialPlanRealizationModel.fromJson(
            Map<dynamic, dynamic>.from(raw),
          ),
        )
        .where((item) => item.userId == userId)
        .where((item) => planId == null || item.planId == planId)
        .toList();
    values.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return values;
  }

  Future<void> addRealization(FinancialPlanRealizationModel item) async {
    await _realizationBox.put(item.id, item.toJson());
  }

  Future<void> deleteByUser(String userId) async {
    final planKeys = <dynamic>[];
    for (final key in _planBox.keys) {
      final raw = _planBox.get(key);
      if (raw == null) {
        continue;
      }
      final item = FinancialPlanModel.fromJson(Map<dynamic, dynamic>.from(raw));
      if (item.userId == userId) {
        planKeys.add(key);
      }
    }
    if (planKeys.isNotEmpty) {
      await _planBox.deleteAll(planKeys);
    }

    final realizationKeys = <dynamic>[];
    for (final key in _realizationBox.keys) {
      final raw = _realizationBox.get(key);
      if (raw == null) {
        continue;
      }
      final item = FinancialPlanRealizationModel.fromJson(
        Map<dynamic, dynamic>.from(raw),
      );
      if (item.userId == userId) {
        realizationKeys.add(key);
      }
    }
    if (realizationKeys.isNotEmpty) {
      await _realizationBox.deleteAll(realizationKeys);
    }
  }
}
