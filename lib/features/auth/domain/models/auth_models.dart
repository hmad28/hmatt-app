enum AuthStatus { authenticated, unauthenticated }

class AuthSession {
  const AuthSession({
    required this.status,
    this.identifier,
    this.userId,
  });

  final AuthStatus status;
  final String? identifier;
  final String? userId;
}

class RegisterPayload {
  const RegisterPayload({
    required this.username,
    required this.password,
    this.securityQuestion,
    this.securityAnswer,
  });

  final String username;
  final String password;
  final String? securityQuestion;
  final String? securityAnswer;
}
