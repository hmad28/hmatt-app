import 'package:app_2/features/finance/domain/entities/finance_account.dart';

class FinanceAccountModel {
  const FinanceAccountModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final String createdAt;

  factory FinanceAccountModel.fromEntity(FinanceAccount entity) {
    return FinanceAccountModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      createdAt: entity.createdAt.toIso8601String(),
    );
  }

  FinanceAccount toEntity() {
    return FinanceAccount(
      id: id,
      userId: userId,
      name: name,
      createdAt: DateTime.parse(createdAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'userId': userId, 'name': name, 'createdAt': createdAt};
  }

  factory FinanceAccountModel.fromJson(Map<dynamic, dynamic> json) {
    return FinanceAccountModel(
      id: json['id'] as String,
      userId: (json['userId'] as String?) ?? '',
      name: json['name'] as String,
      createdAt: json['createdAt'] as String,
    );
  }
}
