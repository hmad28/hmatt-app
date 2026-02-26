import 'dart:convert';
import 'dart:io';

import 'package:app_2/features/auth/presentation/providers/auth_providers.dart';
import 'package:app_2/features/finance/data/datasources/account_local_datasource.dart';
import 'package:app_2/features/finance/data/datasources/calendar_event_local_datasource.dart';
import 'package:app_2/features/finance/data/datasources/category_local_datasource.dart';
import 'package:app_2/features/finance/data/datasources/financial_plan_local_datasource.dart';
import 'package:app_2/features/finance/data/datasources/transaction_local_datasource.dart';
import 'package:app_2/features/finance/data/models/finance_account_model.dart';
import 'package:app_2/features/finance/data/models/calendar_event_model.dart';
import 'package:app_2/features/finance/data/models/finance_category_model.dart';
import 'package:app_2/features/finance/data/models/financial_plan_model.dart';
import 'package:app_2/features/finance/data/models/transaction_item_model.dart';
import 'package:app_2/features/finance/presentation/providers/calendar_event_providers.dart';
import 'package:app_2/features/finance/presentation/providers/transaction_providers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final backupControllerProvider = Provider<BackupController>((ref) {
  return BackupController(ref);
});

class BackupController {
  BackupController(this._ref);

  final Ref _ref;

  Future<String?> exportCurrentUserData() async {
    if (kIsWeb) {
      throw Exception('Ekspor backup belum didukung untuk web.');
    }

    final auth = _ref.read(authControllerProvider).valueOrNull;
    final userId = auth?.userId;
    if (userId == null || userId.isEmpty) {
      throw Exception('Sesi pengguna tidak ditemukan. Silakan login ulang.');
    }

    final transactionsSource = TransactionLocalDataSource(
      Hive.box<Map>(TransactionLocalDataSource.boxName),
    );
    final accountsSource = AccountLocalDataSource(
      Hive.box<Map>(AccountLocalDataSource.boxName),
    );
    final categoriesSource = CategoryLocalDataSource(
      Hive.box<Map>(CategoryLocalDataSource.boxName),
    );
    final plansSource = FinancialPlanLocalDataSource(
      Hive.box<Map>(FinancialPlanLocalDataSource.planBoxName),
      Hive.box<Map>(FinancialPlanLocalDataSource.realizationBoxName),
    );
    final calendarSource = CalendarEventLocalDataSource(
      Hive.box<Map>(CalendarEventLocalDataSource.boxName),
    );

    final transactions = await transactionsSource.getAll(userId: userId);
    final accounts = await accountsSource.getAll(userId: userId);
    final categories = await categoriesSource.getAll(userId: userId);
    final plans = await plansSource.getPlans(userId: userId);
    final realizations = await plansSource.getRealizations(userId: userId);
    final calendarEvents = await calendarSource.getAll(userId: userId);

    final payload = <String, dynamic>{
      'schema_version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'app': 'Hmatt',
      'user': {
        'user_id': userId,
        'username': auth?.identifier,
      },
      'data': {
        'accounts': accounts.map((item) => item.toJson()).toList(),
        'categories': categories.map((item) => item.toJson()).toList(),
        'transactions': transactions.map((item) => item.toJson()).toList(),
        'financial_plans': plans.map((item) => item.toJson()).toList(),
        'financial_plan_realizations':
            realizations.map((item) => item.toJson()).toList(),
        'calendar_events': calendarEvents.map((item) => item.toJson()).toList(),
      },
    };

    final jsonText = const JsonEncoder.withIndent('  ').convert(payload);
    final defaultName =
        'hmatt_backup_${DateTime.now().toIso8601String().split('T').first}.json';

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Simpan backup Hmatt',
      fileName: defaultName,
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (savePath == null || savePath.trim().isEmpty) {
      return null;
    }

    await File(savePath).writeAsString(jsonText, flush: true);
    return savePath;
  }

  Future<String?> importCurrentUserData() async {
    if (kIsWeb) {
      throw Exception('Impor backup belum didukung untuk web.');
    }

    final auth = _ref.read(authControllerProvider).valueOrNull;
    final userId = auth?.userId;
    if (userId == null || userId.isEmpty) {
      throw Exception('Sesi pengguna tidak ditemukan. Silakan login ulang.');
    }

    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'Pilih file backup Hmatt',
      type: FileType.custom,
      allowedExtensions: const ['json'],
      allowMultiple: false,
      withData: false,
    );
    if (picked == null || picked.files.isEmpty) {
      return null;
    }

    final filePath = picked.files.single.path;
    if (filePath == null || filePath.trim().isEmpty) {
      throw Exception('File backup tidak valid.');
    }

    final content = await File(filePath).readAsString();
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format backup tidak valid.');
    }

    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Struktur backup tidak valid.');
    }

    final accountsRaw = data['accounts'];
    final categoriesRaw = data['categories'];
    final transactionsRaw = data['transactions'];
    final plansRaw = data['financial_plans'];
    final realizationsRaw = data['financial_plan_realizations'];
    final calendarRaw = data['calendar_events'];
    if (accountsRaw is! List ||
        categoriesRaw is! List ||
        transactionsRaw is! List ||
        plansRaw is! List ||
        realizationsRaw is! List ||
        calendarRaw is! List) {
      throw Exception('Isi backup tidak lengkap.');
    }

    final transactionsSource = TransactionLocalDataSource(
      Hive.box<Map>(TransactionLocalDataSource.boxName),
    );
    final accountsSource = AccountLocalDataSource(
      Hive.box<Map>(AccountLocalDataSource.boxName),
    );
    final categoriesSource = CategoryLocalDataSource(
      Hive.box<Map>(CategoryLocalDataSource.boxName),
    );
    final plansSource = FinancialPlanLocalDataSource(
      Hive.box<Map>(FinancialPlanLocalDataSource.planBoxName),
      Hive.box<Map>(FinancialPlanLocalDataSource.realizationBoxName),
    );
    final calendarSource = CalendarEventLocalDataSource(
      Hive.box<Map>(CalendarEventLocalDataSource.boxName),
    );

    final accountsToImport = accountsRaw.map((raw) {
      if (raw is! Map) {
        throw Exception('Format akun pada backup tidak valid.');
      }
      final item = Map<String, dynamic>.from(raw);
      item['userId'] = userId;
      return FinanceAccountModel.fromJson(item);
    }).toList(growable: false);

    final categoriesToImport = categoriesRaw.map((raw) {
      if (raw is! Map) {
        throw Exception('Format kategori pada backup tidak valid.');
      }
      final item = Map<String, dynamic>.from(raw);
      item['userId'] = userId;
      return FinanceCategoryModel.fromJson(item);
    }).toList(growable: false);

    final transactionsToImport = transactionsRaw.map((raw) {
      if (raw is! Map) {
        throw Exception('Format transaksi pada backup tidak valid.');
      }
      final item = Map<String, dynamic>.from(raw);
      item['userId'] = userId;
      return TransactionItemModel.fromJson(item);
    }).toList(growable: false);

    final plansToImport = plansRaw.map((raw) {
      if (raw is! Map) {
        throw Exception('Format plan keuangan pada backup tidak valid.');
      }
      final item = Map<String, dynamic>.from(raw);
      item['userId'] = userId;
      return FinancialPlanModel.fromJson(item);
    }).toList(growable: false);

    final realizationsToImport = realizationsRaw.map((raw) {
      if (raw is! Map) {
        throw Exception('Format realisasi plan pada backup tidak valid.');
      }
      final item = Map<String, dynamic>.from(raw);
      item['userId'] = userId;
      return FinancialPlanRealizationModel.fromJson(item);
    }).toList(growable: false);

    final calendarToImport = calendarRaw.map((raw) {
      if (raw is! Map) {
        throw Exception('Format event kalender pada backup tidak valid.');
      }
      final item = Map<String, dynamic>.from(raw);
      item['userId'] = userId;
      return CalendarEventModel.fromJson(item);
    }).toList(growable: false);

    await calendarSource.deleteByUser(userId);
    await plansSource.deleteByUser(userId);
    await transactionsSource.deleteByUser(userId);
    await accountsSource.deleteByUser(userId);
    await categoriesSource.deleteByUser(userId);

    for (final item in accountsToImport) {
      await accountsSource.add(item);
    }

    for (final item in categoriesToImport) {
      await categoriesSource.add(item);
    }

    for (final item in transactionsToImport) {
      await transactionsSource.add(item);
    }

    for (final item in plansToImport) {
      await plansSource.addPlan(item);
    }

    for (final item in realizationsToImport) {
      await plansSource.addRealization(item);
    }

    for (final item in calendarToImport) {
      await calendarSource.add(item);
    }

    _ref.invalidate(transactionsControllerProvider);
    _ref.invalidate(accountsControllerProvider);
    _ref.invalidate(categoriesControllerProvider);
    _ref.invalidate(calendarEventsControllerProvider);

    return filePath;
  }
}
