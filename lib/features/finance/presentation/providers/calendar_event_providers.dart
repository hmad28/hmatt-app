import 'package:app_2/features/auth/presentation/providers/auth_providers.dart';
import 'package:app_2/features/finance/data/datasources/calendar_event_local_datasource.dart';
import 'package:app_2/features/finance/data/repositories/calendar_event_repository_impl.dart';
import 'package:app_2/features/finance/domain/entities/calendar_event.dart';
import 'package:app_2/features/finance/domain/usecases/add_calendar_event_usecase.dart';
import 'package:app_2/features/finance/domain/usecases/delete_calendar_event_usecase.dart';
import 'package:app_2/features/finance/domain/usecases/get_calendar_events_usecase.dart';
import 'package:app_2/features/finance/domain/usecases/update_calendar_event_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

final _calendarUserIdProvider = Provider<String?>((ref) {
  final auth = ref.watch(authControllerProvider).valueOrNull;
  return auth?.userId;
});

final _calendarDataSourceProvider = Provider<CalendarEventLocalDataSource>((ref) {
  return CalendarEventLocalDataSource(
    Hive.box<Map>(CalendarEventLocalDataSource.boxName),
  );
});

final _calendarRepositoryProvider = Provider<CalendarEventRepositoryImpl>((ref) {
  return CalendarEventRepositoryImpl(ref.read(_calendarDataSourceProvider));
});

final _getCalendarEventsUseCaseProvider = Provider<GetCalendarEventsUseCase>((ref) {
  return GetCalendarEventsUseCase(ref.read(_calendarRepositoryProvider));
});

final _addCalendarEventUseCaseProvider = Provider<AddCalendarEventUseCase>((ref) {
  return AddCalendarEventUseCase(ref.read(_calendarRepositoryProvider));
});

final _updateCalendarEventUseCaseProvider = Provider<UpdateCalendarEventUseCase>((ref) {
  return UpdateCalendarEventUseCase(ref.read(_calendarRepositoryProvider));
});

final _deleteCalendarEventUseCaseProvider = Provider<DeleteCalendarEventUseCase>((ref) {
  return DeleteCalendarEventUseCase(ref.read(_calendarRepositoryProvider));
});

final calendarEventsControllerProvider =
    AsyncNotifierProvider<CalendarEventsController, List<CalendarEvent>>(
      CalendarEventsController.new,
    );

class CalendarEventsController extends AsyncNotifier<List<CalendarEvent>> {
  @override
  Future<List<CalendarEvent>> build() async {
    final userId = ref.watch(_calendarUserIdProvider);
    if (userId == null || userId.isEmpty) {
      return const [];
    }
    return ref.read(_getCalendarEventsUseCaseProvider).call(userId);
  }

  Future<void> add({
    required String title,
    required DateTime date,
    required CalendarEventType type,
    String? notes,
  }) async {
    final userId = ref.read(_calendarUserIdProvider);
    if (userId == null || userId.isEmpty) {
      return;
    }
    final now = DateTime.now();
    await ref.read(_addCalendarEventUseCaseProvider).call(
          CalendarEvent(
            id: const Uuid().v4(),
            userId: userId,
            title: title.trim(),
            date: DateTime(date.year, date.month, date.day),
            type: type,
            createdAt: now,
            notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
          ),
        );
    state = AsyncData(await ref.read(_getCalendarEventsUseCaseProvider).call(userId));
  }

  Future<void> updateEvent(CalendarEvent item) async {
    final userId = ref.read(_calendarUserIdProvider);
    if (userId == null || userId.isEmpty || item.userId != userId) {
      return;
    }
    await ref.read(_updateCalendarEventUseCaseProvider).call(item);
    state = AsyncData(await ref.read(_getCalendarEventsUseCaseProvider).call(userId));
  }

  Future<void> deleteEvent(String id) async {
    final userId = ref.read(_calendarUserIdProvider);
    if (userId == null || userId.isEmpty) {
      return;
    }
    final currentItems = state.valueOrNull ?? const <CalendarEvent>[];
    CalendarEvent? target;
    for (final item in currentItems) {
      if (item.id == id) {
        target = item;
        break;
      }
    }
    if (target == null || target.userId != userId) {
      return;
    }
    await ref.read(_deleteCalendarEventUseCaseProvider).call(id);
    state = AsyncData(await ref.read(_getCalendarEventsUseCaseProvider).call(userId));
  }
}
