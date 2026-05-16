# generate.ps1 - PDA Float Tool 项目生成器
# 在桌面的 PdaFloatTool 文件夹中运行

Write-Host "正在生成 PDA 录制工具项目..." -ForegroundColor Green

# 创建目录结构
$dirs = @(
    "app\src\main\java\com\pda\floatool\data",
    "app\src\main\java\com\pda\floatool\engine",
    "app\src\main\java\com\pda\floatool\service",
    "app\src\main\java\com\pda\floatool\model",
    "app\src\main\res\layout",
    "app\src\main\res\values",
    "app\src\main\res\xml",
    "app\src\main\assets",
    "gradle\wrapper"
)

foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

# ========== 生成所有文件 ==========

# 1. settings.gradle.kts
@"
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "PdaFloatTool"
include(":app")
"@ | Out-File -FilePath "settings.gradle.kts" -Encoding UTF8

# 2. build.gradle.kts (项目级)
@"
plugins {
    id("com.android.application") version "8.2.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.20" apply false
}
"@ | Out-File -FilePath "build.gradle.kts" -Encoding UTF8

# 3. gradle.properties
@"
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
kotlin.code.style=official
android.nonTransitiveRClass=true
"@ | Out-File -FilePath "gradle.properties" -Encoding UTF8

# 4. gradle-wrapper.properties
@"
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.2-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
"@ | Out-File -FilePath "gradle\wrapper\gradle-wrapper.properties" -Encoding UTF8

# 5. app/build.gradle.kts
@"
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.pda.floatool"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.pda.floatool"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")

    // Room
    implementation("androidx.room:room-runtime:2.6.1")
    implementation("androidx.room:room-ktx:2.6.1")
    annotationProcessor("androidx.room:room-compiler:2.6.1")

    // DataStore
    implementation("androidx.datastore:datastore-preferences:1.0.0")

    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")

    // Lifecycle
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")

    // Gson
    implementation("com.google.code.gson:gson:2.10.1")
}
"@ | Out-File -FilePath "app\build.gradle.kts" -Encoding UTF8

# 6. proguard-rules.pro
@"
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.pda.floatool.model.** { *; }
-keep class com.pda.floatool.data.** { *; }
"@ | Out-File -FilePath "app\proguard-rules.pro" -Encoding UTF8

# 7. AndroidManifest.xml
@"
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <application
        android:name=".PdaApp"
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="PDA录制工具"
        android:supportsRtl="true"
        android:theme="@style/Theme.PdaFloatTool">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:theme="@style/Theme.PdaFloatTool">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <service
            android:name=".service.FloatService"
            android:foregroundServiceType="dataSync"
            android:exported="false" />

        <service
            android:name=".service.TapAccessibilityService"
            android:exported="true"
            android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE">
            <intent-filter>
                <action android:name="android.accessibilityservice.AccessibilityService" />
            </intent-filter>
            <meta-data
                android:name="android.accessibilityservice"
                android:resource="@xml/accessibility_service_config" />
        </service>
    </application>
</manifest>
"@ | Out-File -FilePath "app\src\main\AndroidManifest.xml" -Encoding UTF8

# 8. PdaApp.kt
@"
package com.pda.floatool

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build

class PdaApp : Application() {
    companion object {
        lateinit var instance: PdaApp
            private set
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "float_channel",
                "悬浮窗服务",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "PDA 悬浮窗后台服务"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
}
"@ | Out-File -FilePath "app\src\main\java\com\pda\floatool\PdaApp.kt" -Encoding UTF8

# 9. MainActivity.kt
@"
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
                    Uri.parse("package:$packageName")
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
            findViewById<TextView>(R.id.tv_status).text = "✅ 数据已就绪: $progress"
        }
    }

    private fun startFloatService() {
        val intent = Intent(this, FloatService::class.java)
        startForegroundService(intent)
        Toast.makeText(this, "悬浮窗已启动", Toast.LENGTH_SHORT).show()
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
            .setTitle("需要权限")
            .setMessage("请先开启「悬浮窗」权限，并在系统设置中开启「无障碍服务」")
            .setPositiveButton("去设置") { _, _ ->
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    startActivity(Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:$packageName")
                    ))
                }
            }
            .setNegativeButton("取消", null)
            .show()
    }

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
    }
}
"@ | Out-File -FilePath "app\src\main\java\com\pda\floatool\MainActivity.kt" -Encoding UTF8

# 10. DataRecord.kt
@"
package com.pda.floatool.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "data_records")
data class DataRecord(
    @PrimaryKey val id: Int,
    val text: String,
    val number: Int
)
"@ | Out-File -FilePath "app\src\main\java\com\pda\floatool\data\DataRecord.kt" -Encoding UTF8

# 11. DataRecordDao.kt
@"
package com.pda.floatool.data

import androidx.room.*

@Dao
interface DataRecordDao {
    @Query("SELECT * FROM data_records WHERE id = :index LIMIT 1")
    suspend fun getByIndex(index: Int): DataRecord?

    @Query("SELECT COUNT(*) FROM data_records")
    suspend fun count(): Int

    @Query("SELECT * FROM data_records ORDER BY id ASC")
    suspend fun getAll(): List<DataRecord>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(records: List<DataRecord>)

    @Query("DELETE FROM data_records")
    suspend fun clearAll()
}
"@ | Out-File -FilePath "app\src\main\java\com\pda\floatool\data\DataRecordDao.kt" -Encoding UTF8

# 12. AppDatabase.kt
@"
package com.pda.floatool.data

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(entities = [DataRecord::class], version = 1, exportSchema = false)
abstract class AppDatabase : RoomDatabase() {
    abstract fun dataRecordDao(): DataRecordDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getInstance(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "pda_float_db"
                ).fallbackToDestructiveMigration().build()
                INSTANCE = instance
                instance
            }
        }
    }
}
"@ | Out-File -FilePath "app\src\main\java\com\pda\floatool\data\AppDatabase.kt" -Encoding UTF8

# 13. CsvLoader.kt
@"
package com.pda.floatool.engine

import android.content.Context
import com.pda.floatool.data.AppDatabase
import com.pda.floatool.data.DataRecord
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.BufferedReader
import java.io.InputStreamReader

class CsvLoader(private val context: Context) {

    suspend fun loadToDatabase(csvFileName: String = "data_30000.csv") {
        val dao = AppDatabase.getInstance(context).dataRecordDao()
        if (dao.count() > 0) return

        withContext(Dispatchers.IO) {
            val records = mutableListOf<DataRecord>()
            var index = 0
            try {
                val inputStream = context.assets.open(csvFileName)
                val reader = BufferedReader(InputStreamReader(inputStream))
                reader.use { r ->
                    r.forEachLine { line ->
                        if (line.isNotBlank()) {
                            val parts = line.split(",", limit = 2)
                            val text = parts[0].trim()
                            val number = parts.getOrNull(1)?.trim()?.toIntOrNull() ?: (index + 1)
                            records.add(DataRecord(id = index++, text = text, number = number))
                            if (records.size >= 500) {
                                dao.insertAll(records.toList())
                                records.clear()
                            }
                        }
                    }
                    if (records.isNotEmpty()) dao.insertAll(records.toList())
                }
            } catch (e: Exception) {
                android.util.Log.e("CsvLoader", "CSV导入失败: ${e.message}")
            }
        }
    }
}
"@ | Out-File -FilePath "app\src\main\java\com\pda\floatool\engine\CsvLoader.kt" -Encoding UTF8

# 14. DataCycleEngine.kt
@"
package com.pda.floatool.engine

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.pda.floatool.data.AppDatabase
import com.pda.floatool.data.DataRecord
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map

private val Context.dataStore by preferencesDataStore(name = "cycle_prefs")

class DataCycleEngine(private val context: Context) {

    private val dao = AppDatabase.getInstance(context).dataRecordDao()
    private val POSITION_KEY = intPreferencesKey("current_index")
    private var cache: List<DataRecord>? = null
    private var total: Int = 0

    suspend fun init() {
        CsvLoader(context).loadToDatabase()
        cache = dao.getAll()
        total = cache?.size ?: 0
    }

    suspend fun getCurrentRecord(): DataRecord? {
        val index = getCurrentIndex()
        return cache?.getOrNull(index) ?: dao.getByIndex(index)
    }

    suspend fun getCurrentIndex(): Int {
        return context.dataStore.data.map { prefs -> prefs[POSITION_KEY] ?: 0 }.first()
    }

    suspend fun getTotal(): Int = total

    suspend fun outputAndAdvance(): DataRecord? {
        val record = getCurrentRecord() ?: return null
        val index = getCurrentIndex()
        val next = if (index + 1 >= total) 0 else index + 1
        context.dataStore.edit { prefs -> prefs[POSITION_KEY] = next }
        return record
    }

    suspend fun rollback() {
        val index = getCurrentIndex()
        val prev = if (index <= 0) total - 1 else index - 1
        context.dataStore.edit { prefs -> prefs[POSITION_KEY] = prev }
    }

    suspend fun resetToStart() {
        context.dataStore.edit { prefs -> prefs[POSITION_KEY] = 0 }
    }

    suspend fun jumpToNumber(targetNumber: Int): Boolean {
        val targetIndex = targetNumber - 1
        if (targetIndex < 0 || targetIndex >= total) return false
        context.dataStore.edit { prefs -> prefs[POSITION_KEY] = targetIndex }
        return true
    }

    suspend fun getProgressText(): String {
        val pos = getCurrentIndex()
        return "${pos + 1} / $total"
    }

    fun getCache(): List<DataRecord>? = cache
}
"@ | Out-File -FilePath "app\src\main\java\com\pda\floatool\engine\DataCycleEngine.kt" -Encoding UTF8

# 15. RecordedStep.kt
@"
package com.pda.floatool.model

data class RecordedStep(
    val type: String,
    val label: String = "",
    val x: Float = 0f,
    val y: Float = 0f
)
"@ | Out-File -FilePath "app\src\main\java\com\pda\floatool\model\RecordedStep.kt" -Encoding UTF8

# 16. FloatBallView.kt
@"
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
"@ | Out-File -FilePath "app\src\main\java\com\pda\floatool\service\FloatBallView.kt" -Encoding UTF8

# 17. TapAccessibilityService.kt
@"
package com.pda.floatool.service

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.os.Build
import android.os.Bundle
import android.view.accessibility.AccessibilityNodeInfo
import androidx.annotation.RequiresApi

@RequiresApi(Build.VERSION_CODES.N)
class TapAccessibilityService : AccessibilityService() {

    companion object { var instance: TapAccessibilityService? = null }

    override fun onServiceConnected() { super.onServiceConnected(); instance = this }
    override fun onAccessibilityEvent(event: android.view.accessibility.AccessibilityEvent?) {}
    override fun onInterrupt() {}

    fun tapAt(x: Float, y: Float) {
        val path = Path().apply { moveTo(x, y); lineTo(x, y) }
        dispatchGesture(GestureDescription.Builder().apply {
            addStroke(GestureDescription.StrokeDescription(path, 0, 1))
        }.build(), null, null)
    }

    fun injectText(text: String) {
        val root = rootInActiveWindow ?: return
        val focused = findFocusedInput(root) ?: return
        val args = Bundle().apply {
            putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, text)
        }
        focused.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
    }

    fun appendText(text: String) {
        val root = rootInActiveWindow ?: return
        val focused = findFocusedInput(root) ?: return
        val current = focused.text?.toString() ?: ""
        val newText = if (current.isNotEmpty()) "$current\n$text" else text
        val args = Bundle().apply {
            putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, newText)
        }
        focused.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
    }

    private fun findFocusedInput(node: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        if (node.isEditable && node.isFocused) return node
        for (i in 0 until node.childCount) {
            node.getChild(i)?.let { child ->
                findFocusedInput(child)?.let { return it }
            }
        }
        return null
    }
}
"@ | Out-File -FilePath "app\src\main\java\com\pda\floatool\service\TapAccessibilityService.kt" -Encoding UTF8

# 18. FloatService.kt
@"
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
            if (isRecording) { currentSteps.add(RecordedStep("outputText", "输出文字")); updateRecordButton(); showToast("📝 已录制: 输出文字") }
            else { scope.launch { val record = dataEngine.getCurrentRecord() ?: return@launch; tapService?.injectText(record.text); showToast("📝 已输出: \${record.text}") } }
        }

        root.findViewById<Button>(R.id.btn_output_num).setOnClickListener {
            if (isRecording) { currentSteps.add(RecordedStep("outputNum", "输出数字")); updateRecordButton(); showToast("🔢 已录制: 输出数字") }
            else { scope.launch { val record = dataEngine.outputAndAdvance() ?: return@launch; tapService?.appendText(record.number.toString()); updatePanelPreview(); showToast("🔢 已输出: \${record.number}") } }
        }

        root.findViewById<Button>(R.id.btn_tap).setOnClickListener {
            if (isRecording) { currentSteps.add(RecordedStep("tap", "点击(540,1400)", 540f, 1400f)); updateRecordButton(); showToast("🎯 已录制: 坐标点击") }
            else { tapService?.tapAt(540f, 1400f); showToast("🎯 已点击 (540, 1400)") }
        }

        root.findViewById<Button>(R.id.btn_clear).setOnClickListener {
            if (isRecording) { currentSteps.clear(); updateRecordButton(); showToast("🗑 已清空录制步骤") }
            else { scope.launch { dataEngine.rollback(); updatePanelPreview(); showToast("↩ 已回退") } }
        }

        root.findViewById<Button>(R.id.btn_reset).setOnClickListener {
            scope.launch { dataEngine.resetToStart(); updatePanelPreview(); showToast("🔄 已重置到第1条") }
        }

        root.findViewById<Button>(R.id.btn_jump).setOnClickListener { showJumpDialog() }
    }

    private fun showJumpDialog() {
        val builder = AlertDialog.Builder(this)
        builder.setTitle("📌 跳转到指定数据")
        val input = EditText(this).apply {
            hint = "输入编号 (1 ~ \${dataEngine.getTotal()})"
            inputType = InputType.TYPE_CLASS_NUMBER
        }
        builder.setView(input, 50, 20, 50, 20)
        builder.setPositiveButton("跳转") { _, _ ->
            val number = input.text.toString().toIntOrNull()
            if (number == null) { showToast("⚠️ 请输入有效数字"); return@setPositiveButton }
            scope.launch {
                if (dataEngine.jumpToNumber(number)) { updatePanelPreview(); showToast("✅ 已跳转到第 \$number 条") }
                else { showToast("⚠️ 编号无效 (1 ~ \${dataEngine.getTotal()})") }
            }
        }
        builder.setNegativeButton("取消", null)
        builder.show()
    }

    private fun toggleRecording() {
        isRecording = !isRecording
        if (!isRecording && currentSteps.isNotEmpty()) saveSequence()
        updateRecordButton()
        showToast(if (isRecording) "🎯 录制开始" else "⏹ 录制结束")
    }

    private fun saveSequence() {
        if (currentSteps.isEmpty()) return
        val gson = Gson(); val json = gson.toJson(currentSteps)
        val prefs = getSharedPreferences("sequences", MODE_PRIVATE)
        val count = prefs.getInt("seq_count", 0)
        prefs.edit().putString("seq_\$count", json).putInt("seq_count", count + 1).apply()
        currentSteps.clear(); updateSavedSequences(); showToast("💾 序列已保存 (#\${count + 1})")
    }

    private fun updateRecordButton() {
        panelView?.findViewById<Button>(R.id.btn_record)?.apply {
            text = if (isRecording) "⏹ 停止录制 (\${currentSteps.size})" else "🎯 录制序列"
            setBackgroundColor(android.graphics.Color.parseColor(if (isRecording) "#f44336" else "#7B1FA2"))
        }
    }

    private fun updateSavedSequences() {
        val count = getSharedPreferences("sequences", MODE_PRIVATE).getInt("seq_count", 0)
        panelView?.findViewById<TextView>(R.id.tv_seq_count)?.text = "已保存: \$count 个序列"
    }

    private fun playSequence() {
        if (isPlaying) { stopPlayback = true; return }
        val prefs = getSharedPreferences("sequences", MODE_PRIVATE)
        val count = prefs.getInt("seq_count", 0)
        if (count == 0) { showToast("⚠️ 没有已保存的序列"); return }
        val json = prefs.getString("seq_\${count - 1}", null) ?: return
        val steps: List<RecordedStep> = Gson().fromJson(json, object : TypeToken<List<RecordedStep>>() {}.type)
        if (isPanelOpen) { wm.removeView(panelView); panelView = null; isPanelOpen = false }
        floatBall.setRunning(true); isPlaying = true; stopPlayback = false
        showToast("▶ 开始播放 (\${steps.size} 步)")
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
            showToast(if (stopPlayback) "🛑 已停止" else "✅ 播放完成")
        }
    }

    private fun updatePanelPreview() {
        scope.launch {
            val record = dataEngine.getCurrentRecord()
            val progress = dataEngine.getProgressText()
            val index = dataEngine.getCurrentIndex() + 1
            panelView?.findViewById<TextView>(R.id.tv_preview_text)?.text = "文字: \${record?.text ?: "---"}"
            panelView?.findViewById<TextView>(R.id.tv_preview_num)?.text = "数字: \${record?.number?.toString() ?: "---"}"
            panelView?.findViewById<TextView>(R.id.tv_progress)?.text = "进度: \$progress"
            panelView?.findViewById<TextView>(R.id.tv_current_index)?.text = "当前: 第 \$index 条"
        }
    }

    private fun showToast(msg: String) { Toast.makeText(this, msg, Toast.LENGTH_SHORT).show() }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, "float_channel")
            .setContentTitle("PDA 录制工具运行中").setContentText("悬浮球已显示")
            .setSmallIcon(android.R.drawable.ic_dialog_info).setOngoing(true).build()
    }

    override fun onDestroy() { super.onDestroy(); scope.cancel(); if (::floatBall.isInitialized) wm.removeView(floatBall); panelView?.let { wm.removeView(it) } }
    override fun onBind(intent: Intent?): IBinder? = null
}
"@ | Out-File -FilePath "app\src\main\java\com\pda\floatool\service\FloatService.kt" -Encoding UTF8

# 19. activity_main.xml
@"
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="24dp"
    android:gravity="center">

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="📦 PDA 录制工具"
        android:textSize="24sp"
        android:textStyle="bold"
        android:layout_marginBottom="8dp"/>

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="悬浮窗 + 数据循环 + 录制播放"
        android:textSize="13sp"
        android:textColor="#888"
        android:layout_marginBottom="32dp"/>

    <TextView
        android:id="@+id/tv_status"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="加载数据中..."
        android:textSize="14sp"
        android:textColor="#666"
        android:layout_marginBottom="32dp"/>

    <Button
        android:id="@+id/btn_overlay"
        android:layout_width="match_parent"
        android:layout_height="52dp"
        android:text="① 开启悬浮窗权限"
        android:textSize="14sp"
        android:layout_marginBottom="12dp"/>

    <Button
        android:id="@+id/btn_accessibility"
        android:layout_width="match_parent"
        android:layout_height="52dp"
        android:text="② 开启无障碍服务"
        android:textSize="14sp"
        android:layout_marginBottom="32dp"/>

    <Button
        android:id="@+id/btn_start"
        android:layout_width="match_parent"
        android:layout_height="56dp"
        android:text="🚀 启动悬浮窗"
        android:backgroundTint="#1976D2"
        android:textColor="@android:color/white"
        android:textSize="17sp"
        android:textStyle="bold"/>
</LinearLayout>
"@ | Out-File -FilePath "app\src\main\res\layout\activity_main.xml" -Encoding UTF8

# 20. float_panel.xml
@"
<?xml version="1.0" encoding="utf-8"?>
<ScrollView xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="280dp"
    android:layout_height="wrap_content"
    android:background="@android:color/white">

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="vertical"
        android:padding="14dp">

        <TextView
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="📋 PDA 录制工具"
            android:textSize="16sp"
            android:textStyle="bold"
            android:layout_gravity="center"
            android:layout_marginBottom="10dp"/>

        <TextView
            android:id="@+id/tv_current_index"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="当前: 第 0 条"
            android:textSize="14sp"
            android:textStyle="bold"
            android:textColor="#E65100"
            android:gravity="center"
            android:padding="6dp"
            android:background="#FFF3E0"
            android:layout_marginBottom="6dp"/>

        <TextView
            android:id="@+id/tv_preview_text"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="文字: ---"
            android:textSize="14sp"
            android:padding="8dp"
            android:background="#E3F2FD"
            android:layout_marginBottom="2dp"/>

        <TextView
            android:id="@+id/tv_preview_num"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="数字: ---"
            android:textSize="14sp"
            android:padding="8dp"
            android:background="#E3F2FD"
            android:layout_marginBottom="2dp"/>

        <TextView
            android:id="@+id/tv_progress"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="进度: 0 / 30000"
            android:textSize="12sp"
            android:textColor="#888"
            android:padding="4dp"
            android:layout_marginBottom="10dp"/>

        <Button
            android:id="@+id/btn_jump"
            android:layout_width="match_parent"
            android:layout_height="40dp"
            android:text="📌 跳转到指定编号"
            android:backgroundTint="#FF9800"
            android:textColor="@android:color/white"
            android:textSize="13sp"
            android:layout_marginBottom="8dp"/>

        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:orientation="horizontal"
            android:layout_marginBottom="8dp">

            <Button
                android:id="@+id/btn_record"
                android:layout_width="0dp"
                android:layout_height="48dp"
                android:layout_weight="1"
                android:text="🎯 录制序列"
                android:backgroundTint="#7B1FA2"
                android:textColor="@android:color/white"
                android:textSize="13sp"
                android:layout_marginEnd="4dp"/>

            <Button
                android:id="@+id/btn_play"
                android:layout_width="0dp"
                android:layout_height="48dp"
                android:layout_weight="1"
                android:text="▶ 播放"
                android:backgroundTint="#1976D2"
                android:textColor="@android:color/white"
                android:textSize="13sp"
                android:layout_marginStart="4dp"/>
        </LinearLayout>

        <TextView
            android:id="@+id/tv_seq_count"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="已保存: 0 个序列"
            android:textSize="11sp"
            android:textColor="#999"
            android:layout_marginBottom="8dp"/>

        <Button
            android:id="@+id/btn_output_text"
            android:layout_width="match_parent"
            android:layout_height="46dp"
            android:text="📝 输出文字"
            android:backgroundTint="#0D47A1"
            android:textColor="@android:color/white"
            android:textSize="14sp"
            android:layout_marginBottom="6dp"/>

        <Button
            android:id="@+id/btn_output_num"
            android:layout_width="match_parent"
            android:layout_height="46dp"
            android:text="🔢 输出数字"
            android:backgroundTint="#00695C"
            android:textColor="@android:color/white"
            android:textSize="14sp"
            android:layout_marginBottom="6dp"/>

        <Button
            android:id="@+id/btn_tap"
            android:layout_width="match_parent"
            android:layout_height="46dp"
            android:text="🎯 坐标点击"
            android:backgroundTint="#7B1FA2"
            android:textColor="@android:color/white"
            android:textSize="14sp"
            android:layout_marginBottom="12dp"/>

        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:orientation="horizontal">

            <Button
                android:id="@+id/btn_clear"
                android:layout_width="0dp"
                android:layout_height="40dp"
                android:layout_weight="1"
                android:text="🗑 清除"
                android:backgroundTint="#9E9E9E"
                android:textColor="@android:color/white"
                android:textSize="12sp"
                android:layout_marginEnd="4dp"/>

            <Button
                android:id="@+id/btn_reset"
                android:layout_width="0dp"
                android:layout_height="40dp"
                android:layout_weight="1"
                android:text="🔄 重置"
                android:backgroundTint="#9E9E9E"
                android:textColor="@android:color/white"
                android:textSize="12sp"
                android:layout_marginStart="4dp"/>
        </LinearLayout>
    </LinearLayout>
</ScrollView>
"@ | Out-File -FilePath "app\src\main\res\layout\float_panel.xml" -Encoding UTF8

# 21. themes.xml
@"
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="Theme.PdaFloatTool" parent="Theme.Material3.DayNight.NoActionBar">
        <item name="colorPrimary">#FF6200EE</item>
        <item name="colorPrimaryVariant">#FF3700B3</item>
        <item name="colorOnPrimary">@android:color/white</item>
    </style>
</resources>
"@ | Out-File -FilePath "app\src\main\res\values\themes.xml" -Encoding UTF8

# 22. strings.xml
@"
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">PDA录制工具</string>
</resources>
"@ | Out-File -FilePath "app\src\main\res\values\strings.xml" -Encoding UTF8

# 23. colors.xml
@"
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="purple_200">#FFBB86FC</color>
    <color name="purple_500">#FF6200EE</color>
    <color name="purple_700">#FF3700B3</color>
    <color name="teal_200">#FF03DAC5</color>
    <color name="teal_700">#FF018786</color>
    <color name="black">#FF000000</color>
    <color name="white">#FFFFFFFF</color>
</resources>
"@ | Out-File -FilePath "app\src\main\res\values\colors.xml" -Encoding UTF8

# 24. accessibility_service_config.xml
@"
<?xml version="1.0" encoding="utf-8"?>
<accessibility-service xmlns:android="http://schemas.android.com/apk/res/android"
    android:accessibilityEventTypes="typeAllMask"
    android:accessibilityFeedbackType="feedbackGeneric"
    android:accessibilityFlags="flagDefault|flagRetrieveInteractiveWindows"
    android:canPerformGestures="true"
    android:canRetrieveWindowContent="true"
    android:description="用于在业务界面模拟点击和输入文本" />
"@ | Out-File -FilePath "app\src\main\res\xml\accessibility_service_config.xml" -Encoding UTF8

# 25. 生成示例数据文件（30000行）
Write-Host "正在生成 30000 条示例数据..." -ForegroundColor Yellow
$prefixes = @('WH','ITEM','BATCH','LINE','ORDER','PACK','LOC','PROD','STORE','SHIP','CODE','REF')
$csvLines = for ($i = 0; $i -lt 30000; $i++) {
    $p = $prefixes[$i % 12]
    $letter = [char](65 + ($i % 26))
    $num = ($i % 1000).ToString("000")
    $year = 2024 + ($i % 3)
    "$p-$letter$num-$year,$($i + 1)"
}
$csvLines | Out-File -FilePath "app\src\main\assets\data_30000.csv" -Encoding UTF8

Write-Host ""
Write-Host "✅ 项目生成完成！" -ForegroundColor Green
Write-Host ""
Write-Host "📁 项目位置: $((Get-Location).Path)" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 下一步操作：" -ForegroundColor Yellow
Write-Host "1. 打开 Android Studio" -ForegroundColor White
Write-Host "2. File → Open → 选择本文件夹" -ForegroundColor White
Write-Host "3. 等待 Gradle 同步完成" -ForegroundColor White
Write-Host "4. 连接 PDA 点击 ▶ Run" -ForegroundColor White
Write-Host ""
Write-Host "或者生成 APK：" -ForegroundColor Yellow
Write-Host "   Build → Build Bundle(s)/APK(s) → Build APK(s)" -ForegroundColor White
Write-Host "   APK 位置: app\build\outputs\apk\debug\app-debug.apk" -ForegroundColor White