class Api {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static String get login => '$baseUrl/api/login/';
  static String get register => '$baseUrl/api/register/';
  static String get users => '$baseUrl/api/users/';
  static String get workers => '$baseUrl/api/workers/';
  static String get updateBudget => '$baseUrl/api/workers/update_budget/';

  static String getWorkerBudgetHistoryUrl(int workerId) {
    return '$baseUrl/api/workers/$workerId/budget_history/';
  }
}
