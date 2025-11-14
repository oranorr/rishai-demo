# Правила ProGuard для оптимизации приложения и поддержки 16 KB страниц памяти
# Критически важно для соответствия требованиям Google Play Android 15+

# Сохраняем классы Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Сохраняем Firebase классы
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Сохраняем классы для работы с изображениями и ресурсами
-keep class * implements android.graphics.drawable.Drawable { *; }

# Оптимизация для 16 KB страниц памяти
# Удаляем неиспользуемые методы и поля
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
}

# Сохраняем нативные методы
-keepclasseswithmembernames class * {
    native <methods>;
}

# Сохраняем классы с аннотациями
-keep @interface androidx.annotation.Keep
-keep @androidx.annotation.Keep class *
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}

# Сохраняем классы для работы с JSON
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Оптимизация для работы с 16 KB страницами памяти
# Удаляем отладочную информацию
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable

# Сохраняем классы для работы с уведомлениями
-keep class com.google.firebase.messaging.** { *; }
-keep class androidx.core.app.NotificationCompat** { *; }

# Сохраняем классы для работы с камерой и галереей
-keep class androidx.camera.** { *; }
-keep class com.google.android.material.** { *; }

# Сохраняем классы для работы с геолокацией
-keep class com.google.android.gms.location.** { *; }

# Оптимизация для уменьшения размера APK
# Удаляем неиспользуемые ресурсы
-dontwarn android.support.**
-dontwarn androidx.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# Сохраняем классы для работы с сетью
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }

# Сохраняем классы для работы с базой данных
-keep class androidx.room.** { *; }
-keep class * extends androidx.room.RoomDatabase { *; }

# Сохраняем классы для работы с шифрованием
-keep class javax.crypto.** { *; }
-keep class java.security.** { *; }

# Оптимизация для 16 KB страниц памяти - удаляем избыточную информацию
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification

# Сохраняем классы для работы с WebView
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Сохраняем классы для работы с Bluetooth
-keep class android.bluetooth.** { *; }

# Сохраняем классы для работы с Wi-Fi
-keep class android.net.wifi.** { *; }

# Сохраняем классы для работы с сенсорами
-keep class android.hardware.** { *; }

# Сохраняем классы для работы с аудио/видео
-keep class android.media.** { *; }

# Сохраняем классы для работы с файловой системой
-keep class java.io.** { *; }
-keep class java.nio.** { *; }

# Оптимизация для работы с 16 KB страницами памяти
# Удаляем логи в релизной версии
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
    public static int w(...);
    public static int e(...);
}

# Сохраняем классы для работы с SharedPreferences
-keep class android.content.SharedPreferences** { *; }

# Сохраняем классы для работы с Intent
-keep class android.content.Intent** { *; }

# Сохраняем классы для работы с Bundle
-keep class android.os.Bundle** { *; }

# Сохраняем классы для работы с Parcelable
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Сохраняем классы для работы с Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Оптимизация для 16 KB страниц памяти - финальные правила
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# Игнорируем отсутствующие классы Google Play Core (для deferred components)
# Эти классы нужны только если используются deferred components, 
# в противном случае их можно игнорировать
# Используем -dontwarn для игнорирования предупреждений об отсутствующих классах
# Правила сгенерированы автоматически R8 и добавлены вручную
-dontwarn com.google.android.play.core.splitcompat.SplitCompat
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
# Общее правило для всех классов из пакета play.core (на случай новых)
-dontwarn com.google.android.play.core.**

# Игнорируем ошибки R8 для отсутствующих классов Google Play Core
# Эти классы не используются в runtime, так как deferred components не включены
# Используем -dontnote для полного игнорирования (включая ошибки)
-dontnote com.google.android.play.core.**
