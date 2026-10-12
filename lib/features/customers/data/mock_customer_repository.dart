import 'package:field_crm/core/mock/mock_store.dart';
import 'package:field_crm/core/mock/mock_validation.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/customers/domain/customer.dart';
import 'package:field_crm/features/customers/domain/customer_repository.dart';

class MockCustomerRepository implements CustomerRepository {
  MockCustomerRepository(this.store);
  final MockStore store;

  List<Customer> get _all => store.state.customers;

  @override
  Future<Result<List<Customer>, Failure>> list({String? query}) =>
      store.call(() {
        store.currentUser; // throws permissionDenied when logged out
        final q = query?.trim().toLowerCase();
        final items = q == null || q.isEmpty
            ? _all
            : _all.where((c) => c.name.toLowerCase().contains(q));
        return items.toList()..sort((a, b) => a.name.compareTo(b.name));
      });

  @override
  Future<Result<Customer, Failure>> getById(String id) => store.call(() {
    store.currentUser;
    final c = _all.where((c) => c.id == id).firstOrNull;
    if (c == null) throw const MockFailure(Failure.unknown('Not found'));
    return c;
  });

  @override
  Future<Result<Customer, Failure>> create(Customer customer) => store.call(() {
    if (!store.currentUser.permissions.canCreateCustomer) {
      throw const MockFailure(Failure.permissionDenied());
    }
    // Idempotent: a retried create with the same client UUID is a no-op.
    final existing = _all.where((c) => c.id == customer.id).firstOrNull;
    if (existing != null) return existing;
    _validate(customer);
    final saved = customer.copyWith(updatedAt: store.clock.now());
    _all.add(saved);
    return saved;
  }, write: true);

  @override
  Future<Result<Customer, Failure>> update(
    Customer customer, {
    required DateTime expectedUpdatedAt,
  }) => store.call(() {
    if (!store.currentUser.permissions.canEditCustomer) {
      throw const MockFailure(Failure.permissionDenied());
    }
    final idx = _all.indexWhere((c) => c.id == customer.id);
    if (idx < 0) throw const MockFailure(Failure.unknown('Not found'));
    MockValidation.conflict(_all[idx].updatedAt, expectedUpdatedAt);
    _validate(customer);
    final saved = customer.copyWith(updatedAt: store.clock.now());
    _all[idx] = saved;
    return saved;
  }, write: true);

  void _validate(Customer c) {
    MockValidation.required(c.name, 'name', 'Name');
    MockValidation.email(c.email);
    MockValidation.phone(c.phone);
    if (c.parentId != null && !_all.any((p) => p.id == c.parentId)) {
      throw const MockFailure(
        Failure.validation('Parent company does not exist', field: 'parentId'),
      );
    }
  }
}
