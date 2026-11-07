import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/notifications.dart';
import '../security/lock_controller.dart';
import '../security/screen_guard.dart';
import 'providers.dart';
import 'router.dart';
import 'theme.dart';

class BruntApp extends ConsumerStatefulWidget {
  const BruntApp({super.key});

  @override
  ConsumerState<BruntApp> createState() => _BruntAppState();
}

class _BruntAppState extends ConsumerState<BruntApp> {
  late final AppLifecycleListener _life;

  @override
  void initState() {
    super.initState();
    _life = AppLifecycleListener(
      onHide: () => ref.read(lockProvider.notifier).onBackground(),
      onShow: () => ref.read(lockProvider.notifier).onForeground(),
    );
  }

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Re-schedule local reminders whenever the unlocked data changes.
    ref.listen(sessionProvider, (_, s) async {
      if (s == null) return;
      unawaited(Reminders.instance.syncFromSession(s));
      if (await s.settings.get('block_screenshots') == '0') {
        await ScreenGuard.disable();
      } else {
        await ScreenGuard.enable();
      }
    });
    ref.listen(monthKeyProvider, (_, _) {
      final s = ref.read(sessionProvider);
      if (s != null) Reminders.instance.scheduleSync(s);
    });
    return MaterialApp.router(
      title: 'BRUNT',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      darkTheme: buildTheme(),
      themeMode: ThemeMode.dark,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        // Respect user font scaling, but cap it so layouts stay usable.
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: mq.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.35)),
          child: child!,
        );
      },
    );
  }
}
