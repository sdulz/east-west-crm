import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/dashboard/domain/dashboard_summary.dart';

abstract interface class DashboardRepository {
  /// Groups computed in the current user's timezone.
  Future<Result<DashboardSummary, Failure>> summary();
}
