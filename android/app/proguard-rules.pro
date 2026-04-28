# Pass #4 - keep rules so R8 doesn't strip classes Flutter / Firebase /
# SignalR rely on via reflection.

# Flutter / Dart embedding
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Play services (used by FCM token retrieval)
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# SignalR (signalr_netcore) uses reflection on its protocol classes
-keep class com.microsoft.signalr.** { *; }
-dontwarn com.microsoft.signalr.**

# OkHttp / Retrofit (Dio uses native http; safe defaults)
-dontwarn okhttp3.**
-dontwarn okio.**

# WebView JS interfaces (we don't use any but plugin includes them)
-keepattributes JavascriptInterface

# Keep generic signatures for Gson-style JSON if any plugin reflects
-keepattributes Signature
-keepattributes *Annotation*

# Strip log lines in release (cheap perf + smaller APK)
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
