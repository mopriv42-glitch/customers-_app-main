package com.private_4t.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.util.Log
import android.os.Build
import kotlinx.coroutines.*

class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val serviceIntent = Intent(context, MyForegroundService::class.java)

        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            ConnectivityManager.CONNECTIVITY_ACTION -> {
                Log.d(TAG, "Device boot completed or app updated")
                
                // Check internet connectivity before starting service
                if (isInternetAvailable(context)) {
                    Log.d(TAG, "Internet available, starting service")
                    // Delay to ensure system is ready
                    CoroutineScope(Dispatchers.IO).launch {
                        delay(5000) // 5 second delay
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            context.startForegroundService(serviceIntent)
                        } else {
                            context.startService(serviceIntent)
                        }
                    }
                } else {
                    Log.d(TAG, "No internet connection, service will start when available")
                    // Register connectivity listener to start service when internet becomes available
                    registerConnectivityListener(context)
                }
            }
        }
    }

    private fun isInternetAvailable(context: Context): Boolean {
        return try {
            val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val network = connectivityManager.activeNetwork ?: return false
            val networkCapabilities = connectivityManager.getNetworkCapabilities(network) ?: return false
            
            networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ||
            networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) ||
            networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET)
        } catch (e: Exception) {
            Log.e(TAG, "Error checking internet connectivity", e)
            false
        }
    }

    private fun registerConnectivityListener(context: Context) {
        try {
            val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val networkCallback = object : ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: android.net.Network) {
                    Log.d(TAG, "Network available, starting service")
                    MyForegroundService.startService(context)
                    connectivityManager.unregisterNetworkCallback(this)
                }
            }
            
            connectivityManager.registerDefaultNetworkCallback(networkCallback)
        } catch (e: Exception) {
            Log.e(TAG, "Error registering connectivity listener", e)
        }
    }
}
