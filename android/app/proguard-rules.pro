# Flutter-specific ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Hive
-keep class hive.** { *; }
-keep class * extends hive.GeneratedAdapter { *; }
-keepclassmembers class * extends hive.HiveObject {
    <fields>;
}

# Your models (prevent field name obfuscation)
-keep class com.example.hakeem.** { *; }

# General optimizations
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

# Keep generic signatures for reflection
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}