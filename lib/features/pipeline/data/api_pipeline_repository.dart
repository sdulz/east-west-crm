import 'package:field_crm/common/constant/api_constant.dart';
import 'package:field_crm/core/network/crm_api_client.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/pipeline/domain/pipeline_repository.dart';
import 'package:field_crm/features/pipeline/domain/pipeline_stage.dart';

class ApiPipelineRepository implements PipelineRepository {
  ApiPipelineRepository(this.client);

  final CrmApiClient client;

  @override
  Future<Result<List<PipelineStage>, Failure>> stages() {
    return client.get<List<PipelineStage>>(
      ApiConstant.crmStagesUrl,
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final list = (map['data'] as List?) ?? const [];
        final parsed = [
          for (final item in list)
            if (item is Map)
              client.parseStage(Map<String, dynamic>.from(item)),
        ]..sort((a, b) => a.sequence.compareTo(b.sequence));

        final allIds = [for (final s in parsed) s.id];
        return [
          for (final s in parsed)
            s.copyWith(
              allowedNextStageIds: [
                for (final id in allIds)
                  if (id != s.id) id,
              ],
            ),
        ];
      },
    );
  }
}

