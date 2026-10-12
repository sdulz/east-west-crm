import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/auth/domain/app_user.dart';
import 'package:field_crm/features/opportunities/domain/opportunity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'team.freezed.dart';
part 'team.g.dart';

@freezed
abstract class Team with _$Team {
  const factory Team({
    required String id,
    required String name,
    required String supervisorId,
  }) = _Team;

  factory Team.fromJson(Map<String, dynamic> json) => _$TeamFromJson(json);
}

@freezed
abstract class TeamMemberOverview with _$TeamMemberOverview {
  const factory TeamMemberOverview({
    required AppUser user,
    @Default(<Opportunity>[]) List<Opportunity> openOpportunities,
    @Default(<Activity>[]) List<Activity> overdueActivities,
  }) = _TeamMemberOverview;
}

@freezed
abstract class TeamOverview with _$TeamOverview {
  const factory TeamOverview({
    required Team team,
    @Default(<TeamMemberOverview>[]) List<TeamMemberOverview> members,
  }) = _TeamOverview;
}
