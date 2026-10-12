import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/customers/domain/customer.dart';
import 'package:field_crm/features/pending/application/write_coordinator.dart';
import 'package:field_crm/features/pending/domain/pending_write.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'customer_controllers.g.dart';

/// FR-MOB-004. Kept alive: tab switches must not refetch.
@Riverpod(keepAlive: true)
Future<List<Customer>> customerList(Ref ref, {String? query}) {
  ref
    ..watch(refreshTickProvider)
    ..watch(currentUserProvider);
  return ref.watch(customerRepositoryProvider).list(query: query).orThrow;
}

@Riverpod(keepAlive: true)
Future<Customer> customerDetail(Ref ref, String id) {
  ref.watch(refreshTickProvider);
  return ref.watch(customerRepositoryProvider).getById(id).orThrow;
}

/// id -> name for quick lookups in opportunity lists and search.
@riverpod
Future<Map<String, String>> customerNames(Ref ref) async {
  final list = await ref.watch(customerListProvider().future);
  return {for (final c in list) c.id: c.name};
}

@Riverpod(keepAlive: true)
class CustomerSaver extends _$CustomerSaver {
  @override
  void build() {}

  Future<SaveOutcome<Customer>> save(
    Customer customer, {
    required bool isNew,
    DateTime? expectedUpdatedAt,
  }) async {
    final repo = ref.read(customerRepositoryProvider);
    final outcome = await ref
        .read(writeCoordinatorProvider)
        .run<Customer>(
          operation: isNew
              ? WriteOperation.customerCreate
              : WriteOperation.customerUpdate,
          targetId: customer.id,
          label: isNew ? 'New customer' : 'Customer update',
          payload: {
            'customer': customer.toJson(),
            'expectedUpdatedAt': expectedUpdatedAt?.toIso8601String(),
          },
          call: () => isNew
              ? repo.create(customer)
              : repo.update(customer, expectedUpdatedAt: expectedUpdatedAt!),
        );
    if (outcome is SaveSuccess) ref.read(refreshTickProvider.notifier).bump();
    return outcome;
  }
}
