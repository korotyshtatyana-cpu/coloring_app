# Flutter ProGuard Keep Rules

-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }
-keep class io.flutter.plugins.** { *; }

# Ignore missing Play Core classes referenced by Flutter JNI deferred components
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Keep Drift / SQLite native bindings
-keep class com.simonbinder.sqlite3.** { *; }
-keep class io.simonbinder.sqlite3.** { *; }
-keep class sqlite3.** { *; }

# Keep Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
