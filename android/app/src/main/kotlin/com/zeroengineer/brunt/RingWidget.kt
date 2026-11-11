package com.zeroengineer.brunt

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RadialGradient
import android.graphics.RectF
import android.graphics.Shader
import android.widget.RemoteViews
import kotlin.math.max

/**
 * Home-screen widget: the dashboard money ring, without any amounts.
 *
 * The app stores only each segment's share of the ring (per mille) and its colour, in private
 * SharedPreferences (excluded from backup). Nothing else from the encrypted database leaves it.
 */
class RingWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        render(context, manager, ids)
    }

    companion object {
        private const val PREFS = "brunt_widget"
        private const val KEY = "segments"

        /** [encoded] is "share:argb,share:argb,…" (share in per mille). Empty clears the ring. */
        fun save(context: Context, encoded: String) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY, encoded).apply()
            refresh(context)
        }

        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, RingWidget::class.java))
            if (ids.isNotEmpty()) render(context, manager, ids)
        }

        private fun render(context: Context, manager: AppWidgetManager, ids: IntArray) {
            val encoded = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, "") ?: ""
            val segments = encoded.split(',').mapNotNull {
                val p = it.split(':')
                if (p.size != 2) null else {
                    val v = p[0].toIntOrNull()
                    val c = p[1].toLongOrNull()
                    if (v == null || c == null || v <= 0) null else Pair(v, c.toInt())
                }
            }
            val bitmap = drawRing(segments, 480)
            val open = PendingIntent.getActivity(
                context, 0,
                Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            for (id in ids) {
                val views = RemoteViews(context.packageName, R.layout.ring_widget)
                views.setImageViewBitmap(R.id.ring, bitmap)
                views.setOnClickPendingIntent(R.id.ring, open)
                manager.updateAppWidget(id, views)
            }
        }

        /** Same geometry as the in-app ring (RingLayout): round caps, equal gaps, one full turn. */
        private fun drawRing(segments: List<Pair<Int, Int>>, size: Int): Bitmap {
            val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bmp)
            val c = size / 2f
            val thickness = size * 0.115f
            val r = size / 2f - thickness / 2f - size * 0.02f

            // dark disc with the blue centre glow, so the ring reads on any wallpaper
            canvas.drawCircle(c, c, size / 2f, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.BLACK })
            canvas.drawCircle(c, c, r, Paint(Paint.ANTI_ALIAS_FLAG).apply {
                shader = RadialGradient(c, c, r, Color.argb(97, 0x1B, 0x53, 0x9A), Color.argb(0, 0x1B, 0x53, 0x9A), Shader.TileMode.CLAMP)
            })

            val rect = RectF(c - r, c - r, c + r, c + r)
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = thickness
            }
            val total = segments.sumOf { it.first }
            if (total <= 0) {
                paint.color = Color.rgb(0x15, 0x19, 0x1D)
                canvas.drawArc(rect, 0f, 360f, false, paint)
                return bmp
            }
            if (segments.size == 1) {
                paint.color = segments[0].second
                canvas.drawArc(rect, 0f, 360f, false, paint)
                return bmp
            }
            paint.strokeCap = Paint.Cap.ROUND
            val cap = Math.toDegrees(((thickness / 2) / r).toDouble())
            val slot = Math.toDegrees(0.05) + cap * 2
            val minSweep = Math.toDegrees(0.02)
            val available = 360.0 - slot * segments.size
            val shares = segments.map { max(minSweep, available * it.first / total) }
            val k = 360.0 / shares.sumOf { it + slot }
            var start = -90.0 + slot / 2
            for ((i, s) in segments.withIndex()) {
                val sweep = (shares[i] + slot) * k - slot
                paint.color = s.second
                canvas.drawArc(rect, start.toFloat(), sweep.toFloat(), false, paint)
                start += (shares[i] + slot) * k
            }
            return bmp
        }
    }
}
