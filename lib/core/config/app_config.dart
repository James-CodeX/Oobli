/// Static configuration. Values can be overridden at build time with
/// `--dart-define=APPWRITE_ENDPOINT=...` etc. None of these are secrets:
/// the Gemini key lives only in the `oobli-ai` Appwrite Function.
abstract final class AppConfig {
  static const appwriteEndpoint = String.fromEnvironment(
    'APPWRITE_ENDPOINT',
    defaultValue: 'https://sgp.cloud.appwrite.io/v1',
  );
  static const appwriteProjectId = String.fromEnvironment(
    'APPWRITE_PROJECT_ID',
    defaultValue: '6b012dd80037b9146a2b',
  );

  static const databaseId = 'oobli';
  static const transactionsTable = 'transactions';
  static const merchantRulesTable = 'merchant_rules';
  static const plansTable = 'plans';
  static const goalsTable = 'goals';

  static const aiFunctionId = 'oobli-ai';

  static const appVersion = '1.0.0';

  /// How far back the first SMS sync reaches.
  static const initialSmsLookback = Duration(days: 90);

  /// How much history the app keeps in memory for charts and insights.
  static const historyWindow = Duration(days: 400);
}
