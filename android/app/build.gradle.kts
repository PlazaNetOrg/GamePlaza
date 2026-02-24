import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "org.plazanet.gameplaza"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    signingConfigs {
        create("release") {
            val keystorePath = System.getProperty("user.home") + "/.gradle/local.properties"
            val localProps = Properties()
            if (file(keystorePath).exists()) {
                localProps.load(file(keystorePath).inputStream())
            } else {
                localProps.load(file("${project.projectDir}/../local.properties").inputStream())
            }
            
            storeFile = file(localProps["KEYSTORE_PATH"].toString())
            storePassword = localProps["KEYSTORE_PASSWORD"].toString()
            keyAlias = localProps["KEY_ALIAS"].toString()
            keyPassword = localProps["KEY_PASSWORD"].toString()
        }
    }

    defaultConfig {
        applicationId = "org.plazanet.gameplaza"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
}
