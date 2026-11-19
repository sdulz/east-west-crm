import 'dart:io';

import 'package:field_crm/core/format/app_formatters.dart';
import 'package:field_crm/core/network/crm_api_client.dart';
import 'package:field_crm/core/uuid.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/core/widgets/save_feedback.dart';
import 'package:field_crm/core/widgets/section.dart';
import 'package:field_crm/features/activities/application/activity_controllers.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/handover/application/user_directory_controllers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Internal notes on a record: a compose box plus the notes, newest first.
/// Notes are activities of type `note`, so they sync and queue like any write.
class NotesPanel extends ConsumerStatefulWidget {
  const NotesPanel({
    required this.relatedType,
    required this.relatedId,
    super.key,
  });
  final RelatedType relatedType;
  final String relatedId;

  @override
  ConsumerState<NotesPanel> createState() => _NotesPanelState();
}

/// `@Name` tokens for known users rendered in the primary colour.
/// ponytail: mentions are plain text; add mentionedUserIds + a notification
/// when the tagged person must be alerted.
List<InlineSpan> mentionSpans(
  String text,
  Iterable<String> names,
  TextStyle style,
) {
  final sorted = names.toList()..sort((a, b) => b.length.compareTo(a.length));
  final spans = <InlineSpan>[];
  var i = 0;
  while (i < text.length) {
    final at = text.indexOf('@', i);
    if (at < 0) break;
    final hit = sorted.where((n) => text.startsWith(n, at + 1)).firstOrNull;
    if (hit == null) {
      spans.add(TextSpan(text: text.substring(i, at + 1)));
      i = at + 1;
      continue;
    }
    if (at > i) spans.add(TextSpan(text: text.substring(i, at)));
    spans.add(TextSpan(text: '@$hit', style: style));
    i = at + 1 + hit.length;
  }
  if (i < text.length) spans.add(TextSpan(text: text.substring(i)));
  return spans;
}

class _NotesPanelState extends ConsumerState<NotesPanel> {
  final _text = TextEditingController();
  bool _saving = false;

  /// Files picked for the note being written.
  final _pending = <String>[];

  // ponytail: picker cache paths are stored as-is; copy into app storage when
  // attachments must survive cache clears.
  Future<void> _attach() async {
    final result = await FilePicker.pickFiles(withData: true);
    if (result == null) return;
    final paths = <String>[];
    for (final f in result.files) {
      // content:// results carry no path; keep a local copy instead.
      final path = f.path ?? await _copyLocal(f);
      if (path != null) paths.add(path);
    }
    if (paths.isNotEmpty && mounted) setState(() => _pending.addAll(paths));
  }

  /// Text after the `@` being typed, or null when not mentioning.
  String? _mentionQuery;

  static final _mentionStart = RegExp(r'(^|\s)@([^\s@]*)$');

  void _onChanged(String v) {
    final cursor = _text.selection.baseOffset;
    final head = cursor < 0 ? v : v.substring(0, cursor);
    setState(() => _mentionQuery = _mentionStart.firstMatch(head)?.group(2));
  }

  /// Replaces the `@query` being typed with `@Name `.
  void _insertMention(String name) {
    final cursor = _text.selection.baseOffset;
    final v = _text.text;
    final head = cursor < 0 ? v : v.substring(0, cursor);
    final tail = cursor < 0 ? '' : v.substring(cursor);
    final m = _mentionStart.firstMatch(head)!;
    final next = '${head.substring(0, m.start)}${m.group(1)}@$name $tail';
    _text.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length - tail.length),
    );
    setState(() => _mentionQuery = null);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final body = _text.text.trim();
    final me = ref.read(currentUserProvider);
    if ((body.isEmpty && _pending.isEmpty) || me == null) return;
    setState(() => _saving = true);
    final now = DateTime.now().toUtc();
    final out = await ref
        .read(activitySaverProvider.notifier)
        .create(
          Activity(
            id: uuidV4(),
            type: ActivityType.note,
            relatedType: widget.relatedType,
            relatedId: widget.relatedId,
            summary: body.isEmpty ? l10nAttachmentsLabel(context) : body,
            attachments: List.of(_pending),
            ownerId: me.id,
            dueAt: now,
            updatedAt: now,
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    final ok = await showSaveOutcome(
      context,
      out,
      successMessage: context.l10n.noteAdded,
    );
    if (ok && mounted) {
      _text.clear();
      setState(_pending.clear);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = ref.watch(formattersProvider);
    final theme = Theme.of(context);
    final users = ref.watch(userNamesProvider).valueOrNull ?? const {};
    final q = _mentionQuery?.toLowerCase();
    final suggestions = q == null
        ? const <String>[]
        : users.values
              .where((n) => n.toLowerCase().contains(q))
              .take(5)
              .toList();
    final canWrite = ref.watch(permissionsProvider).canLogActivity;
    final filter = ActivityFilter(
      relatedType: widget.relatedType,
      relatedId: widget.relatedId,
    );
    final notes = (ref.watch(activityListProvider(filter)).valueOrNull ?? const [])
        .where((a) => a.type == ActivityType.note)
        .toList()
        .reversed
        .toList();
    return Panel(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canWrite)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('note_input'),
                    controller: _text,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: l.addNote,
                      helperText: l.noteHint,
                      isDense: true,
                    ),
                    onChanged: _onChanged,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: IconButton(
                    key: const Key('note_attach'),
                    tooltip: l.attachFile,
                    onPressed: _saving ? null : _attach,
                    icon: const Icon(Icons.attach_file),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: IconButton.filled(
                    key: const Key('note_send'),
                    tooltip: l.addNote,
                    onPressed: _saving ? null : _post,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                  ),
                ),
              ],
            ),
          if (_pending.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final path in _pending)
                    InputChip(
                      avatar: Icon(_iconFor(path), size: 18),
                      label: Text(_name(path)),
                      onDeleted: () => setState(() => _pending.remove(path)),
                    ),
                ],
              ),
            ),
          if (suggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final n in suggestions)
                    ActionChip(
                      key: Key('mention_$n'),
                      avatar: LeadingGlyph(text: n[0], size: 22),
                      label: Text(n),
                      onPressed: () => _insertMention(n),
                    ),
                ],
              ),
            ),
          if (notes.isEmpty && !canWrite)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                l.emptyList,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final n in notes)
            Padding(
              key: Key('note_${n.id}'),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LeadingGlyph(
                    text: (users[n.ownerId] ?? '?')[0],
                    size: 32,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: mentionSpans(
                              n.summary,
                              users.values,
                              TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${users[n.ownerId] ?? n.ownerId} · '
                          '${f.dateTime(n.dueAt ?? n.updatedAt)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (n.attachments.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final path in n.attachments)
                                  _Attachment(path: path),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

Future<String?> _copyLocal(PlatformFile f) async {
  try {
    final bytes =
        f.bytes ?? (f.path != null ? await File(f.path!).readAsBytes() : null);
    if (bytes == null) return null;
    final dir = await Directory('${Directory.systemTemp.path}/attachments')
        .create(recursive: true);
    final out = File(
      '${dir.path}/${DateTime.now().microsecondsSinceEpoch}_${f.name}',
    );
    await out.writeAsBytes(bytes);
    return out.path;
  } on Object {
    return null;
  }
}

String _name(String path) => path.split(Platform.pathSeparator).last;

bool _isImage(String path) {
  final ext = path.split('.').last.toLowerCase();
  return const {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'}.contains(ext);
}

IconData _iconFor(String path) => _isImage(path)
    ? Icons.image_outlined
    : switch (path.split('.').last.toLowerCase()) {
        'pdf' => Icons.picture_as_pdf_outlined,
        'xls' || 'xlsx' || 'csv' => Icons.table_chart_outlined,
        'doc' || 'docx' => Icons.description_outlined,
        _ => Icons.insert_drive_file_outlined,
      };

String l10nAttachmentsLabel(BuildContext context) => context.l10n.attachments;

/// Image thumbnails open a viewer; other files are listed by name.
/// ponytail: add open_filex when non-image files must open in another app.
class _Attachment extends StatelessWidget {
  const _Attachment({required this.path});
  final String path;

  bool get _isNetwork =>
      path.startsWith('http://') || path.startsWith('https://');

  Map<String, String>? get _authHeaders {
    final token = CrmApiClient.activeToken;
    if (token != null && token.isNotEmpty) {
      return {'Authorization': 'Bearer $token'};
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isImg = _isImage(path) || path.contains('/api/v1/attachments/');
    if (!isImg) {
      return Chip(
        avatar: Icon(_iconFor(path), size: 18),
        label: Text(_name(path), overflow: TextOverflow.ellipsis),
      );
    }
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _isNetwork
                  ? Image.network(
                      path,
                      headers: _authHeaders,
                      fit: BoxFit.contain,
                    )
                  : Image.file(File(path), fit: BoxFit.contain),
            ),
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _isNetwork
            ? Image.network(
                path,
                headers: _authHeaders,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Chip(
                  avatar: const Icon(Icons.insert_drive_file_outlined, size: 18),
                  label: Text(_name(path), overflow: TextOverflow.ellipsis),
                ),
              )
            : Image.file(
                File(path),
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 72,
                  height: 72,
                  color: theme.colorScheme.surfaceContainerHigh,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
      ),
    );
  }
}
