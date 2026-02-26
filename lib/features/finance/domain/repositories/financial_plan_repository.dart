import 'package:app_2/features/finance/domain/entities/financial_plan.dart';

abstract class FinancialPlanRepository {
  Future<List<FinancialPlan>> getPlans(String userId);

  Future<void> addPlan(FinancialPlan item);

  Future<void> updatePlan(FinancialPlan item);

  Future<void> deletePlan(String id);

  Future<List<FinancialPlanRealization>> getRealizations(
    String userId, {
    String? planId,
  });

  Future<void> addRealization(FinancialPlanRealization item);
}
