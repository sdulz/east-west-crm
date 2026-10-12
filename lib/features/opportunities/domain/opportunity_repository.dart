import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/opportunities/domain/opportunity.dart';

abstract interface class OpportunityRepository {
  /// Opportunities visible to the current user (own, or team when permitted).
  Future<Result<List<Opportunity>, Failure>> list({String? customerId});
  Future<Result<Opportunity, Failure>> getById(String id);
  Future<Result<Opportunity, Failure>> create(Opportunity opportunity);
  Future<Result<Opportunity, Failure>> update(
    Opportunity opportunity, {
    required DateTime expectedUpdatedAt,
  });
  Future<Result<Opportunity, Failure>> changeStage(
    String id, {
    required String toStageId,
    required DateTime expectedUpdatedAt,
  });
  Future<Result<Opportunity, Failure>> reassign(
    String id, {
    required String newOwnerId,
    required DateTime expectedUpdatedAt,
  });
}
