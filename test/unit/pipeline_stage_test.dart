import 'package:field_crm/features/pipeline/domain/pipeline_stage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('canMoveTo honours allowedNextStageIds and self', () {
    const s = PipelineStage(
      id: 'a',
      name: 'A',
      sequence: 1,
      allowedNextStageIds: ['b'],
    );
    expect(s.canMoveTo('b'), isTrue);
    expect(s.canMoveTo('a'), isTrue);
    expect(s.canMoveTo('c'), isFalse);
  });
}
