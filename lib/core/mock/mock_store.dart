import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:field_crm/core/clock.dart';
import 'package:field_crm/core/mock/mock_state.dart';
import 'package:field_crm/core/mock/mock_state_store.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/auth/domain/app_user.dart';
import 'package:field_crm/features/opportunities/domain/opportunity.dart';
import 'package:flutter/foundation.dart';

/// Thrown inside a mock call body to produce an [Err] without boilerplate.
class MockFailure implements Exception {
  const MockFailure(this.failure);
  final Failure failure;
}

/// The fake backend shared by every Mock*Repository: state, latency, failure
/// injection, scope rules and persistence. Nothing in presentation/ or
/// application/ may import this.
class MockStore extends ChangeNotifier {
  MockStore({
    required MockState initial,
    required this.clock,
    required this.stateStore,
    required this.reseed,
    this.minLatency = const Duration(milliseconds: 200),
    this.maxLatency = const Duration(milliseconds: 1200),
    Random? random,
  }) : _state = initial,
       _random = random ?? Random();

  final Clock clock;
  final MockStateStore stateStore;
  final Duration minLatency;
  final Duration maxLatency;
  final Random _random;
  final MockState Function() reseed;
  MockState _state;

  MockState get state => _state;

  // ---- dev-menu knobs -----------------------------------------------------
  bool _airplaneMode = false;
  Failure? _forceNextFailure;

  bool get airplaneMode => _airplaneMode;
  set airplaneMode(bool v) {
    _airplaneMode = v;
    notifyListeners();
  }

  Failure? get forceNextFailure => _forceNextFailure;
  set forceNextFailure(Failure? f) {
    _forceNextFailure = f;
    notifyListeners();
  }

  // ---- current user -------------------------------------------------------
  String? _currentUserId;

  AppUser? get currentUserOrNull => _currentUserId == null
      ? null
      : _state.users.where((u) => u.id == _currentUserId).firstOrNull;

  AppUser get currentUser {
    final u = currentUserOrNull;
    if (u == null) throw const MockFailure(Failure.permissionDenied());
    return u;
  }

  void setCurrentUser(String? id) {
    _currentUserId = id;
    notifyListeners();
  }

  // ---- scope rules --------------------------------------------------------
  bool canSeeOpportunity(Opportunity o) {
    final me = currentUser;
    if (me.permissions.canViewTeam) return o.teamId == me.teamId;
    return o.ownerId == me.id;
  }

  bool canSeeActivity(Activity a) {
    final me = currentUser;
    if (me.permissions.canViewTeam) {
      final owner = _state.users.where((u) => u.id == a.ownerId).firstOrNull;
      return owner?.teamId == me.teamId;
    }
    return a.ownerId == me.id;
  }

  Iterable<Opportunity> visibleOpportunities() =>
      _state.opportunities.where(canSeeOpportunity);

  Iterable<Activity> visibleActivities() =>
      _state.activities.where(canSeeActivity);

  // ---- call wrapper -------------------------------------------------------
  /// Runs [body] with simulated latency and failure injection.
  Future<Result<T, Failure>> call<T>(
    FutureOr<T> Function() body, {
    bool write = false,
  }) async {
    await Future<void>.delayed(_latency());
    if (_airplaneMode) return const Err(Failure.network());
    final forced = _forceNextFailure;
    if (forced != null) {
      _forceNextFailure = null;
      notifyListeners();
      return Err(forced);
    }
    try {
      final value = await body();
      if (write) await _persist();
      return Ok(value);
    } on MockFailure catch (e) {
      return Err(e.failure);
    }
  }

  Duration _latency() {
    final span = maxLatency.inMilliseconds - minLatency.inMilliseconds;
    if (span <= 0) return minLatency;
    return minLatency + Duration(milliseconds: _random.nextInt(span));
  }

  Future<void> _persist() => stateStore.save(jsonEncode(_state.toJson()));

  /// Dev menu: drop every change and reload the seed.
  Future<void> resetSeed() async {
    _state = reseed();
    await stateStore.clear();
    notifyListeners();
  }

  /// Replace the state (used by tests and by the dev menu).
  void replaceState(MockState s) {
    _state = s;
    notifyListeners();
  }

  /// Test/dev helper: mutate server state "behind the client's back".
  void replaceStateStage(String opportunityId, String stageId) {
    final i = state.opportunities.indexWhere((o) => o.id == opportunityId);
    state.opportunities[i] = state.opportunities[i].copyWith(stageId: stageId);
    notifyListeners();
  }
}
