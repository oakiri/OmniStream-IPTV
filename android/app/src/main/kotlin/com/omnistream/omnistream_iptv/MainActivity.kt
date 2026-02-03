package com.omnistream.omnistream_iptv

import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Enables the new SplashScreen behavior on Android 12+ and provides
        // consistent behavior via the Jetpack SplashScreen library.
        installSplashScreen()
        super.onCreate(savedInstanceState)
    }
}
