package com.pda.floatool.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "data_records")
data class DataRecord(
    @PrimaryKey val id: Int,
    val text: String,
    val number: Int
)
