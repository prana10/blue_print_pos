package com.ayeee.blue_print_pos.extension

import android.graphics.Bitmap
import android.graphics.Canvas
import android.view.View
import android.webkit.WebView
import kotlin.math.absoluteValue

/**
 * Extension function to convert WebView content to Bitmap
 * @param offsetWidth The width of the content in dp
 * @param offsetHeight The height of the content in dp
 * @return Bitmap? Returns null if dimensions are invalid
 */
fun WebView.toBitmap(offsetWidth: Double, offsetHeight: Double): Bitmap? {
    if (!isValidDimensions(offsetWidth, offsetHeight)) return null
    
    return try {
        val metrics = resources.displayMetrics
        val width = (offsetWidth * metrics.density).absoluteValue.toInt()
        val height = (offsetHeight * metrics.density).absoluteValue.toInt()
        
        measureWebView()
        createBitmapFromWebView(width, height)
    } catch (e: Exception) {
        null
    }
}

private fun WebView.isValidDimensions(width: Double, height: Double): Boolean {
    return width > 0 && height > 0
}

private fun WebView.measureWebView() {
    measure(
        View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED),
        View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED)
    )
}

private fun WebView.createBitmapFromWebView(width: Int, height: Int): Bitmap {
    return Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888).also { bitmap ->
        Canvas(bitmap).also { canvas ->
            draw(canvas)
        }
    }
}