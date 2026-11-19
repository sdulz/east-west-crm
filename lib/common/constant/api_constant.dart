import 'base_api_constant.dart';

class ApiConstant {
  static const String _overrideBaseUrl = String.fromEnvironment('BASE_URL');

  static const BaseAPIConstant _api = BaseAPIConstant(
    stagURL: 'https://ewe.smarten.com.np',
    uatURL: 'https://ewe.smarten.com.np',
    prodURL: 'https://ewe.smarten.com.np',
    localUrl: 'http://localhost:8078',
  );

  static String get baseUrl {
    final raw = _overrideBaseUrl.isNotEmpty ? _overrideBaseUrl : _api.baseUrl;
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  static String get baseApiUrl => '$baseUrl/api/v1';

  // Auth
  static String get loginUrl => '$baseApiUrl/auth/login';
  static String get refreshTokenUrl => '$baseApiUrl/auth/refresh-token';
  static String get forgotPasswordUrl => '$baseApiUrl/auth/forget-password';
  static String get changePasswordUrl => '$baseApiUrl/auth/change-password';
  static String get logoutUrl => '$baseApiUrl/auth/logout';

  // Profile
  static String get profileUrl => '$baseApiUrl/profile';
  static String get profileUpdateUrl => '$baseApiUrl/profile/update';
  static String get meUrl => profileUrl;

  // Customers
  static String get customersUrl => '$baseApiUrl/customers';
  static String customerByIdUrl(Object customerId) =>
      '$baseApiUrl/customers/$customerId';
  static String customerActivitiesUrl(Object customerId) =>
      '$baseApiUrl/customers/$customerId/activities';

  // CRM (Stages & Leads)
  static String get crmStagesUrl => '$baseApiUrl/crm/stages';
  static String get pipelineStagesUrl => crmStagesUrl;
  static String get crmLeadsUrl => '$baseApiUrl/crm/leads';
  static String get opportunitiesUrl => crmLeadsUrl;
  static String crmLeadByIdUrl(Object leadId) => '$baseApiUrl/crm/leads/$leadId';
  static String crmLeadStageUrl(Object leadId) =>
      '$baseApiUrl/crm/leads/$leadId/stage';
  static String crmLeadNotesUrl(Object leadId) =>
      '$baseApiUrl/crm/leads/$leadId/notes';
  static String crmLeadActivitiesUrl(Object leadId) =>
      '$baseApiUrl/crm/leads/$leadId/activities';

  // Activities
  static String get activityTypesUrl => '$baseApiUrl/activity-types';
  static String activityDoneUrl(Object activityId) =>
      '$baseApiUrl/activities/$activityId/done';
  static String get activitiesUrl => activityTypesUrl;

  // Media
  static String attachmentUrl(Object attachmentId, {bool download = false}) =>
      '$baseApiUrl/attachments/$attachmentId${download ? '?download=1' : ''}';
  static String imageUrl(
    String model,
    Object id,
    String field, {
    bool download = false,
  }) =>
      '$baseApiUrl/image/$model/$id/$field${download ? '?download=1' : ''}';

  /// Resolves a potentially relative API path (e.g. `/api/v1/attachments/1` or
  /// `/api/v1/image/res.users/2/image_1920`) against [baseUrl].
  static String resolveUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      return '$baseUrl$trimmed';
    }
    return '$baseUrl/$trimmed';
  }

  // Legacy aliases
  static String get resetPasswordUrl => forgotPasswordUrl;
  static String get teamUrl => crmStagesUrl;
  static String get quotationsUrl => '$baseApiUrl/quotations';
  static String get productsUrl => '$baseApiUrl/products';
  static String get invoicesUrl => '$baseApiUrl/invoices';
  static String get dashboardSummaryUrl => '$baseApiUrl/dashboard/summary';
  static String get searchUrl => customersUrl;
  static String get notificationsUrl => '$baseApiUrl/notifications';
  static String get historyUrl => '$baseApiUrl/history';
  static String get syncUrl => '$baseApiUrl/sync';
}
