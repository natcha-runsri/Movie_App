plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.cinema_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    // 👉 ใช้ Java 17
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // 👉 ตั้ง jvmTarget 17 (ถ้าจะให้ชัวร์ ใส่ jvmToolchain ด้านล่างด้วย)
    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.cinema_app"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// 👉 แนะนำเพิ่มบล็อกนี้ (เทียบเท่ากำหนด JDK 17 ให้ Kotlin ทั้งโปรเจกต์)
kotlin {
    jvmToolchain(17)
}