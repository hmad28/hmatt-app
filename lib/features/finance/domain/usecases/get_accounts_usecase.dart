import 'package:app_2/features/finance/domain/entities/finance_account.dart';
import 'package:app_2/features/finance/domain/repositories/account_repository.dart';

class GetAccountsUseCase {
  const GetAccountsUseCase(this._repository);

  final AccountRepository _repository;

  Future<List<FinanceAccount>> call(String userId) {
    return _repository.getAll(userId);
  }
}
