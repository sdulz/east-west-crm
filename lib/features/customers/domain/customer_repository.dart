import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/customers/domain/customer.dart';

abstract interface class CustomerRepository {
  Future<Result<List<Customer>, Failure>> list({String? query});
  Future<Result<Customer, Failure>> getById(String id);

  /// `customer.id` is a client-generated UUID so retries are idempotent.
  Future<Result<Customer, Failure>> create(Customer customer);

  Future<Result<Customer, Failure>> update(
    Customer customer, {
    required DateTime expectedUpdatedAt,
  });
}
