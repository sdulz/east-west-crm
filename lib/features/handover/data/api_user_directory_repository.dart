import 'package:field_crm/common/constant/api_constant.dart';
import 'package:field_crm/core/network/crm_api_client.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/auth/domain/app_user.dart';
import 'package:field_crm/features/handover/domain/user_directory_repository.dart';

class ApiUserDirectoryRepository implements UserDirectoryRepository {
  ApiUserDirectoryRepository(this.client);

  final CrmApiClient client;

  @override
  Future<Result<List<AppUser>, Failure>> users() async {
    if (client.usersById.length <= 1) {
      await client.get<void>(
        ApiConstant.crmLeadsUrl,
        params: const {'page': 1, 'limit': 50},
        parse: (raw) {
          final map = Map<String, dynamic>.from(raw as Map);
          final list = (map['data'] as List?) ?? const [];
          for (final item in list) {
            if (item is Map) {
              client.parseLead(Map<String, dynamic>.from(item));
            }
          }
        },
      );
    }

    final me = client.currentUser;
    if (me != null && !client.usersById.containsKey(me.id)) {
      client.usersById[me.id] = me;
    }

    final result = client.usersById.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return Ok(result);
  }

  @override
  Future<Result<List<AppUser>, Failure>> assignableUsers() async {
    final me = client.currentUser;
    if (me != null && !me.permissions.canReassign) {
      return const Err(Failure.permissionDenied());
    }
    final res = await users();
    return res.map((list) => list.where((u) => u.isActive).toList());
  }
}

