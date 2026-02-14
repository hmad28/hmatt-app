import 'package:app_2/features/finance/domain/entities/transaction_item.dart';
import 'package:app_2/features/finance/domain/repositories/transaction_repository.dart';

class UpdateTransactionUseCase {
  const UpdateTransactionUseCase(this._repository);

  final TransactionRepository _repository;

  Future<void> call(TransactionItem item) {
    return _repository.update(item);
  }
}
