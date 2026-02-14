enum CategoryScope { income, expense, both }

class FinanceCategory {
  const FinanceCategory({
    required this.id,
    required this.userId,
    required this.name,
    required this.scope,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final CategoryScope scope;
  final DateTime createdAt;
}
