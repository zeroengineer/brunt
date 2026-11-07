import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/design.dart';
import '../../security/lock_controller.dart';
import 'brand.dart';

/// Lock screen (spec §11.5 #1): glow, app mark, biometric prompt, PIN pad.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _pin = '';
  Timer? _tick;
  bool _autoPrompted = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      final until = ref.read(lockProvider).lockedUntil;
      if (until != null && mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeBiometric());
  }

  void _maybeBiometric() {
    final s = ref.read(lockProvider);
    if (!_autoPrompted && s.biometricEnabled && s.phase == LockPhase.locked) {
      _autoPrompted = true;
      ref.read(lockProvider.notifier).unlockWithBiometric();
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _digit(String d) async {
    if (_pin.length >= 6) return;
    setState(() => _pin += d);
    if (_pin.length == 6) {
      final pin = _pin;
      await ref.read(lockProvider.notifier).unlockWithPin(pin);
      if (mounted) setState(() => _pin = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(lockProvider);
    ref.listen(lockProvider.select((x) => x.biometricEnabled), (_, _) => _maybeBiometric());
    final until = s.lockedUntil;
    final locked = until != null && until.isAfter(DateTime.now());
    final wait = locked ? until.difference(DateTime.now()).inSeconds + 1 : 0;

    String status;
    Color statusColor = BColors.textMuted;
    if (s.busy) {
      status = 'Unlocking…';
    } else if (locked) {
      status = 'Too many attempts. Try again in ${wait}s';
      statusColor = BColors.warning;
    } else if (s.error != null) {
      status = s.error!;
      statusColor = BColors.danger;
    } else {
      status = 'Enter your 6-digit PIN';
    }

    return GlowBackground(
      centerGlow: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(height: 24),
                  const BruntMark(size: 56),
                  const SizedBox(height: 8),
                  const Text('Your money. Your phone. Nowhere else.', style: BText.caption),
                  const SizedBox(height: 32),
                  Semantics(liveRegion: true, child: Text(status, style: BText.body.copyWith(color: statusColor))),
                  const SizedBox(height: 24),
                  PinPad(
                    length: _pin.length,
                    error: s.error != null && _pin.isEmpty && !s.busy,
                    enabled: !s.busy && !locked,
                    onDigit: _digit,
                    onDelete: () => setState(() => _pin = _pin.isEmpty ? '' : _pin.substring(0, _pin.length - 1)),
                    onBiometric: s.biometricEnabled ? () => ref.read(lockProvider.notifier).unlockWithBiometric() : null,
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
