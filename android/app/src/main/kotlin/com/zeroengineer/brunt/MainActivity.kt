package com.zeroengineer.brunt

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity is required by local_auth / biometric_storage.
class MainActivity : FlutterFragmentActivity() {
    private val isRelease get() = BuildConfig.BUILD_TYPE == "release"

    override fun onCreate(savedInstanceState: Bundle?) {
        // FLAG_SECURE from the very first frame: blocks screenshots / screen recording
        // and blanks the app-switcher preview (spec §9.3). Release builds only, so that
        // debug/profile builds can be screenshotted over adb while testing.
        if (isRelease) {
            window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "brunt/platform").setMethodCallHandler { call, result ->
            when (call.method) {
                "setSecure" -> {
                    val on = (call.arguments as? Boolean ?: true) && isRelease
                    runOnUiThread {
                        if (on) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(true)
                    }
                }
                "updateWidget" -> {
                    RingWidget.save(applicationContext, call.arguments as? String ?: "")
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
