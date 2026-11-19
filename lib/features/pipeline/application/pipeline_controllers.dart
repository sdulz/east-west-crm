import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/pipeline/domain/pipeline_stage.dart';

final stagesProvider = FutureProvider<List<PipelineStage>>((ref) =>
    ref.watch(pipelineRepositoryProvider).stages().orThrow);

final stagesByIdProvider = FutureProvider<Map<String, PipelineStage>>((ref) async {
  final list = await ref.watch(stagesProvider.future);
  return {for (final s in list) s.id: s};
});
