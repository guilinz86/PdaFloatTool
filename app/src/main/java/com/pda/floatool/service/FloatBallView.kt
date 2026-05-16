package com.pda.floatool.service

import android.content.Context
import android.graphics.*
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager

class FloatBallView(context: Context) : View(context) {

    private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#1976D2")
        style = Paint.Style.FILL
    }
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        textSize = 40f
        textAlign = Paint.Align.CENTER
        typeface = Typeface.DEFAULT_BOLD
    }

    private var isDragging = false
    private var downX = 0f
    private var downY = 0f
    var onTap: (() -> Unit)? = null

    override fun onDraw(canvas: Canvas) {
        val cx = width / 2f
        val cy = height / 2f
        val r = minOf(cx, cy) - 4
        canvas.drawCircle(cx, cy, r, paint)
        canvas.drawText("F", cx, cy + 14, textPaint)
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        parent?.requestDisallowInterceptTouchEvent(true)
        when (event.action) {
            MotionEvent.ACTION_DOWN -> {
                downX = event.rawX; downY = event.rawY; isDragging = false; return true
            }
            MotionEvent.ACTION_MOVE -> {
                val dx = event.rawX - downX; val dy = event.rawY - downY
                if (Math.sqrt((dx * dx + dy * dy).toDouble()) > 15) {
                    isDragging = true
                    (layoutParams as WindowManager.LayoutParams).apply { x += dx.toInt(); y += dy.toInt() }
                    (context.getSystemService(Context.WINDOW_SERVICE) as WindowManager).updateViewLayout(this, layoutParams)
                    downX = event.rawX; downY = event.rawY
                }
                return true
            }
            MotionEvent.ACTION_UP -> {
                if (!isDragging) onTap?.invoke() else snapToEdge()
                return true
            }
        }
        return false
    }

    private fun snapToEdge() {
        val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val metrics = android.graphics.Point().also { wm.defaultDisplay.getSize(it) }
        val params = layoutParams as WindowManager.LayoutParams
        params.x = if (params.x + width / 2 > metrics.x / 2) metrics.x - width else 0
        wm.updateViewLayout(this, params)
    }

    fun setRunning(running: Boolean) {
        paint.color = if (running) Color.parseColor("#f44336") else Color.parseColor("#1976D2")
        invalidate()
    }
}
