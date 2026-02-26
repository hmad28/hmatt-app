import 'package:app_2/features/finance/domain/entities/financial_plan.dart';
import 'package:app_2/features/finance/domain/repositories/financial_plan_repository.dart';

class AddFinancialPlanRealizationUseCase {
  const AddFinancialPlanRealizationUseCase(this._repository);

  final FinancialPlanRepository _repository;

  Future<void> call(FinancialPlanRealization item) {
    return _repository.addRealization(item);
  }
}
