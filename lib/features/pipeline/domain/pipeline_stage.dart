import 'package:freezed_annotation/freezed_annotation.dart';

part 'pipeline_stage.freezed.dart';
part 'pipeline_stage.g.dart';

@freezed
abstract class PipelineStage with _$PipelineStage {
  const factory PipelineStage({
    required String id,
    required String name,
    required int sequence,
    @Default(false) bool isWon,
    @Default(false) bool isFolded,
    @Default(<String>[]) List<String> allowedNextStageIds,
  }) = _PipelineStage;

  factory PipelineStage.fromJson(Map<String, dynamic> json) =>
      _$PipelineStageFromJson(json);
}

extension PipelineStageX on PipelineStage {
  bool canMoveTo(String stageId) =>
      stageId == id || allowedNextStageIds.contains(stageId);
}
