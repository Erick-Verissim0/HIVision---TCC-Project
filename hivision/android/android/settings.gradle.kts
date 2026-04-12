pluginManagement {
    val localPropertiesFile = file("local.properties")
    val properties = java.util.Properties()

    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use { properties.load(it) }
    }

    if (properties.getProperty("sdk.dir").isNullOrBlank()) {
        val sdkCandidates = listOfNotNull(
            System.getenv("ANDROID_HOME"),
            System.getenv("ANDROID_SDK_ROOT"),
            "${System.getProperty("user.home")}/Library/Android/sdk",
            "${System.getProperty("user.home")}/Android/Sdk",
        )

        val detectedSdk = sdkCandidates.firstOrNull { path -> file(path).exists() }
        if (detectedSdk != null) {
            properties.setProperty("sdk.dir", detectedSdk)
            localPropertiesFile.writer().use { writer -> properties.store(writer, null) }
        }
    }

    val flutterSdkPath =
        run {
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
