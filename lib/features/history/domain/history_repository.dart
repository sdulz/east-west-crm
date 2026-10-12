import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/history/domain/history_entry.dart';

abstract interface class HistoryRepository {
  /// Newest first.
  Future<Result<List<HistoryEntry>, Failure>> forRecord(
    RelatedType type,
    String id,
  );
}
