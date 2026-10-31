package com.ntlong25.momcare

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/// Home-screen shortcut to the bump camera. Static: a glyph and "Chụp ảnh",
/// no personal data, no periodic updates.
class QuickCameraWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val intent = Intent().setClassName(context, MainActivity.QUICK_CAMERA_ENTRY)
        val tap = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val views = RemoteViews(context.packageName, R.layout.quick_camera_widget)
        views.setOnClickPendingIntent(android.R.id.background, tap)
        appWidgetManager.updateAppWidget(appWidgetIds, views)
    }
}
