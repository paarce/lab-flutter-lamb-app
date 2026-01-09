package com.accessibilityapp.lamb

import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity for Flutter app
 *
 * Handles Platform Channel communication for:
 * - Starting/stopping foreground service for MediaProjection (Android 14+ requirement)
 *
 * Screen capture is handled by flutter_webrtc plugin, but it requires the foreground
 * service to be running first.
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "MainActivity"
        private const val CHANNEL = "com.accessibilityapp/foreground_service"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Setup MethodChannel for foreground service control
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startForegroundService" -> {
                    try {
                        Log.d(TAG, "Starting foreground service for screen capture")
                        ScreenCaptureService.start(this)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to start foreground service", e)
                        result.error(
                            "SERVICE_START_FAILED",
                            "Failed to start foreground service: ${e.message}",
                            e.stackTraceToString()
                        )
                    }
                }

                "stopForegroundService" -> {
                    try {
                        Log.d(TAG, "Stopping foreground service")
                        ScreenCaptureService.stop(this)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to stop foreground service", e)
                        result.error(
                            "SERVICE_STOP_FAILED",
                            "Failed to stop foreground service: ${e.message}",
                            e.stackTraceToString()
                        )
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
