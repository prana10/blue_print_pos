package com.ayeee.blue_print_pos.extension

import android.graphics.Bitmap
import java.io.ByteArrayOutputStream

/**
 * Converts a Bitmap to ByteArray using PNG compression
 * @return ByteArray of the compressed bitmap
 * @throws IllegalStateException if compression fails
 */
fun Bitmap.toByteArray(): ByteArray {
    return ByteArrayOutputStream().use { stream ->
        if (!compress(Bitmap.CompressFormat.PNG, 100, stream)) {
            throw IllegalStateException("Failed to compress bitmap")
        }
        stream.toByteArray()
    }
}