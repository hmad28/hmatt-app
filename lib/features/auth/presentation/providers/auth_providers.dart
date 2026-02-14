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

  Future<void> login({required String identifier, required String password}) async {
    state = const AsyncLoading();
    final username = identifier.trim();
    final pass = password.trim();
    if (username.isEmpty || pass.isEmpty) {
      state = const AsyncData(AuthSession(status: AuthStatus.unauthenticated));
      return;
    }

    final box = Hive.box<Map>('auth_box');
    final users = _readUsers(box);
    Map<String, dynamic>? found;
    for (final user in users) {
      if (user['username'] == username) {
        found = user;
        break;
      }
    }
    if (found == null) {
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
      state = const AsyncData(AuthSession(status: AuthStatus.unauthenticated));
      return;
    }

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
    if (cleanUsername.isEmpty || cleanPassword.length < 4) {
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
}
