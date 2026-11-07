import 'dart:io';

/// Best-effort root / jailbreak detection (spec §9.1: warn, don't block). Fully offline.
abstract final class DeviceIntegrity {
  static const _androidPaths = [
    '/system/app/Superuser.apk',
    '/sbin/su',
    '/system/bin/su',
    '/system/xbin/su',
    '/data/local/xbin/su',
    '/data/local/bin/su',
    '/system/sd/xbin/su',
    '/system/bin/failsafe/su',
    '/data/local/su',
    '/su/bin/su',
    '/system/xbin/daemonsu',
    '/sbin/.magisk',
    '/data/adb/magisk',
  ];

  static const _iosPaths = [
    '/Applications/Cydia.app',
    '/Library/MobileSubstrate/MobileSubstrate.dylib',
    '/bin/bash',
    '/usr/sbin/sshd',
    '/etc/apt',
    '/private/var/lib/apt/',
    '/var/jb',
    '/Applications/Sileo.app',
  ];

  static Future<bool> isCompromised() async {
    try {
      if (Platform.isAndroid) {
        for (final p in _androidPaths) {
          if (File(p).existsSync() || Directory(p).existsSync()) return true;
        }
        final tags = File('/system/build.prop');
        if (tags.existsSync() && tags.readAsStringSync().contains('ro.build.tags=test-keys')) return true;
      } else if (Platform.isIOS) {
        for (final p in _iosPaths) {
          if (File(p).existsSync() || Directory(p).existsSync()) return true;
        }
        // sandbox escape check: writing outside the container must fail
        try {
          final f = File('/private/brunt_jb_check.txt');
          f.writeAsStringSync('x');
          f.deleteSync();
          return true;
        } catch (_) {}
      }
    } catch (_) {}
    return false;
  }
}
