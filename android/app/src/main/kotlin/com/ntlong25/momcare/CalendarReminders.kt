package com.ntlong25.momcare

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import org.json.JSONObject

/// Pre-scheduled calendar notifications. flutter_local_notifications has no
/// public version for the lock screen, so these are posted here with
/// VISIBILITY_PRIVATE and a neutral public version. Entries are kept in
/// app-private preferences only so they survive a reboot without opening
/// the app; nothing is logged.
object CalendarReminders {
    const val ACTION_OPEN_CYCLE = "com.ntlong25.momcare.OPEN_CYCLE"
    private const val ACTION_FIRE = "com.ntlong25.momcare.CALENDAR_REMINDER"
    private const val EXTRA_ID = "id"
    private const val PREFS = "calendar_reminders"

    // Same channel as flutter_local_notifications uses for the app.
    private const val CHANNEL_ID = "momcare_channel"
    private const val CHANNEL_NAME = "Thông báo MomCare+"

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun alarmIntent(context: Context, id: Int): PendingIntent {
        val intent = Intent(context, CalendarReminderReceiver::class.java)
            .setAction(ACTION_FIRE)
            .putExtra(EXTRA_ID, id)
        return PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun arm(context: Context, id: Int, whenMillis: Long) {
        val alarms = context.getSystemService(AlarmManager::class.java)
        // Inexact on purpose: no exact-alarm permission is needed.
        alarms.setAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            whenMillis,
            alarmIntent(context, id),
        )
    }

    fun schedule(context: Context, id: Int, entry: JSONObject) {
        prefs(context).edit().putString(id.toString(), entry.toString()).apply()
        arm(context, id, entry.getLong("whenMillis"))
    }

    fun cancel(context: Context, id: Int) {
        prefs(context).edit().remove(id.toString()).apply()
        context.getSystemService(AlarmManager::class.java)
            .cancel(alarmIntent(context, id))
        context.getSystemService(NotificationManager::class.java).cancel(id)
    }

    /// Alarms do not survive a reboot. Days missed while off are dropped.
    fun rearm(context: Context) {
        val now = System.currentTimeMillis()
        val store = prefs(context)
        for ((key, value) in store.all) {
            val id = key.toIntOrNull()
            val entry = (value as? String)?.let { runCatching { JSONObject(it) }.getOrNull() }
            val whenMillis = entry?.optLong("whenMillis") ?: 0L
            if (id != null && whenMillis > now) {
                arm(context, id, whenMillis)
            } else {
                store.edit().remove(key).apply()
            }
        }
    }

    fun fire(context: Context, intent: Intent) {
        val id = intent.getIntExtra(EXTRA_ID, -1)
        val store = prefs(context)
        val raw = store.getString(id.toString(), null) ?: return
        store.edit().remove(id.toString()).apply()
        val entry = runCatching { JSONObject(raw) }.getOrNull() ?: return

        val manager = context.getSystemService(NotificationManager::class.java)
        if (manager.getNotificationChannel(CHANNEL_ID) == null) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_HIGH,
                ),
            )
        }

        val open = Intent(context, MainActivity::class.java)
            .setAction(ACTION_OPEN_CYCLE)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val tap = PendingIntent.getActivity(
            context,
            id,
            open,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val lockScreen = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(entry.getString("publicTitle"))
            .setContentText(entry.getString("publicBody"))
            .setContentIntent(tap)
            .build()

        val body = entry.getString("body")
        val notification = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(entry.getString("title"))
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setVisibility(Notification.VISIBILITY_PRIVATE)
            .setPublicVersion(lockScreen)
            .setContentIntent(tap)
            .setAutoCancel(true)
            .build()
        manager.notify(id, notification)
    }
}

class CalendarReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            -> CalendarReminders.rearm(context)
            else -> CalendarReminders.fire(context, intent)
        }
    }
}
