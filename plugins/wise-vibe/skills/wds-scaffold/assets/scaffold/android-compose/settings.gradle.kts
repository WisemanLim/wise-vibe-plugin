// {{PROJECT_NAME}} — android-compose (정적 템플릿 / static scaffold)
pluginManagement {
    repositories { google(); mavenCentral(); gradlePluginPortal() }
}
dependencyResolutionManagement {
    repositories { google(); mavenCentral() }
}
rootProject.name = "{{PROJECT_NAME}}"
include(":app")
