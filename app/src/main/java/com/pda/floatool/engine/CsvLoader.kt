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
                android.util.Log.e("CsvLoader", "CSV瀵煎叆澶辫触: ")
            }
        }
    }
}
