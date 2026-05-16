package com.pda.floatool

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import com.pda.floatool.engine.DataCycleEngine
import com.pda.floatool.service.FloatService
import kotlinx.coroutines.*

class MainActivity : AppCompatActivity() {

    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private val dataEngine by lazy { DataCycleEngine(this) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        findViewById<Button>(R.id.btn_overlay).setOnClickListener {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                startActivity(Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:")
                ))
            }
        }

        findViewById<Button>(R.id.btn_accessibility).setOnClickListener {
            startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
        }

        findViewById<Button>(R.id.btn_start).setOnClickListener {
            if (checkPermissions()) {
                startFloatService()
            } else {
                showPermissionDialog()
            }
        }

        scope.launch {
            dataEngine.init()
            val progress = dataEngine.getProgressText()
            findViewById<TextView>(R.id.tv_status).text = "鉁?鏁版嵁宸插氨缁? "
        }
    }

    private fun startFloatService() {
        val intent = Intent(this, FloatService::class.java)
        startForegroundService(intent)
        Toast.makeText(this, "鎮诞绐楀凡鍚姩", Toast.LENGTH_SHORT).show()
        finish()
    }

    private fun checkPermissions(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(this)) return false
        }
        return true
    }

    private fun showPermissionDialog() {
        AlertDialog.Builder(this)
            .setTitle("闇€瑕佹潈闄?)
            .setMessage("璇峰厛寮€鍚€屾偓娴獥銆嶆潈闄愶紝骞跺湪绯荤粺璁剧疆涓紑鍚€屾棤闅滅鏈嶅姟銆?)
            .setPositiveButton("鍘昏缃?) { _, _ ->
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    startActivity(Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:")
                    ))
                }
            }
            .setNegativeButton("鍙栨秷", null)
            .show()
    }

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
    }
}
