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

                "simulateTap" -> {
                    try {
                        val x = call.argument<Double>("x")
                        val y = call.argument<Double>("y")

                        if (x == null || y == null) {
                            result.error(
                                "INVALID_ARGUMENT",
                                "Missing x or y coordinates",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        Log.d(TAG, "Simulate tap requested at: ($x, $y)")

                        // TODO: Implement tap simulation via AccessibilityService
                        // This requires:
                        // 1. AssistantAccessibilityService implementation
                        // 2. Accessibility permission granted by user
                        // 3. Global gesture dispatch capability
                        //
                        // For now, just log the request
                        Log.w(TAG, "Tap simulation not yet implemented - AccessibilityService required")
                        Log.w(TAG, "This will be implemented in future WhatsApp automation feature")

                        // Return success for now (architecture is ready)
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to simulate tap", e)
                        result.error(
                            "TAP_SIMULATION_FAILED",
                            "Failed to simulate tap: ${e.message}",
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
