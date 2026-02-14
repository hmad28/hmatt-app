import 'package:app_2/features/finance/domain/entities/finance_category.dart';
import 'package:app_2/features/finance/domain/repositories/category_repository.dart';

class AddCategoryUseCase {
  const AddCategoryUseCase(this._repository);

  final CategoryRepository _repository;

  Future<void> call(FinanceCategory item) {
    return _repository.add(item);
  }
}
