import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/opportunities/domain/opportunity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'assignment_watcher.g.dart';

/// FR-MOB-012 in-app banner: opportunities that became mine since the last
/// load in this session. First load seeds the baseline silently.
@Riverpod(keepAlive: true)
class AssignmentWatcher extends _$AssignmentWatcher {
  Set<String>? _seen;
  String? _userId;

  @override
  List<Opportunity> build() {
    ref.listen(currentUserProvider, (_, user) {
      if (user?.id != _userId) {
        _userId = user?.id;
        _seen = null;
        state = const [];
      }
    });
    return const [];
  }

  void check(List<Opportunity> mine) {
    final ids = mine.map((o) => o.id).toSet();
    final seen = _seen;
    if (seen == null) {
      _seen = ids;
      return;
    }
    final fresh = mine.where((o) => !seen.contains(o.id)).toList();
    _seen = {...seen, ...ids};
    if (fresh.isNotEmpty) state = [...state, ...fresh];
  }

  void dismiss() => state = const [];
}
