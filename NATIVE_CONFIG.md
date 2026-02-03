# Configuración Nativa para OmniStream IPTV

## 📱 Android Configuration

### AndroidManifest.xml

Añade los siguientes permisos en `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.omnistream.app">

    <!-- Permisos necesarios para IPTV -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.CHANGE_NETWORK_STATE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

    <application
        android:label="OmniStream IPTV"
        android:icon="@mipmap/ic_launcher">
        <!-- ... resto de la configuración ... -->
    </application>
</manifest>
```

### build.gradle (Android App)

Asegúrate de que en `android/app/build.gradle` tienes:

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

### Gradle Properties

En `android/gradle.properties`, asegúrate de tener:

```properties
org.gradle.jvmargs=-Xmx4096m
android.useAndroidX=true
android.enableJetifier=true
```

---

## 🍎 iOS Configuration

### Info.plist

Añade la siguiente configuración en `ios/Runner/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- ... configuración existente ... -->
    
    <!-- Permitir carga de contenido desde URLs externas (HTTP) -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
        <key>NSAllowsArbitraryLoadsForMedia</key>
        <true/>
        <key>NSAllowsLocalNetworking</key>
        <true/>
    </dict>
    
    <!-- Permisos de red -->
    <key>NSBonjourServices</key>
    <array>
        <string>_http._tcp</string>
        <string>_https._tcp</string>
    </array>
    
    <!-- Descripción de uso de cámara (si es necesario) -->
    <key>NSCameraUsageDescription</key>
    <string>OmniStream IPTV necesita acceso a la cámara para futuras características</string>
    
    <!-- Descripción de uso de micrófono (si es necesario) -->
    <key>NSMicrophoneUsageDescription</key>
    <string>OmniStream IPTV necesita acceso al micrófono para futuras características</string>
    
</dict>
</plist>
```

### Podfile

Asegúrate de que en `ios/Podfile` tienes:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',
        'PERMISSION_MICROPHONE=1',
      ]
    end
  end
end
```

---

## 🖥️ macOS Configuration

### Info.plist

En `macos/Runner/Info.plist`, añade:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <key>NSAllowsArbitraryLoadsForMedia</key>
    <true/>
</dict>
```

---

## 🌐 Web Configuration

Para la versión web, asegúrate de que `web/index.html` tiene:

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta content="IE=Edge" http-equiv="X-UA-Compatible">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>OmniStream IPTV</title>
    
    <!-- CORS y seguridad -->
    <meta http-equiv="Content-Security-Policy" content="default-src 'self' https: data: blob:;">
    
    <link rel="apple-touch-icon" href="icons/Icon-192.png">
    <link rel="icon" type="image/png" href="favicon.png"/>
</head>
<body>
    <script src="flutter.js" defer></script>
</body>
</html>
```

---

## ✅ Verificación

Después de aplicar estas configuraciones, verifica que:

1. **Android**: `flutter run -d android` compila sin errores
2. **iOS**: `flutter run -d ios` compila sin errores
3. **Web**: `flutter run -d chrome` carga correctamente

Si encuentras problemas con la carga de videos, verifica:

- ✅ Los permisos de INTERNET están habilitados
- ✅ NSAppTransportSecurity permite carga desde URLs externas
- ✅ La URL del stream es válida y accesible
- ✅ El servidor del stream no está bloqueando requests desde móviles

---

## 🔗 URLs de Prueba

Para probar la aplicación, puedes usar estas URLs de prueba (si están disponibles):

```
https://example.com/playlist.m3u
http://localhost:8080/playlist.m3u
```

Asegúrate de reemplazarlas con URLs válidas de tu proveedor IPTV.
