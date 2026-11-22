import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_crm/core/clock.dart';
import 'package:field_crm/core/connectivity/connectivity_service.dart';
import 'package:field_crm/core/mock/mock_store.dart';
import 'package:field_crm/core/network/crm_api_client.dart';
import 'package:field_crm/core/notifications/push_notification_service.dart';
import 'package:field_crm/core/notifications/reminder_scheduler.dart';
import 'package:field_crm/core/storage/app_database.dart';
import 'package:field_crm/core/storage/biometric_auth.dart';
import 'package:field_crm/core/storage/key_value_store.dart';
import 'package:field_crm/core/storage/secure_store.dart';
import 'package:field_crm/features/activities/data/api_activity_repository.dart';
import 'package:field_crm/features/activities/data/mock_activity_repository.dart';
import 'package:field_crm/features/activities/domain/activity_repository.dart';
import 'package:field_crm/features/auth/data/api_auth_repository.dart';
import 'package:field_crm/features/auth/data/mock_auth_repository.dart';
import 'package:field_crm/features/auth/domain/auth_repository.dart';
import 'package:field_crm/features/customers/data/api_customer_repository.dart';
import 'package:field_crm/features/customers/data/mock_customer_repository.dart';
import 'package:field_crm/features/customers/domain/customer_repository.dart';
import 'package:field_crm/features/dashboard/data/api_dashboard_repository.dart';
import 'package:field_crm/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:field_crm/features/dashboard/domain/dashboard_repository.dart';
import 'package:field_crm/features/handover/data/api_user_directory_repository.dart';
import 'package:field_crm/features/handover/data/mock_user_directory_repository.dart';
import 'package:field_crm/features/handover/domain/user_directory_repository.dart';
import 'package:field_crm/features/history/data/api_history_repository.dart';
import 'package:field_crm/features/history/data/mock_history_repository.dart';
import 'package:field_crm/features/history/domain/history_repository.dart';
import 'package:field_crm/features/notifications/data/api_notification_repository.dart';
import 'package:field_crm/features/notifications/data/mock_notification_repository.dart';
import 'package:field_crm/features/notifications/domain/notification_repository.dart';
import 'package:field_crm/features/opportunities/data/api_opportunity_repository.dart';
import 'package:field_crm/features/opportunities/data/mock_opportunity_repository.dart';
import 'package:field_crm/features/opportunities/domain/opportunity_repository.dart';
import 'package:field_crm/features/pending/data/drift_pending_queue_repository.dart';
import 'package:field_crm/features/pending/domain/pending_queue_repository.dart';
import 'package:field_crm/features/pipeline/data/api_pipeline_repository.dart';
import 'package:field_crm/features/pipeline/data/mock_pipeline_repository.dart';
import 'package:field_crm/features/pipeline/domain/pipeline_repository.dart';
import 'package:field_crm/features/quotations/data/api_quotation_repository.dart';
import 'package:field_crm/features/quotations/data/mock_quotation_repository.dart';
import 'package:field_crm/features/quotations/domain/quotation_repository.dart';
import 'package:field_crm/features/search/data/api_search_repository.dart';
import 'package:field_crm/features/search/data/mock_search_repository.dart';
import 'package:field_crm/features/search/domain/search_repository.dart';
import 'package:field_crm/features/team/data/api_team_repository.dart';
import 'package:field_crm/features/team/data/mock_team_repository.dart';
import 'package:field_crm/features/team/domain/team_repository.dart';

// ---------------------------------------------------------------------------
// Infrastructure. Bootstrap overrides the ones that need async setup.
// ---------------------------------------------------------------------------

final clockProvider = Provider<Clock>((ref) => const Clock());

final secureStoreProvider = Provider<SecureStore>((ref) => FlutterSecureStore());

final biometricAuthProvider = Provider<BiometricAuth>((ref) => LocalAuthBiometricAuth());

final connectivityServiceProvider = Provider<ConnectivityService>((ref) => PlusConnectivityService());

final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) => LocalReminderScheduler());

final pushNotificationServiceProvider = Provider<PushNotificationService>(
  (ref) => const NoopPushNotificationService(),
);

final appDatabaseProvider = Provider<AppDatabase>((ref) =>
    throw UnimplementedError('Overridden in bootstrap'));

final keyValueStoreProvider = Provider<KeyValueStore>((ref) =>
    DriftKeyValueStore(ref.watch(appDatabaseProvider)));

final mockStoreProvider = Provider<MockStore>((ref) =>
    throw UnimplementedError('Overridden in bootstrap'));

/// Controls whether repositories use the East West CRM REST API (`false`,
/// default) or the offline `MockStore` (`true`, used in widget/unit tests or
/// when launched with `--dart-define=USE_MOCK=true`).
final useMockApiProvider = Provider<bool>(
  (ref) => const bool.fromEnvironment('USE_MOCK', defaultValue: false),
);

// ---------------------------------------------------------------------------
// Repositories.
// ---------------------------------------------------------------------------

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (ref.watch(useMockApiProvider)) {
    return MockAuthRepository(ref.watch(mockStoreProvider));
  }
  return ApiAuthRepository(ref.watch(crmApiClientProvider));
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  if (ref.watch(useMockApiProvider)) {
    return MockCustomerRepository(ref.watch(mockStoreProvider));
  }
  return ApiCustomerRepository(ref.watch(crmApiClientProvider));
});

final opportunityRepositoryProvider = Provider<OpportunityRepository>((ref) {
  if (ref.watch(useMockApiProvider)) {
    return MockOpportunityRepository(ref.watch(mockStoreProvider));
  }
  return ApiOpportunityRepository(ref.watch(crmApiClientProvider));
});

final pipelineRepositoryProvider = Provider<PipelineRepository>((ref) {
  if (ref.watch(useMockApiProvider)) {
    return MockPipelineRepository(ref.watch(mockStoreProvider));
  }
  return ApiPipelineRepository(ref.watch(crmApiClientProvider));
});

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  if (ref.watch(useMockApiProvider)) {
    return MockActivityRepository(ref.watch(mockStoreProvider));
  }
  return ApiActivityRepository(ref.watch(crmApiClientProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  if (ref.watch(useMockApiProvider)) {
    return MockDashboardRepository(ref.watch(mockStoreProvider));
  }
  return ApiDashboardRepository(
    client: ref.watch(crmApiClientProvider),
    opportunityRepository: ref.watch(opportunityRepositoryProvider),
    activityRepository: ref.watch(activityRepositoryProvider),
    pipelineRepository: ref.watch(pipelineRepositoryProvider),
  );
});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  if (ref.watch(useMockApiProvider)) {
    return MockSearchRepository(ref.watch(mockStoreProvider));
  }
  return ApiSearchRepository(ref.watch(crmApiClientProvider));
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  if (ref.watch(useMockApiProvider)) {
    return MockHistoryRepository(ref.watch(mockStoreProvider));
  }
  return ApiHistoryRepository(ref.watch(crmApiClientProvider));
});

final userDirectoryRepositoryProvider = Provider<UserDirectoryRepository>((ref) {
  if (ref.watch(useMockApiProvider)) {
    return MockUserDirectoryRepository(ref.watch(mockStoreProvider));
  }
  return ApiUserDirectoryRepository(ref.watch(crmApiClientProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  if (ref.watch(useMockApiProvider)) {
    return MockNotificationRepository(ref.watch(mockStoreProvider));
  }
  return ApiNotificationRepository(ref.watch(crmApiClientProvider));
});

final quotationRepositoryProvider = Provider<QuotationRepository>((ref) {
  if (ref.watch(useMockApiProvider)) {
    return MockQuotationRepository(ref.watch(mockStoreProvider));
  }
  return ApiQuotationRepository(ref.watch(crmApiClientProvider));
});

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  if (ref.watch(useMockApiProvider)) {
    return MockTeamRepository(ref.watch(mockStoreProvider));
  }
  return ApiTeamRepository(
    client: ref.watch(crmApiClientProvider),
    opportunityRepository: ref.watch(opportunityRepositoryProvider),
    activityRepository: ref.watch(activityRepositoryProvider),
    pipelineRepository: ref.watch(pipelineRepositoryProvider),
  );
});

final pendingQueueRepositoryProvider = Provider<PendingQueueRepository>((ref) =>
    DriftPendingQueueRepository(ref.watch(appDatabaseProvider)));

// ---------------------------------------------------------------------------
// Cross-feature refresh signal. Any confirmed write bumps it; list providers
// watch it so they reload from the repository (never from local state).
// ---------------------------------------------------------------------------

class RefreshTickNotifier extends StateNotifier<int> {
  RefreshTickNotifier() : super(0);
  void bump() => state++;
}

final refreshTickProvider = StateNotifierProvider<RefreshTickNotifier, int>(
  (ref) => RefreshTickNotifier(),
);
