import 'package:app_2/features/auth/domain/models/auth_models.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession>(AuthController.new);

class AuthController extends AsyncNotifier<AuthSession> {
  static const _sessionKey = 'session';
  static const _usersKey = 'users';
  static const _ownerBroadcastKey = 'owner_broadcast';
  static const _loginAttemptsKey = 'login_attempts';
  static const _minPasswordLength = 8;
  static const _maxFailedAttempts = 5;
  static const _lockMinutes = 5;

  @override
  Future<AuthSession> build() async {
    if (!Hive.isBoxOpen('auth_box')) {
      return const AuthSession(status: AuthStatus.unauthenticated);
    }
    final box = Hive.box<Map>('auth_box');
    final raw = box.get(_sessionKey);
    if (raw == null) {
      return const AuthSession(status: AuthStatus.unauthenticated);
    }
    final isAuthenticated = raw['isAuthenticated'] as bool? ?? false;
    final userId = raw['userId'] as String?;
    return AuthSession(
      status: isAuthenticated && userId != null && userId.isNotEmpty
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated,
      identifier: raw['identifier'] as String?,
      userId: userId,
    );
  }

  String? readOwnerBroadcastMessage() {
    if (!Hive.isBoxOpen('auth_box')) {
      return null;
    }
    final raw = Hive.box<Map>('auth_box').get(_ownerBroadcastKey);
    return raw?['message'] as String?;
  }

  String? currentProfilePhotoPath() {
    if (!Hive.isBoxOpen('auth_box')) {
      return null;
    }
    final box = Hive.box<Map>('auth_box');
    final session = box.get(_sessionKey);
    final userId = (session?['userId'] as String?) ?? '';
    if (userId.isEmpty) {
      return null;
    }

    final users = _readUsers(box);
    for (final user in users) {
      if (user['id'] == userId) {
        return user['profilePhotoPath'] as String?;
      }
    }
    return null;
  }

  Future<void> updateCurrentProfilePhotoPath(String? path) async {
    if (!Hive.isBoxOpen('auth_box')) {
      return;
    }
    final box = Hive.box<Map>('auth_box');
    final session = box.get(_sessionKey);
    final userId = (session?['userId'] as String?) ?? '';
    if (userId.isEmpty) {
      return;
    }

    final users = _readUsers(box);
    var updated = false;
    for (final user in users) {
      if (user['id'] != userId) {
        continue;
      }
      if (path == null || path.trim().isEmpty) {
        user.remove('profilePhotoPath');
      } else {
        user['profilePhotoPath'] = path.trim();
      }
      updated = true;
      break;
    }
    if (!updated) {
      return;
    }
    await box.put(_usersKey, {'items': users});
    state = AsyncData(
      AuthSession(
        status: AuthStatus.authenticated,
        identifier: session?['identifier'] as String?,
        userId: userId,
      ),
    );
  }

  Future<void> login({required String identifier, required String password}) async {
    state = const AsyncLoading();
    final username = identifier.trim();
    final pass = password.trim();
    if (username.isEmpty || pass.isEmpty) {
      state = const AsyncData(AuthSession(status: AuthStatus.unauthenticated));
      return;
    }

    final box = Hive.box<Map>('auth_box');
    if (await _isLockedOut(box, username)) {
      state = const AsyncData(AuthSession(status: AuthStatus.unauthenticated));
      return;
    }
    final users = _readUsers(box);
    Map<String, dynamic>? found;
    for (final user in users) {
      if (user['username'] == username) {
        found = user;
        break;
      }
    }
    if (found == null) {
      await _recordFailedAttempt(box, username);
      state = const AsyncData(AuthSession(status: AuthStatus.unauthenticated));
      return;
    }

    final passwordHash = found['passwordHash'] as String?;
    final legacyPassword = found['password'] as String?;
    var isValid = false;
    if (passwordHash != null && passwordHash.isNotEmpty) {
      isValid = BCrypt.checkpw(pass, passwordHash);
    } else if (legacyPassword != null) {
      isValid = legacyPassword == pass;
    }

    if (!isValid) {
      await _recordFailedAttempt(box, username);
      state = const AsyncData(AuthSession(status: AuthStatus.unauthenticated));
      return;
    }

    await _clearFailedAttempts(box, username);

    final userId = found['id'] as String? ?? const Uuid().v4();
    if (found['id'] == null || passwordHash == null || passwordHash.isEmpty) {
      found['id'] = userId;
      found['passwordHash'] = BCrypt.hashpw(pass, BCrypt.gensalt());
      found.remove('password');
      await box.put(_usersKey, {'items': users});
    }

    await box.put(_sessionKey, {
      'isAuthenticated': true,
      'identifier': username,
      'userId': userId,
    });
    state = AsyncData(
      AuthSession(
        status: AuthStatus.authenticated,
        identifier: username,
        userId: userId,
      ),
    );
  }

  Future<void> register({
    required String username,
    required String password,
    String? securityQuestion,
    String? securityAnswer,
  }) async {
    state = const AsyncLoading();
    final cleanUsername = username.trim();
    final cleanPassword = password.trim();
    if (cleanUsername.isEmpty || cleanPassword.length < _minPasswordLength) {
      state = const AsyncData(AuthSession(status: AuthStatus.unauthenticated));
      return;
    }

    final box = Hive.box<Map>('auth_box');
    final users = _readUsers(box);
    final exists = users.any((u) => u['username'] == cleanUsername);
    if (exists) {
      state = const AsyncData(AuthSession(status: AuthStatus.unauthenticated));
      return;
    }

    final cleanQuestion = securityQuestion?.trim();
    final cleanAnswer = securityAnswer?.trim();
    users.add({
      'id': const Uuid().v4(),
      'username': cleanUsername,
      'passwordHash': BCrypt.hashpw(cleanPassword, BCrypt.gensalt()),
      'securityQuestion': (cleanQuestion == null || cleanQuestion.isEmpty)
          ? null
          : cleanQuestion,
      'securityAnswerHash': (cleanAnswer == null || cleanAnswer.isEmpty)
          ? null
          : BCrypt.hashpw(cleanAnswer, BCrypt.gensalt()),
      'createdAt': DateTime.now().toIso8601String(),
    });
    final created = users.last;
    await box.put(_usersKey, {'items': users});
    await box.put(_sessionKey, {
      'isAuthenticated': true,
      'identifier': cleanUsername,
      'userId': created['id'] as String,
    });

    state = AsyncData(
      AuthSession(
        status: AuthStatus.authenticated,
        identifier: cleanUsername,
        userId: created['id'] as String,
      ),
    );
  }

  Future<void> logout() async {
    if (Hive.isBoxOpen('auth_box')) {
      await Hive.box<Map>('auth_box').delete(_sessionKey);
    }
    state = const AsyncData(AuthSession(status: AuthStatus.unauthenticated));
  }

  List<Map<String, dynamic>> _readUsers(Box<Map> box) {
    final raw = box.get(_usersKey, defaultValue: {'items': <Map>[]});
    final items = (raw?['items'] as List?) ?? const [];
    return items
        .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
        .toList();
  }

  Future<void> _recordFailedAttempt(Box<Map> box, String username) async {
    final attempts = _readAttempts(box);
    final key = username.toLowerCase();
    final now = DateTime.now();
    final entry = Map<String, dynamic>.from(attempts[key] ?? const <String, dynamic>{});
    final count = (entry['count'] as int? ?? 0) + 1;
    entry['count'] = count;
    entry['lastFailedAt'] = now.toIso8601String();
    if (count >= _maxFailedAttempts) {
      entry['lockedUntil'] = now
          .add(const Duration(minutes: _lockMinutes))
          .toIso8601String();
      entry['count'] = 0;
    }
    attempts[key] = entry;
    await box.put(_loginAttemptsKey, {'items': attempts});
  }

  Future<void> _clearFailedAttempts(Box<Map> box, String username) async {
    final attempts = _readAttempts(box);
    final key = username.toLowerCase();
    if (!attempts.containsKey(key)) {
      return;
    }
    attempts.remove(key);
    await box.put(_loginAttemptsKey, {'items': attempts});
  }

  Future<bool> _isLockedOut(Box<Map> box, String username) async {
    final attempts = _readAttempts(box);
    final key = username.toLowerCase();
    final entry = attempts[key];
    if (entry == null) {
      return false;
    }
    final lockedUntil = DateTime.tryParse((entry['lockedUntil'] as String?) ?? '');
    if (lockedUntil == null) {
      return false;
    }
    if (lockedUntil.isAfter(DateTime.now())) {
      return true;
    }
    attempts.remove(key);
    await box.put(_loginAttemptsKey, {'items': attempts});
    return false;
  }

  Map<String, Map<String, dynamic>> _readAttempts(Box<Map> box) {
    final raw = box.get(_loginAttemptsKey);
    final items = (raw?['items'] as Map?) ?? const <dynamic, dynamic>{};
    final mapped = <String, Map<String, dynamic>>{};
    for (final entry in items.entries) {
      mapped[entry.key.toString()] = Map<String, dynamic>.from(
        entry.value as Map<dynamic, dynamic>,
      );
    }
    return mapped;
  }
}
