import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:flutter/material.dart';

/// Form field that opens a searchable bottom sheet to pick one item.
class SearchPickerField<T> extends StatelessWidget {
  const SearchPickerField({
    required this.items,
    required this.labelOf,
    required this.value,
    required this.onChanged,
    required this.label,
    super.key,
    this.subtitleOf,
    this.validator,
    this.enabled = true,
  });
  final List<T> items;
  final String Function(T) labelOf;
  final String Function(T)? subtitleOf;
  final T? value;
  final ValueChanged<T>? onChanged;
  final String label;
  final FormFieldValidator<T>? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) => FormField<T>(
    initialValue: value,
    validator: validator,
    enabled: enabled,
    builder: (state) {
      final current = value ?? state.value;
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled && onChanged != null
            ? () async {
                final picked = await showSearchPicker<T>(
                  context,
                  title: label,
                  items: items,
                  labelOf: labelOf,
                  subtitleOf: subtitleOf,
                );
                if (picked != null) {
                  state.didChange(picked);
                  onChanged!(picked);
                }
              }
            : null,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            errorText: state.errorText,
            enabled: enabled,
            suffixIcon: const Icon(Icons.search),
          ),
          isEmpty: current == null,
          child: Text(
            current == null ? '' : labelOf(current),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    },
  );
}

Future<T?> showSearchPicker<T>(
  BuildContext context, {
  required String title,
  required List<T> items,
  required String Function(T) labelOf,
  String Function(T)? subtitleOf,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (ctx) => _SearchSheet<T>(
    title: title,
    items: items,
    labelOf: labelOf,
    subtitleOf: subtitleOf,
  ),
);

class _SearchSheet<T> extends StatefulWidget {
  const _SearchSheet({
    required this.title,
    required this.items,
    required this.labelOf,
    this.subtitleOf,
  });
  final String title;
  final List<T> items;
  final String Function(T) labelOf;
  final String Function(T)? subtitleOf;

  @override
  State<_SearchSheet<T>> createState() => _SearchSheetState<T>();
}

class _SearchSheetState<T> extends State<_SearchSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final q = _query.trim().toLowerCase();
    final shown = q.isEmpty
        ? widget.items
        : widget.items.where((i) {
            final text =
                '${widget.labelOf(i)} ${widget.subtitleOf?.call(i) ?? ''}'
                    .toLowerCase();
            return text.contains(q);
          }).toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              key: const Key('picker_search'),
              autofocus: true,
              decoration: InputDecoration(
                hintText: l.search,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: shown.isEmpty
                ? Center(
                    child: Text(
                      l.searchNoResults(_query),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                    itemCount: shown.length,
                    itemBuilder: (_, i) {
                      final item = shown[i];
                      final sub = widget.subtitleOf?.call(item);
                      return ListTile(
                        title: Text(widget.labelOf(item)),
                        subtitle: sub == null ? null : Text(sub),
                        onTap: () => Navigator.pop(context, item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
