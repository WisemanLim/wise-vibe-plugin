// {{PROJECT_NAME}} — root build (정적 템플릿 / static scaffold)
plugins {
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.1.0" apply false
    // kapt 대신 KSP — JDK 25 호환, kapt는 JDK 25 javacOptions 파싱 불가
    id("com.google.devtools.ksp") version "2.1.0-1.0.29" apply false
}
