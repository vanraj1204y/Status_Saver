# Flutter's own engine/embedding keep rules are injected automatically by
# the Flutter Gradle plugin. The plugins this app uses (video_player,
# webview_flutter, shared_preferences, url_launcher, package_info_plus,
# provider, font_awesome_flutter) are modern federated plugins that ship
# their own consumer ProGuard rules bundled in their AARs, so this file
# only needs to cover our own native code and standard safe defaults.

# Keep our MethodChannel handler and its call surface — argument values are
# passed as platform-channel maps (no reflection), but keep the class shape
# stable in case R8 ever tries to inline/rename across the JNI-ish boundary.
-keep class com.statussaver.app.** { *; }

# Standard Android/Kotlin metadata used by libraries at runtime.
-keepattributes Signature,InnerClasses,EnclosingMethod,*Annotation*
-keep class kotlin.Metadata { *; }
