import 'package:field_crm/features/auth/domain/app_user.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'session.freezed.dart';

@freezed
abstract class Session with _$Session {
  const factory Session({required String token, required AppUser user}) =
      _Session;
}
