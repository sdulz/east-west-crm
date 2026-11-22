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
    final res = await client.get<List<AppUser>>(
      ApiConstant.usersUrl,
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final list = (map['data'] as List?) ?? const [];
        return [
          for (final item in list)
            if (item is Map)
              client.parseUser(Map<String, dynamic>.from(item)),
        ]..sort((a, b) => a.name.compareTo(b.name));
      },
    );

    if (res case Ok(:final value)) {
      return Ok(value);
    }

    // Fallback to any cached users if endpoint returns an error
    final me = client.currentUser;
    if (me != null && !client.usersById.containsKey(me.id)) {
      client.usersById[me.id] = me;
    }
    if (client.usersById.isNotEmpty) {
      final cached = client.usersById.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return Ok(cached);
    }
    return res;
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
