import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// App name/version/applicationId live in the repo-root .env so a release
// bump (or a white-label rebrand) is a one-file edit instead of hunting
// through Gradle. Falls back to sane defaults if .env is missing so a
// fresh checkout still builds. `namespace` below and the Kotlin package
// folders/declarations under android/app/src/main/kotlin are NOT driven by
// .env — they're fixed at project creation.
val envProps = Properties().apply {
    val envFile = rootProject.file("../.env")
    if (envFile.exists()) {
        envFile.forEachLine { line ->
            val trimmed = line.trim()
            if (trimmed.isNotEmpty() && !trimmed.startsWith("#") && trimmed.contains("=")) {
                val (key, value) = trimmed.split("=", limit = 2)
                setProperty(key.trim(), value.trim())
            }
        }
    }
}
val envAppName: String = envProps.getProperty("APP_NAME", "StatusNest")
val envVersionName: String = envProps.getProperty("APP_VERSION_NAME", "1.0.0")
val envVersionCode: Int = envProps.getProperty("APP_VERSION_CODE", "1").toInt()
val envApplicationId: String = envProps.getProperty("APP_PACKAGE_NAME", "com.twocompo.statusnest")

// Release signing is read from android/key.properties, which is gitignored.
// Debug builds fall back to the standard debug keystore.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) {
        file.inputStream().use { load(it) }
    }
}
val hasReleaseKeystore = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "com.statussaver.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = envApplicationId
        minSdk = 24
        targetSdk = 35
        versionCode = envVersionCode
        versionName = envVersionName
        manifestPlaceholders["appLabel"] = envAppName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                // No keystore configured yet. The debug key keeps
                // `flutter build apk --release` working for sideloading.
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.documentfile:documentfile:1.0.1")
}

flutter {
    source = "../.."
}
