package com.ntlong25.momcare

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class MainActivity : FlutterFragmentActivity() {
    private var channel: MethodChannel? = null
    private var reminderChannel: MethodChannel? = null

    /// A tap on the home-screen widget that Dart has not taken yet.
    private var widgetTapped = false

    /// A tap on a fertile-day notification that Dart has not taken yet.
    private var calendarTapped = false

    override fun onCreate(savedInstanceState: Bundle?) {
        // A recreated activity replays its old intent: not a new tap.
        if (savedInstanceState == null && isWidgetTap(intent)) widgetTapped = true
        if (savedInstanceState == null && isCalendarTap(intent)) calendarTapped = true
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).also {
            it.setMethodCallHandler { call, result ->
                if (call.method == "takeTap") {
                    result.success(widgetTapped)
                    widgetTapped = false
                } else {
                    result.notImplemented()
                }
            }
        }
        reminderChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            REMINDER_CHANNEL,
        ).also {
            it.setMethodCallHandler { call, result ->
                when (call.method) {
                    "takeTap" -> {
                        result.success(calendarTapped)
                        calendarTapped = false
                    }
                    "schedule" -> {
                        val args = call.arguments as Map<*, *>
                        CalendarReminders.schedule(
                            applicationContext,
                            (args["id"] as Number).toInt(),
                            JSONObject(args),
                        )
                        result.success(null)
                    }
                    "cancel" -> {
                        CalendarReminders.cancel(
                            applicationContext,
                            (call.argument<Number>("id"))!!.toInt(),
                        )
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (isCalendarTap(intent)) {
            calendarTapped = true
            reminderChannel?.invokeMethod("tapped", null)
        }
        if (isWidgetTap(intent)) {
            widgetTapped = true
            channel?.invokeMethod("tapped", null)
        }
    }

    private fun isCalendarTap(intent: Intent?): Boolean {
        if (intent == null) return false
        val replayed = intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0
        return !replayed && intent.action == CalendarReminders.ACTION_OPEN_CYCLE
    }

    /// Only the widget can start the non-exported entry alias, so other apps
    /// cannot open the camera screen. Reopening from Recents replays the
    /// launch intent and is not a tap either.
    private fun isWidgetTap(intent: Intent?): Boolean {
        if (intent == null) return false
        val replayed = intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0
        return !replayed && intent.component?.className == QUICK_CAMERA_ENTRY
    }

    companion object {
        private const val CHANNEL = "com.ntlong25.momcare/quick_camera"
        private const val REMINDER_CHANNEL = "com.ntlong25.momcare/reminders"

        const val QUICK_CAMERA_ENTRY = "com.ntlong25.momcare.QuickCameraEntry"
    }
}
