import 'package:app_2/features/finance/domain/entities/transaction_item.dart';

class TransactionItemModel {
  const TransactionItemModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.notes,
    this.account,
    this.category,
    this.transferToAccount,
    this.proofImagePath,
  });

  final String id;
  final String userId;
  final String title;
  final double amount;
  final String type;
  final String createdAt;
  final String updatedAt;
  final String syncStatus;
  final String? notes;
  final String? account;
  final String? category;
  final String? transferToAccount;
  final String? proofImagePath;

  factory TransactionItemModel.fromEntity(TransactionItem entity) {
    return TransactionItemModel(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      amount: entity.amount,
      type: entity.type.name,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
      syncStatus: entity.syncStatus.name,
      notes: entity.notes,
      account: entity.account,
      category: entity.category,
      transferToAccount: entity.transferToAccount,
      proofImagePath: entity.proofImagePath,
    );
  }

  TransactionItem toEntity() {
    return TransactionItem(
      id: id,
      userId: userId,
      title: title,
      amount: amount,
      type: type == TransactionType.income.name
          ? TransactionType.income
          : type == TransactionType.transfer.name
          ? TransactionType.transfer
          : TransactionType.expense,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      syncStatus: SyncStatus.values.firstWhere(
        (status) => status.name == syncStatus,
        orElse: () => SyncStatus.pending,
      ),
      notes: notes,
      account: account,
      category: category,
      transferToAccount: transferToAccount,
      proofImagePath: proofImagePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'amount': amount,
      'type': type,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'syncStatus': syncStatus,
      'notes': notes,
      'account': account,
      'category': category,
      'transferToAccount': transferToAccount,
      'proofImagePath': proofImagePath,
    };
  }

  factory TransactionItemModel.fromJson(Map<dynamic, dynamic> json) {
    return TransactionItemModel(
      id: json['id'] as String,
      userId: (json['userId'] as String?) ?? '',
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      createdAt: json['createdAt'] as String,
      updatedAt: (json['updatedAt'] as String?) ?? (json['createdAt'] as String),
      syncStatus: (json['syncStatus'] as String?) ?? SyncStatus.pending.name,
      notes: json['notes'] as String?,
      account: json['account'] as String?,
      category: json['category'] as String?,
      transferToAccount: json['transferToAccount'] as String?,
      proofImagePath: json['proofImagePath'] as String?,
    );
  }
}
