import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class OwnerDashboardState {
  const OwnerDashboardState({
    required this.userCount,
    required this.users,
    required this.lastBroadcastMessage,
    required this.lastBroadcastAt,
    required this.lastBroadcastTarget,
    required this.lastBroadcastTargetUserId,
    required this.history,
  });

  final int userCount;
  final List<OwnerUserItem> users;
  final String? lastBroadcastMessage;
  final DateTime? lastBroadcastAt;
  final OwnerNotificationTarget? lastBroadcastTarget;
  final String? lastBroadcastTargetUserId;
  final List<OwnerNotificationItem> history;
}

class OwnerUserItem {
  const OwnerUserItem({
    required this.id,
    required this.username,
    required this.createdAt,
  });

  final String id;
  final String username;
  final DateTime? createdAt;
}

enum OwnerNotificationTarget { global, direct }

class OwnerNotificationItem {
  const OwnerNotificationItem({
    required this.id,
    required this.message,
    required this.createdAt,
    required this.target,
    this.targetUserId,
    this.targetUsername,
  });

  final String id;
  final String message;
  final DateTime createdAt;
  final OwnerNotificationTarget target;
  final String? targetUserId;
  final String? targetUsername;
}

final ownerDashboardProvider =
    AsyncNotifierProvider<OwnerDashboardController, OwnerDashboardState>(
      OwnerDashboardController.new,
    );

class OwnerDashboardController extends AsyncNotifier<OwnerDashboardState> {
  static const _usersKey = 'users';
  static const _ownerBroadcastKey = 'owner_broadcast';
  static const _ownerBroadcastHistoryKey = 'owner_broadcast_history';

  @override
  Future<OwnerDashboardState> build() async {
    if (!Hive.isBoxOpen('auth_box')) {
      return const OwnerDashboardState(
        userCount: 0,
        users: [],
        lastBroadcastMessage: null,
        lastBroadcastAt: null,
        lastBroadcastTarget: null,
        lastBroadcastTargetUserId: null,
        history: [],
      );
    }

    final box = Hive.box<Map>('auth_box');
    final users = _readUsers(box);
    final userItems = users.map((item) {
      final createdAtRaw = item['createdAt'] as String?;
      return OwnerUserItem(
        id: item['id'] as String? ?? '-',
        username: item['username'] as String? ?? '-',
        createdAt: createdAtRaw == null ? null : DateTime.tryParse(createdAtRaw),
      );
    }).toList()
      ..sort((a, b) {
        final aDate = a.createdAt;
        final bDate = b.createdAt;
        if (aDate == null && bDate == null) {
          return a.username.compareTo(b.username);
        }
        if (aDate == null) {
          return 1;
        }
        if (bDate == null) {
          return -1;
        }
        return bDate.compareTo(aDate);
      });
    final broadcastRaw = box.get(_ownerBroadcastKey);
    final historyRaw = box.get(_ownerBroadcastHistoryKey);

    final lastMessage = broadcastRaw?['message'] as String?;
    final lastAtRaw = broadcastRaw?['createdAt'] as String?;
    final lastAt = lastAtRaw == null ? null : DateTime.tryParse(lastAtRaw);
    final lastTargetRaw = broadcastRaw?['target'] as String?;
    final lastTarget = lastTargetRaw == OwnerNotificationTarget.direct.name
        ? OwnerNotificationTarget.direct
        : lastTargetRaw == OwnerNotificationTarget.global.name
        ? OwnerNotificationTarget.global
        : null;
    final lastTargetUserId = broadcastRaw?['targetUserId'] as String?;
    final history = _readHistory(historyRaw);

    return OwnerDashboardState(
      userCount: users.length,
      users: userItems,
      lastBroadcastMessage: lastMessage,
      lastBroadcastAt: lastAt,
      lastBroadcastTarget: lastTarget,
      lastBroadcastTargetUserId: lastTargetUserId,
      history: history,
    );
  }

  Future<void> sendBroadcast(String message) async {
    final clean = message.trim();
    if (clean.isEmpty || !Hive.isBoxOpen('auth_box')) {
      return;
    }
    final box = Hive.box<Map>('auth_box');
    final now = DateTime.now().toIso8601String();
    await box.put(_ownerBroadcastKey, {
      'message': clean,
      'createdAt': now,
      'target': OwnerNotificationTarget.global.name,
      'targetUserId': null,
      'targetUsername': null,
    });
    await _appendHistory(
      box: box,
      message: clean,
      target: OwnerNotificationTarget.global,
    );
    ref.invalidateSelf();
  }

  Future<void> sendDirectNotification({
    required String userId,
    required String username,
    required String message,
  }) async {
    final clean = message.trim();
    if (clean.isEmpty || userId.trim().isEmpty || !Hive.isBoxOpen('auth_box')) {
      return;
    }

    final box = Hive.box<Map>('auth_box');
    final now = DateTime.now().toIso8601String();
    await box.put(_ownerBroadcastKey, {
      'message': clean,
      'createdAt': now,
      'target': OwnerNotificationTarget.direct.name,
      'targetUserId': userId,
      'targetUsername': username,
    });
    await _appendHistory(
      box: box,
      message: clean,
      target: OwnerNotificationTarget.direct,
      targetUserId: userId,
      targetUsername: username,
    );
    ref.invalidateSelf();
  }

  Future<void> _appendHistory({
    required Box<Map> box,
    required String message,
    required OwnerNotificationTarget target,
    String? targetUserId,
    String? targetUsername,
  }) async {
    final existing = box.get(_ownerBroadcastHistoryKey);
    final list = ((existing?['items']) as List?)
            ?.map((item) => Map<String, dynamic>.from(item as Map))
            .toList() ??
        <Map<String, dynamic>>[];
    list.insert(0, {
      'id': const Uuid().v4(),
      'message': message,
      'createdAt': DateTime.now().toIso8601String(),
      'target': target.name,
      'targetUserId': targetUserId,
      'targetUsername': targetUsername,
    });
    if (list.length > 20) {
      list.removeRange(20, list.length);
    }
    await box.put(_ownerBroadcastHistoryKey, {'items': list});
  }

  List<OwnerNotificationItem> _readHistory(Map<dynamic, dynamic>? raw) {
    final items = (raw?['items'] as List?) ?? const [];
    return items.map((item) {
      final map = Map<String, dynamic>.from(item as Map<dynamic, dynamic>);
      final createdAt =
          DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now();
      final targetName = map['target'] as String?;
      final target = targetName == OwnerNotificationTarget.direct.name
          ? OwnerNotificationTarget.direct
          : OwnerNotificationTarget.global;
      return OwnerNotificationItem(
        id: map['id'] as String? ?? '-',
        message: map['message'] as String? ?? '-',
        createdAt: createdAt,
        target: target,
        targetUserId: map['targetUserId'] as String?,
        targetUsername: map['targetUsername'] as String?,
      );
    }).toList();
  }

  List<Map<String, dynamic>> _readUsers(Box<Map> box) {
    final raw = box.get(_usersKey, defaultValue: {'items': <Map>[]});
    final items = (raw?['items'] as List?) ?? const [];
    return items
        .map((item) => Map<String, dynamic>.from(item as Map<dynamic, dynamic>))
        .toList();
  }
}
