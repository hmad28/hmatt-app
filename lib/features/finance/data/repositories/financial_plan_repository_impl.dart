import 'package:app_2/features/finance/data/datasources/financial_plan_local_datasource.dart';
import 'package:app_2/features/finance/data/models/financial_plan_model.dart';
import 'package:app_2/features/finance/domain/entities/financial_plan.dart';
import 'package:app_2/features/finance/domain/repositories/financial_plan_repository.dart';

class FinancialPlanRepositoryImpl implements FinancialPlanRepository {
  FinancialPlanRepositoryImpl(this._localDataSource);

  final FinancialPlanLocalDataSource _localDataSource;

  @override
  Future<List<FinancialPlan>> getPlans(String userId) async {
    final raw = await _localDataSource.getPlans(userId: userId);
    return raw.map((item) => item.toEntity()).toList();
  }

  @override
  Future<void> addPlan(FinancialPlan item) async {
    await _localDataSource.addPlan(FinancialPlanModel.fromEntity(item));
  }

  @override
  Future<void> updatePlan(FinancialPlan item) async {
    await _localDataSource.updatePlan(FinancialPlanModel.fromEntity(item));
  }

  @override
  Future<void> deletePlan(String id) async {
    await _localDataSource.deletePlan(id);
  }

  @override
  Future<List<FinancialPlanRealization>> getRealizations(
    String userId, {
    String? planId,
  }) async {
    final raw = await _localDataSource.getRealizations(
      userId: userId,
      planId: planId,
    );
    return raw.map((item) => item.toEntity()).toList();
  }

  @override
  Future<void> addRealization(FinancialPlanRealization item) async {
    await _localDataSource.addRealization(
      FinancialPlanRealizationModel.fromEntity(item),
    );
  }
}
