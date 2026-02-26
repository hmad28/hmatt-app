import 'package:app_2/features/finance/domain/entities/financial_plan.dart';
import 'package:app_2/features/finance/domain/repositories/financial_plan_repository.dart';

class GetFinancialPlansUseCase {
  const GetFinancialPlansUseCase(this._repository);

  final FinancialPlanRepository _repository;

  Future<List<FinancialPlan>> call(String userId) {
    return _repository.getPlans(userId);
  }
}
