plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.vodid_prototype2"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Proje kaynakları için Java 11 hedefi (AGP JDK >=17 ister; bu ayar kaynak uyumluluğudur)
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Uygulama paket adı Firebase’de kayıtlı olandan farklıysa BURAYI Firebase’dekiyle aynı yap.
        applicationId = "com.example.vodid_prototype2"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // İleride release keystore ekleyeceğiz; şimdilik debug imzası ile çalışsın
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// NOT: .kts dosyasında Groovy formatındaki
// apply plugin: 'com.google.gms.google-services'
// SATIRINI KULLANMAYACAĞIZ. (Yukarıdaki plugins bloğu zaten yeterli.)
