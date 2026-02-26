import 'package:app_2/features/finance/domain/entities/financial_plan.dart';
import 'package:app_2/features/finance/domain/repositories/financial_plan_repository.dart';

class GetFinancialPlanRealizationsUseCase {
  const GetFinancialPlanRealizationsUseCase(this._repository);

  final FinancialPlanRepository _repository;

  Future<List<FinancialPlanRealization>> call(
    String userId, {
    String? planId,
  }) {
    return _repository.getRealizations(userId, planId: planId);
  }
}
