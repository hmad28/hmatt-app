import 'package:app_2/features/finance/domain/entities/finance_category.dart';
import 'package:app_2/features/finance/domain/repositories/category_repository.dart';

class GetCategoriesUseCase {
  const GetCategoriesUseCase(this._repository);

  final CategoryRepository _repository;

  Future<List<FinanceCategory>> call(String userId) {
    return _repository.getAll(userId);
  }
}
