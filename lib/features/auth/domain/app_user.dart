import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

enum UserRole { salesperson, supervisor }

/// Permission set returned by the backend. Widgets read these flags and never
/// check roles directly.
@freezed
abstract class Permissions with _$Permissions {
  const factory Permissions({
    @Default(false) bool canCreateCustomer,
    @Default(false) bool canEditCustomer,
    @Default(false) bool canCreateOpportunity,
    @Default(false) bool canEditOpportunity,
    @Default(false) bool canChangeStage,
    @Default(false) bool canReassign,
    @Default(false) bool canViewTeam,
    @Default(false) bool canLogActivity,
  }) = _Permissions;

  factory Permissions.fromJson(Map<String, dynamic> json) =>
      _$PermissionsFromJson(json);
}

@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({
    required String id,
    required String name,
    required String email,
    required UserRole role,
    required String teamId,
    required Permissions permissions,
    @Default('UTC') String timezone,
    @Default(true) bool isActive,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);
}
