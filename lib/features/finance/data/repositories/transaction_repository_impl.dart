import 'package:app_2/features/finance/data/datasources/transaction_local_datasource.dart';
import 'package:app_2/features/finance/data/models/transaction_item_model.dart';
import 'package:app_2/features/finance/domain/entities/transaction_item.dart';
import 'package:app_2/features/finance/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl(this._localDataSource);

  final TransactionLocalDataSource _localDataSource;

  @override
  Future<List<TransactionItem>> getAll(String userId) async {
    final raw = await _localDataSource.getAll(userId: userId);
    return raw.map((item) => item.toEntity()).toList();
  }

  @override
  Future<void> add(TransactionItem item) async {
    await _localDataSource.add(TransactionItemModel.fromEntity(item));
  }

  @override
  Future<void> update(TransactionItem item) async {
    await _localDataSource.update(TransactionItemModel.fromEntity(item));
  }

  @override
  Future<void> delete(String id) async {
    await _localDataSource.delete(id);
  }
}
