plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // ✅ Kotlin plugin
    id("com.google.gms.google-services") // ✅ Firebase plugin
    id("dev.flutter.flutter-gradle-plugin") // ✅ Flutter plugin cuối cùng
}

android {
    namespace = "com.example.cuahanghoa_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // ✅ JDK 25 hỗ trợ Java 21, dùng bản này
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        jvmTarget = "21"
    }

    defaultConfig {
        applicationId = "com.example.cuahanghoa_flutter"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            // 🔹 Dùng debug key để tránh lỗi khi chưa ký keystore riêng
            signingConfig = signingConfigs.getByName("debug")

            // 🔹 Tắt shrink để tránh lỗi build
            isMinifyEnabled = false
            isShrinkResources = false
        }

        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Firebase SDKs cơ bản
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-database")
    implementation("com.google.firebase:firebase-storage")

    // (Tuỳ chọn nếu bạn có Firestore)
    // implementation("com.google.firebase:firebase-firestore")
}
