import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/history/domain/history_entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_controller.g.dart';

/// FR-MOB-010.
@riverpod
Future<List<HistoryEntry>> history(Ref ref, RelatedType type, String id) {
  ref.watch(refreshTickProvider);
  return ref.watch(historyRepositoryProvider).forRecord(type, id).orThrow;
}
