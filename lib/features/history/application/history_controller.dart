import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/history/domain/history_entry.dart';

class HistoryParams {
  final RelatedType type;
  final String id;
  const HistoryParams(this.type, this.id);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryParams && type == other.type && id == other.id;

  @override
  int get hashCode => Object.hash(type, id);
}

final _historyFamily =
    FutureProvider.family<List<HistoryEntry>, HistoryParams>((ref, params) {
  ref.watch(refreshTickProvider);
  return ref
      .watch(historyRepositoryProvider)
      .forRecord(params.type, params.id)
      .orThrow;
});

FutureProvider<List<HistoryEntry>> historyProvider(
        RelatedType type, String id) =>
    _historyFamily(HistoryParams(type, id));
