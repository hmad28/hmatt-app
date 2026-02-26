enum TransactionType { income, expense, transfer }

enum SyncStatus { pending, synced, conflict }

class TransactionItem {
  static const Object _unset = Object();

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
    this.proofImagePath,
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
  final String? proofImagePath;

  TransactionItem copyWith({
    String? id,
    String? userId,
    String? title,
    double? amount,
    TransactionType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    Object? notes = _unset,
    Object? account = _unset,
    Object? category = _unset,
    Object? transferToAccount = _unset,
    Object? proofImagePath = _unset,
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
      notes: notes == _unset ? this.notes : notes as String?,
      account: account == _unset ? this.account : account as String?,
      category: category == _unset ? this.category : category as String?,
      transferToAccount: transferToAccount == _unset
          ? this.transferToAccount
          : transferToAccount as String?,
      proofImagePath: proofImagePath == _unset
          ? this.proofImagePath
          : proofImagePath as String?,
    );
  }
}
