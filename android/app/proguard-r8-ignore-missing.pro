# Дополнительные правила ProGuard для игнорирования ошибок R8
# Используется для игнорирования отсутствующих классов Google Play Core

# Игнорируем все предупреждения и ошибки об отсутствующих классах Google Play Core
# Это безопасно, так как эти классы не используются в runtime
-dontwarn com.google.android.play.core.**
-dontnote com.google.android.play.core.**

