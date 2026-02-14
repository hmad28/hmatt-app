import 'package:app_2/features/finance/data/datasources/account_local_datasource.dart';
import 'package:app_2/features/finance/data/models/finance_account_model.dart';
import 'package:app_2/features/finance/domain/entities/finance_account.dart';
import 'package:app_2/features/finance/domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl(this._localDataSource);

  final AccountLocalDataSource _localDataSource;

  @override
  Future<List<FinanceAccount>> getAll(String userId) async {
    final raw = await _localDataSource.getAll(userId: userId);
    return raw.map((item) => item.toEntity()).toList();
  }

  @override
  Future<void> add(FinanceAccount item) async {
    await _localDataSource.add(FinanceAccountModel.fromEntity(item));
  }

  @override
  Future<void> delete(String id) async {
    await _localDataSource.delete(id);
  }
}
