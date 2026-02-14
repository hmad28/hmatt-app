enum TransactionType { income, expense, transfer }

enum SyncStatus { pending, synced, conflict }

class TransactionItem {
  const TransactionItem({
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
  });

  final String id;
  final String userId;
  final String title;
  final double amount;
  final TransactionType type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final String? notes;
  final String? account;
  final String? category;
  final String? transferToAccount;

  TransactionItem copyWith({
    String? id,
    String? userId,
    String? title,
    double? amount,
    TransactionType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    String? notes,
    String? account,
    String? category,
    String? transferToAccount,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      notes: notes ?? this.notes,
      account: account ?? this.account,
      category: category ?? this.category,
      transferToAccount: transferToAccount ?? this.transferToAccount,
    );
  }
}
