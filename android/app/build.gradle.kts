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
        load(FileInputStream(keystorePropertiesFile))
    }
}

android {
    namespace = "com.deepinheart.deepinheart"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        // Enable core library desugaring and use Java 21
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8  // Change this to Java 17
        targetCompatibility = JavaVersion.VERSION_1_8  // Change this to Java 17
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }
    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.deepinheart.deepinheart"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

  
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"]?.toString()
                ?: throw GradleException("Missing keyAlias in key.properties")
            keyPassword = keystoreProperties["keyPassword"]?.toString()
                ?: throw GradleException("Missing keyPassword in key.properties")
            storeFile = file(
                keystoreProperties["storeFile"]?.toString()
                    ?: throw GradleException("Missing storeFile in key.properties")
            )
            storePassword = keystoreProperties["storePassword"]?.toString()
                ?: throw GradleException("Missing storePassword in key.properties")
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")

            // Enable R8 full mode for maximum optimization
            isCrunchPngs = true  // Enable PNG compression
            isMinifyEnabled = true
            isShrinkResources = true

            // Strip debug symbols to reduce size
            ndk {
                debugSymbolLevel = "none"
            }

            // Use default optimized rules + custom rules file
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    /*
    // Split APKs by ABI to reduce individual APK size
    splits {
        abi {
            isEnable = true
            reset()
            include("armeabi-v7a", "arm64-v8a", "x86_64")
            isUniversalApk = false  // Set to true if you want a universal APK
        }
    }
    */

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
            // Pick first occurrence for remaining architectures
            pickFirsts += setOf(
                "lib/armeabi-v7a/libc++_shared.so",
                "lib/arm64-v8a/libc++_shared.so"
            )
        }
        jniLibs {
            useLegacyPackaging = false  // Use new packaging format for better compression
            // IMPORTANT: Do not exclude lib/x86/*.so or lib/x86_64/*.so as they contain libflutter.so
            // Only exclude specific unused Agora extensions to save space
            excludes += setOf(
                // Exclude unused Agora extensions (save ~20MB)
                // Note: Keep libflutter.so for all architectures
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

    // Configure resource shrinking keep.xml
    // This file can be created in res/raw/ to specify resources to keep
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")

    // Updated Firebase dependencies
    implementation(platform("com.google.firebase:firebase-bom:33.6.0"))
    implementation("com.google.firebase:firebase-messaging-ktx")
    implementation("com.google.firebase:firebase-auth-ktx")
    implementation("com.google.firebase:firebase-analytics-ktx")
    implementation("com.google.firebase:firebase-firestore-ktx")

    // Updated Google Play services auth
    implementation("com.google.android.gms:play-services-auth:20.7.0")

    // Enable core library desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

//com.deepinheart.deepinheart

