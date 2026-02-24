package com.private_4t.app

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.media.AudioManager
import android.util.Log
import android.widget.Toast
import android.app.ActivityManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app_channel"
    private val SERVICE_CHANNEL = "com.private-4t.service"
    private val TOAST_DURATION = 5000
    private var serviceMethodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)



        // Main app channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "showToast" -> {
                    val message: String? = call.argument("message")
                    message?.let { showToast(applicationContext, it) }
                    result.success(null)
                }
                "exitApp" -> {
                    exitApp()
                    result.success(null)
                }
                "minimizeApp" -> {
                    minimizeApp()
                    result.success(null)
                }
                "openApp" -> {
                    openApp()
                    result.success(null)
                }
                "startBackgroundService" -> {
                    startBackgroundService()
                    result.success(null)
                }
                "stopBackgroundService" -> {
                    stopBackgroundService()
                    result.success(null)
                }
                 "isAppInBackground" -> {
                     val isBackground = isAppInBackground(applicationContext)
                      result.success(isBackground)
                }
                "setSpeaker" -> {
                    val on = call.argument<Boolean>("on") ?: false
                    val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    audioManager.mode = if (on) AudioManager.MODE_NORMAL else AudioManager.MODE_IN_COMMUNICATION
                    audioManager.isSpeakerphoneOn = on
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun minimizeApp() {
        moveTaskToBack(true)
    }

    private fun bringToForeground() {
        val intent = Intent(this, MainActivity::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
        startActivity(intent)
    }

    private fun showToast(context: Context, message: String) {
        val toast = Toast.makeText(context, message, Toast.LENGTH_LONG)
        toast.show()
        Handler().postDelayed({ toast.cancel() }, TOAST_DURATION.toLong())
    }

    private fun exitApp() {
        finishAffinity()
    }

    private fun openApp(){
        val intent = Intent(this, MainActivity::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
        startActivity(intent)
    }

    private fun startBackgroundService() {
        try {
            MyForegroundService.startService(this)
            Log.d("MainActivity", "Background service started")
        } catch (e: Exception) {
            Log.e("MainActivity", "Error starting background service", e)
        }
    }

    private fun stopBackgroundService() {
        try {
            val intent = Intent(this, MyForegroundService::class.java)
            stopService(intent)
            Log.d("MainActivity", "Background service stopped")
        } catch (e: Exception) {
            Log.e("MainActivity", "Error stopping background service", e)
        }
    }

    private fun isAppInBackground(context: Context): Boolean {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val runningAppProcesses = activityManager.runningAppProcesses ?: return true

        val packageName = context.packageName
        for (processInfo in runningAppProcesses) {
            if (processInfo.processName == packageName) {
                return processInfo.importance != ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND
            }
        }
        return true
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceMethodChannel = null
    }
}