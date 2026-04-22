# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in ${sdk.dir}/tools/proguard/proguard-android.txt

# Compose
-keep class androidx.compose.** { *; }

# Keep Material classes
-keep class com.google.android.material.** { *; }
