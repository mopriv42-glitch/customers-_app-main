-keep class com.github.chinloyal.pusher_client.** { *; }
-keep class com.hiennv.flutter_callkit_incoming.** { *; }
-keep class org.jni_zero.** { *; }
-dontwarn org.jni_zero.**

# ============================================
# FIREBASE RULES - CRITICAL FOR RELEASE BUILDS
# ============================================
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Keep Firebase Messaging
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.iid.** { *; }

# ============================================
# GSON RULES - REQUIRED FOR JSON PARSING  
# ============================================
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# ============================================
# FLUTTER RULES
# ============================================
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# Keep Flutter background callbacks
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.firebase.messaging.** { *; }

# Pusher Channels Flutter
-keep class com.pusher.** { *; }
-keep class org.java_websocket.** { *; }
-dontwarn com.pusher.**
-dontwarn org.java_websocket.**

# SLF4J (used by Pusher)
-keep class org.slf4j.** { *; }
-dontwarn org.slf4j.**
-dontwarn org.slf4j.impl.**

# Keep all annotations
-keepattributes *Annotation*

# Keep Pusher event classes
-keepclassmembers class * {
    @com.pusher.** *;
}