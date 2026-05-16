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
