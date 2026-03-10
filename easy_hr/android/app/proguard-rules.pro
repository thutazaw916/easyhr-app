# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Google Play Services
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }

# Google Play Core (deferred components)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Prevent R8 from stripping interface info
-keepattributes *Annotation*

# OkHttp / OkIO (used by Dio on Android)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Conscrypt (SSL provider)
-dontwarn org.conscrypt.**
-keep class org.conscrypt.** { *; }

# BouncyCastle (SSL)
-dontwarn org.bouncycastle.**
-keep class org.bouncycastle.** { *; }

# OpenJSSE
-dontwarn org.openjsse.**
-keep class org.openjsse.** { *; }

# Gson (JSON parsing)
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes EnclosingMethod

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Keep SSL/TLS classes
-keep class javax.net.ssl.** { *; }
-keep class java.security.** { *; }
-keep class sun.security.ssl.** { *; }
