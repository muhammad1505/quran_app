import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.quran_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlin {
        compilerOptions {
            jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
        }
    }

    // Release signing configuration
    val keystorePropertiesFile = rootProject.file("key.properties")
    val signingRelease = if (keystorePropertiesFile.exists()) {
        println("Found key.properties at: ${keystorePropertiesFile.absolutePath}")
        try {
            val props = Properties().apply { load(keystorePropertiesFile.inputStream()) }
            println("Loaded properties: storeFile=${props["storeFile"]}, keyAlias=${props["keyAlias"]}")
            signingConfigs.create("release") {
                storeFile = file(props.getProperty("storeFile"))
                storePassword = props.getProperty("storePassword")
                keyAlias = props.getProperty("keyAlias")
                keyPassword = props.getProperty("storePassword")
            }
        } catch (e: Exception) {
            println("❌ Error loading release signing config: ${e.message}")
            e.printStackTrace()
            null
        }
    } else {
        println("⚠️ key.properties not found, skipping release signing configuration")
        null
    }

    defaultConfig {
        applicationId = "com.example.quran_app"
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingRelease ?: signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

