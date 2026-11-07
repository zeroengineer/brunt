import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../design/design.dart';
import '../../security/lock_controller.dart';

/// Lets the user save [bytes] to a folder or share them, without auto-locking while the
/// system picker / share sheet is in front.
Future<void> saveOrShare(BuildContext context, WidgetRef ref, {required Uint8List bytes, required String fileName, required String mimeType, required String title}) async {
  final mode = await showBruntSheet<String>(
    context,
    builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(title, style: BText.h2),
      const SizedBox(height: 4),
      Text(fileName, style: BText.caption),
      const SizedBox(height: 16),
      PillButton(label: 'Save to a folder', expand: true, onPressed: () => Navigator.pop(ctx, 'save')),
      const SizedBox(height: 10),
      PillButton(label: 'Share…', variant: PillVariant.outline, expand: true, onPressed: () => Navigator.pop(ctx, 'share')),
    ]),
  );
  if (mode == null || !context.mounted) return;
  final lock = ref.read(lockProvider.notifier);
  try {
    if (mode == 'save') {
      final uri = await lock.suppressWhile(() => FilePicker.saveFile(fileName: fileName, bytes: bytes, mimeType: mimeType));
      if (context.mounted && uri != null) toast(context, 'Saved $fileName');
    } else {
      final dir = await getTemporaryDirectory();
      final f = File(p.join(dir.path, fileName));
      await f.writeAsBytes(bytes, flush: true);
      await lock.suppressWhile(() => SharePlus.instance.share(ShareParams(files: [XFile(f.path, mimeType: mimeType)])));
      if (f.existsSync()) await f.delete();
    }
  } catch (e) {
    if (context.mounted) toast(context, 'Could not export: $e', error: true);
  }
}
