/// Future push integration. Nothing calls a real push provider yet.
abstract interface class PushNotificationService {
  Future<void> initialize();
  Future<String?> deviceToken();
  Stream<Map<String, dynamic>> get messages;
}

class NoopPushNotificationService implements PushNotificationService {
  const NoopPushNotificationService();
  @override
  Future<void> initialize() async {}
  @override
  Future<String?> deviceToken() async => null;
  @override
  Stream<Map<String, dynamic>> get messages => const Stream.empty();
}
