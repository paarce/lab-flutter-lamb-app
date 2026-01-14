package com.accessibilityapp.lamb

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * Foreground service for screen capture/media projection
 *
 * Required for Android 14+ (API 34+) to use MediaProjection.
 * Even though build.gradle targets API 33, Android 14+ enforces this
 * requirement at runtime for security reasons.
 *
 * This service must be running before calling MediaProjection.start()
 */
class ScreenCaptureService : Service() {

    companion object {
        private const val TAG = "ScreenCaptureService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "screen_capture_channel"
        private const val CHANNEL_NAME = "Sesión Remota"

        /**
         * Starts the foreground service
         */
        fun start(context: Context) {
            val intent = Intent(context, ScreenCaptureService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
            Log.d(TAG, "Service start requested")
        }

        /**
         * Stops the foreground service
         */
        fun stop(context: Context) {
            val intent = Intent(context, ScreenCaptureService::class.java)
            context.stopService(intent)
            Log.d(TAG, "Service stop requested")
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service created")

        // Create notification channel (required for Android 8+)
        createNotificationChannel()

        // Start foreground with notification
        val notification = createNotification()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // Android 14+ (API 34+) requires specific foreground service type
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
            )
            Log.d(TAG, "Started foreground with MEDIA_PROJECTION type (Android 14+)")
        } else {
            // Android 13 and below
            startForeground(NOTIFICATION_ID, notification)
            Log.d(TAG, "Started foreground (Android 13 and below)")
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand called")
        // Service will continue running until explicitly stopped
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        // Not a bound service
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Service destroyed")
    }

    /**
     * Creates notification channel for Android 8+
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW // Low importance = no sound
            ).apply {
                description = "Notificación de sesión remota activa"
                setShowBadge(false)
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "Notification channel created")
        }
    }

    /**
     * Creates the foreground notification
     */
    private fun createNotification(): Notification {
        // Intent to launch the app when notification is tapped
        val notificationIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            notificationIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Sesión Remota Activa")
            .setContentText("Tu familiar puede ver tu pantalla")
            .setSmallIcon(R.drawable.ic_notification_remote_session)
            .setContentIntent(pendingIntent)
            .setOngoing(true) // Cannot be dismissed by user
            .setPriority(NotificationCompat.PRIORITY_LOW) // Low priority = no sound/vibration
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }
}
