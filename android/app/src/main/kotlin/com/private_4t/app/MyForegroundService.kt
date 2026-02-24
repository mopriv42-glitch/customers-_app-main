package com.private_4t.app

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*

class MyForegroundService : Service() {

    companion object {
        const val TAG = "ForegroundService"
        const val CHANNEL_ID = "matrix_sync_service"
        const val METHOD_CHANNEL = "com.private-4t.service"

        var methodChannel: MethodChannel? = null
        var flutterEngine: FlutterEngine? = null

        fun startService(context: Context) {
            val intent = Intent(context, MyForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }

    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    override fun onCreate() {
        super.onCreate()
        startForegroundServiceSilent()
        initFlutterEngine()
        Log.d(TAG, "Service created")
    }

    private fun startForegroundServiceSilent() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Matrix Sync Service",
                NotificationManager.IMPORTANCE_NONE
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }

        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.logo)
            .setPriority(NotificationCompat.PRIORITY_MIN) // يخليه غير مزعج
            .setCategory(Notification.CATEGORY_SERVICE)
            .setSilent(true)
            .build()

        startForeground(1, notification)
    }

    private fun initFlutterEngine() {
        flutterEngine = FlutterEngineCache.getInstance().get("background_engine")
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            methodChannel = MethodChannel(messenger, METHOD_CHANNEL)
        }
        // فوراً إرسال رسالة للـ Flutter
        methodChannel?.invokeMethod("onServiceStarted", "Service running")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startMatrixSyncLoop()
        return START_STICKY // إعادة التشغيل تلقائياً إذا تم قتل الخدمة
    }

    private fun startMatrixSyncLoop() {
        try {
            serviceScope.launch {
                while (isActive) {
                    if (isInternetAvailable()) {
                        // إرسال رسالة للفلاتر لتشغيل المزامنة
                        withContext(Dispatchers.Main) {
                            methodChannel?.invokeMethod("startMatrixSync", null)
                            Log.d(TAG, "Request Flutter to sync Matrix")
                        }
                    }
                    delay(60_000L) // كل دقيقة
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun isInternetAvailable(): Boolean {
        return try {
            val command = "ping -c 1 google.com"
            val process = Runtime.getRuntime().exec(command)
            process.waitFor() == 0
        } catch (e: Exception) {
            false
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        serviceScope.cancel()
        methodChannel = null
    }
}