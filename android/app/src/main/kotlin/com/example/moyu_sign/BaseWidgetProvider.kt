package com.example.moyu_sign

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

abstract class BaseWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_INCREMENT = "com.example.moyu_sign.ACTION_INCREMENT"
        const val FLUTTER_PREFS_NAME = "FlutterSharedPreferences"
        const val KEY_COUNT = "today_count"

        fun getCount(context: Context): Int {
            val flutterPrefs = context.getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE)
            return try {
                flutterPrefs.getInt("flutter.$KEY_COUNT", 0)
            } catch (e: ClassCastException) {
                // 兼容旧数据：旧版用 Long 存储，迁移到 Int
                val longValue = flutterPrefs.getLong("flutter.$KEY_COUNT", 0L).toInt()
                flutterPrefs.edit()
                    .remove("flutter.$KEY_COUNT")
                    .putInt("flutter.$KEY_COUNT", longValue)
                    .apply()
                longValue
            }
        }

        fun setCount(context: Context, count: Int) {
            val flutterPrefs = context.getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE)
            flutterPrefs.edit().putInt("flutter.$KEY_COUNT", count).apply()
        }

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            
            // 更新所有类型的 Widget
            val smallComponent = ComponentName(context, MoyuSmallWidgetProvider::class.java)
            val mediumComponent = ComponentName(context, MoyuMediumWidgetProvider::class.java)
            val largeComponent = ComponentName(context, MoyuLargeWidgetProvider::class.java)
            
            val smallIds = appWidgetManager.getAppWidgetIds(smallComponent)
            val mediumIds = appWidgetManager.getAppWidgetIds(mediumComponent)
            val largeIds = appWidgetManager.getAppWidgetIds(largeComponent)
            
            for (id in smallIds) {
                updateSmallWidget(context, appWidgetManager, id)
            }
            for (id in mediumIds) {
                updateMediumWidget(context, appWidgetManager, id)
            }
            for (id in largeIds) {
                updateLargeWidget(context, appWidgetManager, id)
            }
        }

        private fun getOpenPendingIntent(context: Context): PendingIntent {
            val openIntent = Intent(context, MainActivity::class.java)
            return PendingIntent.getActivity(
                context, 0, openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        private fun getIncrementPendingIntent(context: Context, requestCode: Int = 1): PendingIntent {
            val incrementIntent = Intent(context, MoyuLargeWidgetProvider::class.java).apply {
                action = ACTION_INCREMENT
            }
            return PendingIntent.getBroadcast(
                context, requestCode, incrementIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        private fun updateSmallWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val count = getCount(context)
            val views = RemoteViews(context.packageName, R.layout.widget_small).apply {
                setTextViewText(R.id.widget_count, count.toString())
                setOnClickPendingIntent(R.id.widget_count, getOpenPendingIntent(context))
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun updateMediumWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val count = getCount(context)
            val views = RemoteViews(context.packageName, R.layout.widget_medium).apply {
                setTextViewText(R.id.widget_count, count.toString())
                setOnClickPendingIntent(R.id.widget_count, getOpenPendingIntent(context))
                
                // 点击标签/提示区域累加
                setOnClickPendingIntent(R.id.widget_label, getIncrementPendingIntent(context, 2))
                setOnClickPendingIntent(R.id.widget_hint, getIncrementPendingIntent(context, 3))
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun updateLargeWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val count = getCount(context)
            val views = RemoteViews(context.packageName, R.layout.widget_large).apply {
                setTextViewText(R.id.widget_count, count.toString())
                setOnClickPendingIntent(R.id.widget_count, getOpenPendingIntent(context))
                
                // +1 按钮
                setOnClickPendingIntent(R.id.widget_btn_plus, getIncrementPendingIntent(context, 1))
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        updateAllWidgets(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        when (intent.action) {
            ACTION_INCREMENT -> {
                val count = getCount(context) + 1
                setCount(context, count)
                updateAllWidgets(context)
            }
        }
    }
}
