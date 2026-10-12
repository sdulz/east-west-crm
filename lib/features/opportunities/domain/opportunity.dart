import 'package:freezed_annotation/freezed_annotation.dart';

part 'opportunity.freezed.dart';
part 'opportunity.g.dart';

@freezed
abstract class Opportunity with _$Opportunity {
  const factory Opportunity({
    required String id,
    required String title,
    required String customerId,
    required String stageId,
    required String ownerId,
    required String teamId,
    required DateTime updatedAt,
    @Default(0) double expectedRevenue,
    @Default(0) int probability,
    DateTime? nextActionAt,
    String? nextActionSummary,
  }) = _Opportunity;

  factory Opportunity.fromJson(Map<String, dynamic> json) =>
      _$OpportunityFromJson(json);
}
