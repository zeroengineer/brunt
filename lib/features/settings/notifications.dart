import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show BooleanExpressionOperators;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../app/session.dart';
import '../../core/constants.dart';
import '../../core/dates.dart';

/// On-device reminders (spec §4.5, §9.3). No push server. Notification text never contains
/// amounts or names, so nothing private shows on the lock screen.
class Reminders {
  Reminders._();
  static final instance = Reminders._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  Timer? _debounce;

  static const _dailyId = 1;
  static const _dueBase = 100;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'brunt_reminders',
      'Reminders',
      channelDescription: 'Daily log and due-date reminders',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      visibility: NotificationVisibility.private,
    ),
    iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
  );

  Future<void> _init() async {
    if (_ready || kIsWeb) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  Future<bool> requestPermission() async {
    await _init();
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
    }
    if (Platform.isIOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, sound: true) ??
          false;
    }
    return false;
  }

  /// Debounced re-sync after data changes.
  void scheduleSync(Session s) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () => syncFromSession(s));
  }

  Future<void> syncFromSession(Session s) async {
    try {
      await _init();
      if (!_ready) return;
      final settings = await s.settings.all();
      if (settings[SettingKeys.onboardedAt] == null) return;
      await _plugin.cancelAll();

      final now = tz.TZDateTime.now(tz.local);
      if (settings[SettingKeys.remindersEnabled] != '0') {
        final parts = (settings[SettingKeys.reminderTime] ?? '21:00').split(':');
        final h = int.tryParse(parts.first) ?? 21;
        final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
        var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
        if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
        await _plugin.zonedSchedule(
          id: _dailyId,
          title: 'BRUNT',
          body: "Time to log today's expenses",
          scheduledDate: at,
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }

      if (settings[SettingKeys.dueRemindersEnabled] != '0') {
        final month = await s.engine.latest();
        if (month == null) return;
        final items = await (s.db.select(s.db.plannedItems)
              ..where((p) => p.monthId.equals(month.id) & p.status.equals('pending') & p.dueDate.isNotNull()))
            .get();
        final dueDays = items.map((p) => p.dueDate!).toSet().toList()..sort();
        var i = 0;
        for (final iso in dueDays) {
          final d = Dates.parseIso(iso);
          final at = tz.TZDateTime(tz.local, d.year, d.month, d.day, 9);
          if (!at.isAfter(now)) continue;
          final n = items.where((p) => p.dueDate == iso).length;
          await _plugin.zonedSchedule(
            id: _dueBase + i++,
            title: 'BRUNT',
            body: n == 1 ? 'You have a bill due today' : 'You have $n bills due today',
            scheduledDate: at,
            notificationDetails: _details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
          if (i >= 40) break;
        }
      }
    } catch (e) {
      // Reminders are best-effort; never break the app over them. (No data in logs.)
      debugPrint('Reminders sync failed: ${e.runtimeType}');
    }
  }

  Future<void> cancelAll() async {
    await _init();
    await _plugin.cancelAll();
  }
}
