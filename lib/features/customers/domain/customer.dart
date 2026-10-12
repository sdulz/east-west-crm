import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer.freezed.dart';
part 'customer.g.dart';

@freezed
abstract class Customer with _$Customer {
  const factory Customer({
    required String id,
    required String name,
    required DateTime updatedAt,
    @Default(false) bool isCompany,
    String? parentId,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? country,
    String? taxId,
  }) = _Customer;

  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);
}
