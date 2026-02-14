class AppEnv {
  const AppEnv._();

  static const authMode = String.fromEnvironment(
    'AUTH_MODE',
    defaultValue: 'mock',
  );

  static const authApiBaseUrl = String.fromEnvironment(
    'AUTH_API_BASE_URL',
    defaultValue: '',
  );

  static const authApiKey = String.fromEnvironment(
    'AUTH_API_KEY',
    defaultValue: '',
  );

  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  static const updateConfigUrl = String.fromEnvironment(
    'UPDATE_CONFIG_URL',
    defaultValue: '',
  );

  static const ownerDashboardPin = String.fromEnvironment(
    'OWNER_DASHBOARD_PIN',
    defaultValue: 'owner123',
  );

  static bool get useWorkerAuth => authMode.toLowerCase() == 'worker';
}
