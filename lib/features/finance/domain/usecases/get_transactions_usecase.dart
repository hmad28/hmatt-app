import 'package:app_2/features/finance/domain/entities/transaction_item.dart';
import 'package:app_2/features/finance/domain/repositories/transaction_repository.dart';

class GetTransactionsUseCase {
  const GetTransactionsUseCase(this._repository);

  final TransactionRepository _repository;

  Future<List<TransactionItem>> call(String userId) {
    return _repository.getAll(userId);
  }
}
