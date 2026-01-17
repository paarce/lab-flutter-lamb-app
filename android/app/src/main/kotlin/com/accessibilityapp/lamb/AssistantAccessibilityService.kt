package com.accessibilityapp.lamb

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.util.Log
import android.view.accessibility.AccessibilityEvent

/**
 * Accessibility Service for simulating touch gestures
 *
 * This service allows the app to dispatch touch gestures globally,
 * enabling remote control functionality for family members to help
 * elderly users with low vision.
 *
 * Security & Privacy:
 * - Only used for tap simulation during active remote sessions
 * - Does NOT read or collect any data from other apps
 * - User must explicitly enable in Settings > Accessibility
 *
 * Google Play Policy Compliance:
 * This is a legitimate use case for AssistanceAccessibilityService:
 * helping users with disabilities receive remote support from family.
 */
class AssistantAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "AccessibilityService"

        /**
         * Singleton instance of the service
         * Used by MainActivity to dispatch gestures
         */
        private var instance: AssistantAccessibilityService? = null

        /**
         * Gets the current service instance if available
         * @return Service instance or null if not enabled
         */
        fun getInstance(): AssistantAccessibilityService? = instance

        /**
         * Checks if the accessibility service is currently enabled
         * @return true if service is running, false otherwise
         */
        fun isServiceEnabled(): Boolean = instance != null
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.d(TAG, "Accessibility Service connected and ready")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // We don't need to process accessibility events
        // This service is only used for dispatching gestures
    }

    override fun onInterrupt() {
        Log.w(TAG, "Accessibility Service interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        Log.d(TAG, "Accessibility Service destroyed")
    }

    /**
     * Simulates a tap gesture at the specified screen coordinates
     *
     * @param x X coordinate in pixels
     * @param y Y coordinate in pixels
     * @return true if gesture was dispatched successfully, false otherwise
     */
    fun simulateTap(x: Float, y: Float): Boolean {
        Log.d(TAG, "Simulating tap at ($x, $y)")

        try {
            // Create a path for the tap gesture (single point)
            val path = Path().apply {
                moveTo(x, y)
            }

            // Create gesture description (100ms tap duration)
            val gesture = GestureDescription.Builder()
                .addStroke(GestureDescription.StrokeDescription(path, 0, 100))
                .build()

            // Dispatch the gesture
            val result = dispatchGesture(gesture, object : GestureResultCallback() {
                override fun onCompleted(gestureDescription: GestureDescription) {
                    Log.d(TAG, "Tap gesture completed successfully at ($x, $y)")
                }

                override fun onCancelled(gestureDescription: GestureDescription) {
                    Log.w(TAG, "Tap gesture was cancelled at ($x, $y)")
                }
            }, null)

            if (!result) {
                Log.e(TAG, "Failed to dispatch tap gesture at ($x, $y)")
            }

            return result
        } catch (e: Exception) {
            Log.e(TAG, "Exception while simulating tap at ($x, $y)", e)
            return false
        }
    }
}
