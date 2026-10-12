import 'package:freezed_annotation/freezed_annotation.dart';

part 'pending_write.freezed.dart';
part 'pending_write.g.dart';

enum PendingStatus { pending, failed }

/// The write operations that can be replayed. The payload is the JSON of the
/// entity (or the change) so a retry needs no UI state.
enum WriteOperation {
  customerCreate,
  customerUpdate,
  opportunityCreate,
  opportunityUpdate,
  opportunityStageChange,
  opportunityReassign,
  activityCreate,
  activityComplete,
  activityReschedule,
}

@freezed
abstract class PendingWrite with _$PendingWrite {
  const factory PendingWrite({
    required String id,
    required WriteOperation operation,
    required String payloadJson,
    required String targetId,
    required DateTime createdAt,
    @Default(PendingStatus.pending) PendingStatus status,
    @Default(0) int attempts,
    String? lastError,

    /// Human-readable label for the pending centre (no sensitive data).
    @Default('') String label,
  }) = _PendingWrite;

  factory PendingWrite.fromJson(Map<String, dynamic> json) =>
      _$PendingWriteFromJson(json);
}
