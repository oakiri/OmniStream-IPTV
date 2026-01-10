# Flutter y Plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase Auth y Core (El arreglo crítico)
-keep class com.google.firebase.auth.** { *; }
-keep class io.flutter.plugins.firebase.auth.** { *; }
-keep class io.flutter.plugins.firebase.core.** { *; }
-keep class com.google.firebase.** { *; }

# Arreglo específico para el error PigeonUserDetails
-keep class **.PigeonUserDetails { *; }
-keep class io.flutter.plugins.firebase.auth.GeneratedAndroidFirebaseAuth$PigeonUserDetails { *; }

# Evitar que R8 rompa las estructuras de datos genéricas
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Silenciar advertencias
-dontwarn io.flutter.**
-dontwarn com.google.firebase.**
-dontwarn androidx.***

# Proteger los modelos de datos de tu app (ajusta la ruta si cambiaste nombres)
-keep class com.example.omnistream_iptv.features.** { *; }
-keep class com.omnistream.app.** { *; } 

# Por si usas Hive (base de datos local)
-keep class androidx.lifecycle.DefaultLifecycleObserver
-keep class **.g.dart
-keepnames class * extends com.google.protobuf.GeneratedMessageLite { *; }

# Protección genérica para evitar que R8 rompa los nombres de variables JSON
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keepclassmembers enum * { *; }