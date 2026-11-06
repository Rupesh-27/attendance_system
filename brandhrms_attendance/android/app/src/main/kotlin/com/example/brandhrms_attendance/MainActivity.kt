package com.example.brandhrms_attendance

import android.annotation.SuppressLint
import android.media.MediaDrm
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.brandhrms.device/hardware_id"

    // Universally supported Widevine DRM UUID across Android devices
    private val WIDEVINE_UUID = UUID(-0x121074568629b532L, -0x5c37d8232ae2de13L)

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
        // 1. Try Widevine MediaDrm permanent hardware ID (factory-burned TrustZone key)
        var drm: MediaDrm? = null
        try {
            drm = MediaDrm(WIDEVINE_UUID)
            val bytes = drm.getPropertyByteArray(MediaDrm.PROPERTY_DEVICE_UNIQUE_ID)
            if (bytes != null && bytes.isNotEmpty()) {
                val sb = StringBuilder()
                for (b in bytes) {
                    sb.append(String.format("%02x", b))
                }
                val hex = sb.toString()
                if (hex.isNotBlank()) {
                    return hex
                }
            }
        } catch (_: Throwable) {
            // Fall through to ANDROID_ID if DRM not supported
        } finally {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    drm?.close()
                } else {
                    @Suppress("DEPRECATION")
                    drm?.release()
                }
            } catch (_: Throwable) {}
        }

        // 2. Fallback to Settings.Secure.ANDROID_ID
        try {
            val androidId: String? = Settings.Secure.getString(
                contentResolver,
                Settings.Secure.ANDROID_ID
            )
            if (!androidId.isNullOrBlank()) {
                return androidId
            }
        } catch (_: Throwable) {}

        return null
    }
}
