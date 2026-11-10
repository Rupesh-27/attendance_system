package com.example.brandhrms_attendance

import android.annotation.SuppressLint
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.brandhrms.device/hardware_id"

    @SuppressLint("HardwareIds")
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getHardwareId") {
                val hwId = getPermanentHardwareId()
                result.success(hwId)
            } else {
                result.notImplemented()
            }
        }
    }

    @SuppressLint("HardwareIds")
    private fun getPermanentHardwareId(): String? {
        // Settings.Secure.ANDROID_ID is Google's official permanent hardware identifier.
        // It persists across app uninstalls, reinstalls, updates, and device reboots.
        try {
            val androidId: String? = Settings.Secure.getString(
                contentResolver,
                Settings.Secure.ANDROID_ID
            )
            if (!androidId.isNullOrBlank()) {
                return androidId.trim().lowercase()
            }
        } catch (_: Throwable) {}

        return null
    }
}
