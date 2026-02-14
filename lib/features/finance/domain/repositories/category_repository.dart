import 'package:app_2/features/finance/domain/entities/finance_category.dart';

abstract class CategoryRepository {
  Future<List<FinanceCategory>> getAll(String userId);

  Future<void> add(FinanceCategory item);

  Future<void> delete(String id);
}
