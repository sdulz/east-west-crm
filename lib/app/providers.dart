import 'package:field_crm/core/clock.dart';
import 'package:field_crm/core/connectivity/connectivity_service.dart';
import 'package:field_crm/core/mock/mock_store.dart';
import 'package:field_crm/core/notifications/push_notification_service.dart';
import 'package:field_crm/core/notifications/reminder_scheduler.dart';
import 'package:field_crm/core/storage/app_database.dart';
import 'package:field_crm/core/storage/biometric_auth.dart';
import 'package:field_crm/core/storage/key_value_store.dart';
import 'package:field_crm/core/storage/secure_store.dart';
import 'package:field_crm/features/activities/data/mock_activity_repository.dart';
import 'package:field_crm/features/activities/domain/activity_repository.dart';
import 'package:field_crm/features/auth/data/mock_auth_repository.dart';
import 'package:field_crm/features/auth/domain/auth_repository.dart';
import 'package:field_crm/features/customers/data/mock_customer_repository.dart';
import 'package:field_crm/features/customers/domain/customer_repository.dart';
import 'package:field_crm/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:field_crm/features/dashboard/domain/dashboard_repository.dart';
import 'package:field_crm/features/handover/data/mock_user_directory_repository.dart';
import 'package:field_crm/features/handover/domain/user_directory_repository.dart';
import 'package:field_crm/features/history/data/mock_history_repository.dart';
import 'package:field_crm/features/history/domain/history_repository.dart';
import 'package:field_crm/features/opportunities/data/mock_opportunity_repository.dart';
import 'package:field_crm/features/opportunities/domain/opportunity_repository.dart';
import 'package:field_crm/features/pending/data/drift_pending_queue_repository.dart';
import 'package:field_crm/features/pending/domain/pending_queue_repository.dart';
import 'package:field_crm/features/pipeline/data/mock_pipeline_repository.dart';
import 'package:field_crm/features/pipeline/domain/pipeline_repository.dart';
import 'package:field_crm/features/search/data/mock_search_repository.dart';
import 'package:field_crm/features/search/domain/search_repository.dart';
import 'package:field_crm/features/team/data/mock_team_repository.dart';
import 'package:field_crm/features/team/domain/team_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

// ---------------------------------------------------------------------------
// Infrastructure. Bootstrap overrides the ones that need async setup.
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
Clock clock(Ref ref) => const Clock();

@Riverpod(keepAlive: true)
SecureStore secureStore(Ref ref) => FlutterSecureStore();

@Riverpod(keepAlive: true)
BiometricAuth biometricAuth(Ref ref) => LocalAuthBiometricAuth();

@Riverpod(keepAlive: true)
ConnectivityService connectivityService(Ref ref) => PlusConnectivityService();

@Riverpod(keepAlive: true)
ReminderScheduler reminderScheduler(Ref ref) => LocalReminderScheduler();

@Riverpod(keepAlive: true)
PushNotificationService pushNotificationService(Ref ref) =>
    const NoopPushNotificationService();

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) =>
    throw UnimplementedError('Overridden in bootstrap');

@Riverpod(keepAlive: true)
KeyValueStore keyValueStore(Ref ref) =>
    DriftKeyValueStore(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
MockStore mockStore(Ref ref) =>
    throw UnimplementedError('Overridden in bootstrap');

// ---------------------------------------------------------------------------
// Repositories. THIS is the only file to touch when a real backend arrives:
// return the real implementations here and nothing above the domain changes.
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    MockAuthRepository(ref.watch(mockStoreProvider));

@Riverpod(keepAlive: true)
DashboardRepository dashboardRepository(Ref ref) =>
    MockDashboardRepository(ref.watch(mockStoreProvider));

@Riverpod(keepAlive: true)
SearchRepository searchRepository(Ref ref) =>
    MockSearchRepository(ref.watch(mockStoreProvider));

@Riverpod(keepAlive: true)
CustomerRepository customerRepository(Ref ref) =>
    MockCustomerRepository(ref.watch(mockStoreProvider));

@Riverpod(keepAlive: true)
OpportunityRepository opportunityRepository(Ref ref) =>
    MockOpportunityRepository(ref.watch(mockStoreProvider));

@Riverpod(keepAlive: true)
PipelineRepository pipelineRepository(Ref ref) =>
    MockPipelineRepository(ref.watch(mockStoreProvider));

@Riverpod(keepAlive: true)
ActivityRepository activityRepository(Ref ref) =>
    MockActivityRepository(ref.watch(mockStoreProvider));

@Riverpod(keepAlive: true)
HistoryRepository historyRepository(Ref ref) =>
    MockHistoryRepository(ref.watch(mockStoreProvider));

@Riverpod(keepAlive: true)
UserDirectoryRepository userDirectoryRepository(Ref ref) =>
    MockUserDirectoryRepository(ref.watch(mockStoreProvider));

@Riverpod(keepAlive: true)
TeamRepository teamRepository(Ref ref) =>
    MockTeamRepository(ref.watch(mockStoreProvider));

@Riverpod(keepAlive: true)
PendingQueueRepository pendingQueueRepository(Ref ref) =>
    DriftPendingQueueRepository(ref.watch(appDatabaseProvider));

// ---------------------------------------------------------------------------
// Cross-feature refresh signal. Any confirmed write bumps it; list providers
// watch it so they reload from the repository (never from local state).
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
class RefreshTick extends _$RefreshTick {
  @override
  int build() => 0;
  void bump() => state++;
}
