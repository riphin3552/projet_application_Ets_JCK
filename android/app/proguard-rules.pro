# Garder les classes AndroidX Window
-keep class androidx.window.** { *; }

# Ne pas générer d’avertissement si extensions/sidecar manquent
-dontwarn androidx.window.extensions.**
-dontwarn androidx.window.sidecar.**

# Garder les classes si elles existent
-keep class androidx.window.extensions.** { *; }
-keep class androidx.window.sidecar.** { *; }

# Garder les membres utilisés par réflexion
-keepclassmembers class androidx.window.** {
    *;
}





-dontwarn androidx.window.extensions.WindowExtensions
-dontwarn androidx.window.extensions.WindowExtensionsProvider
-dontwarn androidx.window.extensions.area.ExtensionWindowAreaPresentation
-dontwarn androidx.window.extensions.layout.DisplayFeature
-dontwarn androidx.window.extensions.layout.FoldingFeature
-dontwarn androidx.window.extensions.layout.WindowLayoutComponent
-dontwarn androidx.window.extensions.layout.WindowLayoutInfo
-dontwarn androidx.window.sidecar.SidecarDeviceState
-dontwarn androidx.window.sidecar.SidecarDisplayFeature
-dontwarn androidx.window.sidecar.SidecarInterface$SidecarCallback
-dontwarn androidx.window.sidecar.SidecarInterface
-dontwarn androidx.window.sidecar.SidecarProvider
-dontwarn androidx.window.sidecar.SidecarWindowLayoutInfo