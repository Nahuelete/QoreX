import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.bluetooth"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.bluetooth"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ⭐ AGREGADO PARA ML KIT (Sintaxis Kotlin DSL)
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
    
    @Suppress("DEPRECATION")
    aaptOptions {
        noCompress("tflite")
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

tasks.withType<KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

dependencies {

    // Firebase BOM (mantiene todo alineado entre Android e iOS)
    implementation(platform("com.google.firebase:firebase-bom:33.5.1"))

    // Firebase Messaging SIN firebase-iid (evita clases duplicadas)
    implementation("com.google.firebase:firebase-messaging") {
        exclude(group = "com.google.firebase", module = "firebase-iid")
    }
}