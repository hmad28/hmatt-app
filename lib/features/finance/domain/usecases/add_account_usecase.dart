import 'package:app_2/features/finance/domain/entities/finance_account.dart';
import 'package:app_2/features/finance/domain/repositories/account_repository.dart';

class AddAccountUseCase {
  const AddAccountUseCase(this._repository);

  final AccountRepository _repository;

  Future<void> call(FinanceAccount item) {
    return _repository.add(item);
  }
}
