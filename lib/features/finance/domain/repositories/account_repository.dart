import 'package:app_2/features/finance/domain/entities/finance_account.dart';

abstract class AccountRepository {
  Future<List<FinanceAccount>> getAll(String userId);

  Future<void> add(FinanceAccount item);

  Future<void> delete(String id);
}
