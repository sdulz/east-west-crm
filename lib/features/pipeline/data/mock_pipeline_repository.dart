import 'package:field_crm/core/mock/mock_store.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/pipeline/domain/pipeline_repository.dart';
import 'package:field_crm/features/pipeline/domain/pipeline_stage.dart';

class MockPipelineRepository implements PipelineRepository {
  MockPipelineRepository(this.store);
  final MockStore store;

  @override
  Future<Result<List<PipelineStage>, Failure>> stages() => store.call(
    () =>
        [...store.state.stages]
          ..sort((a, b) => a.sequence.compareTo(b.sequence)),
  );
}
