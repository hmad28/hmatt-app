import 'package:app_2/features/finance/domain/entities/finance_category.dart';

class FinanceCategoryModel {
  const FinanceCategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.scope,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final String scope;
  final String createdAt;

  factory FinanceCategoryModel.fromEntity(FinanceCategory entity) {
    return FinanceCategoryModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      scope: entity.scope.name,
      createdAt: entity.createdAt.toIso8601String(),
    );
  }

  FinanceCategory toEntity() {
    return FinanceCategory(
      id: id,
      userId: userId,
      name: name,
      scope: CategoryScope.values.firstWhere(
        (item) => item.name == scope,
        orElse: () => CategoryScope.both,
      ),
      createdAt: DateTime.parse(createdAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'scope': scope,
      'createdAt': createdAt,
    };
  }

  factory FinanceCategoryModel.fromJson(Map<dynamic, dynamic> json) {
    return FinanceCategoryModel(
      id: json['id'] as String,
      userId: (json['userId'] as String?) ?? '',
      name: json['name'] as String,
      scope: (json['scope'] as String?) ?? CategoryScope.both.name,
      createdAt: json['createdAt'] as String,
    );
  }
}
