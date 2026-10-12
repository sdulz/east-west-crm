import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/pipeline/domain/pipeline_stage.dart';

abstract interface class PipelineRepository {
  /// Stages ordered by [PipelineStage.sequence].
  Future<Result<List<PipelineStage>, Failure>> stages();
}
