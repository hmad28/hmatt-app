import 'package:app_2/features/finance/domain/repositories/financial_plan_repository.dart';

class DeleteFinancialPlanUseCase {
  const DeleteFinancialPlanUseCase(this._repository);

  final FinancialPlanRepository _repository;

  Future<void> call(String id) {
    return _repository.deletePlan(id);
  }
}
