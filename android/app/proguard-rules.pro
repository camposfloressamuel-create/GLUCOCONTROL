# Reglas ProGuard/R8 para flutter_local_notifications y GSON
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.examples.android.model.** { <fields>; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * extends com.google.gson.internal.bind.TypeAdapterFactory
-keep class * extends com.google.gson.JsonSerializer
-keep class * extends com.google.gson.JsonDeserializer
-keep class com.dexterous.** { *; }

# Mantener clases de notificaciones locales
-keep class com.dexterous.flutterlocalnotifications.** { *; }
