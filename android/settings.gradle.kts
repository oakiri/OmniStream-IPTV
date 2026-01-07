// Load Flutter SDK path from local.properties
val localProperties = java.util.Properties()
val localPropertiesFile = rootProject.projectDir.parentFile.parentFile.resolve("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

val flutterSdkPath = localProperties.getProperty("flutter.sdk")
    ?: throw GradleException("flutter.sdk not found in local.properties")

// Add Flutter SDK to plugin management
includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.6.0" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
