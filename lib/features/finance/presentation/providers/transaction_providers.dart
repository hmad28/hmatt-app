import 'package:app_2/features/finance/data/datasources/account_local_datasource.dart';
import 'package:app_2/features/finance/data/datasources/category_local_datasource.dart';
import 'package:app_2/features/finance/data/datasources/transaction_local_datasource.dart';
import 'package:app_2/features/finance/data/repositories/account_repository_impl.dart';
import 'package:app_2/features/finance/data/repositories/category_repository_impl.dart';
import 'package:app_2/features/finance/data/repositories/transaction_repository_impl.dart';
import 'package:app_2/features/finance/domain/entities/finance_account.dart';
import 'package:app_2/features/finance/domain/entities/finance_category.dart';
import 'package:app_2/features/finance/domain/entities/transaction_item.dart';
import 'package:app_2/features/finance/domain/usecases/add_account_usecase.dart';
import 'package:app_2/features/finance/domain/usecases/add_category_usecase.dart';
import 'package:app_2/features/finance/domain/usecases/add_transaction_usecase.dart';
import 'package:app_2/features/finance/domain/usecases/delete_transaction_usecase.dart';
import 'package:app_2/features/finance/domain/usecases/delete_account_usecase.dart';
import 'package:app_2/features/finance/domain/usecases/delete_category_usecase.dart';
import 'package:app_2/features/finance/domain/usecases/get_accounts_usecase.dart';
import 'package:app_2/features/finance/domain/usecases/get_categories_usecase.dart';
import 'package:app_2/features/finance/domain/usecases/get_transactions_usecase.dart';
import 'package:app_2/features/finance/domain/usecases/update_transaction_usecase.dart';
import 'package:app_2/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

final _currentUserIdProvider = Provider<String?>((ref) {
  final auth = ref.watch(authControllerProvider).valueOrNull;
  return auth?.userId;
});

final _transactionBoxProvider = Provider<Box<Map>>((ref) {
  return Hive.box<Map>(TransactionLocalDataSource.boxName);
});

final _accountBoxProvider = Provider<Box<Map>>((ref) {
  return Hive.box<Map>(AccountLocalDataSource.boxName);
});

final _categoryBoxProvider = Provider<Box<Map>>((ref) {
  return Hive.box<Map>(CategoryLocalDataSource.boxName);
});

final _transactionLocalDataSourceProvider = Provider<TransactionLocalDataSource>((
  ref,
) {
  return TransactionLocalDataSource(ref.read(_transactionBoxProvider));
});

final _accountLocalDataSourceProvider = Provider<AccountLocalDataSource>((ref) {
  return AccountLocalDataSource(ref.read(_accountBoxProvider));
});

final _categoryLocalDataSourceProvider = Provider<CategoryLocalDataSource>((ref) {
  return CategoryLocalDataSource(ref.read(_categoryBoxProvider));
});

final _transactionRepositoryProvider = Provider<TransactionRepositoryImpl>((ref) {
  return TransactionRepositoryImpl(ref.read(_transactionLocalDataSourceProvider));
});

final _accountRepositoryProvider = Provider<AccountRepositoryImpl>((ref) {
  return AccountRepositoryImpl(ref.read(_accountLocalDataSourceProvider));
});

final _categoryRepositoryProvider = Provider<CategoryRepositoryImpl>((ref) {
  return CategoryRepositoryImpl(ref.read(_categoryLocalDataSourceProvider));
});

final _getTransactionsUseCaseProvider = Provider<GetTransactionsUseCase>((ref) {
  return GetTransactionsUseCase(ref.read(_transactionRepositoryProvider));
});

final _addTransactionUseCaseProvider = Provider<AddTransactionUseCase>((ref) {
  return AddTransactionUseCase(ref.read(_transactionRepositoryProvider));
});

final _deleteTransactionUseCaseProvider = Provider<DeleteTransactionUseCase>((
  ref,
) {
  return DeleteTransactionUseCase(ref.read(_transactionRepositoryProvider));
});

final _updateTransactionUseCaseProvider = Provider<UpdateTransactionUseCase>((
  ref,
) {
  return UpdateTransactionUseCase(ref.read(_transactionRepositoryProvider));
});

final _getAccountsUseCaseProvider = Provider<GetAccountsUseCase>((ref) {
  return GetAccountsUseCase(ref.read(_accountRepositoryProvider));
});

final _addAccountUseCaseProvider = Provider<AddAccountUseCase>((ref) {
  return AddAccountUseCase(ref.read(_accountRepositoryProvider));
});

final _deleteAccountUseCaseProvider = Provider<DeleteAccountUseCase>((ref) {
  return DeleteAccountUseCase(ref.read(_accountRepositoryProvider));
});

final _getCategoriesUseCaseProvider = Provider<GetCategoriesUseCase>((ref) {
  return GetCategoriesUseCase(ref.read(_categoryRepositoryProvider));
});

final _addCategoryUseCaseProvider = Provider<AddCategoryUseCase>((ref) {
  return AddCategoryUseCase(ref.read(_categoryRepositoryProvider));
});

final _deleteCategoryUseCaseProvider = Provider<DeleteCategoryUseCase>((ref) {
  return DeleteCategoryUseCase(ref.read(_categoryRepositoryProvider));
});

final transactionsControllerProvider =
    AsyncNotifierProvider<TransactionsController, List<TransactionItem>>(
      TransactionsController.new,
    );

class TransactionsController extends AsyncNotifier<List<TransactionItem>> {
  @override
  Future<List<TransactionItem>> build() async {
    final userId = ref.watch(_currentUserIdProvider);
    if (userId == null || userId.isEmpty) {
      return const [];
    }
    return ref.read(_getTransactionsUseCaseProvider).call(userId);
  }

  Future<void> add({
    required String title,
    required double amount,
    required TransactionType type,
    String? notes,
    String? account,
    String? category,
    String? transferToAccount,
  }) async {
    final userId = ref.read(_currentUserIdProvider);
    if (userId == null || userId.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final item = TransactionItem(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      amount: amount,
      type: type,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
      notes: notes,
      account: account,
      category: category,
      transferToAccount: transferToAccount,
    );

    await ref.read(_addTransactionUseCaseProvider).call(item);
    state = AsyncData(await ref.read(_getTransactionsUseCaseProvider).call(userId));
  }

  Future<void> remove(String id) async {
    final userId = ref.read(_currentUserIdProvider);
    if (userId == null || userId.isEmpty) {
      return;
    }
    await ref.read(_deleteTransactionUseCaseProvider).call(id);
    state = AsyncData(await ref.read(_getTransactionsUseCaseProvider).call(userId));
  }

  Future<void> editItem(TransactionItem item) async {
    final userId = ref.read(_currentUserIdProvider);
    if (userId == null || userId.isEmpty || item.userId != userId) {
      return;
    }
    final updated = item.copyWith(
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
    );
    await ref.read(_updateTransactionUseCaseProvider).call(updated);
    state = AsyncData(await ref.read(_getTransactionsUseCaseProvider).call(userId));
  }
}

final accountsControllerProvider =
    AsyncNotifierProvider<AccountsController, List<FinanceAccount>>(
      AccountsController.new,
    );

class AccountsController extends AsyncNotifier<List<FinanceAccount>> {
  @override
  Future<List<FinanceAccount>> build() async {
    final userId = ref.watch(_currentUserIdProvider);
    if (userId == null || userId.isEmpty) {
      return const [];
    }

    final items = await ref.read(_getAccountsUseCaseProvider).call(userId);
    if (items.isEmpty) {
      await _seedDefaults(userId);
      return ref.read(_getAccountsUseCaseProvider).call(userId);
    }
    return items;
  }

  Future<void> _seedDefaults(String userId) async {
    final now = DateTime.now();
    final defaults = ['Kas', 'Bank Utama', 'E-Wallet'];
    for (final name in defaults) {
      await ref.read(_addAccountUseCaseProvider).call(
        FinanceAccount(
          id: const Uuid().v4(),
          userId: userId,
          name: name,
          createdAt: now,
        ),
      );
    }
  }

  Future<void> add(String name) async {
    final userId = ref.read(_currentUserIdProvider);
    if (userId == null || userId.isEmpty) {
      return;
    }

    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      return;
    }

    final alreadyExists = state.valueOrNull?.any(
          (item) => item.name.toLowerCase() == cleanName.toLowerCase(),
        ) ??
        false;
    if (alreadyExists) {
      return;
    }

    final now = DateTime.now();
    await ref.read(_addAccountUseCaseProvider).call(
      FinanceAccount(
        id: const Uuid().v4(),
        userId: userId,
        name: cleanName,
        createdAt: now,
      ),
    );
    state = AsyncData(await ref.read(_getAccountsUseCaseProvider).call(userId));
  }

  Future<void> delete(String id) async {
    final userId = ref.read(_currentUserIdProvider);
    if (userId == null || userId.isEmpty) {
      return;
    }
    await ref.read(_deleteAccountUseCaseProvider).call(id);
    state = AsyncData(await ref.read(_getAccountsUseCaseProvider).call(userId));
  }
}

final categoriesControllerProvider =
    AsyncNotifierProvider<CategoriesController, List<FinanceCategory>>(
      CategoriesController.new,
    );

class CategoriesController extends AsyncNotifier<List<FinanceCategory>> {
  @override
  Future<List<FinanceCategory>> build() async {
    final userId = ref.watch(_currentUserIdProvider);
    if (userId == null || userId.isEmpty) {
      return const [];
    }

    final items = await ref.read(_getCategoriesUseCaseProvider).call(userId);
    if (items.isEmpty) {
      await _seedDefaults(userId);
      return ref.read(_getCategoriesUseCaseProvider).call(userId);
    }
    return items;
  }

  Future<void> _seedDefaults(String userId) async {
    final now = DateTime.now();
    final defaults = [
      ('Gaji', CategoryScope.income),
      ('Bonus', CategoryScope.income),
      ('Makan', CategoryScope.expense),
      ('Transport', CategoryScope.expense),
      ('Belanja', CategoryScope.expense),
      ('Tagihan', CategoryScope.expense),
    ];

    for (final item in defaults) {
      await ref.read(_addCategoryUseCaseProvider).call(
        FinanceCategory(
          id: const Uuid().v4(),
          userId: userId,
          name: item.$1,
          scope: item.$2,
          createdAt: now,
        ),
      );
    }
  }

  Future<void> add({required String name, required CategoryScope scope}) async {
    final userId = ref.read(_currentUserIdProvider);
    if (userId == null || userId.isEmpty) {
      return;
    }

    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      return;
    }

    final alreadyExists = state.valueOrNull?.any(
          (item) =>
              item.name.toLowerCase() == cleanName.toLowerCase() &&
              item.scope == scope,
        ) ??
        false;
    if (alreadyExists) {
      return;
    }

    final now = DateTime.now();
    await ref.read(_addCategoryUseCaseProvider).call(
      FinanceCategory(
        id: const Uuid().v4(),
        userId: userId,
        name: cleanName,
        scope: scope,
        createdAt: now,
      ),
    );
    state = AsyncData(await ref.read(_getCategoriesUseCaseProvider).call(userId));
  }

  Future<void> delete(String id) async {
    final userId = ref.read(_currentUserIdProvider);
    if (userId == null || userId.isEmpty) {
      return;
    }
    await ref.read(_deleteCategoryUseCaseProvider).call(id);
    state = AsyncData(await ref.read(_getCategoriesUseCaseProvider).call(userId));
  }
}
