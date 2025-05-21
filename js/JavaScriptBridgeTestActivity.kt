package com.example.legacyviewdemo

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.os.Bundle
import android.view.accessibility.AccessibilityManager
import android.webkit.WebChromeClient
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.appbar.MaterialToolbar

class JavaScriptBridgeTestActivity : AppCompatActivity() {
    private lateinit var toolbar: MaterialToolbar
    private lateinit var webView: WebView
    private lateinit var accessibilityManager: AccessibilityManager
    private var talkBackEnabled: Boolean = false
    private var pageLoaded = false

    private val webViewUrl = "https://khsruru.com/javascript_bridge/#"

    private val touchExplorationListener = AccessibilityManager.TouchExplorationStateChangeListener { enabled ->
        talkBackEnabled = enabled
        sendTalkBackStatusToWebView()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_javascript_bridge_test)

        toolbar = findViewById(R.id.toolbar)
        setSupportActionBar(toolbar)
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
        supportActionBar?.setDisplayShowHomeEnabled(true)
        toolbar.setNavigationOnClickListener { onBackPressed() }

        webView = findViewById(R.id.webView)
        webView.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            loadWithOverviewMode = true
            useWideViewPort = true
            builtInZoomControls = false
            displayZoomControls = false
        }
        webView.webViewClient = object : WebViewClient() {
            override fun onPageFinished(view: WebView?, url: String?) {
                super.onPageFinished(view, url)
                pageLoaded = true
                sendTalkBackStatusToWebView()
            }
        }
        webView.webChromeClient = WebChromeClient()
        webView.loadUrl(webViewUrl)

        accessibilityManager = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        talkBackEnabled = accessibilityManager.isTouchExplorationEnabled
        sendTalkBackStatusToWebView() // 앱 시작 시 현재 상태 전달
    }

    override fun onResume() {
        super.onResume()
        accessibilityManager.addTouchExplorationStateChangeListener(touchExplorationListener)
        // onResume 시점에 페이지가 이미 로드되었으면 다시 JS 메시지 전달
        sendTalkBackStatusToWebView()
    }

    override fun onPause() {
        super.onPause()
        accessibilityManager.removeTouchExplorationStateChangeListener(touchExplorationListener)
    }

    private fun sendTalkBackStatusToWebView() {
        if (!pageLoaded) return
        val js = if (talkBackEnabled) {
            "window.onAccessibilityStatusChanged({ voiceOver: false, talkBack: true });"
        } else {
            "window.onAccessibilityStatusChanged({ voiceOver: false, talkBack: false });"
        }
        webView.evaluateJavascript(js) { result ->
            // 디버깅용: JS 실행 결과 로그 출력
            android.util.Log.d("JSBridge", "evaluateJavascript result: $result")
        }
    }

    override fun onBackPressed() {
        if (webView.canGoBack()) {
            webView.goBack()
        } else {
            super.onBackPressed()
        }
    }
}
