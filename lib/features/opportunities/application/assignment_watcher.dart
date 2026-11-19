import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/opportunities/domain/opportunity.dart';

class AssignmentWatcherNotifier extends StateNotifier<List<Opportunity>> {
  AssignmentWatcherNotifier(this.ref) : super(const []) {
    ref.listen(currentUserProvider, (_, user) {
      if (user?.id != _userId) {
        _userId = user?.id;
        _seen = null;
        state = const [];
      }
    });
  }

  final Ref ref;
  Set<String>? _seen;
  String? _userId;

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

final assignmentWatcherProvider =
    StateNotifierProvider<AssignmentWatcherNotifier, List<Opportunity>>(
  (ref) => AssignmentWatcherNotifier(ref),
);
