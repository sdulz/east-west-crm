import 'package:freezed_annotation/freezed_annotation.dart';

part 'history_entry.freezed.dart';
part 'history_entry.g.dart';

enum HistoryKind { activity, note, stageChange, ownerChange }

@freezed
abstract class HistoryEntry with _$HistoryEntry {
  const factory HistoryEntry({
    required String id,
    required HistoryKind kind,
    required DateTime at,
    required String actorName,
    String? from,
    String? to,
    String? text,
  }) = _HistoryEntry;

  factory HistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$HistoryEntryFromJson(json);
}
