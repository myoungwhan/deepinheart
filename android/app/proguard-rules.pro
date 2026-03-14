# Optimized Proguard Rules for Deepinheart
# This file is configured to maximize code shrinking and reduce APK size.

# Stripe: Ignore warnings for optional push provisioning classes
-dontwarn com.stripe.android.pushProvisioning.**
-dontwarn com.reactnativestripesdk.** # If applicable
-keep class com.stripe.** { *; }

# Firebase and Google Play Services rules are typically handled by the libraries themselves.

# Agora RTC: Keep only essential classes for JNI and media processing
-keep class io.agora.rtc.** { *; }
-keep class io.agora.media.** { *; }
-keep class io.agora.base.** { *; }
-keep class io.agora.rtc.internal.** { *; }
-keep class io.agora.ans.** { *; }
-keep class io.agora.dr.internal.** { *; }

# Remove unused Agora logging to save space
-assumenosideeffects class io.agora.rtc.internal.Logging {
    public static *** v(...);
    public static *** d(...);
    public static *** i(...);
    public static *** log(...);
}

# Flutter optimization
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# General optimization rules
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

# Remove Android logging
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int i(...);
    public static int d(...);
    public static int w(...);
    public static int e(...);
}

# Keep native methods (Crucial for Agora and Flutter)
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enums and Parcelable
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Remove unused resources references in code
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Renaming and obfuscation improvements
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable,Signature,EnclosingMethod,InnerClasses