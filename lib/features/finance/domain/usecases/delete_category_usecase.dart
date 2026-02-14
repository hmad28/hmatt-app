import 'package:app_2/features/finance/domain/repositories/category_repository.dart';

class DeleteCategoryUseCase {
  const DeleteCategoryUseCase(this._repository);

  final CategoryRepository _repository;

  Future<void> call(String id) {
    return _repository.delete(id);
  }
}
