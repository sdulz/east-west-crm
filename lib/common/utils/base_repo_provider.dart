import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_crm/common/controller/local_storage_provider.dart';
import 'package:field_crm/common/utils/base_repository/base_repository.dart';
import 'package:field_crm/common/utils/base_repository/base_repository_setup.dart';
import 'package:field_crm/common/utils/base_repository/repository_details.dart';
import 'package:field_crm/core/network/crm_api_client.dart';

final openBaseRepoProvider = Provider<BaseRepository>((ref) {
  _initBaseRepoSetupOnce(ref);

  return BaseRepository(
    ref: ref,
    repositoryDetails: RepositoryDetails.noToken(),
  );
});

final tokenBaseRepoProvider = Provider<BaseRepository>((ref) {
  _initBaseRepoSetupOnce(ref);

  return BaseRepository(
    ref: ref,
    repositoryDetails: RepositoryDetails(),
  );
});

bool _setupDone = false;
void _initBaseRepoSetupOnce(Ref ref) {
  if (_setupDone) return;
  _setupDone = true;

  BaseRepositorySetup.init(
    errorWithMobileOnApiRequest: () =>
        'Something went wrong. Please check your connection.',
    errorWithApiOnApiRequest: () => 'Server error. Please try again later.',
    tokenMapper: () {
      final active = CrmApiClient.activeToken;
      if (active != null && active.isNotEmpty) return active;
      try {
        final login = ref.read(authStorageProvider).loginData;
        return login?.token ?? '';
      } on Object {
        return '';
      }
    },
    companyIdMapper: () => null,
    onErrorHandleTokenExpiry: (err) {},
    onResponseInterceptor: (response) {},
    onErrorMapper: (data) {
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return null;
    },
    onParsingException: (e, s) {},
    extraHeader: const {},
  );
}
