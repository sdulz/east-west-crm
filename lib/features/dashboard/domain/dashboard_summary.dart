import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/opportunities/domain/opportunity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_summary.freezed.dart';

@freezed
abstract class DashboardSummary with _$DashboardSummary {
  const factory DashboardSummary({
    @Default(<Activity>[]) List<Activity> today,
    @Default(<Activity>[]) List<Activity> upcoming,
    @Default(<Activity>[]) List<Activity> overdue,
    @Default(<Opportunity>[]) List<Opportunity> noFollowUp,
  }) = _DashboardSummary;
}
