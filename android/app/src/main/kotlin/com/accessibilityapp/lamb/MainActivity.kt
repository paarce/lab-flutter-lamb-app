package com.accessibilityapp.lamb

import android.content.Context
import android.content.Intent
import android.os.BatteryManager
import android.provider.Settings
import android.util.DisplayMetrics
import android.util.Log
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.*

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
        private const val WHATSAPP_CHANNEL = "com.accessibilityapp/whatsapp"
        private const val SYSTEM_INFO_CHANNEL = "com.accessibilityapp/system_info"
        private const val WHATSAPP_PACKAGE = "com.whatsapp"
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

        // Setup MethodChannel for WhatsApp automation
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WHATSAPP_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openWhatsApp" -> {
                    try {
                        Log.d(TAG, "Opening WhatsApp")
                        val intent = packageManager.getLaunchIntentForPackage(WHATSAPP_PACKAGE)

                        if (intent != null) {
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            Log.d(TAG, "WhatsApp opened successfully")
                            result.success(null)
                        } else {
                            Log.e(TAG, "WhatsApp not installed")
                            result.error(
                                "NOT_FOUND",
                                "WhatsApp is not installed on this device",
                                null
                            )
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to open WhatsApp", e)
                        result.error(
                            "WHATSAPP_OPEN_FAILED",
                            "Failed to open WhatsApp: ${e.message}",
                            e.stackTraceToString()
                        )
                    }
                }

                "isWhatsAppInstalled" -> {
                    try {
                        val intent = packageManager.getLaunchIntentForPackage(WHATSAPP_PACKAGE)
                        val isInstalled = intent != null
                        Log.d(TAG, "WhatsApp installed: $isInstalled")
                        result.success(isInstalled)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error checking WhatsApp installation", e)
                        result.success(false)
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }

        // Setup MethodChannel for System Info
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SYSTEM_INFO_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getTime" -> {
                    try {
                        val time = getCurrentTimeFormatted()
                        Log.d(TAG, "Time: $time")
                        result.success(time)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to get time", e)
                        result.error(
                            "TIME_ERROR",
                            "Failed to get time: ${e.message}",
                            e.stackTraceToString()
                        )
                    }
                }

                "getDate" -> {
                    try {
                        val date = getCurrentDateFormatted()
                        Log.d(TAG, "Date: $date")
                        result.success(date)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to get date", e)
                        result.error(
                            "DATE_ERROR",
                            "Failed to get date: ${e.message}",
                            e.stackTraceToString()
                        )
                    }
                }

                "getBatteryLevel" -> {
                    try {
                        val level = getBatteryLevelInternal()
                        Log.d(TAG, "Battery level: $level%")
                        result.success(level)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to get battery level", e)
                        result.error(
                            "BATTERY_ERROR",
                            "Failed to get battery level: ${e.message}",
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

    /**
     * Obtiene la hora actual en formato accesible para TTS
     *
     * Formato: "2:30 de la tarde" (no "14:30")
     */
    private fun getCurrentTimeFormatted(): String {
        val calendar = Calendar.getInstance()
        val hour = calendar.get(Calendar.HOUR_OF_DAY)
        val minute = calendar.get(Calendar.MINUTE)

        // Determinar período del día para formato accesible
        val period = when {
            hour < 12 -> "de la mañana"
            hour < 20 -> "de la tarde"
            else -> "de la noche"
        }

        // Convertir a formato 12 horas
        val hour12 = if (hour > 12) hour - 12 else if (hour == 0) 12 else hour

        // Formatear minutos con 2 dígitos
        val minuteStr = minute.toString().padStart(2, '0')

        return "$hour12:$minuteStr $period"
    }

    /**
     * Obtiene la fecha actual en formato accesible para TTS
     *
     * Formato: "25 de enero de 2026" (no "25/01/2026")
     */
    private fun getCurrentDateFormatted(): String {
        val calendar = Calendar.getInstance()
        val day = calendar.get(Calendar.DAY_OF_MONTH)
        val monthNames = arrayOf(
            "enero", "febrero", "marzo", "abril", "mayo", "junio",
            "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"
        )
        val month = monthNames[calendar.get(Calendar.MONTH)]
        val year = calendar.get(Calendar.YEAR)

        return "$day de $month de $year"
    }

    /**
     * Obtiene el nivel de batería actual
     *
     * Returns porcentaje de 0 a 100
     */
    private fun getBatteryLevelInternal(): Int {
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        return batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
    }
}
