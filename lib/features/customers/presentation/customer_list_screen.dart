import 'package:field_crm/app/router.dart';
import 'package:field_crm/core/widgets/async_view.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/core/widgets/list_detail_layout.dart';
import 'package:field_crm/core/widgets/pending_badge.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/customers/application/customer_controllers.dart';
import 'package:field_crm/features/customers/domain/customer.dart';
import 'package:field_crm/features/customers/presentation/customer_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FR-MOB-004 list. Two-pane at ≥ 840dp.
class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  String _query = '';
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final list = ref.watch(customerListProvider(query: _query));
    final perms = ref.watch(permissionsProvider);
    final wide = ListDetailLayout.isWide(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.customers),
        actions: [
          IconButton(
            tooltip: l.search,
            icon: const Icon(Icons.search),
            onPressed: () => const SearchRoute().push<void>(context),
          ),
          if (perms.canCreateCustomer)
            IconButton(
              key: const Key('customer_add'),
              tooltip: l.newCustomer,
              icon: const Icon(Icons.person_add_alt),
              onPressed: () => const CustomerNewRoute().push<void>(context),
            ),
        ],
      ),
      body: ListDetailLayout(
        list: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                key: const Key('customer_filter'),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.filter_list),
                  hintText: l.name,
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.refresh(customerListProvider(query: _query).future),
                child: AsyncView<List<Customer>>(
                  value: list,
                  onRetry: () =>
                      ref.invalidate(customerListProvider(query: _query)),
                  isEmpty: (v) => v.isEmpty,
                  data: (items) => ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final c = items[i];
                      return ListTile(
                        key: Key('customer_${c.id}'),
                        selected: wide && c.id == _selectedId,
                        leading: Icon(
                          c.isCompany ? Icons.business : Icons.person_outline,
                        ),
                        title: Text(c.name),
                        subtitle: Text(
                          [c.city, c.phone].whereType<String>().join(' · '),
                        ),
                        trailing: PendingBadge(targetId: c.id),
                        onTap: () => wide
                            ? setState(() => _selectedId = c.id)
                            : CustomerDetailRoute(id: c.id).push<void>(context),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        detail: _selectedId == null
            ? null
            : CustomerDetailScreen(id: _selectedId!, embedded: true),
      ),
    );
  }
}
