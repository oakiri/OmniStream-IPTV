plugins {
    id("com.google.gms.google-services")
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.omnistream.omnistream_iptv"
    // Use a stable SDK level that exists on most dev machines.
    // Android 12+ splash screen support is provided via androidx.core:core-splashscreen.
    compileSdk = 36
    ndkVersion = "28.2.13676358" // O la versión que tengas instalada

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.omnistream.omnistream_iptv"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
        
        multiDexEnabled = true
        
        ndk {
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a", "x86_64"))
        }

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            // MANTENER EN FALSE PARA EVITAR EL ERROR DE FIREBASE
            isMinifyEnabled = false 
            isShrinkResources = false
            
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Jetpack SplashScreen (fixes Theme.SplashScreen / postSplashScreenTheme linking)
    implementation("androidx.core:core-splashscreen:1.0.1")

    // --- ESTO ES LO QUE ARREGLA EL ERROR DE AGP 8.9.1 ---
    // Forzamos versiones estables que funcionan con tu compilador actual
    constraints {
        implementation("androidx.browser:browser:1.8.0") {
            because("1.9.0 requiere una versión de Gradle demasiado nueva")
        }
        implementation("androidx.core:core-ktx:1.13.1") {
            because("1.17.0 requiere una versión de Gradle demasiado nueva")
        }
        implementation("androidx.core:core:1.13.1") {
            because("1.17.0 requiere una versión de Gradle demasiado nueva")
        }
    }
}
// --- PEGA ESTO AL FINAL DEL ARCHIVO android/app/build.gradle.kts ---

configurations.all {
    resolutionStrategy {
        // Obligamos a usar versiones ESTABLES antiguas, ignorando las nuevas betas
        force("androidx.browser:browser:1.8.0")
        force("androidx.core:core-ktx:1.13.1")
        force("androidx.core:core:1.13.1")
    }
}