import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/dashboard/domain/dashboard_summary.dart';

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, DashboardSummary>(
  DashboardController.new,
);

class DashboardController extends AsyncNotifier<DashboardSummary> {
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
