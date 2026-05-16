package com.pda.floatool.model

data class RecordedStep(
    val type: String,
    val label: String = "",
    val x: Float = 0f,
    val y: Float = 0f
)
