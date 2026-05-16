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
                "鎮诞绐楁湇鍔?,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "PDA 鎮诞绐楀悗鍙版湇鍔?
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
}
