import 'package:app_2/features/finance/data/datasources/category_local_datasource.dart';
import 'package:app_2/features/finance/data/models/finance_category_model.dart';
import 'package:app_2/features/finance/domain/entities/finance_category.dart';
import 'package:app_2/features/finance/domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._localDataSource);

  final CategoryLocalDataSource _localDataSource;

  @override
  Future<List<FinanceCategory>> getAll(String userId) async {
    final raw = await _localDataSource.getAll(userId: userId);
    return raw.map((item) => item.toEntity()).toList();
  }

  @override
  Future<void> add(FinanceCategory item) async {
    await _localDataSource.add(FinanceCategoryModel.fromEntity(item));
  }

  @override
  Future<void> delete(String id) async {
    await _localDataSource.delete(id);
  }
}
