pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
    
    plugins {
        id("com.android.application") version "8.2.1"
        id("org.jetbrains.kotlin.android") version "1.9.22"
    }
}

plugins {
    id("dev.flutter.flutter-gradle-plugin") apply false
}

include(":app")
