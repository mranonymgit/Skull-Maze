import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ==============================================================================
// 1. CARGA DE ARCHIVOS DE PROPIEDADES (key.properties)
// Adaptado a la sintaxis Kotlin (KTS)
// ==============================================================================
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use {
        localProperties.load(it)
    }
}

val signingProperties = Properties()
// Busca key.properties en el directorio raíz de Android (tu_proyecto/android/)
val signingPropertiesFile = rootProject.file("key.properties")
if (signingPropertiesFile.canRead()) {
    signingPropertiesFile.inputStream().use {
        signingProperties.load(it)
    }
}
// ==============================================================================

android {
    namespace = "com.example.skull_maze"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // ==============================================================================
    // 2. CONFIGURACIÓN DE FIRMA (Usa las propiedades cargadas)
    // ==============================================================================
    signingConfigs {
        create("release") {
            // Buscamos el archivo key.properties en el directorio padre (android/)
            val keyPropertiesFile = rootProject.file("key.properties")
            if (keyPropertiesFile.exists()) {
                val props = Properties().apply { load(FileInputStream(keyPropertiesFile)) }

                // La ruta del JKS (storeFile) se busca desde el contexto de android/app/.
                // Por eso, la propiedad "storeFile" solo debe contener el nombre del JKS.
                val storeName = props.getProperty("storeFile")

                storeFile = file(storeName) // Aquí usa solo el nombre: SkullMaze.jks
                storePassword = props.getProperty("storePassword")
                keyAlias = props.getProperty("keyAlias")
                keyPassword = props.getProperty("keyPassword")
            } else {
                // FALLO CRÍTICO: Si key.properties no existe, esto imprimirá un mensaje
                println("ERROR: key.properties file not found in android/ directory.")
            }
        }
    }
    // ==============================================================================

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.skull_maze"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            // Usa la configuración de firma definida arriba
            signingConfig = signingConfigs.getByName("release")

            // Opciones de optimización.
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}

flutter {
    source = "../.."
}