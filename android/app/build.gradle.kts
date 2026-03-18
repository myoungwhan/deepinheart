import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore.properties safely
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        try {
            load(FileInputStream(keystorePropertiesFile))
        } catch (e: Exception) {
            println("Warning: Could not load key.properties")
        }
    }
}

android {
    namespace = "com.deepinheart.deepinheart"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.deepinheart.deepinheart"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"]?.toString() ?: ""
                keyPassword = keystoreProperties["keyPassword"]?.toString() ?: ""
                val storeFilePath = keystoreProperties["storeFile"]?.toString() ?: ""
                if (storeFilePath.isNotEmpty()) {
                    storeFile = file(storeFilePath)
                }
                storePassword = keystoreProperties["storePassword"]?.toString() ?: ""
            }
        }
    }

    buildTypes {
        getByName("debug") {
            // Default debug build doesn't need explicit signingConfig, 
            // it will use the default debug.keystore
            signingConfig = signingConfigs.getByName("debug")
        }

        getByName("release") {
            // Only use release signing if file exists and has content
            if (keystorePropertiesFile.exists() && keystoreProperties.containsKey("keyAlias")) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Fallback to debug signing so the build doesn't fail
                signingConfig = signingConfigs.getByName("debug")
                println("Warning: Release build is using debug signing because key.properties is missing or incomplete")
            }

            isCrunchPngs = true
            isMinifyEnabled = true
            isShrinkResources = true

            ndk {
                debugSymbolLevel = "none"
            }

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    packagingOptions {
        resources {
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "**/attach_hotspot_windows.dll",
                "META-INF/licenses/**",
                "META-INF/AL2.0",
                "META-INF/LGPL2.1",
                "**/libjsc.so",
                "**/libjschelpers.so"
            )
            pickFirsts += setOf(
                "lib/armeabi-v7a/libc++_shared.so",
                "lib/arm64-v8a/libc++_shared.so"
            )
        }
        jniLibs {
            useLegacyPackaging = false
            excludes += setOf(
                "**/libagora_lip_sync_extension.so",
                "**/libagora_spatial_audio_extension.so",
                "**/libagora_audio_beauty_extension.so",
                "**/libagora_face_capture_extension.so",
                "**/libagora_content_inspect_extension.so",
                "**/libagora_segmentation_extension.so",
                "**/libagora_clear_vision_extension.so",
                "**/libagora_ai_echo_cancellation_extension.so",
                "**/libagora_full_audio_format_extension.so"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
    implementation(platform("com.google.firebase:firebase-bom:33.6.0"))
    implementation("com.google.firebase:firebase-messaging-ktx")
    implementation("com.google.firebase:firebase-auth-ktx")
    implementation("com.google.firebase:firebase-analytics-ktx")
    implementation("com.google.firebase:firebase-firestore-ktx")
    implementation("com.google.android.gms:play-services-auth:20.7.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
