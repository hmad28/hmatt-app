import 'package:app_2/features/finance/domain/repositories/transaction_repository.dart';

class DeleteTransactionUseCase {
  const DeleteTransactionUseCase(this._repository);

  final TransactionRepository _repository;

  Future<void> call(String id) {
    return _repository.delete(id);
  }
}
