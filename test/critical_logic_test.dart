import 'package:app_2/features/finance/domain/entities/calendar_event.dart';
import 'package:app_2/features/finance/domain/entities/financial_plan.dart';
import 'package:app_2/features/finance/domain/entities/transaction_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('copyWith nullable field clearing', () {
    test('TransactionItem can clear nullable fields', () {
      final item = TransactionItem(
        id: '1',
        userId: 'u1',
        title: 'Coffee',
        amount: 10000,
        type: TransactionType.expense,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        syncStatus: SyncStatus.pending,
        notes: 'note',
        account: 'Kas',
        category: 'Makan',
        transferToAccount: 'Bank',
        proofImagePath: 'a.jpg',
      );

      final updated = item.copyWith(
        notes: null,
        category: null,
        transferToAccount: null,
        proofImagePath: null,
      );

      expect(updated.notes, isNull);
      expect(updated.category, isNull);
      expect(updated.transferToAccount, isNull);
      expect(updated.proofImagePath, isNull);
      expect(updated.account, equals('Kas'));
    });

    test('FinancialPlan can clear nullable links and notes', () {
      final plan = FinancialPlan(
        id: 'p1',
        userId: 'u1',
        type: FinancialPlanType.spendingItem,
        title: 'Budget',
        targetAmount: 500000,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 31),
        status: FinancialPlanStatus.active,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        notes: 'n',
        linkedCategory: 'Makan',
        linkedAccount: 'Kas',
      );

      final updated = plan.copyWith(
        notes: null,
        linkedCategory: null,
        linkedAccount: null,
      );

      expect(updated.notes, isNull);
      expect(updated.linkedCategory, isNull);
      expect(updated.linkedAccount, isNull);
    });

    test('CalendarEvent and realization copyWith can clear notes', () {
      final event = CalendarEvent(
        id: 'e1',
        userId: 'u1',
        title: 'Payday',
        date: DateTime(2025, 1, 5),
        type: CalendarEventType.payday,
        createdAt: DateTime(2025, 1, 1),
        notes: 'reminder',
      );
      expect(event.copyWith(notes: null).notes, isNull);

      final realization = FinancialPlanRealization(
        id: 'r1',
        userId: 'u1',
        planId: 'p1',
        actualAmount: 1000,
        realizedAt: DateTime(2025, 1, 10),
        createdAt: DateTime(2025, 1, 10),
        source: FinancialPlanRealizationSource.manual,
        reflectionNote: 'ok',
      );
      expect(realization.copyWith(reflectionNote: null).reflectionNote, isNull);
    });
  });

  group('financial plan evaluation', () {
    test('returns over/under/on plan correctly', () {
      expect(
        evaluateFinancialPlan(targetAmount: 100, actualAmount: 120).status,
        FinancialPlanEvaluationStatus.overPlan,
      );
      expect(
        evaluateFinancialPlan(targetAmount: 100, actualAmount: 80).status,
        FinancialPlanEvaluationStatus.underPlan,
      );
      expect(
        evaluateFinancialPlan(targetAmount: 100, actualAmount: 100).status,
        FinancialPlanEvaluationStatus.onPlan,
      );
    });
  });
}
