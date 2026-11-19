# Zoom Meeting SDK - Core Classes (CRITICAL for native crash fix)
-keep class us.zoom.** { *; }
-keep class com.zipow.** { *; }
-keep class us.zipow.** { *; }
-keep class net.zoom.** { *; }
-dontwarn com.zipow.**
-dontwarn us.zipow.**
-dontwarn net.zoom.**

# WebRTC (required by Zoom)
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**

# Protobuf (required by Zoom)
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# JWT and Encryption used by Zoom
-keep class com.google.crypto.tink.** { *; }
-keep class androidx.security.crypto.** { *; }

# Prevent R8 from removing native interface methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep all classes with native methods
-keepclasseswithmembers class * {
    native <methods>;
}

# Flutter Method Channels (for zoom_meeting_sdk_flutter plugin)
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.view.** { *; }

# Keep all annotations
-keepattributes *Annotation*

# Keep source file names and line numbers for better crash reports
-keepattributes SourceFile,LineNumberTable

# Keep generic signatures for reflection
-keepattributes Signature

# Keep inner classes
-keepattributes InnerClasses

# Keep exceptions
-keepattributes Exceptions

# Zoom SDK specific - prevent obfuscation of callback methods
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# RxJava - prevent issues with Zoom internal threading
-keep class io.reactivex.** { *; }
-keep class io.reactivex.rxjava3.** { *; }
-dontwarn io.reactivex.**
-dontwarn io.reactivex.rxjava3.**

# Preserve native method signatures
-keepclasseswithmembers class * {
    native <methods>;
}

# Keep serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Suppress warnings
-dontwarn us.zoom.**
-dontwarn com.zipow.**
-dontwarn us.zipow.**
-dontwarn org.webrtc.**
-dontwarn com.google.protobuf.**

# Zoom SDK specific
-keep class us.zoom.**{ *; }
-keep class us.zoom.sdk.**{ *; }
-keep class us.zoom.proguard.**{ *; }
-keep class us.zipow.**{ *; }
-keep class com.zipow.**{ *; }
-keep class com.zipow.videobox.**{ *; }
-keep class org.webrtc.**{ *; }
-keep class us.google.protobuf.**{ *; }
-keep class com.google.crypto.tink.** { *; }
-keep class androidx.security.crypto.** { *; }
-keep class com.davemorrissey.labs.subscaleview.** { *; }

# eSewa SDK
-keep class com.esewa.** { *; }
-keep class com.f1soft.esewasdk.** { *; }

# Jetpack Compose (Required by Zoom SDK)
-keep class androidx.compose.** { *; }
-dontwarn androidx.compose.**

# AndroidX and Support Library
-keep class androidx.appcompat.** { *; }
-keep class androidx.core.** { *; }
-keep class androidx.lifecycle.** { *; }
-keep class com.google.android.material.** { *; }

# Prevent shrinking of Zoom resources
-keep class us.zoom.videomeetings.R$* { *; }
-keep class com.zipow.videobox.R$* { *; }

# Workaround for IllegalStateException in createSubDecor
-keep class androidx.appcompat.app.AppCompatDelegateImpl { *; }
-keep class androidx.appcompat.app.AppCompatViewInflater { *; }
