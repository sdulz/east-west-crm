/// Build-time configuration, injected with `--dart-define-from-file=env/<flavor>.json`.
/// Nothing here is a secret; secrets live in secure storage at runtime.
enum Flavor { dev, uat, prod }

abstract final class AppEnv {
  static const flavorName = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );
  static const appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'East West CRM',
  );
  static const currencyCode = String.fromEnvironment(
    'CURRENCY_CODE',
    defaultValue: 'NPR',
  );
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const inactivityTimeoutMinutes = int.fromEnvironment(
    'INACTIVITY_TIMEOUT_MINUTES',
    defaultValue: 30,
  );
  static const pendingMaxAgeDays = int.fromEnvironment(
    'PENDING_MAX_AGE_DAYS',
    defaultValue: 7,
  );
  static const privacyScreen = bool.fromEnvironment(
    'PRIVACY_SCREEN',
    defaultValue: true,
  );
  static const mockMinLatencyMs = int.fromEnvironment(
    'MOCK_MIN_LATENCY_MS',
    defaultValue: 200,
  );
  static const mockMaxLatencyMs = int.fromEnvironment(
    'MOCK_MAX_LATENCY_MS',
    defaultValue: 1200,
  );

  static Flavor get flavor => Flavor.values.firstWhere(
    (f) => f.name == flavorName,
    orElse: () => Flavor.dev,
  );

  static bool get isDev => flavor == Flavor.dev;
}
