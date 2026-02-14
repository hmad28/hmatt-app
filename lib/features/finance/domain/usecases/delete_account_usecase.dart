import 'package:app_2/features/finance/domain/repositories/account_repository.dart';

class DeleteAccountUseCase {
  const DeleteAccountUseCase(this._repository);

  final AccountRepository _repository;

  Future<void> call(String id) {
    return _repository.delete(id);
  }
}
