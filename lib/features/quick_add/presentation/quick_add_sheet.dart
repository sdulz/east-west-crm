import 'package:field_crm/app/router.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FR-MOB-011. Pre-filled when launched from a record.
Future<void> showQuickAdd(
  BuildContext context, {
  RelatedType? relatedType,
  String? relatedId,
  String? customerId,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (_) => QuickAddSheet(
    relatedType: relatedType,
    relatedId: relatedId,
    customerId: customerId,
  ),
);

class QuickAddSheet extends ConsumerWidget {
  const QuickAddSheet({
    super.key,
    this.relatedType,
    this.relatedId,
    this.customerId,
  });
  final RelatedType? relatedType;
  final String? relatedId;
  final String? customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final p = ref.watch(permissionsProvider);
    void go(void Function() nav) {
      Navigator.pop(context);
      nav();
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              l.quickAdd,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (p.canCreateCustomer)
            ListTile(
              key: const Key('quick_customer'),
              leading: const Icon(Icons.person_add_alt),
              title: Text(l.newCustomer),
              onTap: () =>
                  go(() => const CustomerNewRoute().push<void>(context)),
            ),
          if (p.canCreateOpportunity)
            ListTile(
              key: const Key('quick_opportunity'),
              leading: const Icon(Icons.add_business_outlined),
              title: Text(l.newOpportunity),
              onTap: () => go(
                () => OpportunityNewRoute(
                  customerId:
                      customerId ??
                      (relatedType == RelatedType.customer ? relatedId : null),
                ).push<void>(context),
              ),
            ),
          if (p.canLogActivity) ...[
            ListTile(
              key: const Key('quick_interaction'),
              leading: const Icon(Icons.call_outlined),
              title: Text(l.logInteraction),
              onTap: () => go(
                () => ActivityFormRoute(
                  type: ActivityType.call.name,
                  relatedType: relatedType?.name,
                  relatedId: relatedId,
                ).push<void>(context),
              ),
            ),
            ListTile(
              key: const Key('quick_followup'),
              leading: const Icon(Icons.alarm_add_outlined),
              title: Text(l.newFollowUp),
              onTap: () => go(
                () => ActivityFormRoute(
                  type: ActivityType.todo.name,
                  relatedType: relatedType?.name,
                  relatedId: relatedId,
                ).push<void>(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
