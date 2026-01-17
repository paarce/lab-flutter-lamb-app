package com.accessibilityapp.lamb

import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.util.DisplayMetrics
import android.util.Log
import android.view.WindowManager
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

                "getScreenDimensions" -> {
                    try {
                        Log.d(TAG, "Getting screen dimensions")
                        val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
                        val display = windowManager.defaultDisplay
                        val metrics = DisplayMetrics()
                        display.getRealMetrics(metrics)

                        val dimensions = mapOf(
                            "width" to metrics.widthPixels,
                            "height" to metrics.heightPixels
                        )

                        Log.d(TAG, "Screen dimensions: ${metrics.widthPixels}x${metrics.heightPixels}")
                        result.success(dimensions)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to get screen dimensions", e)
                        result.error(
                            "SCREEN_DIMENSIONS_FAILED",
                            "Failed to get screen dimensions: ${e.message}",
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

                        // Get AccessibilityService instance
                        val service = AssistantAccessibilityService.getInstance()
                        if (service == null) {
                            Log.e(TAG, "AccessibilityService not enabled")
                            result.error(
                                "PERMISSION_DENIED",
                                "Accessibility service is not enabled. Please enable it in Settings.",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        // Dispatch tap gesture
                        val success = service.simulateTap(x.toFloat(), y.toFloat())

                        if (success) {
                            Log.d(TAG, "Tap dispatched successfully")
                            result.success(null)
                        } else {
                            result.error("TAP_SIMULATION_FAILED", "Failed to dispatch tap", null)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to simulate tap", e)
                        result.error(
                            "TAP_SIMULATION_FAILED",
                            "Failed to simulate tap: ${e.message}",
                            e.stackTraceToString()
                        )
                    }
                }

                "openAccessibilitySettings" -> {
                    try {
                        Log.d(TAG, "Opening accessibility settings")
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to open accessibility settings", e)
                        result.error(
                            "SETTINGS_OPEN_FAILED",
                            "Failed to open accessibility settings: ${e.message}",
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
