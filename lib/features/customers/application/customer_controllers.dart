import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/customers/domain/customer.dart';
import 'package:field_crm/features/pending/application/write_coordinator.dart';
import 'package:field_crm/features/pending/domain/pending_write.dart';

final _customerListFamily =
    FutureProvider.family<List<Customer>, String?>((ref, query) {
  ref
    ..watch(refreshTickProvider)
    ..watch(currentUserProvider);
  return ref.watch(customerRepositoryProvider).list(query: query).orThrow;
});

FutureProvider<List<Customer>> customerListProvider({String? query}) {
  final q = (query == null || query.trim().isEmpty) ? null : query.trim();
  return _customerListFamily(q);
}

final customerDetailProvider =
    FutureProvider.family<Customer, String>((ref, id) {
  ref.watch(refreshTickProvider);
  return ref.watch(customerRepositoryProvider).getById(id).orThrow;
});

final customerNamesProvider = FutureProvider<Map<String, String>>((ref) async {
  final list = await ref.watch(customerListProvider().future);
  return {for (final c in list) c.id: c.name};
});

class CustomerSaver extends Notifier<void> {
  @override
  void build() {}

  Future<SaveOutcome<Customer>> save(
    Customer customer, {
    required bool isNew,
    DateTime? expectedUpdatedAt,
  }) async {
    final repo = ref.read(customerRepositoryProvider);
    final outcome = await ref.read(writeCoordinatorProvider).run<Customer>(
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

final customerSaverProvider =
    NotifierProvider<CustomerSaver, void>(CustomerSaver.new);
