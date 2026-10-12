import 'package:field_crm/core/mock/mock_state.dart';
import 'package:field_crm/core/mock/mock_store.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/history/domain/history_entry.dart';
import 'package:field_crm/features/history/domain/history_repository.dart';

class MockHistoryRepository implements HistoryRepository {
  MockHistoryRepository(this.store);
  final MockStore store;

  @override
  Future<Result<List<HistoryEntry>, Failure>> forRecord(
    RelatedType type,
    String id,
  ) => store.call(() {
    if (type == RelatedType.opportunity) {
      final o = store.state.opportunities.where((o) => o.id == id).firstOrNull;
      if (o != null && !store.canSeeOpportunity(o)) {
        throw const MockFailure(Failure.permissionDenied());
      }
    } else {
      store.currentUser;
    }
    final items = [...?store.state.history[MockState.historyKey(type, id)]]
      ..sort((a, b) => b.at.compareTo(a.at));
    return items;
  });
}
