import 'package:flutter/material.dart';

import 'tokens.dart';

/// Shows a BRUNT bottom sheet: surface colour, 28 top radius, drag handle, keyboard aware.
Future<T?> showBruntSheet<T>(BuildContext context, {required WidgetBuilder builder, bool scrollable = true}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: BColors.surface,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(BRadius.sheet))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 10),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: BColors.borderStrong, borderRadius: BorderRadius.circular(2))),
        Flexible(
          child: scrollable
              ? SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), child: builder(ctx))
              : Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), child: builder(ctx)),
        ),
      ]),
    ),
  );
}

/// Simple confirm dialog in the BRUNT style.
Future<bool> confirmDialog(BuildContext context,
    {required String title, required String message, String confirm = 'Confirm', bool danger = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: BColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BRadius.card)),
      title: Text(title, style: BText.h2),
      content: Text(message, style: BText.bodyMuted),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirm, style: TextStyle(color: danger ? BColors.danger : BColors.primaryLight, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  return r ?? false;
}

void toast(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message, style: BText.body.copyWith(color: error ? BColors.text : BColors.bg)),
      backgroundColor: error ? BColors.danger : BColors.primarySoft,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
      duration: const Duration(seconds: 2),
    ));
}
