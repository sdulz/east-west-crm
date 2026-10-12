import 'package:field_crm/app/router.dart';
import 'package:field_crm/core/widgets/async_view.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/features/customers/domain/customer.dart';
import 'package:field_crm/features/search/application/search_controller.dart';
import 'package:field_crm/features/search/domain/search_results.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FR-MOB-003.
class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final results = ref.watch(searchControllerProvider);
    final ctrl = ref.read(searchControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          key: const Key('search_field'),
          autofocus: true,
          decoration: InputDecoration(
            hintText: l.searchHint,
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
          onChanged: ctrl.setQuery,
        ),
      ),
      body: AsyncView<SearchResults>(
        value: results,
        onRetry: () => ctrl.setQuery(ctrl.query),
        isEmpty: (r) => r.isEmpty && ctrl.query.trim().isNotEmpty,
        emptyMessage: l.searchNoResults(ctrl.query),
        data: (r) => ListView(
          children: [
            if (r.customers.isNotEmpty) ...[
              _Header(l.searchCustomers),
              ...r.customers.map(_CustomerRow.new),
            ],
            if (r.contacts.isNotEmpty) ...[
              _Header(l.searchContacts),
              ...r.contacts.map(_CustomerRow.new),
            ],
            if (r.opportunities.isNotEmpty) ...[
              _Header(l.searchOpportunities),
              ...r.opportunities.map(
                (o) => ListTile(
                  leading: const Icon(Icons.work_outline),
                  title: Text(o.title),
                  onTap: () =>
                      OpportunityDetailRoute(id: o.id).push<void>(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(text, style: Theme.of(context).textTheme.labelLarge),
  );
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow(this.c);
  final Customer c;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(c.isCompany ? Icons.business : Icons.person_outline),
    title: Text(c.name),
    subtitle: Text([c.phone, c.email].whereType<String>().join(' · ')),
    onTap: () => CustomerDetailRoute(id: c.id).push<void>(context),
  );
}
