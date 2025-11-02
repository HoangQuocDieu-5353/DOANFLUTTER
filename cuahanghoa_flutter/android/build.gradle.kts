// ✅ Root-level Gradle build file cho Flutter + Firebase (Hỗ trợ JDK 25)

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // 🔥 Plugin Google Services để cấu hình Firebase
        classpath("com.google.gms:google-services:4.4.2")

        // 🔥 Kotlin plugin (bắt buộc cho KTS)
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.25")

        // (Tùy chọn) Firebase Crashlytics và Performance Monitoring
        // classpath("com.google.firebase:firebase-crashlytics-gradle:2.9.9")
        // classpath("com.google.firebase:perf-plugin:1.4.2")

        // ⚡️ Nếu dùng JDK 25, đảm bảo Gradle Wrapper >= 8.7
        // Bạn có thể kiểm tra tại file gradle/wrapper/gradle-wrapper.properties
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ Đồng bộ build folder để tránh lỗi path trong multi-module
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Bắt buộc để app được đánh giá trước
    project.evaluationDependsOn(":app")
}

// ✅ Task dọn dẹp build folder
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
