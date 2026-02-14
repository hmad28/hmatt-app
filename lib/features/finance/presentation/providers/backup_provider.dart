import 'dart:convert';
import 'dart:io';

import 'package:app_2/features/auth/presentation/providers/auth_providers.dart';
import 'package:app_2/features/finance/data/datasources/account_local_datasource.dart';
import 'package:app_2/features/finance/data/datasources/category_local_datasource.dart';
import 'package:app_2/features/finance/data/datasources/transaction_local_datasource.dart';
import 'package:app_2/features/finance/data/models/finance_account_model.dart';
import 'package:app_2/features/finance/data/models/finance_category_model.dart';
import 'package:app_2/features/finance/data/models/transaction_item_model.dart';
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

    final transactions = await transactionsSource.getAll(userId: userId);
    final accounts = await accountsSource.getAll(userId: userId);
    final categories = await categoriesSource.getAll(userId: userId);

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
    if (accountsRaw is! List || categoriesRaw is! List || transactionsRaw is! List) {
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

    await transactionsSource.deleteByUser(userId);
    await accountsSource.deleteByUser(userId);
    await categoriesSource.deleteByUser(userId);

    for (final raw in accountsRaw) {
      if (raw is! Map) {
        continue;
      }
      final item = Map<String, dynamic>.from(raw);
      item['userId'] = userId;
      await accountsSource.add(FinanceAccountModel.fromJson(item));
    }

    for (final raw in categoriesRaw) {
      if (raw is! Map) {
        continue;
      }
      final item = Map<String, dynamic>.from(raw);
      item['userId'] = userId;
      await categoriesSource.add(FinanceCategoryModel.fromJson(item));
    }

    for (final raw in transactionsRaw) {
      if (raw is! Map) {
        continue;
      }
      final item = Map<String, dynamic>.from(raw);
      item['userId'] = userId;
      await transactionsSource.add(TransactionItemModel.fromJson(item));
    }

    _ref.invalidate(transactionsControllerProvider);
    _ref.invalidate(accountsControllerProvider);
    _ref.invalidate(categoriesControllerProvider);

    return filePath;
  }
}
