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
        val newText = if (current.isNotEmpty()) "\n" else text
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
