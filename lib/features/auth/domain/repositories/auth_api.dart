import 'package:app_2/features/auth/domain/models/auth_models.dart';

abstract class AuthApi {
  Future<AuthSession> getSession();

  Future<AuthSession> login({required String identifier, required String password});

  Future<AuthSession> register(RegisterPayload payload);

  Future<void> logout();
}
