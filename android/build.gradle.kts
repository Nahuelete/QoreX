import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    `java-gradle-plugin`
    groovy
    `kotlin-dsl`
    kotlin("jvm") version "1.9.20" apply false
    id("com.android.application") version "8.1.0" apply false
    id("com.android.library") version "8.1.0" apply false
}

group = "dev.flutter.plugin"
version = "1.0.0"

// Valida que la configuración de plugins sea correcta
tasks.validatePlugins {
    enableStricterValidation.set(true)
}

// Definición de plugins de Flutter
gradlePlugin {
    plugins {
        create("flutterPlugin") {
            id = "dev.flutter.flutter-gradle-plugin"
            implementationClass = "com.flutter.gradle.FlutterPlugin"
        }
        create("flutterAppPluginLoaderPlugin") {
            id = "dev.flutter.flutter-plugin-loader"
            implementationClass = "com.flutter.gradle.FlutterAppPluginLoaderPlugin"
        }
    }
}

// Configuración de compilación Java
tasks.withType<JavaCompile> {
    options.release.set(17)
}

// Configuración de compilación Kotlin
tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

// Dependencias necesarias para plugins y testing
dependencies {
    compileOnly("androidx.annotation:annotation-jvm:1.9.1")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.4.0")

    testImplementation(kotlin("test"))
    testImplementation("org.mockito:mockito-core:5.8.0")
    testImplementation("io.mockk:mockk:1.13.16")
}




