-keep class com.github.chinloyal.pusher_client.** { *; }
-keep class com.hiennv.flutter_callkit_incoming.** { *; }
-keep class org.jni_zero.** { *; }
-dontwarn org.jni_zero.**

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