package com.ayeee.blue_print_pos

import android.util.Log

/**
 * Utility class for handling logging across the application
 * Only logs in DEBUG mode for security and performance
 */
object Logger {
    private const val TAG = "BluePrintPos"
    
    fun log(message: String, throwable: Throwable? = null) {
        if (BuildConfig.DEBUG) {
            Log.d(TAG, message, throwable)
        }
    }

    fun error(message: String, throwable: Throwable? = null) {
        if (BuildConfig.DEBUG) {
            Log.e(TAG, message, throwable)
        }
    }

    fun warning(message: String, throwable: Throwable? = null) {
        if (BuildConfig.DEBUG) {
            Log.w(TAG, message, throwable)
        }
    }

    fun info(message: String, throwable: Throwable? = null) {
        if (BuildConfig.DEBUG) {
            Log.i(TAG, message, throwable)
        }
    }
}