import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}
val storePasswordEnv = System.getenv("SAATENSCHLUESSEL_STORE_PASSWORD")
val keyPasswordEnv = System.getenv("SAATENSCHLUESSEL_KEY_PASSWORD")

android {
    namespace = "app.saatenschluessel"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "app.saatenschluessel"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (
            keystorePropertiesFile.exists() &&
                storePasswordEnv != null &&
                keyPasswordEnv != null
        ) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keyPasswordEnv
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = storePasswordEnv
            }
        }
    }

    buildTypes {
        release {
            if (
                keystorePropertiesFile.exists() &&
                    storePasswordEnv != null &&
                    keyPasswordEnv != null
            ) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                throw GradleException(
                    "Missing Android release signing configuration. " +
                        "Provide android/key.properties plus the environment variables " +
                        "SAATENSCHLUESSEL_STORE_PASSWORD and " +
                        "SAATENSCHLUESSEL_KEY_PASSWORD.",
                )
            }
        }
    }
}

flutter {
    source = "../.."
}
