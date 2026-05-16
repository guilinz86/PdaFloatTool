package com.pda.floatool.service

import android.app.*
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.text.InputType
import android.view.*
import android.widget.*
import androidx.core.app.NotificationCompat
import com.pda.floatool.R
import com.pda.floatool.engine.DataCycleEngine
import com.pda.floatool.model.RecordedStep
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import kotlinx.coroutines.*

class FloatService : Service() {

    private lateinit var wm: WindowManager
    private lateinit var floatBall: FloatBallView
    private var panelView: View? = null
    private var isPanelOpen = false
    private var isPlaying = false
    private var stopPlayback = false
    private val dataEngine by lazy { DataCycleEngine(this) }
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var currentSteps = mutableListOf<RecordedStep>()
    private var isRecording = false

    override fun onCreate() {
        super.onCreate()
        wm = getSystemService(WINDOW_SERVICE) as WindowManager
        scope.launch { dataEngine.init() }
        showFloatBall()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(1, createNotification())
        return START_STICKY
    }

    private fun showFloatBall() {
        floatBall = FloatBallView(this).apply { onTap = { togglePanel() } }
        val params = WindowManager.LayoutParams(120, 120,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE, PixelFormat.TRANSLUCENT
        ).apply { gravity = Gravity.END or Gravity.CENTER_VERTICAL }
        wm.addView(floatBall, params)
    }

    private fun togglePanel() {
        if (isPlaying) return
        if (panelView != null) { wm.removeView(panelView); panelView = null; isPanelOpen = false }
        else { showPanel(); isPanelOpen = true }
    }

    private fun showPanel() {
        val inflater = LayoutInflater.from(this)
        panelView = inflater.inflate(R.layout.float_panel, null).apply { setupPanelButtons(this) }
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT, WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE, PixelFormat.TRANSLUCENT
        ).apply { gravity = Gravity.END or Gravity.CENTER_VERTICAL; x = 140 }
        wm.addView(panelView, params)
        updatePanelPreview(); updateRecordButton(); updateSavedSequences()
    }

    private fun setupPanelButtons(root: View) {
        val tapService = TapAccessibilityService.instance

        root.findViewById<Button>(R.id.btn_record).setOnClickListener { toggleRecording() }
        root.findViewById<Button>(R.id.btn_play).setOnClickListener { playSequence() }

        root.findViewById<Button>(R.id.btn_output_text).setOnClickListener {
            if (isRecording) { currentSteps.add(RecordedStep("outputText", "杈撳嚭鏂囧瓧")); updateRecordButton(); showToast("馃摑 宸插綍鍒? 杈撳嚭鏂囧瓧") }
            else { scope.launch { val record = dataEngine.getCurrentRecord() ?: return@launch; tapService?.injectText(record.text); showToast("馃摑 宸茶緭鍑? \") } }
        }

        root.findViewById<Button>(R.id.btn_output_num).setOnClickListener {
            if (isRecording) { currentSteps.add(RecordedStep("outputNum", "杈撳嚭鏁板瓧")); updateRecordButton(); showToast("馃敘 宸插綍鍒? 杈撳嚭鏁板瓧") }
            else { scope.launch { val record = dataEngine.outputAndAdvance() ?: return@launch; tapService?.appendText(record.number.toString()); updatePanelPreview(); showToast("馃敘 宸茶緭鍑? \") } }
        }

        root.findViewById<Button>(R.id.btn_tap).setOnClickListener {
            if (isRecording) { currentSteps.add(RecordedStep("tap", "鐐瑰嚮(540,1400)", 540f, 1400f)); updateRecordButton(); showToast("馃幆 宸插綍鍒? 鍧愭爣鐐瑰嚮") }
            else { tapService?.tapAt(540f, 1400f); showToast("馃幆 宸茬偣鍑?(540, 1400)") }
        }

        root.findViewById<Button>(R.id.btn_clear).setOnClickListener {
            if (isRecording) { currentSteps.clear(); updateRecordButton(); showToast("馃棏 宸叉竻绌哄綍鍒舵楠?) }
            else { scope.launch { dataEngine.rollback(); updatePanelPreview(); showToast("鈫?宸插洖閫€") } }
        }

        root.findViewById<Button>(R.id.btn_reset).setOnClickListener {
            scope.launch { dataEngine.resetToStart(); updatePanelPreview(); showToast("馃攧 宸查噸缃埌绗?鏉?) }
        }

        root.findViewById<Button>(R.id.btn_jump).setOnClickListener { showJumpDialog() }
    }

    private fun showJumpDialog() {
        val builder = AlertDialog.Builder(this)
        builder.setTitle("馃搶 璺宠浆鍒版寚瀹氭暟鎹?)
        val input = EditText(this).apply {
            hint = "杈撳叆缂栧彿 (1 ~ \)"
            inputType = InputType.TYPE_CLASS_NUMBER
        }
        builder.setView(input, 50, 20, 50, 20)
        builder.setPositiveButton("璺宠浆") { _, _ ->
            val number = input.text.toString().toIntOrNull()
            if (number == null) { showToast("鈿狅笍 璇疯緭鍏ユ湁鏁堟暟瀛?); return@setPositiveButton }
            scope.launch {
                if (dataEngine.jumpToNumber(number)) { updatePanelPreview(); showToast("鉁?宸茶烦杞埌绗?\ 鏉?) }
                else { showToast("鈿狅笍 缂栧彿鏃犳晥 (1 ~ \)") }
            }
        }
        builder.setNegativeButton("鍙栨秷", null)
        builder.show()
    }

    private fun toggleRecording() {
        isRecording = !isRecording
        if (!isRecording && currentSteps.isNotEmpty()) saveSequence()
        updateRecordButton()
        showToast(if (isRecording) "馃幆 褰曞埗寮€濮? else "鈴?褰曞埗缁撴潫")
    }

    private fun saveSequence() {
        if (currentSteps.isEmpty()) return
        val gson = Gson(); val json = gson.toJson(currentSteps)
        val prefs = getSharedPreferences("sequences", MODE_PRIVATE)
        val count = prefs.getInt("seq_count", 0)
        prefs.edit().putString("seq_\", json).putInt("seq_count", count + 1).apply()
        currentSteps.clear(); updateSavedSequences(); showToast("馃捑 搴忓垪宸蹭繚瀛?(#\)")
    }

    private fun updateRecordButton() {
        panelView?.findViewById<Button>(R.id.btn_record)?.apply {
            text = if (isRecording) "鈴?鍋滄褰曞埗 (\)" else "馃幆 褰曞埗搴忓垪"
            setBackgroundColor(android.graphics.Color.parseColor(if (isRecording) "#f44336" else "#7B1FA2"))
        }
    }

    private fun updateSavedSequences() {
        val count = getSharedPreferences("sequences", MODE_PRIVATE).getInt("seq_count", 0)
        panelView?.findViewById<TextView>(R.id.tv_seq_count)?.text = "宸蹭繚瀛? \ 涓簭鍒?
    }

    private fun playSequence() {
        if (isPlaying) { stopPlayback = true; return }
        val prefs = getSharedPreferences("sequences", MODE_PRIVATE)
        val count = prefs.getInt("seq_count", 0)
        if (count == 0) { showToast("鈿狅笍 娌℃湁宸蹭繚瀛樼殑搴忓垪"); return }
        val json = prefs.getString("seq_\", null) ?: return
        val steps: List<RecordedStep> = Gson().fromJson(json, object : TypeToken<List<RecordedStep>>() {}.type)
        if (isPanelOpen) { wm.removeView(panelView); panelView = null; isPanelOpen = false }
        floatBall.setRunning(true); isPlaying = true; stopPlayback = false
        showToast("鈻?寮€濮嬫挱鏀?(\ 姝?")
        scope.launch {
            val ts = TapAccessibilityService.instance
            for (i in steps.indices) {
                if (stopPlayback) break
                when (steps[i].type) {
                    "outputText" -> { val r = dataEngine.getCurrentRecord(); if (r != null) ts?.injectText(r.text) }
                    "outputNum" -> { val r = dataEngine.outputAndAdvance(); if (r != null) ts?.appendText(r.number.toString()) }
                    "tap" -> ts?.tapAt(steps[i].x, steps[i].y)
                }
                updatePanelPreview(); delay(300)
            }
            isPlaying = false; floatBall.setRunning(false)
            showToast(if (stopPlayback) "馃洃 宸插仠姝? else "鉁?鎾斁瀹屾垚")
        }
    }

    private fun updatePanelPreview() {
        scope.launch {
            val record = dataEngine.getCurrentRecord()
            val progress = dataEngine.getProgressText()
            val index = dataEngine.getCurrentIndex() + 1
            panelView?.findViewById<TextView>(R.id.tv_preview_text)?.text = "鏂囧瓧: \"
            panelView?.findViewById<TextView>(R.id.tv_preview_num)?.text = "鏁板瓧: \"
            panelView?.findViewById<TextView>(R.id.tv_progress)?.text = "杩涘害: \"
            panelView?.findViewById<TextView>(R.id.tv_current_index)?.text = "褰撳墠: 绗?\ 鏉?
        }
    }

    private fun showToast(msg: String) { Toast.makeText(this, msg, Toast.LENGTH_SHORT).show() }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, "float_channel")
            .setContentTitle("PDA 褰曞埗宸ュ叿杩愯涓?).setContentText("鎮诞鐞冨凡鏄剧ず")
            .setSmallIcon(android.R.drawable.ic_dialog_info).setOngoing(true).build()
    }

    override fun onDestroy() { super.onDestroy(); scope.cancel(); if (::floatBall.isInitialized) wm.removeView(floatBall); panelView?.let { wm.removeView(it) } }
    override fun onBind(intent: Intent?): IBinder? = null
}
