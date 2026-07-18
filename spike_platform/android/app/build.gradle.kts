plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.memocard.spike.spike_platform"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.memocard.spike.spike_platform"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Explicit minSdk lock — Firebase SDK requires API 23 minimum (per
        // 00-RESEARCH.md Pitfall 3). NOTE (deviation): Flutter 3.41.9's own
        // MinSdkVersionMigration silently rewrites any explicit `minSdk` value
        // in the 16-23 range back to `flutter.minSdkVersion` on every build/run
        // (this SDK's own floor is already 24, above Firebase's requirement).
        // 23 is therefore unstable here — pinned to 24 instead, which is both
        // >= Firebase's floor and immune to that auto-migration.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
