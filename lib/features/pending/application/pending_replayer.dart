import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/customers/domain/customer.dart';
import 'package:field_crm/features/opportunities/domain/opportunity.dart';
import 'package:field_crm/features/pending/domain/pending_write.dart';

/// Re-issues a queued write against the repositories. Payload shapes are
/// produced by the feature controllers and consumed only here.
class PendingReplayer {
  PendingReplayer(this.ref);
  final Ref ref;

  Future<Result<Object?, Failure>> replay(PendingWrite w) {
    final p = jsonDecode(w.payloadJson) as Map<String, dynamic>;
    DateTime expected() => DateTime.parse(p['expectedUpdatedAt'] as String);
    final customers = ref.read(customerRepositoryProvider);
    final opps = ref.read(opportunityRepositoryProvider);
    final acts = ref.read(activityRepositoryProvider);
    return switch (w.operation) {
      WriteOperation.customerCreate => customers.create(
        Customer.fromJson(p['customer'] as Map<String, dynamic>),
      ),
      WriteOperation.customerUpdate => customers.update(
        Customer.fromJson(p['customer'] as Map<String, dynamic>),
        expectedUpdatedAt: expected(),
      ),
      WriteOperation.opportunityCreate => opps.create(
        Opportunity.fromJson(p['opportunity'] as Map<String, dynamic>),
      ),
      WriteOperation.opportunityUpdate => opps.update(
        Opportunity.fromJson(p['opportunity'] as Map<String, dynamic>),
        expectedUpdatedAt: expected(),
      ),
      WriteOperation.opportunityStageChange => opps.changeStage(
        w.targetId,
        toStageId: p['toStageId'] as String,
        expectedUpdatedAt: expected(),
      ),
      WriteOperation.opportunityReassign => opps.reassign(
        w.targetId,
        newOwnerId: p['newOwnerId'] as String,
        expectedUpdatedAt: expected(),
      ),
      WriteOperation.activityCreate => acts.create(
        Activity.fromJson(p['activity'] as Map<String, dynamic>),
      ),
      WriteOperation.activityComplete => acts.complete(
        w.targetId,
        outcome: p['outcome'] as String,
        expectedUpdatedAt: expected(),
      ),
      WriteOperation.activityReschedule => acts.reschedule(
        w.targetId,
        dueAt: DateTime.parse(p['dueAt'] as String),
        expectedUpdatedAt: expected(),
      ),
    };
  }
}

final pendingReplayerProvider =
    Provider<PendingReplayer>((ref) => PendingReplayer(ref));
