class AppConfig {
  const AppConfig._();

  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'https://backend.hakeem-app.cloud',
  );

  static const String aiApiBaseUrl = String.fromEnvironment(
    'AI_API_BASE_URL',
    defaultValue: 'https://ai-api.hakim-app.cloud',
  );

  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue:
        '66ba4126aa3b9f227adde3d1e8e143ad0086ad0fdaf861501051eabec00ccc0b',
  );

  static const String registrationAdminEmail = String.fromEnvironment(
    'ADMIN_EMAIL',
    defaultValue: 'admin@system.com',
  );

  static const String registrationAdminPassword = String.fromEnvironment(
    'ADMIN_PASSWORD',
    defaultValue: 'admin123!',
  );

  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const int auditLogsPageSize = 50;
}
