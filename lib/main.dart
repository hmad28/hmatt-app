import 'package:app_2/app.dart';
import 'package:app_2/features/finance/data/datasources/account_local_datasource.dart';
import 'package:app_2/features/finance/data/datasources/calendar_event_local_datasource.dart';
import 'package:app_2/features/finance/data/datasources/category_local_datasource.dart';
import 'package:app_2/features/finance/data/datasources/financial_plan_local_datasource.dart';
import 'package:app_2/features/finance/data/datasources/transaction_local_datasource.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  await Hive.initFlutter();
  await Hive.openBox<Map>(TransactionLocalDataSource.boxName);
  await Hive.openBox<Map>(AccountLocalDataSource.boxName);
  await Hive.openBox<Map>(CategoryLocalDataSource.boxName);
  await Hive.openBox<Map>(CalendarEventLocalDataSource.boxName);
  await Hive.openBox<Map>(FinancialPlanLocalDataSource.planBoxName);
  await Hive.openBox<Map>(FinancialPlanLocalDataSource.realizationBoxName);
  await Hive.openBox<Map>('auth_box');

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (_) => const ProviderScope(
        child: App(),
      ),
    ),
  );
}
