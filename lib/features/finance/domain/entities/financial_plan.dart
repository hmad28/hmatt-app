enum FinancialPlanType { saving, spendingItem }

enum FinancialPlanStatus { active, completed, cancelled }

enum PlanPriority { low, medium, high }

enum FinancialPlanEvaluationStatus { underPlan, onPlan, overPlan }

class FinancialPlan {
  static const Object _unset = Object();

  const FinancialPlan({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.targetAmount,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.priority = PlanPriority.medium,
    this.notes,
    this.autoTrackFromTransactions = false,
    this.linkedCategory,
    this.linkedAccount,
  });

  final String id;
  final String userId;
  final FinancialPlanType type;
  final String title;
  final double targetAmount;
  final DateTime startDate;
  final DateTime endDate;
  final FinancialPlanStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PlanPriority priority;
  final String? notes;
  final bool autoTrackFromTransactions;
  final String? linkedCategory;
  final String? linkedAccount;

  FinancialPlan copyWith({
    String? id,
    String? userId,
    FinancialPlanType? type,
    String? title,
    double? targetAmount,
    DateTime? startDate,
    DateTime? endDate,
    FinancialPlanStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    PlanPriority? priority,
    Object? notes = _unset,
    bool? autoTrackFromTransactions,
    Object? linkedCategory = _unset,
    Object? linkedAccount = _unset,
  }) {
    return FinancialPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      priority: priority ?? this.priority,
      notes: notes == _unset ? this.notes : notes as String?,
      autoTrackFromTransactions:
          autoTrackFromTransactions ?? this.autoTrackFromTransactions,
      linkedCategory: linkedCategory == _unset
          ? this.linkedCategory
          : linkedCategory as String?,
      linkedAccount: linkedAccount == _unset
          ? this.linkedAccount
          : linkedAccount as String?,
    );
  }
}

enum FinancialPlanRealizationSource { manual, auto }

class FinancialPlanRealization {
  static const Object _unset = Object();

  const FinancialPlanRealization({
    required this.id,
    required this.userId,
    required this.planId,
    required this.actualAmount,
    required this.realizedAt,
    required this.createdAt,
    required this.source,
    this.reflectionNote,
  });

  final String id;
  final String userId;
  final String planId;
  final double actualAmount;
  final DateTime realizedAt;
  final DateTime createdAt;
  final FinancialPlanRealizationSource source;
  final String? reflectionNote;

  FinancialPlanRealization copyWith({
    String? id,
    String? userId,
    String? planId,
    double? actualAmount,
    DateTime? realizedAt,
    DateTime? createdAt,
    FinancialPlanRealizationSource? source,
    Object? reflectionNote = _unset,
  }) {
    return FinancialPlanRealization(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planId: planId ?? this.planId,
      actualAmount: actualAmount ?? this.actualAmount,
      realizedAt: realizedAt ?? this.realizedAt,
      createdAt: createdAt ?? this.createdAt,
      source: source ?? this.source,
      reflectionNote: reflectionNote == _unset
          ? this.reflectionNote
          : reflectionNote as String?,
    );
  }
}

class FinancialPlanEvaluation {
  const FinancialPlanEvaluation({
    required this.status,
    required this.delta,
  });

  final FinancialPlanEvaluationStatus status;
  final double delta;
}

FinancialPlanEvaluation evaluateFinancialPlan({
  required double targetAmount,
  required double actualAmount,
}) {
  final delta = actualAmount - targetAmount;
  if (delta > 0) {
    return FinancialPlanEvaluation(
      status: FinancialPlanEvaluationStatus.overPlan,
      delta: delta,
    );
  }
  if (delta < 0) {
    return FinancialPlanEvaluation(
      status: FinancialPlanEvaluationStatus.underPlan,
      delta: delta,
    );
  }
  return FinancialPlanEvaluation(
    status: FinancialPlanEvaluationStatus.onPlan,
    delta: 0,
  );
}
