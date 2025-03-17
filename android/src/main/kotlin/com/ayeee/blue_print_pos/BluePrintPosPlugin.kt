package com.ayeee.blue_print_pos

import android.app.Activity
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.WindowInsets
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import com.ayeee.blue_print_pos.extension.toBitmap
import com.ayeee.blue_print_pos.extension.toByteArray
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** BluePrintPosPlugin */
class BluePrintPosPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var activity: Activity
    private lateinit var context: Context
    private lateinit var webView: WebView

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        val viewID = "webview-view-type"
        flutterPluginBinding.platformViewRegistry.registerViewFactory(viewID, FLNativeViewFactory())

        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "blue_print_pos")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        val arguments = call.arguments as Map<*, *>
        val content = arguments["content"] as String
        val duration = arguments["duration"] as Double?

        if (call.method == "contentToImage") {
            webView = WebView(this.context)
            val (dWidth, dHeight) = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                getWindowMetricsR(activity)
            } else {
                getWindowMetricsLegacy(activity)
            }

            Logger.log("\ndwidth : $dWidth")
            Logger.log("\ndheight : $dHeight")
            
            setupWebView(dWidth, dHeight, content)
            configureWebViewSettings()

            webView.webViewClient = createWebViewClient(result, duration)
        } else {
            result.notImplemented()
        }
    }

    private fun setupWebView(width: Int, height: Int, content: String) {
        webView.layout(0, 0, width, height)
        webView.loadDataWithBaseURL(null, content, "text/HTML", "UTF-8", null)
        webView.setInitialScale(1)
    }

    private fun configureWebViewSettings() {
        webView.settings.apply {
            javaScriptEnabled = true
            useWideViewPort = true
            javaScriptCanOpenWindowsAutomatically = true
            loadWithOverviewMode = true
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            Logger.log("\n=======> enabled scrolled <=========")
            WebView.enableSlowWholeDocumentDraw()
        }
        Logger.log("\n ///////////////// webview setted /////////////////")
    }

    private fun createWebViewClient(result: Result, duration: Double?): WebViewClient {
        return object : WebViewClient() {
            override fun onPageFinished(view: WebView, url: String) {
                super.onPageFinished(view, url)
                handlePageFinished(view, result, duration)
            }
        }
    }

    private fun handlePageFinished(view: WebView, result: Result, duration: Double?) {
        Handler(Looper.getMainLooper()).postDelayed({
            Logger.log("\n ================ webview completed ==============")
            Logger.log("\n scroll delayed ${webView.scrollBarFadeDuration}")

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                captureWebViewContent(view, result)
            }
        }, (duration ?: 0.0).toLong())
    }

    private fun captureWebViewContent(view: WebView, result: Result) {
        view.evaluateJavascript("document.body.offsetWidth") { offsetWidth ->
            view.evaluateJavascript("document.body.offsetHeight") { offsetHeight ->
                Logger.log("\noffsetWidth : $offsetWidth")
                Logger.log("\noffsetHeight : $offsetHeight")
                
                if (offsetWidth != null && offsetWidth.isNotEmpty() && 
                    offsetHeight != null && offsetHeight.isNotEmpty()) {
                    processWebViewSnapshot(offsetWidth.toDouble(), offsetHeight.toDouble(), result)
                }
            }
        }
    }

    private fun processWebViewSnapshot(width: Double, height: Double, result: Result) {
        val bitmap = webView.toBitmap(width, height)
        bitmap?.let {
            val bytes = it.toByteArray()
            result.success(bytes)
            Logger.log("\n Got snapshot")
        }
    }

    @RequiresApi(Build.VERSION_CODES.R)
    private fun getWindowMetricsR(activity: Activity): Pair<Int, Int> {
        val windowMetrics = activity.windowManager.currentWindowMetrics
        val insets = windowMetrics.windowInsets
            .getInsetsIgnoringVisibility(WindowInsets.Type.systemBars())
        val width = windowMetrics.bounds.width() - insets.left - insets.right
        val height = windowMetrics.bounds.height() - insets.bottom - insets.top
        return Pair(width, height)
    }

    @Suppress("DEPRECATION")
    private fun getWindowMetricsLegacy(activity: Activity): Pair<Int, Int> {
        val display = activity.windowManager.defaultDisplay
        return Pair(display.width, display.height)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Logger.log("onAttachedToActivity")
        activity = binding.activity
        webView = WebView(activity.applicationContext)
        webView.minimumHeight = 1
        webView.minimumWidth = 1
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Logger.log("onDetachedFromActivityForConfigChanges")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Logger.log("onAttachedToActivity")
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        Logger.log("onDetachedFromActivity")
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
