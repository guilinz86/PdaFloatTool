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
        return " / "
    }

    fun getCache(): List<DataRecord>? = cache
}
