import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../design/design.dart';
import 'lock_controller.dart';

/// Re-authentication for sensitive actions (export, restore, change PIN, biometrics) — spec §9.3.
Future<bool> reauthenticate(BuildContext context, WidgetRef ref, {required String reason}) async {
  final lock = ref.read(lockProvider.notifier);
  if (ref.read(lockProvider).biometricEnabled) {
    try {
      final ok = await lock.suppressWhile(
        () => LocalAuthentication().authenticate(localizedReason: reason, biometricOnly: true),
      );
      if (ok) return true;
    } catch (_) {
      // fall through to PIN
    }
  }
  if (!context.mounted) return false;
  final ok = await showBruntSheet<bool>(context, scrollable: true, builder: (_) => _PinCheck(reason: reason));
  return ok ?? false;
}

class _PinCheck extends ConsumerStatefulWidget {
  const _PinCheck({required this.reason});
  final String reason;

  @override
  ConsumerState<_PinCheck> createState() => _PinCheckState();
}

class _PinCheckState extends ConsumerState<_PinCheck> {
  String _pin = '';
  bool _error = false;
  bool _busy = false;

  Future<void> _digit(String d) async {
    if (_pin.length >= 6 || _busy) return;
    setState(() {
      _pin += d;
      _error = false;
    });
    if (_pin.length < 6) return;
    setState(() => _busy = true);
    final ok = await ref.read(lockProvider.notifier).verifyPin(_pin);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _pin = '';
        _error = true;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Text('Confirm it is you', style: BText.h2),
      const SizedBox(height: 6),
      Text(_error ? 'Wrong PIN' : widget.reason, style: BText.bodyMuted.copyWith(color: _error ? BColors.danger : null), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      if (_busy)
        const Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator())
      else
        PinPad(
          length: _pin.length,
          error: _error,
          onDigit: _digit,
          onDelete: () => setState(() => _pin = _pin.isEmpty ? '' : _pin.substring(0, _pin.length - 1)),
        ),
    ]);
  }
}

/// Asks for a new PIN twice. Returns null when cancelled.
Future<String?> askNewPin(BuildContext context) =>
    showBruntSheet<String>(context, builder: (_) => const _NewPin());

class _NewPin extends StatefulWidget {
  const _NewPin();
  @override
  State<_NewPin> createState() => _NewPinState();
}

class _NewPinState extends State<_NewPin> {
  String _pin = '';
  String? _first;
  String? _msg;

  void _digit(String d) {
    if (_pin.length >= 6) return;
    setState(() => _pin += d);
    if (_pin.length < 6) return;
    if (_first == null) {
      if (RegExp(r'^(\d)\1{5}$').hasMatch(_pin) || _pin == '123456') {
        setState(() {
          _msg = 'Too easy to guess';
          _pin = '';
        });
        return;
      }
      setState(() {
        _first = _pin;
        _pin = '';
        _msg = null;
      });
    } else if (_first == _pin) {
      Navigator.pop(context, _pin);
    } else {
      setState(() {
        _first = null;
        _pin = '';
        _msg = "PINs didn't match";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(_first == null ? 'New 6-digit PIN' : 'Confirm new PIN', style: BText.h2),
      const SizedBox(height: 6),
      Text(_msg ?? ' ', style: BText.bodyMuted.copyWith(color: BColors.danger)),
      const SizedBox(height: 20),
      PinPad(
        length: _pin.length,
        error: _msg != null,
        onDigit: _digit,
        onDelete: () => setState(() => _pin = _pin.isEmpty ? '' : _pin.substring(0, _pin.length - 1)),
      ),
    ]);
  }
}
