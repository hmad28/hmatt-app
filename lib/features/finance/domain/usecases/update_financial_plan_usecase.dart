import 'package:app_2/features/finance/domain/entities/financial_plan.dart';
import 'package:app_2/features/finance/domain/repositories/financial_plan_repository.dart';

class UpdateFinancialPlanUseCase {
  const UpdateFinancialPlanUseCase(this._repository);

  final FinancialPlanRepository _repository;

  Future<void> call(FinancialPlan item) {
    return _repository.updatePlan(item);
  }
}
