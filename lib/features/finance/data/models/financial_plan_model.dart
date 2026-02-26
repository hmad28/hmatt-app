import 'package:app_2/features/finance/domain/entities/financial_plan.dart';

class FinancialPlanModel {
  const FinancialPlanModel({
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
    required this.priority,
    this.notes,
    this.autoTrackFromTransactions = false,
    this.linkedCategory,
    this.linkedAccount,
  });

  final String id;
  final String userId;
  final String type;
  final String title;
  final double targetAmount;
  final String startDate;
  final String endDate;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String priority;
  final String? notes;
  final bool autoTrackFromTransactions;
  final String? linkedCategory;
  final String? linkedAccount;

  factory FinancialPlanModel.fromEntity(FinancialPlan entity) {
    return FinancialPlanModel(
      id: entity.id,
      userId: entity.userId,
      type: entity.type.name,
      title: entity.title,
      targetAmount: entity.targetAmount,
      startDate: entity.startDate.toIso8601String(),
      endDate: entity.endDate.toIso8601String(),
      status: entity.status.name,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
      priority: entity.priority.name,
      notes: entity.notes,
      autoTrackFromTransactions: entity.autoTrackFromTransactions,
      linkedCategory: entity.linkedCategory,
      linkedAccount: entity.linkedAccount,
    );
  }

  FinancialPlan toEntity() {
    return FinancialPlan(
      id: id,
      userId: userId,
      type: FinancialPlanType.values.firstWhere(
        (item) => item.name == type,
        orElse: () => FinancialPlanType.spendingItem,
      ),
      title: title,
      targetAmount: targetAmount,
      startDate: DateTime.parse(startDate),
      endDate: DateTime.parse(endDate),
      status: FinancialPlanStatus.values.firstWhere(
        (item) => item.name == status,
        orElse: () => FinancialPlanStatus.active,
      ),
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      priority: PlanPriority.values.firstWhere(
        (item) => item.name == priority,
        orElse: () => PlanPriority.medium,
      ),
      notes: notes,
      autoTrackFromTransactions: autoTrackFromTransactions,
      linkedCategory: linkedCategory,
      linkedAccount: linkedAccount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'targetAmount': targetAmount,
      'startDate': startDate,
      'endDate': endDate,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'priority': priority,
      'notes': notes,
      'autoTrackFromTransactions': autoTrackFromTransactions,
      'linkedCategory': linkedCategory,
      'linkedAccount': linkedAccount,
    };
  }

  factory FinancialPlanModel.fromJson(Map<dynamic, dynamic> json) {
    return FinancialPlanModel(
      id: json['id'] as String,
      userId: (json['userId'] as String?) ?? '',
      type:
          (json['type'] as String?) ?? FinancialPlanType.spendingItem.name,
      title: (json['title'] as String?) ?? '',
      targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0,
      startDate: (json['startDate'] as String?) ?? DateTime.now().toIso8601String(),
      endDate: (json['endDate'] as String?) ?? DateTime.now().toIso8601String(),
      status: (json['status'] as String?) ?? FinancialPlanStatus.active.name,
      createdAt:
          (json['createdAt'] as String?) ?? DateTime.now().toIso8601String(),
      updatedAt:
          (json['updatedAt'] as String?) ?? DateTime.now().toIso8601String(),
      priority: (json['priority'] as String?) ?? PlanPriority.medium.name,
      notes: json['notes'] as String?,
      autoTrackFromTransactions:
          (json['autoTrackFromTransactions'] as bool?) ?? false,
      linkedCategory: json['linkedCategory'] as String?,
      linkedAccount: json['linkedAccount'] as String?,
    );
  }
}

class FinancialPlanRealizationModel {
  const FinancialPlanRealizationModel({
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
  final String realizedAt;
  final String createdAt;
  final String source;
  final String? reflectionNote;

  factory FinancialPlanRealizationModel.fromEntity(
    FinancialPlanRealization entity,
  ) {
    return FinancialPlanRealizationModel(
      id: entity.id,
      userId: entity.userId,
      planId: entity.planId,
      actualAmount: entity.actualAmount,
      realizedAt: entity.realizedAt.toIso8601String(),
      createdAt: entity.createdAt.toIso8601String(),
      source: entity.source.name,
      reflectionNote: entity.reflectionNote,
    );
  }

  FinancialPlanRealization toEntity() {
    return FinancialPlanRealization(
      id: id,
      userId: userId,
      planId: planId,
      actualAmount: actualAmount,
      realizedAt: DateTime.parse(realizedAt),
      createdAt: DateTime.parse(createdAt),
      source: FinancialPlanRealizationSource.values.firstWhere(
        (item) => item.name == source,
        orElse: () => FinancialPlanRealizationSource.manual,
      ),
      reflectionNote: reflectionNote,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'planId': planId,
      'actualAmount': actualAmount,
      'realizedAt': realizedAt,
      'createdAt': createdAt,
      'source': source,
      'reflectionNote': reflectionNote,
    };
  }

  factory FinancialPlanRealizationModel.fromJson(Map<dynamic, dynamic> json) {
    return FinancialPlanRealizationModel(
      id: json['id'] as String,
      userId: (json['userId'] as String?) ?? '',
      planId: (json['planId'] as String?) ?? '',
      actualAmount: (json['actualAmount'] as num?)?.toDouble() ?? 0,
      realizedAt:
          (json['realizedAt'] as String?) ?? DateTime.now().toIso8601String(),
      createdAt:
          (json['createdAt'] as String?) ?? DateTime.now().toIso8601String(),
      source:
          (json['source'] as String?) ?? FinancialPlanRealizationSource.manual.name,
      reflectionNote: json['reflectionNote'] as String?,
    );
  }
}
