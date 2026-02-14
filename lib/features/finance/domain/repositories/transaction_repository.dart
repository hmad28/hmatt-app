import 'package:app_2/features/finance/domain/entities/transaction_item.dart';

abstract class TransactionRepository {
  Future<List<TransactionItem>> getAll(String userId);

  Future<void> add(TransactionItem item);

  Future<void> update(TransactionItem item);

  Future<void> delete(String id);
}
