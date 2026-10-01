// {{PROJECT_NAME}} — app module (빌드 플레이버 = 환경 매핑)
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
    id("com.google.devtools.ksp")  // kapt 대신 KSP — JDK 25 호환
}

android {
    namespace = "com.example.{{PROJECT_NAME}}"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.example.{{PROJECT_NAME}}"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "0.1.0"
    }

    flavorDimensions += "env"
    productFlavors {
        create("local") { dimension = "env"; buildConfigField("String", "API_BASE_URL", "\"http://10.0.2.2:8000\"") }
        create("prod")  { dimension = "env"; buildConfigField("String", "API_BASE_URL", "\"https://api.example\"") }
    }
    buildFeatures { compose = true; buildConfig = true }
}

dependencies {
    implementation(platform("androidx.compose:compose-bom:2025.01.00"))
    implementation("androidx.compose.material3:material3")
    implementation("androidx.activity:activity-compose:1.9.3")
}
