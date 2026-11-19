import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/team/domain/team.dart';

final teamOverviewProvider = FutureProvider<TeamOverview>((ref) {
  ref
    ..watch(refreshTickProvider)
    ..watch(currentUserProvider);
  return ref.watch(teamRepositoryProvider).overview().orThrow;
});
