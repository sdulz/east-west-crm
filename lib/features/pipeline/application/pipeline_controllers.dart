import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/pipeline/domain/pipeline_stage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pipeline_controllers.g.dart';

@Riverpod(keepAlive: true)
Future<List<PipelineStage>> stages(Ref ref) =>
    ref.watch(pipelineRepositoryProvider).stages().orThrow;

@riverpod
Future<Map<String, PipelineStage>> stagesById(Ref ref) async {
  final list = await ref.watch(stagesProvider.future);
  return {for (final s in list) s.id: s};
}
