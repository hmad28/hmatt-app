import 'dart:async';

import 'package:app_2/features/auth/presentation/providers/auth_providers.dart';
import 'package:app_2/features/finance/data/datasources/financial_plan_local_datasource.dart';
import 'package:app_2/features/finance/data/repositories/financial_plan_repository_impl.dart';
import 'package:app_2/features/finance/domain/entities/financial_plan.dart';
import 'package:app_2/features/finance/domain/entities/transaction_item.dart';
import 'package:app_2/features/finance/domain/usecases/add_financial_plan_realization_usecase.dart';
import 'package:app_2/features/finance/domain/usecases/add_financial_plan_usecase.dart';
import 'package:app_2/features/finance/domain/usecases/delete_financial_plan_usecase.dart';
import 'package:app_2/features/finance/domain/usecases/get_financial_plan_realizations_usecase.dart';
import 'package:app_2/features/finance/domain/usecases/get_financial_plans_usecase.dart';
import 'package:app_2/features/finance/domain/usecases/update_financial_plan_usecase.dart';
import 'package:app_2/features/finance/presentation/providers/transaction_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

final _currentUserIdProvider = Provider<String?>((ref) {
  final auth = ref.watch(authControllerProvider).valueOrNull;
  return auth?.userId;
});

final _financialPlanDataSourceProvider = Provider<FinancialPlanLocalDataSource>((
  ref,
) {
  return FinancialPlanLocalDataSource(
    Hive.box<Map>(FinancialPlanLocalDataSource.planBoxName),
    Hive.box<Map>(FinancialPlanLocalDataSource.realizationBoxName),
  );
});

final _financialPlanRepositoryProvider = Provider<FinancialPlanRepositoryImpl>((
  ref,
) {
  return FinancialPlanRepositoryImpl(ref.read(_financialPlanDataSourceProvider));
});

final _getFinancialPlansUseCaseProvider = Provider<GetFinancialPlansUseCase>((
  ref,
) {
  return GetFinancialPlansUseCase(ref.read(_financialPlanRepositoryProvider));
});

final _addFinancialPlanUseCaseProvider = Provider<AddFinancialPlanUseCase>((
  ref,
) {
  return AddFinancialPlanUseCase(ref.read(_financialPlanRepositoryProvider));
});

final _updateFinancialPlanUseCaseProvider = Provider<UpdateFinancialPlanUseCase>((
  ref,
) {
  return UpdateFinancialPlanUseCase(ref.read(_financialPlanRepositoryProvider));
});

final _deleteFinancialPlanUseCaseProvider = Provider<DeleteFinancialPlanUseCase>((
  ref,
) {
  return DeleteFinancialPlanUseCase(ref.read(_financialPlanRepositoryProvider));
});

final _getFinancialPlanRealizationsUseCaseProvider =
    Provider<GetFinancialPlanRealizationsUseCase>((ref) {
      return GetFinancialPlanRealizationsUseCase(
        ref.read(_financialPlanRepositoryProvider),
      );
    });

final _addFinancialPlanRealizationUseCaseProvider =
    Provider<AddFinancialPlanRealizationUseCase>((ref) {
      return AddFinancialPlanRealizationUseCase(
        ref.read(_financialPlanRepositoryProvider),
      );
    });

final financialPlansControllerProvider =
    AsyncNotifierProvider<FinancialPlansController, List<FinancialPlan>>(
      FinancialPlansController.new,
    );

final financialPlanRealizationsProvider =
    FutureProvider.family<List<FinancialPlanRealization>, String>((ref, planId) async {
      final userId = ref.watch(_currentUserIdProvider);
      if (userId == null || userId.isEmpty) {
        return const [];
      }
      return ref
          .read(_getFinancialPlanRealizationsUseCaseProvider)
          .call(userId, planId: planId);
    });

final financialPlanAllRealizationsProvider =
    FutureProvider<List<FinancialPlanRealization>>((ref) async {
      final userId = ref.watch(_currentUserIdProvider);
      if (userId == null || userId.isEmpty) {
        return const [];
      }
      return ref.read(_getFinancialPlanRealizationsUseCaseProvider).call(userId);
    });

final financialPlanAutoSyncProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<List<TransactionItem>>>(
    transactionsControllerProvider,
    (previous, next) {
      if (!next.hasValue) {
        return;
      }
      unawaited(
        ref.read(financialPlansControllerProvider.notifier).syncAutoTrackedPlanRealizations(),
      );
    },
  );
});

class FinancialPlansController extends AsyncNotifier<List<FinancialPlan>> {
  @override
  Future<List<FinancialPlan>> build() async {
    final userId = ref.watch(_currentUserIdProvider);
    if (userId == null || userId.isEmpty) {
      return const [];
    }
    return ref.read(_getFinancialPlansUseCaseProvider).call(userId);
  }

  Future<void> addPlan({
    required String title,
    required double targetAmount,
    required PlanPriority priority,
  }) async {
    final userId = ref.read(_currentUserIdProvider);
    if (userId == null || userId.isEmpty) {
      return;
    }
    final now = DateTime.now();
    final item = FinancialPlan(
      id: const Uuid().v4(),
      userId: userId,
      type: FinancialPlanType.spendingItem,
      title: title.trim(),
      targetAmount: targetAmount,
      startDate: DateTime(now.year, now.month, now.day),
      endDate: DateTime(now.year + 30, now.month, now.day),
      status: FinancialPlanStatus.active,
      createdAt: now,
      updatedAt: now,
      priority: priority,
    );
    await ref.read(_addFinancialPlanUseCaseProvider).call(item);
    state = AsyncData(await ref.read(_getFinancialPlansUseCaseProvider).call(userId));
  }

  Future<void> updatePlan(FinancialPlan item) async {
    final userId = ref.read(_currentUserIdProvider);
    if (userId == null || userId.isEmpty || item.userId != userId) {
      return;
    }
    await ref
        .read(_updateFinancialPlanUseCaseProvider)
        .call(item.copyWith(updatedAt: DateTime.now()));
    state = AsyncData(await ref.read(_getFinancialPlansUseCaseProvider).call(userId));
    await syncAutoTrackedPlanRealizations();
  }

  Future<void> deletePlan(String id) async {
    final userId = ref.read(_currentUserIdProvider);
    if (userId == null || userId.isEmpty) {
      return;
    }
    final currentItems = state.valueOrNull ?? const <FinancialPlan>[];
    FinancialPlan? target;
    for (final item in currentItems) {
      if (item.id == id) {
        target = item;
        break;
      }
    }
    if (target == null || target.userId != userId) {
      return;
    }
    await ref.read(_deleteFinancialPlanUseCaseProvider).call(id);
    state = AsyncData(await ref.read(_getFinancialPlansUseCaseProvider).call(userId));
  }

  Future<void> addRealization({
    required String planId,
    required double actualAmount,
    required DateTime realizedAt,
    String? reflectionNote,
  }) async {
    final userId = ref.read(_currentUserIdProvider);
    if (userId == null || userId.isEmpty) {
      return;
    }
    final now = DateTime.now();
    final item = FinancialPlanRealization(
      id: const Uuid().v4(),
      userId: userId,
      planId: planId,
      actualAmount: actualAmount,
      realizedAt: realizedAt,
      createdAt: now,
      source: FinancialPlanRealizationSource.manual,
      reflectionNote: reflectionNote?.trim().isEmpty ?? true
          ? null
          : reflectionNote?.trim(),
    );
    await ref.read(_addFinancialPlanRealizationUseCaseProvider).call(item);
    ref.invalidate(financialPlanRealizationsProvider(planId));
    ref.invalidate(financialPlanAllRealizationsProvider);
  }

  Future<void> syncAutoTrackedPlanRealizations() async {
    final userId = ref.read(_currentUserIdProvider);
    if (userId == null || userId.isEmpty) {
      return;
    }

    final plans = await ref.read(_getFinancialPlansUseCaseProvider).call(userId);
    final autoPlans = plans.where((item) => item.autoTrackFromTransactions).toList();
    if (autoPlans.isEmpty) {
      return;
    }

    final transactions = await ref.read(transactionsControllerProvider.future);

    for (final plan in autoPlans) {
      final linkedCategory = plan.linkedCategory;
      final linkedAccount = plan.linkedAccount;
      if ((linkedCategory == null || linkedCategory.isEmpty) &&
          (linkedAccount == null || linkedAccount.isEmpty)) {
        continue;
      }

      final actual = _sumPlanAmountFromTransactions(
        transactions: transactions,
        plan: plan,
        linkedCategory: linkedCategory,
        linkedAccount: linkedAccount,
      );

      final existing = await ref
          .read(_getFinancialPlanRealizationsUseCaseProvider)
          .call(userId, planId: plan.id);
      final latest = existing.isEmpty ? null : existing.first;
      final latestAmount = latest?.actualAmount ?? -1;
      if ((latestAmount - actual).abs() < 0.01) {
        continue;
      }

      final now = DateTime.now();
      final autoId = 'auto::${plan.id}';
      final sourceBits = <String>[];
      if (linkedCategory != null && linkedCategory.isNotEmpty) {
        sourceBits.add('kategori "$linkedCategory"');
      }
      if (linkedAccount != null && linkedAccount.isNotEmpty) {
        sourceBits.add('akun "$linkedAccount"');
      }
      await ref.read(_addFinancialPlanRealizationUseCaseProvider).call(
            FinancialPlanRealization(
              id: autoId,
              userId: userId,
              planId: plan.id,
              actualAmount: actual,
              realizedAt: now,
              createdAt: now,
              source: FinancialPlanRealizationSource.auto,
              reflectionNote:
                  'Auto dari transaksi ${sourceBits.join(' & ')}',
            ),
          );
      ref.invalidate(financialPlanRealizationsProvider(plan.id));
    }
    ref.invalidate(financialPlanAllRealizationsProvider);
  }

  double _sumPlanAmountFromTransactions({
    required List<TransactionItem> transactions,
    required FinancialPlan plan,
    required String? linkedCategory,
    required String? linkedAccount,
  }) {
    final lowerCategory = linkedCategory?.toLowerCase();
    final lowerAccount = linkedAccount?.toLowerCase();
    return transactions
        .where((item) {
          if (item.createdAt.isBefore(_startOfDay(plan.startDate)) ||
              item.createdAt.isAfter(_endOfDay(plan.endDate))) {
            return false;
          }
          if (lowerCategory != null && lowerCategory.isNotEmpty) {
            final itemCategory = item.category?.toLowerCase();
            if (itemCategory != lowerCategory) {
              return false;
            }
          }
          if (lowerAccount != null && lowerAccount.isNotEmpty) {
            final itemAccount = item.account?.toLowerCase();
            if (itemAccount != lowerAccount) {
              return false;
            }
          }
          if (plan.type == FinancialPlanType.saving) {
            return item.type == TransactionType.income;
          }
          return item.type == TransactionType.expense;
        })
        .fold<double>(0, (sum, item) => sum + item.amount);
  }

  DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _endOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
  }
}
