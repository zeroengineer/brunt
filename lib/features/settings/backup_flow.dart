import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../core/dates.dart';
import '../../data/repositories/backup_repo.dart';
import '../../design/design.dart';
import '../../security/backup_crypto.dart';
import '../../security/lock_controller.dart';
import '../../security/reauth.dart';

Future<String?> _askPassword(BuildContext context, {required bool confirm}) async {
  final a = TextEditingController();
  final b = TextEditingController();
  final ok = await showBruntSheet<bool>(
    context,
    builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(confirm ? 'Backup password' : 'Backup password', style: BText.h2),
      const SizedBox(height: 6),
      Text(
        confirm
            ? 'The file is encrypted with this password (AES-256). Without it the backup cannot be opened — not even by us.'
            : 'Enter the password used when this backup was made.',
        style: BText.bodyMuted,
      ),
      const SizedBox(height: 18),
      BField(label: 'Password', controller: a, obscure: true, autofocus: true),
      if (confirm) ...[const SizedBox(height: 12), BField(label: 'Repeat password', controller: b, obscure: true)],
      const SizedBox(height: 20),
      PillButton(label: 'Continue', expand: true, onPressed: () => Navigator.pop(ctx, true)),
    ]),
  );
  final pw = a.text;
  final pw2 = b.text;
  a.dispose();
  b.dispose();
  if (ok != true) return null;
  if (!context.mounted) return null;
  if (confirm && pw.length < 8) {
    toast(context, 'Use at least 8 characters', error: true);
    return null;
  }
  if (confirm && pw != pw2) {
    toast(context, "Passwords don't match", error: true);
    return null;
  }
  return pw;
}

Future<void> exportBackup(BuildContext context, WidgetRef ref) async {
  final s = ref.read(sessionProvider);
  if (s == null) return;
  if (!await reauthenticate(context, ref, reason: 'Confirm to export an encrypted backup')) return;
  if (!context.mounted) return;
  final pw = await _askPassword(context, confirm: true);
  if (pw == null || !context.mounted) return;
  final mode = await showBruntSheet<String>(
    context,
    builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Save backup', style: BText.h2),
      const SizedBox(height: 16),
      PillButton(label: 'Save to a folder', expand: true, onPressed: () => Navigator.pop(ctx, 'save')),
      const SizedBox(height: 10),
      PillButton(label: 'Share…', variant: PillVariant.outline, expand: true, onPressed: () => Navigator.pop(ctx, 'share')),
    ]),
  );
  if (mode == null || !context.mounted) return;
  toast(context, 'Encrypting…');
  final lock = ref.read(lockProvider.notifier);
  try {
    final bytes = await BackupCrypto.encrypt(await BackupRepo(s.db).export(), pw);
    final name = 'brunt-backup-${Dates.iso(DateTime.now())}.brunt';
    if (mode == 'save') {
      final uri = await lock.suppressWhile(() => FilePicker.saveFile(fileName: name, bytes: bytes));
      if (context.mounted && uri != null) toast(context, 'Backup saved');
    } else {
      final dir = await getTemporaryDirectory();
      final f = File(p.join(dir.path, name));
      await f.writeAsBytes(bytes, flush: true);
      await lock.suppressWhile(() => SharePlus.instance.share(ShareParams(files: [XFile(f.path, mimeType: 'application/octet-stream')])));
      if (f.existsSync()) await f.delete();
    }
  } catch (e) {
    if (context.mounted) toast(context, 'Export failed: $e', error: true);
  }
}

Future<void> restoreBackup(BuildContext context, WidgetRef ref) async {
  final s = ref.read(sessionProvider);
  if (s == null) return;
  if (!await reauthenticate(context, ref, reason: 'Confirm to restore a backup')) return;
  final lock = ref.read(lockProvider.notifier);
  final picked = await lock.suppressWhile(() => FilePicker.pickFile(type: FileType.any));
  if (picked == null || !context.mounted) return;
  final Uint8List bytes = await picked.readAsBytes();
  if (!context.mounted) return;
  final pw = await _askPassword(context, confirm: false);
  if (pw == null || !context.mounted) return;
  try {
    toast(context, 'Decrypting…');
    final data = await BackupCrypto.decrypt(bytes, pw);
    if (!context.mounted) return;
    final when = data['exportedAt'] as String? ?? '';
    final ok = await confirmDialog(
      context,
      title: 'Replace all data?',
      message: 'Everything in BRUNT will be replaced with the backup${when.length >= 10 ? ' from ${Dates.short(DateTime.parse(when))}' : ''}. This cannot be undone.',
      confirm: 'Restore',
      danger: true,
    );
    if (!ok) return;
    await BackupRepo(s.db).restore(data);
    await s.onOpen();
    if (context.mounted) toast(context, 'Backup restored');
  } on BackupException catch (e) {
    if (context.mounted) toast(context, e.message, error: true);
  } catch (e) {
    if (context.mounted) toast(context, 'Restore failed: $e', error: true);
  }
}
