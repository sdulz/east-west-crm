import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity is a hint only; the repository result is the truth.
abstract interface class ConnectivityService {
  Stream<bool> get onlineChanges;
  Future<bool> isOnline();
}

class PlusConnectivityService implements ConnectivityService {
  PlusConnectivityService([Connectivity? c]) : _c = c ?? Connectivity();
  final Connectivity _c;

  static bool _online(List<ConnectivityResult> r) =>
      r.any((x) => x != ConnectivityResult.none);

  @override
  Stream<bool> get onlineChanges =>
      _c.onConnectivityChanged.map(_online).distinct();

  @override
  Future<bool> isOnline() async => _online(await _c.checkConnectivity());
}
