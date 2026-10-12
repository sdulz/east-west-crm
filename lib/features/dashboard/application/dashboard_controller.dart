import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/dashboard/domain/dashboard_summary.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_controller.g.dart';

/// FR-MOB-002. Kept alive: tab switches must not refetch.
@Riverpod(keepAlive: true)
class DashboardController extends _$DashboardController {
  @override
  Future<DashboardSummary> build() {
    ref
      ..watch(refreshTickProvider)
      ..watch(currentUserProvider);
    return ref.watch(dashboardRepositoryProvider).summary().orThrow;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
