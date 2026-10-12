import 'dart:io';

import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/core/widgets/save_feedback.dart';
import 'package:field_crm/core/widgets/section.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Name, phone and profile photo.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: ref.read(currentUserProvider)?.name,
  );
  late final _phone = TextEditingController(
    text: ref.read(currentUserProvider)?.phone,
  );
  late String? _avatarPath = ref.read(currentUserProvider)?.avatarPath;
  final _serverErrors = <String, String>{};
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final l = context.l10n;
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l.takePhoto),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l.chooseFromGallery),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            if (_avatarPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(l.removePhoto),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    if (source == 'remove') {
      setState(() => _avatarPath = null);
      return;
    }
    // ponytail: the picker's cache path is used directly; copy the file into
    // the app documents dir when the photo must survive cache clears.
    final file = await ImagePicker().pickImage(
      source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (file != null && mounted) setState(() => _avatarPath = file.path);
  }

  Future<void> _save() async {
    setState(_serverErrors.clear);
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final r = await ref
        .read(authControllerProvider.notifier)
        .updateProfile(
          name: _name.text.trim(),
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          avatarPath: _avatarPath,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    final l = context.l10n;
    switch (r) {
      case Ok():
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.profileUpdated)));
        Navigator.pop(context);
      case Err(error: ValidationFailure(:final field?, :final message)):
        setState(() => _serverErrors[field] = message);
        _form.currentState!.validate();
      case Err(:final error):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failureMessage(context, error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final initial = (_name.text.trim().isEmpty ? '?' : _name.text.trim())[0];
    return Scaffold(
      appBar: AppBar(title: Text(l.editProfile)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Stack(
                children: [
                  if (_avatarPath == null)
                    LeadingGlyph(text: initial, size: 96)
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.file(
                        File(_avatarPath!),
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
                    ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: IconButton.filled(
                      key: const Key('profile_photo'),
                      tooltip: l.changePhoto,
                      onPressed: _pickPhoto,
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              key: const Key('profile_name'),
              controller: _name,
              decoration: InputDecoration(labelText: l.name),
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  _serverErrors['name'] ??
                  ((v == null || v.trim().isEmpty) ? l.required : null),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('profile_phone'),
              controller: _phone,
              decoration: InputDecoration(labelText: l.phone),
              keyboardType: TextInputType.phone,
              validator: (v) => _serverErrors['phone'],
            ),
            const SizedBox(height: 24),
            SaveButton(
              key: const Key('profile_save'),
              saving: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
