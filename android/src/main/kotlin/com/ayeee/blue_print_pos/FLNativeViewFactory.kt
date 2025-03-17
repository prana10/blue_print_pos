package com.ayeee.blue_print_pos

import android.content.Context
import android.view.View
import android.webkit.WebView
import android.webkit.WebSettings
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class FLNativeViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as? Map<String?, Any?>
        return FLNativeView(context, viewId, creationParams)
    }
}

internal class FLNativeView(
    context: Context,
    id: Int,
    private val creationParams: Map<String?, Any?>?
) : PlatformView {
    private val webView: WebView = WebView(context).apply {
        setupWebView()
    }

    override fun getView(): View = webView

    override fun dispose() {
        webView.destroy()
    }

    init {
        try {
            initializeWebView()
        } catch (e: Exception) {
            Logger.log("Error initializing WebView: ${e.message}")
        }
    }

    private fun initializeWebView() {
        creationParams?.let { params ->
            val width = (params["width"] as? Number)?.toInt() 
                ?: throw IllegalArgumentException("Width must not be null")
            val height = (params["height"] as? Number)?.toInt() 
                ?: throw IllegalArgumentException("Height must not be null")
            val content = params["content"] as? String 
                ?: throw IllegalArgumentException("Content must not be null")

            webView.layout(0, 0, width, height)
            webView.loadDataWithBaseURL(null, content, "text/HTML", "UTF-8", null)
        } ?: throw IllegalArgumentException("Creation params must not be null")
    }

    private fun WebView.setupWebView() {
        setInitialScale(1)
        settings.apply {
            javaScriptEnabled = true
            useWideViewPort = true
            javaScriptCanOpenWindowsAutomatically = true
            loadWithOverviewMode = true
            // Additional security settings
            allowFileAccess = false
            allowContentAccess = false
            allowFileAccessFromFileURLs = false
            allowUniversalAccessFromFileURLs = false
        }
    }
}
