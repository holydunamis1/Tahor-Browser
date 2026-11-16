# Keep rules for release builds (R8). Each later batch that adds a plugin with
# reflection adds its rules here, and the release APK is launched to confirm.

# The web view plugin reaches its Android classes by name.
-keep class com.pichillilorenzo.flutter_inappwebview_android.** { *; }

# Flutter references Play Core classes that this app does not ship.
-dontwarn com.google.android.play.core.**
