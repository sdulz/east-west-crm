import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity.freezed.dart';
part 'activity.g.dart';

enum ActivityType { call, visit, meeting, note, todo }

enum ActivityState { planned, done, overdue }

enum RelatedType { customer, opportunity }

@freezed
abstract class Activity with _$Activity {
  const factory Activity({
    required String id,
    required ActivityType type,
    required RelatedType relatedType,
    required String relatedId,
    required String summary,
    required String ownerId,
    required DateTime updatedAt,
    @Default(ActivityState.planned) ActivityState state,
    String? outcome,
    DateTime? dueAt,
  }) = _Activity;

  factory Activity.fromJson(Map<String, dynamic> json) =>
      _$ActivityFromJson(json);
}

/// Activity types are configuration loaded from the repository, not baked
/// into the UI.
@freezed
abstract class ActivityTypeDef with _$ActivityTypeDef {
  const factory ActivityTypeDef({
    required ActivityType type,
    required String label,
    @Default(false) bool isFollowUp,
  }) = _ActivityTypeDef;

  factory ActivityTypeDef.fromJson(Map<String, dynamic> json) =>
      _$ActivityTypeDefFromJson(json);
}

@freezed
abstract class ActivityFilter with _$ActivityFilter {
  const factory ActivityFilter({
    RelatedType? relatedType,
    String? relatedId,
    String? ownerId,
    ActivityState? state,
    bool? followUpsOnly,
    DateTime? dueFrom,
    DateTime? dueTo,
  }) = _ActivityFilter;
}
