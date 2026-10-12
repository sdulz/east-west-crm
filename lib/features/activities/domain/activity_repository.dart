import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/activities/domain/activity.dart';

abstract interface class ActivityRepository {
  Future<Result<List<ActivityTypeDef>, Failure>> types();
  Future<Result<List<Activity>, Failure>> list([ActivityFilter? filter]);
  Future<Result<Activity, Failure>> getById(String id);
  Future<Result<Activity, Failure>> create(Activity activity);
  Future<Result<Activity, Failure>> complete(
    String id, {
    required String outcome,
    required DateTime expectedUpdatedAt,
  });
  Future<Result<Activity, Failure>> reschedule(
    String id, {
    required DateTime dueAt,
    required DateTime expectedUpdatedAt,
  });
}
